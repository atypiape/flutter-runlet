import json
import os
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "verify-release-authorization.sh"


class ReleaseAuthorizationTests(unittest.TestCase):
    def setUp(self):
        fixture = TemporaryDirectory()
        self.addCleanup(fixture.cleanup)
        self.repo = Path(fixture.name)
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.git("commit", "-q", "--allow-empty", "-m", "Base")
        self.base = self.git("rev-parse", "HEAD")
        self.git("switch", "-q", "-c", "dev")
        self.git("commit", "-q", "--allow-empty", "-m", "Feature")
        self.merge_dev()

        stub = self.repo / "gh"
        stub.write_text("""#!/bin/sh
case "$1 $2 $3 $4" in
  'api --paginate --slurp repos/owner/project/commits/'*'/pulls?per_page=100') cat pulls.json ;;
  'api repos/owner/project/pulls/5  ') cat pull.json ;;
  *) exit 1 ;;
esac
""")
        stub.chmod(0o755)

    def merge_dev(self):
        self.head = self.git("rev-parse", "HEAD")
        self.git("switch", "-q", "main")
        self.git("merge", "-q", "--no-ff", "-m", "Release", "dev")
        self.merge = self.git("rev-parse", "HEAD")
        self.pr = {
            "number": 5, "merge_commit_sha": self.merge, "merged_at": "2026-11-16T10:00:00Z",
            "merged": True, "merged_by": {"type": "User", "id": 10},
            "base": {"ref": "main", "repo": {"full_name": "owner/project"}},
            "head": {"ref": "dev", "repo": {"full_name": "owner/project"}, "sha": self.head},
        }

    def git(self, *args):
        return subprocess.check_output(["git", *args], cwd=self.repo, text=True).strip()

    def verify(self, mode="auto", **overrides):
        (self.repo / "pulls.json").write_text(json.dumps([[self.pr]]))
        (self.repo / "pull.json").write_text(json.dumps({**self.pr, **overrides}))
        return subprocess.run(
            ["bash", str(SCRIPT), mode],
            cwd=self.repo, capture_output=True, text=True,
            env={**os.environ, "PATH": f"{self.repo}:{os.environ['PATH']}",
                 "GITHUB_SHA": self.merge, "GITHUB_REPOSITORY": "owner/project",
                 "GITHUB_REPOSITORY_OWNER_ID": "10"},
        )

    def test_owner_merge_authorizes_automatic_release(self):
        result = self.verify()
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_missing_other_user_or_bot_merger_blocks_release(self):
        for merger in (None, {"type": "User", "id": 11}, {"type": "Bot", "id": 10}):
            with self.subTest(merger=merger):
                result = self.verify(merged_by=merger)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("repository owner must merge", result.stderr)

    def test_pr_detail_must_match_checkout_and_merge_parent(self):
        other_head = {**self.pr["head"], "sha": self.base}
        for detail in ({"merge_commit_sha": self.base}, {"head": other_head}, {"merged": False}):
            with self.subTest(detail=detail):
                self.assertNotEqual(self.verify(**detail).returncode, 0)

    def test_manual_release_requires_matching_notes_added_by_pr(self):
        self.assertNotEqual(self.verify(mode="v0.4.2").returncode, 0)
        self.git("switch", "-q", "dev")
        notes = self.repo / "docs/releases/v0.4.2.md"
        notes.parent.mkdir(parents=True)
        notes.write_text("Release notes")
        self.git("add", str(notes))
        self.git("commit", "-qm", "Release notes")
        self.merge_dev()

        result = self.verify(mode="v0.4.2")
        self.assertEqual(result.returncode, 0, result.stderr)
        for mode in ("v0.4.3", "auto"):
            with self.subTest(mode=mode):
                self.assertNotEqual(self.verify(mode=mode).returncode, 0)

        self.git("switch", "-q", "dev")
        self.git("commit", "-q", "--allow-empty", "-m", "Another change")
        self.merge_dev()
        self.assertNotEqual(self.verify(mode="v0.4.2").returncode, 0)
