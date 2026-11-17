from contextlib import ExitStack
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "verify-issue-queue.py"
OWNER = {"id": 22855313, "type": "User"}
BEFORE = "2026-11-15T00:00:00Z"
APPROVED = "2026-11-16T00:00:00Z"
AFTER = "2026-11-17T00:00:00Z"
CONTRACT = """### 目标

补充窗口说明

### 验收条件

O1. 开发者指南写明启动方式 | 核对指南

### 排除项

X1. 不调整窗口布局

### 任务类型

文档

### 改动范围

docs/DEVELOPMENT.md

### 前置 Issue

无
"""


def issue(number, labels=("task:ready",), **overrides):
    return {
        "number": number, "node_id": f"issue-{number}", "title": "窗口说明",
        "created_at": BEFORE, "state": "open", "body": CONTRACT,
        "labels": [{"name": label} for label in labels],
        **overrides,
    }


def event(event_id=1, kind="labeled", at=APPROVED, label="task:ready", actor=OWNER):
    return {
        "id": event_id, "event": kind, "created_at": at,
        "label": {"name": label}, "actor": actor,
    }


class GitHubRequestTests(unittest.TestCase):
    def setUp(self):
        queue = runpy.run_path(str(SCRIPT))
        self.gh_json = queue["gh_json"]
        self.error_type = queue["GitHubError"]
        self.query = queue["ISSUE_EDIT_QUERY"]
        with ExitStack() as patches:
            self.run_gh = patches.enter_context(patch("subprocess.run"))
            self.sleep = patches.enter_context(patch("time.sleep"))
            self.addCleanup(patches.pop_all().close)

    def test_read_recovers_from_transport_timeout_or_service_error(self):
        for request, failure in (
            (("--method", "GET", "user"),
             subprocess.CompletedProcess([], 1, "", "gh: unexpected EOF")),
            (("--method", "GET", "repos/atypiape/flutter-runlet/labels?per_page=100"),
             subprocess.CompletedProcess([], 1, "", "gh: Service Unavailable (HTTP 503)")),
            (("graphql", "-f", f"query={self.query}", "-f", "id=issue-7"),
             subprocess.TimeoutExpired("gh", 45)),
        ):
            with self.subTest(request=request[0:2]):
                self.run_gh.reset_mock()
                self.sleep.reset_mock()
                self.run_gh.side_effect = [failure, subprocess.CompletedProcess([], 0, "{}", "")]
                self.assertEqual(self.gh_json(*request), {})
                self.assertEqual(self.run_gh.call_count, 2)
                self.sleep.assert_called_once_with(1)

    def test_repeat_failure_reports_the_endpoint_without_raw_output(self):
        self.run_gh.return_value = subprocess.CompletedProcess([], 1, "", "fixture secret: EOF")
        with self.assertRaises(self.error_type) as raised:
            self.gh_json("--method", "GET", "repos/atypiape/flutter-runlet/issues?labels=task:ready")
        self.assertEqual(self.run_gh.call_count, 2)
        self.assertIn("GET repos/atypiape/flutter-runlet/issues", str(raised.exception))
        self.assertIn("已重试一次", str(raised.exception))
        self.assertNotIn("fixture secret", str(raised.exception))
        self.assertNotIn("labels=", str(raised.exception))

    def test_permission_rate_limit_and_write_failures_are_not_retried(self):
        for method, detail in (("GET", "HTTP 401"), ("GET", "HTTP 403"),
                               ("GET", "HTTP 429"), ("POST", "HTTP 503")):
            with self.subTest(method=method, detail=detail):
                self.run_gh.reset_mock()
                self.run_gh.return_value = subprocess.CompletedProcess([], 1, "", f"gh: ({detail})")
                with self.assertRaisesRegex(self.error_type, detail):
                    self.gh_json("--method", method, "repos/atypiape/flutter-runlet/pulls")
                self.run_gh.assert_called_once()
                self.sleep.assert_not_called()


