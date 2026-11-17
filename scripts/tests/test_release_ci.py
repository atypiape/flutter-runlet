import json
import os
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "verify-release-ci.sh"
SHA = "a" * 40


class ReleaseCITests(unittest.TestCase):
    def setUp(self):
        fixture = TemporaryDirectory()
        self.addCleanup(fixture.cleanup)
        self.root = Path(fixture.name)
        stub = self.root / "gh"
        stub.write_text("""#!/bin/sh
case "$*" in
  "api --method GET repos/owner/project/actions/workflows/ci.yml/runs -f branch=main -f event=push -f head_sha=$GITHUB_SHA -F per_page=1") cat run.json ;;
  "api repos/owner/project/actions/runs/101/jobs?filter=latest&per_page=100") cat jobs.json ;;
  *) exit 1 ;;
esac
""")
        stub.chmod(0o755)
        self.run = {"id": 101, "event": "push", "head_branch": "main", "head_sha": SHA,
                    "conclusion": "success"}
        self.job = {"head_sha": SHA, "conclusion": "success", "steps": [
            {"name": step, "conclusion": "success"} for step in (
                "Build and run XCTest", "Build and verify Universal DMG", "Upload candidate",
            )
        ]}

    def verify(self, runs, jobs):
        (self.root / "run.json").write_text(json.dumps({"workflow_runs": runs}))
        (self.root / "jobs.json").write_text(json.dumps({"jobs": jobs}))
        return subprocess.run(
            ["bash", str(SCRIPT)], cwd=self.root, capture_output=True, text=True,
            env={**os.environ, "PATH": f"{self.root}:{os.environ['PATH']}",
                 "GITHUB_REPOSITORY": "owner/project", "GITHUB_SHA": SHA},
        )

    def test_exact_main_push_with_all_required_steps_passes(self):
        result = self.verify([self.run], [self.job])
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_unrelated_or_failed_runs_block_release(self):
        for runs in ([], [{**self.run, "head_sha": "b" * 40}],
                     [{**self.run, "head_branch": "dev"}],
                     [{**self.run, "event": "pull_request"}],
                     [{**self.run, "conclusion": "failure"}]):
            with self.subTest(runs=runs):
                self.assertNotEqual(self.verify(runs, [self.job]).returncode, 0)

    def test_successful_lightweight_run_cannot_release(self):
        for skipped in self.job["steps"]:
            with self.subTest(step=skipped["name"]):
                steps = [{**step, "conclusion": "skipped"} if step == skipped else step
                         for step in self.job["steps"]]
                result = self.verify([self.run], [{**self.job, "steps": steps}])
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("must pass XCTest, Universal DMG verification, and upload", result.stderr)

    def test_missing_or_unrelated_job_blocks_release(self):
        for jobs in ([], [{**self.job, "head_sha": "b" * 40}]):
            with self.subTest(jobs=jobs):
                self.assertNotEqual(self.verify([self.run], jobs).returncode, 0)
