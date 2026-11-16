#!/usr/bin/env python3
"""Plan a release from published tags and PRs merged into dev or main."""

import json
import os
from pathlib import Path
import re
import subprocess
import sys

TAG = re.compile(r"v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)")
APP_PATHS = ("FlutterRunlet", "FlutterRunlet.xcodeproj", "FlutterRunletSessionWorker", "FlutterRunletUpdateHelper")
FIELDS = ("Release type", "简体中文", "English")


def command(*args):
    return subprocess.check_output(args, text=True).strip()


def api(endpoint):
    return json.loads(command("gh", "api", "--paginate", "--slurp", endpoint))


def metadata(pr):
    sections = {}
    section = None
    for line in re.sub(r"<!--.*?-->", "", pr["body"] or "", flags=re.S).splitlines():
        if match := re.fullmatch(r"#{1,6}\s+(.+?)\s*", line):
            section = match[1]
            if section in FIELDS:
                if section in sections:
                    raise ValueError(f"PR #{pr['number']} repeats the {section} section.")
                sections[section] = []
        elif section in FIELDS and line.strip():
            sections[section].append(line.strip())

    kind = sections.get("Release type", [])
    if kind == ["none"]:
        return None
    if kind == ["manual"]:
        raise ValueError(f"PR #{pr['number']} needs a manually chosen version.")
    if kind not in (["patch"], ["minor"]) or any(len(sections.get(lang, [])) != 1 for lang in FIELDS[1:]):
        raise ValueError(f"PR #{pr['number']} needs a release type and one update sentence in each language.")
    return kind[0], sections["简体中文"][0], sections["English"][0]


def plain_markdown(text):
    return re.sub(r"([\\`*_{}\[\]()<>#|!~@&:\$])", r"\\\1", text)


def plan(repo, head, notes_path):
    releases = [release for page in api(f"repos/{repo}/releases?per_page=100") for release in page]
    published = [
        (tuple(map(int, match.groups())), match[0])
        for release in releases
        if not release["draft"] and (match := TAG.fullmatch(release["tag_name"]))
    ]
    if not published:
        raise ValueError("No published vX.Y.Z release to use as a baseline.")
    (major, minor, patch), base = max(published)
    base_ref = f"refs/tags/{base}"
    if subprocess.run(["git", "merge-base", "--is-ancestor", base_ref, head], check=False).returncode:
        raise ValueError(f"Published baseline {base} is not in the selected main history.")

    if not command("git", "diff", "--name-only", base_ref, head, "--", *APP_PATHS):
        return None, base

    entries = []
    # dev and hotfix PRs use squash. The dev-to-main promotion keeps their commits.
    commits = command("git", "rev-list", "--reverse", "--full-history", "--no-merges", f"{base_ref}..{head}", "--", *APP_PATHS)
    if not commits:
        raise ValueError("Application changes have no source PR commits in the release range.")
    for commit in commits.splitlines():
        matches = [
            pr for page in api(f"repos/{repo}/commits/{commit}/pulls?per_page=100") for pr in page
            if pr["merged_at"] and pr["merge_commit_sha"] == commit
            and pr["base"]["ref"] in ("dev", "main") and pr["base"]["repo"]["full_name"] == repo
        ]
        if len(matches) != 1:
            raise ValueError(f"Cannot associate application commit {commit[:12]} with one merged PR.")
        pr = matches[0]
        if entry := metadata(pr):
            entries.append((pr["number"], *entry))

    if not entries:
        return None, base

    version = f"v{major}.{minor + 1}.0" if any(kind == "minor" for _, kind, *_ in entries) else f"v{major}.{minor}.{patch + 1}"
    if command("git", "tag", "--list", version) or any(release["tag_name"] == version for release in releases):
        raise ValueError(f"{version} is already reserved by a tag or Release.")

    lines = []
    for language, feature, fixes, index in (("简体中文", "新增", "修复", 2), ("English", "Features", "Fixes", 3)):
        lines.extend((f"## {language}", ""))
        for kind, title in (("minor", feature), ("patch", fixes)):
            group = [entry for entry in entries if entry[1] == kind]
            if group:
                lines.extend((f"### {title}", ""))
                for entry in group:
                    number = entry[0]
                    lines.append(f"- {plain_markdown(entry[index])} ([#{number}](https://github.com/{repo}/pull/{number}))")
                lines.append("")
    notes_path.write_text("\n".join(lines), encoding="utf-8")
    return version, base


if __name__ == "__main__":
    try:
        repo = os.environ["GITHUB_REPOSITORY"]
        head = command("git", "rev-parse", "HEAD")
        version, baseline = plan(repo, head, Path(sys.argv[1]))
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
            print(f"version={version or ''}", file=output)
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as summary:
            if version:
                print(f"Candidate: `{version}` from `{baseline}` at `{head}`.", file=summary)
            else:
                print(f"No releasable application changes since `{baseline}`. Candidate skipped.", file=summary)
    except (ValueError, subprocess.CalledProcessError) as error:
        print(f"::error::{error}", file=sys.stderr)
        sys.exit(1)
