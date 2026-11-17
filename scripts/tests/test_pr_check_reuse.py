import json
import os
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "reuse-pr-check.sh"
HEAD = "a" * 40
MERGE = "b" * 40
CHECK = "macOS build and test"


class PRCheckReuseTests(unittest.TestCase):
    def setUp(self):
        fixture = TemporaryDirectory()
        self.addCleanup(fixture.cleanup)
        self.root = Path(fixture.name)
        (self.root / "event.json").write_text(json.dumps({
            "number": 60, "pull_request": {"head": {"sha": HEAD}},
        }))
        stub = self.root / "gh"
        stub.write_text("""#!/bin/sh
case "$*" in
  "api --method GET --paginate --slurp repos/owner/project/actions/workflows/ci.yml/runs -f event=pull_request -f head_sha=$FIXTURE_HEAD -F per_page=100")
    cat runs.json ;;
  'api repos/owner/project/actions/runs/101') cat completed.json ;;
  'api repos/owner/project/actions/runs/101/jobs?filter=latest&per_page=100') cat jobs.json ;;
  *) exit 1 ;;
esac
""")
        stub.chmod(0o755)
        sleep = self.root / "sleep"
        sleep.write_text("#!/bin/sh\nexit 0\n")
        sleep.chmod(0o755)

    def run_record(self, **overrides):
        return {
            "id": 101, "run_number": 8, "event": "pull_request", "head_sha": HEAD,
            "display_title": f"[PR #60] [validate {MERGE}] Example",
            "status": "completed", "conclusion": "success", **overrides,
        }

    def verify(self, records, job_conclusion="success"):
        (self.root / "runs.json").write_text(json.dumps([{"workflow_runs": records}]))
        (self.root / "completed.json").write_text(json.dumps(self.run_record()))
        (self.root / "jobs.json").write_text(json.dumps({"jobs": [
            {"name": CHECK, "head_sha": HEAD, "conclusion": job_conclusion},
        ]}))
        output = self.root / "output"
        output.write_text("")
        result = subprocess.run(
            ["bash", str(SCRIPT), "ci.yml", CHECK], cwd=self.root,
            env={**os.environ, "PATH": f"{self.root}:{os.environ['PATH']}",
                 "GITHUB_REPOSITORY": "owner/project", "GITHUB_SHA": MERGE,
                 "GITHUB_RUN_NUMBER": "10", "GITHUB_EVENT_PATH": str(self.root / "event.json"),
                 "GITHUB_OUTPUT": str(output), "FIXTURE_HEAD": HEAD},
            capture_output=True, text=True, timeout=10,
        )
        return result, output.read_text()

    def test_exact_previous_success_is_reused(self):
        result, output = self.verify([self.run_record()])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(output, "reused=true\n")

    def test_successful_previous_edit_can_supply_the_same_merge_commit(self):
        result, output = self.verify([
            self.run_record(display_title=f"[PR #60] [metadata {MERGE}] Example"),
        ])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(output, "reused=true\n")

    def test_prior_verification_can_finish_after_metadata_edit(self):
        result, output = self.verify([self.run_record(status="in_progress", conclusion=None)])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Waiting for prior validation run 101", result.stdout)
        self.assertEqual(output, "reused=true\n")

    def test_different_merge_pr_head_and_current_run_need_verification(self):
        for record in (
            self.run_record(display_title=f"[PR #60] [validate {'c' * 40}] Example"),
            self.run_record(display_title=f"[PR #61] [validate {MERGE}] Example"),
            self.run_record(head_sha="d" * 40), self.run_record(event="push"),
            self.run_record(run_number=10), self.run_record(run_number=11),
            self.run_record(display_title=f"[PR #60] [metadata {MERGE}] Example",
                            conclusion="cancelled"),
        ):
            with self.subTest(record=record):
                result, output = self.verify([record])
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(output, "")
                self.assertIn("Running verification", result.stdout)

    def test_latest_failure_is_preserved_despite_prior_success(self):
        result, output = self.verify([
            self.run_record(id=100, run_number=7), self.run_record(conclusion="failure"),
        ])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("did not pass", result.stderr)
        self.assertEqual(output, "")

    def test_workflow_success_alone_cannot_supply_a_skipped_required_job(self):
        result, output = self.verify([self.run_record()], job_conclusion="skipped")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("did not pass", result.stderr)
        self.assertEqual(output, "")
