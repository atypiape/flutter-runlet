#!/bin/bash
set -euo pipefail

repo="repos/$GITHUB_REPOSITORY"
if ! run_id="$(gh api --method GET "$repo/actions/workflows/ci.yml/runs" \
    -f branch=main -f event=push -f head_sha="$GITHUB_SHA" -F per_page=1 |
    jq -er --arg sha "$GITHUB_SHA" '.workflow_runs[0] |
      select(.head_sha == $sha and .head_branch == "main" and .event == "push" and .conclusion == "success") |
      .id | select(type == "number")')"; then
  echo '::error::The exact main commit must pass the push CI workflow.' >&2
  exit 1
fi

# These step names match the build, verification, and upload in ci.yml.
if ! gh api "$repo/actions/runs/$run_id/jobs?filter=latest&per_page=100" |
    jq -e --arg sha "$GITHUB_SHA" 'any(.jobs[];
      .head_sha == $sha and .conclusion == "success" and
      ([.steps[] | select(.conclusion == "success") | .name] |
        index("Build and run XCTest") != null and
        index("Build and verify Universal DMG") != null and
        index("Upload candidate") != null))' >/dev/null; then
  echo '::error::The exact main commit must pass XCTest, Universal DMG verification, and upload in push CI.' >&2
  exit 1
fi
