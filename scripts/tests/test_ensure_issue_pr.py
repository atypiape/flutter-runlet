import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "ensure-issue-pr.py"
REPO = "atypiape/flutter-runlet"
BRANCH = "docs/issue-66-pr-resume"
AUTHOR = 22855313


class EnsureIssuePRTests(unittest.TestCase):
    def setUp(self):
        temporary = TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        folder = Path(temporary.name)
        self.worktree = folder / "checkout"
        self.worktree.mkdir()
        self.git("init", "-q", "-b", BRANCH)
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
                 "-c", "commit.gpgsign=false", "commit", "--allow-empty", "-qm", "Fixture")
        self.head = self.git("rev-parse", "HEAD")
        self.body = folder / "pr.md"
        self.body.write_text("验证说明\n\nRefs #66\n", encoding="utf-8")
        issue = {
            "number": 66, "state": "open", "title": "任务", "body": "规格",
            "labels": [{"name": "task:working"}, {"name": "documentation"}],
        }
        self.spec = hashlib.sha256(json.dumps(
            [issue["title"], issue["body"]], ensure_ascii=False,
        ).encode()).hexdigest()
        self.state = folder / "github.json"
        self.save({"issue": issue, "pulls": [], "calls": [], "remote": self.head, "fail": None})

        stub = folder / "gh"
        stub.write_text("""#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

assert sys.argv[1:5] == ["api", "--hostname", "github.com", "--method"]
method, *args = sys.argv[5:]
repo = "atypiape/flutter-runlet"
branch = "docs/issue-66-pr-resume"
fixture = Path(os.environ["RUNLET_FIXTURE"])
state = json.loads(fixture.read_text())
issue = state["issue"]
if method == "GET":
    if args[0] == "--paginate":
        assert args == ["--paginate", "--slurp", f"repos/{repo}/pulls",
                        "-f", "state=all", "-f", f"head=atypiape:{branch}", "-F", "per_page=100"]
        if state.get("fail") == "find-pr":
            sys.exit("模拟 GitHub 查询失败 (HTTP 403)")
        answer = state.get("history_response", [[pr] for pr in state["pulls"]] or [[]])
    else:
        answer = {
            "user": {"id": 22855313},
            f"repos/{repo}/issues/66": issue,
            f"repos/{repo}/git/ref/heads/{branch}": {"object": {"sha": state["remote"]}},
            **{f"repos/{repo}/pulls/{pr['number']}": pr for pr in state["pulls"]},
        }[args[0]]
else:
    path = args[0]
    if path == f"repos/{repo}/pulls" and method == "POST":
        assert not state["pulls"], "PR create attempted twice"
        assert args[1:5] == ["-f", "base=dev", "-f", f"head={branch}"]
        assert args[5:8] == ["-f", "title=docs: 任务", "-F"]
        body = Path(args[8].removeprefix("body=@")).read_text()
        answer = {
            "number": 67, "state": "open", "draft": False, "body": body,
            "head": {"ref": branch, "sha": state["remote"], "repo": {"full_name": repo}},
            "base": {"ref": "dev", "repo": {"full_name": repo}},
            "user": {"id": 22855313}, "html_url": f"https://github.com/{repo}/pull/67",
        }
        state["pulls"].append(answer)
        action = "create-pr"
    elif path == f"repos/{repo}/issues/66/labels" and method == "POST":
        assert args[1:] == ["-f", "labels[]=task:review"]
        assert {"name": "task:review"} not in issue["labels"]
        issue["labels"].append({"name": "task:review"})
        answer = issue["labels"]
        action = "add-review"
    elif path == f"repos/{repo}/issues/66/labels/task%3Aworking" and method == "DELETE":
        issue["labels"].remove({"name": "task:working"})
        answer = issue["labels"]
        action = "remove-working"
    else:
        raise AssertionError((method, args))
    state["calls"].append(action)
    fixture.write_text(json.dumps(state))
    if state["fail"] == action:
        sys.exit("模拟请求已写入远端后丢失响应")
print(json.dumps(answer))
""", encoding="utf-8")
        stub.chmod(0o755)

    def git(self, *args):
        return subprocess.check_output(["git", *args], cwd=self.worktree, text=True).strip()

    def load(self):
        return json.loads(self.state.read_text())

    def save(self, state):
        self.state.write_text(json.dumps(state), encoding="utf-8")

    def invoke(self, *, create=False):
        args = ["--title", "docs: 任务", "--body-file", str(self.body)] if create else []
        return subprocess.run(
            [sys.executable, "-B", str(SCRIPT), "--issue", "66", "--spec", self.spec, *args],
            cwd=self.worktree, capture_output=True, text=True, encoding="utf-8",
            env={**os.environ, "RUNLET_FIXTURE": str(self.state),
                 "PATH": os.pathsep.join((str(self.state.parent), os.environ["PATH"]))},
        )

    def result(self, **kwargs):
        result = self.invoke(**kwargs)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_creates_after_push_then_reuses_without_writes(self):
        result = self.result(create=True)
        self.assertEqual((result["action"], result["pr"], result["head"]), ("created", 67, self.head))
        self.assertEqual(self.result()["action"], "reused")
        state = self.load()
        self.assertEqual(state["calls"], ["create-pr", "add-review", "remove-working"])
        self.assertEqual(state["pulls"][0]["body"], self.body.read_text())

    def test_recovers_after_pr_creation_response_is_lost(self):
        self.save({**self.load(), "fail": "create-pr"})
        self.assertNotEqual(self.invoke(create=True).returncode, 0)
        self.assertEqual(self.load()["calls"], ["create-pr"])
        self.assertEqual(self.result()["pr"], 67)
        state = self.load()
        self.assertEqual(len(state["pulls"]), 1)
        self.assertEqual(state["calls"], ["create-pr", "add-review", "remove-working"])
        self.assertCountEqual([label["name"] for label in state["issue"]["labels"]],
                              ["task:review", "documentation"])

    def test_recovers_between_label_mutations(self):
        self.save({**self.load(), "fail": "add-review"})
        self.assertNotEqual(self.invoke(create=True).returncode, 0)
        self.assertEqual(self.load()["calls"], ["create-pr", "add-review"])
        self.assertEqual(self.result()["action"], "reused")
        self.assertEqual(self.load()["calls"], ["create-pr", "add-review", "remove-working"])

    def test_refuses_closed_retargeted_or_ambiguous_pulls(self):
        self.result(create=True)
        original = self.load()
        pr = original["pulls"][0]
        for pulls in ([{**pr, "state": "closed"}],
                      [{**pr, "base": {**pr["base"], "ref": "main"}}],
                      [{**pr, "user": {"id": AUTHOR + 1}}],
                      [{**pr, "body": "Refs #99"}],
                      [pr, {**pr, "number": 68}]):
            with self.subTest(pulls=pulls):
                self.save({**original, "pulls": pulls, "calls": []})
                self.assertNotEqual(self.invoke(create=True).returncode, 0)
                self.assertEqual(self.load()["calls"], [])

    def test_rechecks_spec_and_requires_exact_pushed_commit(self):
        original = self.load()
        for state in ({**original, "remote": "0" * 40},
                      {**original, "issue": {**original["issue"], "body": "规格已修改"}},
                      {**original, "issue": {**original["issue"],
                                             "labels": [{"name": "task:blocked"}]}}):
            with self.subTest(state=state):
                self.save(state)
                self.assertNotEqual(self.invoke(create=True).returncode, 0)
                self.assertEqual(self.load()["calls"], [])

    def test_failed_or_malformed_lookup_does_not_create(self):
        original = self.load()
        for state in ({**original, "fail": "find-pr"}, {**original, "history_response": {}}):
            with self.subTest(state=state):
                self.save(state)
                self.assertNotEqual(self.invoke(create=True).returncode, 0)
                self.assertEqual(self.load()["calls"], [])
