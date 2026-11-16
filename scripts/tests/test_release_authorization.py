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
        self.head = self.git("rev-parse", "HEAD")
        self.git("switch", "-q", "main")
        self.git("merge", "-q", "--no-ff", "-m", "Release", "dev")
        self.merge = self.git("rev-parse", "HEAD")
        self.pr = {
            "number": 5, "merge_commit_sha": self.merge, "merged_at": "2026-11-16T10:00:00Z",
            "base": {"ref": "main", "repo": {"full_name": "owner/project"}},
            "head": {"ref": "dev", "repo": {"full_name": "owner/project"}, "sha": self.head},
        }
        stub = self.repo / "gh"
        stub.write_text("""#!/bin/sh
case "$1 $2 $3 $4" in
  'api --paginate --slurp repos/owner/project/commits/'*'/pulls?per_page=100') cat pulls.json ;;
  'api --paginate --slurp repos/owner/project/issues/5/comments?per_page=100') cat comments.json ;;
  *) exit 1 ;;
esac
""")
        stub.chmod(0o755)

    def git(self, *args):
        return subprocess.check_output(["git", *args], cwd=self.repo, text=True).strip()

    def verify(self, comments, mode="auto"):
        (self.repo / "pulls.json").write_text(json.dumps([[self.pr]]))
        (self.repo / "comments.json").write_text(json.dumps([comments]))
        return subprocess.run(
            ["bash", str(SCRIPT), mode],
            cwd=self.repo, capture_output=True, text=True,
            env={**os.environ, "PATH": f"{self.repo}:{os.environ['PATH']}",
                 "GITHUB_SHA": self.merge, "GITHUB_REPOSITORY": "owner/project",
                 "GITHUB_REPOSITORY_OWNER_ID": "10"},
        )

    def approval(self, **overrides):
        return {
            "body": f"release-approved {self.head} {self.base} auto",
            "user": {"type": "User", "id": 10},
            "created_at": "2026-11-16T09:58:00Z",
            "updated_at": "2026-11-16T09:58:00Z",
            **overrides,
        }

    def test_owner_approval_covers_exact_pr_and_mode(self):
        result = self.verify([self.approval()])
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.verify([self.approval()], mode="v0.3.1")
        self.assertNotEqual(result.returncode, 0)

    def test_missing_wrong_owner_stale_or_late_approval_blocks(self):
        for comments in (
            [],
            [self.approval(user={"type": "User", "id": 11})],
            [self.approval(body=f"release-approved {'0' * 40} {self.base} auto")],
            [self.approval(body=f"release-approved {self.head} {'0' * 40} auto")],
            [self.approval(updated_at="2026-11-16T10:01:00Z")],
        ):
            with self.subTest(comments=comments):
                result = self.verify(comments)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("missing the owner approval recorded before merge", result.stderr)
