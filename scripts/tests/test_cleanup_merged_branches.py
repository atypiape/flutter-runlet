import importlib.util
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "cleanup-merged-branches.py"
SPEC = importlib.util.spec_from_file_location("cleanup_merged_branches", SCRIPT)
cleanup = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(cleanup)


class CleanupMergedBranchesTests(unittest.TestCase):
    def setUp(self):
        temporary = TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.folder = Path(temporary.name)
        self.repo = self.folder / "repo"
        self.repo.mkdir()
        self.git("init", "-qb", "dev")
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.git("config", "commit.gpgsign", "false")
        self.git("commit", "--allow-empty", "-qm", "Base")
        for branch in ("main", "codex/local", "docs/ancestor", "docs/occupied"):
            self.git("branch", branch)
        self.git("worktree", "add", "-q", str(self.folder / "occupied"), "docs/occupied")
        self.git("switch", "-qc", "docs/squashed")
        (self.repo / "note.md").write_text("文档\n", encoding="utf-8")
        self.git("add", "note.md")
        self.git("commit", "-qm", "Task")
        self.head = self.git("rev-parse", "HEAD")
        self.git("switch", "-q", "dev")
        self.git("merge", "--squash", "docs/squashed")
        self.git("commit", "-qm", "Squash")
        self.dev = self.git("rev-parse", "HEAD")
        self.git("update-ref", cleanup.DEV, self.dev)
        original_git = cleanup.git
        git_patch = patch.object(cleanup, "git", side_effect=lambda *a, **kw:
                                 original_git("-C", str(self.repo), *a, **kw))
        git_patch.start()
        self.addCleanup(git_patch.stop)
        self.pr = {
            "number": 42, "merged_at": "2026-11-17T08:00:00Z", "merge_commit_sha": self.dev,
            "head": {"ref": "docs/squashed", "sha": self.head, "repo": {"full_name": cleanup.REPO}},
            "base": {"ref": "dev", "repo": {"full_name": cleanup.REPO}},
        }

    def git(self, *args):
        return subprocess.check_output(
            ["git", "-C", str(self.repo), *args], text=True, stderr=subprocess.PIPE,
        ).strip()

    def test_preview_and_delete_merged_branches_keep_worktrees_and_protected_refs(self):
        with patch.object(cleanup, "gh", return_value=[[self.pr]]) as gh:
            items = {item["branch"]: item for item in cleanup.scan(self.dev)}
        self.assertEqual(gh.call_count, 1)
        self.assertEqual(items["docs/ancestor"]["status"], "merged")
        self.assertEqual(items["docs/squashed"]["evidence"]["pr"], 42)
        self.assertEqual(items["docs/occupied"]["status"], "checked-out")
        self.assertEqual(items["codex/local"]["status"], "protected")
        self.assertEqual(items["main"]["status"], "protected")
        self.assertEqual(items["dev"]["status"], "protected")
        self.assertEqual(self.git("rev-parse", "docs/squashed"), self.head)
        self.assertFalse(cleanup.clean(items.values()))
        self.assertEqual({b for b, item in items.items() if item["status"] == "deleted"},
                         {"docs/ancestor", "docs/squashed"})
        self.assertEqual(set(self.git("for-each-ref", "--format=%(refname:short)", "refs/heads").splitlines()),
                         {"main", "dev", "codex/local", "docs/occupied"})
        self.assertEqual(cleanup.scan(self.dev, "docs/squashed"), [])

    def test_retains_branch_without_matching_merged_pr_on_dev(self):
        for pr in (
            {**self.pr, "merged_at": None},
            {**self.pr, "merge_commit_sha": self.head},
            {**self.pr, "base": {**self.pr["base"], "ref": "main"}},
            {**self.pr, "head": {**self.pr["head"], "repo": {"full_name": "someone/fork"}}},
        ):
            with self.subTest(pr=pr), patch.object(cleanup, "gh", return_value=[[pr]]):
                self.assertEqual(cleanup.scan(self.dev, "docs/squashed")[0]["status"], "unmerged")
        self.git("switch", "-q", "docs/squashed")
        self.git("commit", "--allow-empty", "-qm", "New local work")
        with patch.object(cleanup, "gh", return_value=[[self.pr]]):
            self.assertEqual(cleanup.scan(self.dev, "docs/squashed")[0]["status"], "unmerged")

    def test_rechecks_branch_tip_and_checkout_before_deleting(self):
        changed = cleanup.scan(self.dev, "docs/ancestor")
        self.git("branch", "-f", "docs/ancestor", self.head)
        self.assertFalse(cleanup.clean(changed))
        self.assertEqual(changed[0]["status"], "changed")
        self.assertEqual(self.git("rev-parse", "docs/ancestor"), self.head)

        with patch.object(cleanup, "gh", return_value=[[self.pr]]):
            occupied = cleanup.scan(self.dev, "docs/squashed")
        self.git("switch", "-q", "docs/squashed")
        self.assertFalse(cleanup.clean(occupied))
        self.assertEqual(occupied[0]["status"], "checked-out")
