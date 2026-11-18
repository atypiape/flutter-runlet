"""预览已合入远端 dev 的本地分支及其 worktree，指定 --apply 时清理。"""

import argparse
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys


queue = runpy.run_path(str(Path(__file__).with_name("verify-issue-queue.py")))
REPO = queue["REPO"]
check_origin = queue["check_origin"]
gh = queue["gh_json"]
HEADS = "refs/heads/"
DEV = "refs/remotes/origin/dev"


def git(*args, accepted=(0,)):
    result = subprocess.run(
        ["git", "--no-replace-objects", *args],
        capture_output=True, encoding="utf-8", timeout=90,
    )
    if result.returncode not in accepted:
        raise RuntimeError(f"Git {args[0]} 失败：{result.stderr.strip()}")
    return result


def branch_worktrees():
    worktrees = {}
    for record in git("worktree", "list", "--porcelain", "-z").stdout.split("\0\0"):
        fields = record.split("\0")
        for field in fields[1:]:
            if field.startswith("branch "):
                ref = field.removeprefix("branch ")
                worktrees.setdefault(ref, []).append(fields[0].removeprefix("worktree "))
    return worktrees


def current_branch():
    return git("symbolic-ref", "--quiet", "HEAD", accepted=(0, 1)).stdout.strip()


def is_ancestor(head, dev):
    return git("merge-base", "--is-ancestor", head, dev, accepted=(0, 1)).returncode == 0


def merged_pr(branch, head, dev):
    pages = gh("--method", "GET", "--paginate", "--slurp", f"repos/{REPO}/pulls",
               "-f", "state=closed", "-f", "base=dev",
               "-f", f"head={REPO.split('/')[0]}:{branch}", "-F", "per_page=100")
    for page in pages:
        for pr in page:
            source, target = pr["head"], pr["base"]
            if (not pr["merged_at"] or source["ref"] != branch or source["sha"] != head
                    or (source["repo"] or {}).get("full_name") != REPO
                    or target["ref"] != "dev" or target["repo"]["full_name"] != REPO):
                continue
            merge = pr["merge_commit_sha"] or ""
            if not re.fullmatch(r"[0-9a-f]{40}", merge):
                continue
            if git("cat-file", "-e", f"{merge}^{{commit}}", accepted=(0, 1, 128)).returncode == 0:
                if is_ancestor(merge, dev):
                    return {"type": "merged-pr", "pr": pr["number"], "commit": merge}
    return None


def scan(dev, selected=None):
    worktrees = branch_worktrees()
    current = current_branch()
    branches = []
    refs = git("for-each-ref", "--format=%(refname) %(objectname)", HEADS).stdout
    for line in refs.splitlines():
        ref, head = line.split(" ")
        branch = ref.removeprefix(HEADS)
        if selected is not None and branch != selected:
            continue
        item = {"branch": branch, "head": head, "status": "protected"}
        branches.append(item)
        if branch in {"main", "dev"} or branch.startswith("codex/"):
            continue
        if ref == current:
            item["status"] = "current"
            continue
        evidence = {"type": "ancestor"} if is_ancestor(head, dev) else merged_pr(branch, head, dev)
        if evidence is None:
            item["status"] = "unmerged"
        else:
            item["evidence"] = evidence
            item["status"] = "merged"
            if ref in worktrees:
                item["worktrees"] = worktrees[ref]
    return branches


def still_eligible(item, ref):
    if ref == current_branch():
        item["status"] = "current"
        return False
    current = git("for-each-ref", "--format=%(refname) %(objectname)", ref).stdout.splitlines()
    if f"{ref} {item['head']}" not in current:
        item["status"] = "changed"
        return False
    return True


def clean(branches):
    failed = False
    for item in branches:
        if item["status"] != "merged":
            continue
        branch = item["branch"]
        ref = HEADS + branch
        try:
            for path in branch_worktrees().get(ref, []):
                if not still_eligible(item, ref):
                    break
                if path in branch_worktrees().get(ref, []):
                    git("worktree", "remove", "--", path)
                    item.setdefault("removed_worktrees", []).append(path)
            if item["status"] != "merged" or not still_eligible(item, ref):
                continue
            # Squash does not preserve the source SHA. Git still checks remaining worktrees.
            git("branch", "-D", "--", branch)
            item["status"] = "deleted"
        except RuntimeError as error:
            failed = True
            item.update(status="error", reason=str(error))
    return failed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--branch", help="仅扫描这个本地分支")
    parser.add_argument("--apply", action="store_true", help="删除通过核验的本地分支")
    args = parser.parse_args()
    try:
        check_origin()
        git("fetch", "--no-tags", "--no-prune", "--no-recurse-submodules",
            "origin", f"refs/heads/dev:{DEV}")
        dev = git("rev-parse", "--verify", f"{DEV}^{{commit}}").stdout.strip()
        branches = scan(dev, args.branch)
        failed = clean(branches) if args.apply else False
    except (RuntimeError, OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(f"分支清理停止：{error}", file=sys.stderr)
        return 1
    print(json.dumps({"origin_dev": dev, "branches": branches}, ensure_ascii=False))
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
