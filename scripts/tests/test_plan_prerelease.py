import importlib.util
import os
import subprocess
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("plan_prerelease", Path(__file__).resolve().parents[1] / "plan-prerelease.py")
planner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(planner)


class PlanPrereleaseTests(unittest.TestCase):
    def setUp(self):
        fixture = TemporaryDirectory()
        self.addCleanup(fixture.cleanup)
        self.addCleanup(os.chdir, Path.cwd())
        os.chdir(fixture.name)
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.git("commit", "-q", "--allow-empty", "-m", "Baseline")
        self.git("tag", "v0.3.0")
        self.releases = [{"tag_name": "v0.3.0", "draft": False, "prerelease": True}]
        self.prs = {}
        self.notes = Path("notes.md")
        mock_api = patch.object(planner, "api", side_effect=self.api)
        mock_api.start()
        self.addCleanup(mock_api.stop)

    def git(self, *args):
        return planner.command("git", *args)

    def api(self, endpoint):
        if "/releases?" in endpoint:
            return [self.releases]
        commit = endpoint.split("/")[-2]
        return [self.prs.get(commit, [])]

    def commit(self, path):
        changed = Path(path)
        changed.parent.mkdir(parents=True, exist_ok=True)
        changed.write_text(path, encoding="utf-8")
        self.git("add", path)
        self.git("commit", "-q", "-m", path)
        return self.git("rev-parse", "HEAD")

    def app_pr(self, number, kind, english="Fix device selection.", path=None):
        commit = self.commit(path or f"FlutterRunlet/{number}.swift")
        self.prs[commit] = [{
            "merged_at": "2026-11-16",
            "merge_commit_sha": commit,
            "number": number,
            "title": "Fix device selection",
            "base": {"ref": "dev", "repo": {"full_name": "owner/project"}},
            "body": f"## Release type\n{kind}\n## 简体中文\n改善设备选择。\n## English\n{english}",
        }]
        return commit

    def plan(self):
        return planner.plan("owner/project", self.git("rev-parse", "HEAD"), self.notes)

    def test_ci_and_docs_only_skip(self):
        self.commit(".github/workflows/test.yml")
        self.commit("docs/example.md")
        self.assertEqual(self.plan(), (None, "v0.3.0"))
        self.assertFalse(self.notes.exists())

    def test_squashed_fix_bumps_patch_and_links_bilingual_pr(self):
        self.app_pr(16, "patch")
        self.assertEqual(self.plan(), ("v0.3.1", "v0.3.0"))
        notes = self.notes.read_text()
        self.assertIn("## 简体中文\n\n### 修复", notes)
        self.assertIn("## English\n\n### Fixes", notes)
        self.assertEqual(notes.count("https://github.com/owner/project/pull/16"), 2)

    def test_bundled_menu_icon_counts_as_application_change(self):
        self.app_pr(23, "patch", path="docs/design/assets/flutterrunlet-menubar-template@2x.png")
        self.assertEqual(self.plan(), ("v0.3.1", "v0.3.0"))

    def test_promoted_dev_history_uses_highest_bump(self):
        self.git("switch", "-q", "-c", "dev")
        self.app_pr(17, "patch")
        self.app_pr(18, "minor")
        self.git("switch", "-q", "main")
        self.commit("docs/guide.md")
        self.git("merge", "-q", "--no-ff", "-m", "Promote dev", "dev")
        self.assertEqual(self.plan(), ("v0.4.0", "v0.3.0"))
        self.assertIn("### Features", self.notes.read_text())
        self.assertIn("### Fixes", self.notes.read_text())

    def test_internal_app_change_skips(self):
        self.app_pr(19, "none", "")
        self.assertEqual(self.plan(), (None, "v0.3.0"))

    def test_missing_translation_uses_copilot_after_authorization(self):
        self.app_pr(20, "patch", "")
        checks = []
        with patch.object(planner, "fill_notes", side_effect=lambda pr, zh, en: (
            checks.append("notes") or zh, "Fix device selection"
        )):
            result = planner.plan("owner/project", self.git("rev-parse", "HEAD"), self.notes,
                                  authorize=lambda: checks.append("authorized"))
        self.assertEqual(result, ("v0.3.1", "v0.3.0"))
        self.assertEqual(checks, ["authorized", "notes"])
        self.assertIn("改善设备选择", self.notes.read_text())
        self.assertIn("Fix device selection", self.notes.read_text())

    def test_copilot_only_fills_missing_language(self):
        pr = {"number": 20, "title": "Device fix", "body": "Fixed it. <!-- hidden -->"}
        response = subprocess.CompletedProcess([], 0, '{"en":"Fix device selection."}', "")
        with patch.object(planner.subprocess, "run", return_value=response) as copilot:
            self.assertEqual(planner.fill_notes(pr, "修复设备选择。", ""),
                             ("修复设备选择。", "Fix device selection."))
            self.assertNotIn("hidden", copilot.call_args.args[0][-1])
        with patch.object(planner.subprocess, "run") as copilot:
            self.assertEqual(planner.fill_notes(pr, "原文", "Original"), ("原文", "Original"))
            copilot.assert_not_called()

    def test_invalid_copilot_response_blocks_candidate(self):
        pr = {"number": 20, "title": "Device fix", "body": None}
        response = subprocess.CompletedProcess([], 0, '{"en":""}', "")
        with patch.object(planner.subprocess, "run", return_value=response):
            with self.assertRaisesRegex(ValueError, "PR #20"):
                planner.fill_notes(pr, "原文", "")

    def test_manual_version_blocks_automatic_candidate(self):
        self.app_pr(21, "manual")
        with self.assertRaisesRegex(ValueError, "manually chosen version"):
            self.plan()

    def test_unassociated_application_commit_blocks_candidate(self):
        self.commit("FlutterRunlet/unknown.swift")
        with self.assertRaisesRegex(ValueError, "one merged PR"):
            self.plan()

    def test_draft_release_reserves_version(self):
        self.app_pr(22, "patch")
        self.releases.append({"tag_name": "v0.3.1", "draft": True})
        with self.assertRaisesRegex(ValueError, "already reserved"):
            self.plan()
