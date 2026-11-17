import json
import os
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "create-github-labels.sh"
REPO = "new-owner/flutter-runlet"
COLORS = {
    "task:ready": "0E8A16", "task:working": "0052CC",
    "task:review": "D4C5F9", "task:blocked": "B60205",
}


class CreateGitHubLabelsTests(unittest.TestCase):
    def setUp(self):
        temporary = TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.state = self.root / "labels.json"
        self.save({"repo": REPO, "labels": {}, "created": [], "list_error": False})
        gh = self.root / "gh"
        gh.write_text("""#!/usr/bin/env python3
import json
from pathlib import Path
import sys

path = Path("labels.json")
fixture = json.loads(path.read_text())
args = sys.argv[1:]
repo = "new-owner/flutter-runlet"
if args == ["api", "--hostname", "github.com", "--method", "GET", f"repos/{repo}", "--jq", ".full_name"]:
    print(fixture["repo"])
elif args == ["api", "--hostname", "github.com", "--method", "GET", "--paginate",
              f"repos/{repo}/labels?per_page=100", "--jq", ".[].name"]:
    if fixture["list_error"]:
        sys.exit("gh: HTTP 403")
    print(*fixture["labels"], sep="\\n")
elif args[:2] == ["label", "create"]:
    assert args[3:5] == ["--repo", "github.com/" + repo]
    assert args[5] == "--color" and args[7] == "--description" and len(args) == 9
    name = args[2]
    assert name not in fixture["labels"], "existing label must not be updated"
    fixture["labels"][name] = {"color": args[6], "description": args[8]}
    fixture["created"].append(name)
    path.write_text(json.dumps(fixture))
else:
    raise AssertionError(args)
""", encoding="utf-8")
        gh.chmod(0o755)

    def save(self, state):
        self.state.write_text(json.dumps(state), encoding="utf-8")

    def read(self):
        return json.loads(self.state.read_text(encoding="utf-8"))

    def invoke(self, *args):
        return subprocess.run(
            ["bash", str(SCRIPT), *args], cwd=self.root,
            capture_output=True, text=True, encoding="utf-8",
            env={**os.environ, "PATH": os.pathsep.join((str(self.root), os.environ["PATH"]))},
        )

    def test_initializes_explicit_new_repo(self):
        result = self.invoke("--repo", REPO)
        self.assertEqual(result.returncode, 0, result.stderr)
        labels = self.read()["labels"]
        self.assertEqual({name: item["color"] for name, item in labels.items()}, COLORS)

    def test_restores_missing_label_only_and_can_repeat(self):
        existing = {name: {"color": "ff0000", "description": "保留我的设置"}
                    for name in COLORS if name != "task:working"}
        self.save({**self.read(), "labels": existing})
        for _ in range(2):
            result = self.invoke("--repo", REPO)
            self.assertEqual(result.returncode, 0, result.stderr)
        final = self.read()
        self.assertEqual(final["created"], ["task:working"])
        self.assertEqual({name: final["labels"][name] for name in existing}, existing)
        self.assertEqual(final["labels"]["task:working"], {
            "color": "0052CC", "description": "AI Agent 正在处理",
        })

    def test_stops_without_explicit_repo_or_safe_lookup(self):
        result = self.invoke()
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("--repo", result.stderr)
        original = self.read()
        for changed, message in (({"repo": "moved/flutter-runlet"}, "仓库全名"),
                                 ({"list_error": True}, "HTTP 403")):
            with self.subTest(changed=changed):
                self.save({**original, **changed})
                result = self.invoke("--repo", REPO)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(message, result.stderr)
                self.assertEqual(self.read()["created"], [])