class IssueQueueTests(unittest.TestCase):
    def setUp(self):
        temporary = TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        stub = self.root / "gh"
        stub.write_text("""#!/usr/bin/env python3
import json
from pathlib import Path
import sys

assert sys.argv[1:4] == ["api", "--hostname", "github.com"]
args = sys.argv[4:]
if args[0] == "graphql":
    assert len(args) == 5 and args[1::2] == ["-f", "-f"]
    assert args[2].startswith("query=") and args[2][6:].lstrip().startswith("query(")
    key = "graphql/" + args[4].removeprefix("id=")
else:
    assert args[:2] == ["--method", "GET"]
    key = args[-1].removeprefix("repos/atypiape/flutter-runlet/")
    assert args[2:-1] == (["--paginate", "--slurp"] if "per_page=" in key else [])
fixture = json.loads(Path("responses.json").read_text())
response = fixture[key]
if isinstance(response, dict) and "_http_error" in response:
    print(f"gh: Fixture error (HTTP {response['_http_error']})", file=sys.stderr)
    sys.exit(1)
print(json.dumps(response))
""", encoding="utf-8")
        stub.chmod(0o755)
        self.responses = {self.list_path(label): [[]] for label in (
            "task:ready", "task:working", "task:review",
        )}
        self.responses["labels?per_page=100"] = [
            [{"name": "task:ready"}, {"name": "task:working"}],
            [{"name": "task:review"}, {"name": "task:blocked"}],
        ]

    @staticmethod
    def list_path(label):
        return f"issues?state=open&labels={label}&per_page=100"

    def add_issue(self, item, events=None, edited=None, native=()):
        number = item["number"]
        self.responses[f"issues/{number}"] = item
        self.responses[f"issues/{number}/events?per_page=100"] = (
            [[event()]] if events is None else events
        )
        self.responses[f"graphql/issue-{number}"] = {"data": {"node": {
            "title": item["title"], "body": item["body"] or "",
            "state": item["state"].upper(), "lastEditedAt": edited,
        }}}
        self.responses[f"issues/{number}/dependencies/blocked_by?per_page=100"] = [native]

    def run_queue(self, *args):
        (self.root / "responses.json").write_text(json.dumps(self.responses), encoding="utf-8")
        return subprocess.run(
            [sys.executable, "-B", str(SCRIPT), *map(str, args)], cwd=self.root,
            capture_output=True, text=True, encoding="utf-8",
            env={**os.environ, "PATH": os.pathsep.join((str(self.root), os.environ["PATH"]))},
        )

    def inspect(self, *args):
        result = self.run_queue(*args)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def git(self, *args):
        subprocess.run(["git", *args], cwd=self.root, check=True, capture_output=True)

    def set_origin(self, url="https://github.com/atypiape/flutter-runlet.git"):
        self.git("init", "-q")
        self.git("remote", "add", "origin", url)

    def test_preflight_confirms_identity_and_returns_the_same_queue(self):
        self.set_origin("git@github.com:atypiape/flutter-runlet.git")
        self.responses["user"] = {**OWNER, "login": "atypiape"}
        self.add_issue(issue(7))
        self.responses[self.list_path("task:ready")] = [[issue(7)]]
        result = self.inspect("--preflight", "--issue", 7)
        self.assertEqual(result["candidate"], 7)
        self.assertEqual(result["preflight"],
                         {"repository": "atypiape/flutter-runlet", "github_user": "atypiape"})

    def test_preflight_rejects_wrong_origin_push_target_or_identity(self):
        self.set_origin("https://github.com/example/other.git")
        self.responses["user"] = {"_http_error": 401}
        result = self.run_queue("--preflight")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("origin 获取地址", result.stderr)

        self.git("remote", "set-url", "origin", "https://github.com/atypiape/flutter-runlet")
        self.git("config", "remote.origin.pushurl", "https://github.com/example/other.git")
        result = self.run_queue("--preflight")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("origin 推送地址", result.stderr)
        self.git("config", "--unset", "remote.origin.pushurl")

        result = self.run_queue("--preflight")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("HTTP 401", result.stderr)
        self.responses["user"] = {"type": "User", "id": 42, "login": "another"}
        result = self.run_queue("--preflight")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("允许名单", result.stderr)

    def test_missing_task_label_blocks_preflight_before_queue_lookup(self):
        self.set_origin()
        self.responses = {
            "user": {**OWNER, "login": "atypiape"},
            "labels?per_page=100": [[{"name": label} for label in (
                "task:ready", "task:review", "task:blocked",
            )]],
        }
        result = self.run_queue("--preflight")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")
        self.assertIn("仓库缺少任务标签：task:working", result.stderr)
        self.assertIn("bash scripts/create-github-labels.sh --repo atypiape/flutter-runlet", result.stderr)

    def test_push_hook_check_is_read_only_and_rejects_invalid_hooks(self):
        self.set_origin()
        hook = self.root / ".githooks" / "pre-push"
        hook.parent.mkdir()
        hook.write_text("#!/bin/sh\nexit 0\n")
        hook.chmod(0o755)
        self.git("add", ".githooks/pre-push")
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
                 "-c", "commit.gpgsign=false", "commit", "-qm", "Trusted hook")
        self.git("update-ref", "refs/remotes/origin/dev", "HEAD")
        self.responses.clear()  # This mode must succeed without querying GitHub.

        self.git("config", "core.hooksPath", ".githooks-other")
        result = self.run_queue("--check-push-hook")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("core.hooksPath", result.stderr)
        self.git("config", "core.hooksPath", ".githooks")
        self.assertEqual(self.inspect("--check-push-hook")["status"], "ready")

        hook.chmod(0o644)
        result = self.run_queue("--check-push-hook")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("可执行", result.stderr)
        hook.chmod(0o755)
        hook.write_text("#!/bin/sh\nexit 1\n")
        result = self.run_queue("--check-push-hook")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("origin/dev 的版本不同", result.stderr)
        hook.unlink()
        result = self.run_queue("--check-push-hook")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("可执行", result.stderr)

    def assert_ineligible(self, reason):
        result = self.inspect("--issue", 7)
        self.assertIsNone(result["candidate"])
        self.assertFalse(result["checked"][0]["eligible"])
        self.assertIn(reason, result["checked"][0]["reason"])

    def test_selects_oldest_eligible_and_ignores_pull_requests_across_pages(self):
        bad = issue(5, body="没有有效批准")
        ready = issue(7, labels=("task:ready", "bug"))
        self.add_issue(bad, events=[[]])
        self.add_issue(ready, events=[[event(at=BEFORE)], [event(2)]], edited=BEFORE)
        self.responses[self.list_path("task:ready")] = [
            [issue(9), issue(3, pull_request={})], [ready, bad],
        ]
        result = self.inspect()
        self.assertEqual(result["candidate"], 7)
        self.assertEqual([item["number"] for item in result["checked"]], [5, 7])
        self.assertEqual(result["checked"][1]["approved_at"], APPROVED)
        self.assertEqual(result["checked"][1]["approval_event_id"], 2)
        self.assertRegex(result["checked"][1]["spec_sha256"], r"^[0-9a-f]{64}$")

    def test_approved_issues_enter_scope_review_in_either_format(self):
        for body in ("补充窗口启动说明。验证开发者指南中的启动步骤。", None,
                     CONTRACT.replace(" | 核对指南", ""),
                     CONTRACT + "\n### 目标\n\n补充说明"):
            with self.subTest(body=body):
                self.add_issue(issue(7, body=body))
                result = self.inspect("--issue", 7)
                self.assertEqual(result["candidate"], 7)
                self.assertEqual(result["checked"][0]["approval_event_id"], 1)
                self.assertRegex(result["checked"][0]["spec_sha256"], r"^[0-9a-f]{64}$")

    def test_skips_scope_reviewed_issues_for_this_search(self):
        issues = [issue(number, body="补充窗口说明") for number in (5, 7, 9)]
        for item in issues:
            self.add_issue(item)
        self.responses[self.list_path("task:ready")] = [issues]
        self.assertEqual(self.inspect()["candidate"], 5)
        result = self.inspect("--skip", 5, "--skip", 7)
        self.assertEqual(result["candidate"], 9)
        self.assertEqual([item["number"] for item in result["checked"]], [9])
        self.assertEqual(self.inspect("--issue", 5)["candidate"], 5)

    def test_empty_or_existing_active_tasks_have_no_candidate(self):
        self.assertEqual(self.inspect(), {"candidate": None, "active": [], "checked": []})
        for label in ("task:working", "task:review"):
            with self.subTest(label=label):
                self.responses[self.list_path(label)] = [[issue(9, labels=(label,))]]
                self.responses.pop(self.list_path("task:ready"), None)
                self.assertEqual(self.inspect(), {"candidate": None, "active": [9], "checked": []})
                self.responses[self.list_path(label)] = [[]]

    def test_rejects_closed_conflicting_or_manual_tasks(self):
        for item, reason in (
            (issue(7, pull_request={}), "PR"),
            (issue(7, state="closed"), "已关闭"),
            (issue(7, labels=()), "只能有 task:ready"),
            (issue(7, labels=("task:ready", "task:blocked")), "只能有 task:ready"),
            (issue(7, labels=("task:ready", "task:working")), "只能有 task:ready"),
            (issue(7, body=CONTRACT.replace("文档", "人工处理")), "需要人工处理"),
            (issue(7, body="定位窗口问题。\n\n## 任务类型\n\n人工处理"), "需要人工处理"),
        ):
            with self.subTest(reason=reason):
                self.add_issue(item)
                self.assert_ineligible(reason)

    def test_requires_current_trusted_approval(self):
        for history, edited, reason in (
            ([[]], None, "找不到生效"),
            ([[event(), event(2, kind="unlabeled")]], None, "找不到生效"),
            ([[event(), event(2, kind="unlabeled"), event(3, actor={"type": "User", "id": 42})]],
             None, "已授权维护者"),
            ([[event(actor={"type": "Bot", "id": OWNER["id"]})]], None, "已授权维护者"),
            ([[event(), event(2, kind="renamed")]], None, "标题或任务状态"),
            ([[event(), event(2, label="task:blocked")]], None, "标题或任务状态"),
            ([[event()]], APPROVED, "时间无法区分"),
            ([[event()]], AFTER, "正文有修改"),
        ):
            with self.subTest(history=history, edited=edited):
                self.add_issue(issue(7, body="补充窗口说明"), events=history, edited=edited)
                self.assert_ineligible(reason)
        self.add_issue(issue(7), events=[[event(), event(2, label="task:blocked"), event(3, at=AFTER)]],
                       edited=APPROVED)
        self.assertEqual(self.inspect("--issue", 7)["candidate"], 7)

    def test_checks_written_and_github_dependencies(self):
        dependent = issue(7, body="补充窗口说明。\n\n### 前置 Issue\n\n- #8\n")
        done = issue(8, state="closed", state_reason="completed")
        self.add_issue(dependent)
        for prereq, reason in (
            (issue(8), "#8 尚未完成"),
            (issue(8, state="closed", state_reason="not_planned"), "#8 尚未完成"),
            (issue(8, state="closed", state_reason="completed", pull_request={}), "对应 PR"),
            ({"_http_error": 404}, "无法读取前置 Issue #8"),
        ):
            with self.subTest(prereq=prereq):
                self.responses["issues/8"] = prereq
                self.assert_ineligible(reason)
        self.responses["issues/8"] = done
        self.add_issue(issue(7, body="补充窗口说明"), native=[issue(9)])
        self.assert_ineligible("GitHub 标记的阻塞")
        self.add_issue(dependent, native=[done])
        self.assertEqual(self.inspect("--issue", 7)["candidate"], 7)
        self.add_issue(issue(7, body=dependent["body"].replace("#8", "#7")))
        self.assert_ineligible("不能依赖自身")
        self.add_issue(issue(7, body=dependent["body"].replace("#8", "另一个仓库的修复")))
        self.assert_ineligible("无法核实正文声明的前置 Issue")

    def test_api_failure_returns_error_instead_of_empty_queue(self):
        self.responses[self.list_path("task:ready")] = {"_http_error": 403}
        result = self.run_queue()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("HTTP 403", result.stderr)
