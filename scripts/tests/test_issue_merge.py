import hashlib
import importlib.util
import json
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import unittest
from unittest.mock import patch


PATH = Path(__file__).resolve().parents[1] / "merge-issue-pr.py"
SPEC = importlib.util.spec_from_file_location("issue_merge", PATH)
gate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gate)


class IssueMergeTests(unittest.TestCase):
    def setUp(self):
        self.issue = {
            "number": 66, "title": "任务", "body": "规格", "state": "open",
            "labels": [{"name": "task:review"}],
        }
        self.args = SimpleNamespace(
            pr=67, issue=66, author=123, head="1" * 40, base="2" * 40, test_merge="3" * 40,
            spec=hashlib.sha256(json.dumps(["任务", "规格"], ensure_ascii=False).encode()).hexdigest(),
            require_strict=True, apply=True,
        )
        self.pr = {
            "base": {"ref": "dev", "sha": self.args.base, "repo": {"full_name": gate.REPO}},
            "head": {"ref": "docs/issue-66-test", "sha": self.args.head, "repo": {"full_name": gate.REPO}},
            "user": {"type": "User", "id": 123}, "body": "Refs #66", "merged": False, "draft": False,
            "state": "open", "mergeable": True, "mergeable_state": "clean",
            "merge_commit_sha": self.args.test_merge,
        }
        self.rules = [
            {"type": "required_status_checks", "parameters": {
                "required_status_checks": [{"context": name, "integration_id": gate.ACTIONS_APP}
                                           for name in gate.WORKFLOWS.values()],
                "strict_required_status_checks_policy": True,
            }},
            {"type": "pull_request", "parameters": {"allowed_merge_methods": ["squash"]}},
        ]
        self.run_info = {
            "id": 9, "run_number": 1, "event": "pull_request", "head_sha": self.args.head,
            "display_title": f"[PR #67] [validate {self.args.test_merge}] 任务",
            "status": "completed", "conclusion": "success",
        }
        self.calls = []
        self.dev = self.args.base
        self.change_on_final_read = False
        self.recheck = 0
        self.approval = {
            "id": 10, "event": "labeled", "label": {"name": "task:ready"},
            "actor": {"type": "User", "id": next(iter(gate.APPROVER_IDS))},
            "created_at": "2026-11-17T00:00:00Z",
        }
        self.events = [self.approval]
        self.addCleanup(patch.stopall)
        patch.object(gate, "get", side_effect=self.get).start()
        patch.object(gate, "gh", side_effect=self.gh).start()
        patch.object(gate.subprocess, "run", side_effect=self.remove_label).start()

    def get(self, path, *, paginate=False):
        if path == "pulls/67":
            self.recheck += 1
            if self.change_on_final_read and self.recheck > 1:
                return {**self.pr, "draft": True}
            return dict(self.pr)
        if path == "issues/66":
            return dict(self.issue)
        if path == "issues/66/events?per_page=100" and paginate:
            return self.events
        if path == "rules/branches/dev":
            return self.rules
        if path == f"commits/{self.args.test_merge}":
            return {"parents": [{"sha": sha} for sha in (self.args.base, self.args.head)]}
        if path == "actions/runs/9/jobs?filter=latest&per_page=100":
            return {"jobs": [{"name": name, "head_sha": self.args.head,
                              "status": "completed", "conclusion": "success"}
                             for name in gate.WORKFLOWS.values()]}
        if path == "git/ref/heads/dev":
            return {"object": {"sha": self.dev}}
        raise AssertionError(path)

    def gh(self, _, method, path, *fields):
        if method == "GET":
            return [{"workflow_runs": [dict(self.run_info)]}]
        self.calls.append((method, path, fields))
        if method == "PUT":
            assert fields == ("-f", f"sha={self.args.head}", "-f", "merge_method=squash")
            self.pr.update(merged=True, state="closed", merge_commit_sha="4" * 40)
            return {"merged": True, "sha": self.pr["merge_commit_sha"]}
        if method == "PATCH":
            self.issue.update(state="closed", state_reason="completed")
            return self.issue
        raise AssertionError(method)

    def remove_label(self, command, **kwargs):
        self.assertEqual(command[-2:], ["--remove-label", "task:review"])
        self.calls.append(("remove-label",))
        self.issue["labels"] = []

    def test_manual_check_and_apply_then_repeat(self):
        self.args.apply = False
        self.assertEqual(gate.run(self.args)["state"], "ready")
        self.assertEqual(self.calls, [])
        self.args.apply = True
        self.assertEqual(gate.run(self.args)["sha"], "4" * 40)
        self.assertEqual(self.issue["state"], "closed")
        self.assertEqual(self.issue["labels"], [])
        self.assertEqual(gate.run(self.args)["state"], "merged")
        self.assertEqual([call[0] for call in self.calls], ["PUT", "PATCH", "remove-label"])

    def test_rejects_old_or_failed_ci(self):
        old_name = self.run_info["display_title"]
        for changes in (
            {"display_title": old_name.replace(self.args.test_merge, "0" * 40)},
            {"display_title": old_name, "conclusion": "failure"},
        ):
            with self.subTest(changes=changes):
                self.run_info.update(changes)
                with self.assertRaisesRegex(RuntimeError, "缺少成功"):
                    gate.run(self.args)
        self.assertEqual(self.calls, [])

    def test_rechecks_review_target_and_base(self):
        self.change_on_final_read = True
        with self.assertRaisesRegex(RuntimeError, "PR 状态"):
            gate.run(self.args)
        self.change_on_final_read = False
        self.dev = "0" * 40
        with self.assertRaisesRegex(RuntimeError, "dev 已前进"):
            gate.run(self.args)
        self.assertEqual(self.calls, [])

    def test_requires_strict_for_scheduled_merge(self):
        self.rules[0]["parameters"]["strict_required_status_checks_policy"] = False
        with self.assertRaisesRegex(RuntimeError, "定时合并"):
            gate.run(self.args)
        self.assertEqual(self.calls, [])

    def write_review(self):
        temp = TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        path = Path(temp.name) / "reviews" / "66.json"
        writing = SimpleNamespace(**{
            **vars(self.args), "apply": False, "require_strict": False,
            "record_review": path, "review_file": None,
            "approval_event": 10, "summary": "O1：核对通过。",
        })
        gate.validate_snapshot(writing)
        self.assertEqual(gate.record_review(writing)["state"], "review-recorded")
        return path

    def read_review(self, path):
        reading = SimpleNamespace(record_review=None, review_file=path,
                                  require_strict=True, apply=True)
        gate.use_review_file(reading)
        gate.validate_snapshot(reading)
        return reading

    def test_review_record_from_previous_run_can_be_used_after_ci(self):
        self.pr["mergeable_state"] = "unstable"
        self.run_info.update(status="in_progress", conclusion=None)
        path = self.write_review()
        self.assertEqual(self.calls, [])
        reading = self.read_review(path)
        self.assertEqual(reading.summary, "O1：核对通过。")
        with self.assertRaisesRegex(RuntimeError, "仍有合并阻塞"):
            gate.run(reading)
        self.pr["mergeable_state"] = "clean"
        with self.assertRaisesRegex(RuntimeError, "缺少成功"):
            gate.run(reading)
        self.assertEqual(self.calls, [])
        self.run_info.update(status="completed", conclusion="success")
        self.assertEqual(gate.run(reading)["state"], "merged")

    def test_saved_review_is_rejected_after_spec_head_or_approval_changes(self):
        path = self.write_review()
        reading = self.read_review(path)
        self.issue["body"] = "新规格"
        with self.assertRaisesRegex(RuntimeError, "规格已变化"):
            gate.run(reading)
        self.issue["body"] = "规格"
        self.pr["head"]["sha"] = "a" * 40
        with self.assertRaisesRegex(RuntimeError, "源提交不匹配"):
            gate.run(reading)
        self.pr["head"]["sha"] = self.args.head
        self.pr["base"]["sha"] = "b" * 40
        with self.assertRaisesRegex(RuntimeError, "审查基线"):
            gate.run(reading)
        self.pr["base"]["sha"] = self.args.base
        self.events.append({**self.approval, "id": 11, "label": {"name": "task:blocked"}})
        with self.assertRaisesRegex(RuntimeError, "曾被阻塞"):
            gate.run(reading)
        self.events.append({**self.approval, "id": 12})
        with self.assertRaisesRegex(RuntimeError, "批准已变化"):
            gate.run(reading)
        self.assertEqual(self.calls, [])

    def test_review_file_must_contain_a_complete_record(self):
        path = self.write_review()
        evidence = json.loads(path.read_text())
        path.write_text(json.dumps({**evidence, "summary": ""}))
        with self.assertRaisesRegex(RuntimeError, "审查结论"):
            self.read_review(path)
