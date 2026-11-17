#!/bin/bash
set -euo pipefail

workflow="$1"
check_name="$2"
number=$(jq -er '.number | select(type == "number")' "$GITHUB_EVENT_PATH")
head=$(jq -er '.pull_request.head.sha | select(test("^[0-9a-f]{40}$"))' "$GITHUB_EVENT_PATH")
repo="repos/$GITHUB_REPOSITORY"

# GitHub lists PR runs under the source SHA, so also match the actual merge SHA
# recorded by the workflow in its run name. A different target needs a new check.
run=$(gh api --method GET --paginate --slurp "$repo/actions/workflows/$workflow/runs" \
    -f event=pull_request -f head_sha="$head" -F per_page=100 |
  jq -c --arg prefix "[PR #$number]" --arg head "$head" --arg sha "$GITHUB_SHA" \
    --argjson run_number "$GITHUB_RUN_NUMBER" '
      [.[] | .workflow_runs[] | select(
        .event == "pull_request" and .head_sha == $head and .run_number < $run_number and
        ((.display_title | startswith($prefix + " [validate " + $sha + "] ")) or
         (.status == "completed" and .conclusion != "cancelled" and
          (.display_title | startswith($prefix + " [metadata " + $sha + "] "))))
      )] | max_by(.run_number) // empty')
if [[ -z "$run" ]]; then
  echo 'No prior result for this PR merge commit. Running verification.'
  exit 0
fi

run_id=$(jq -er '.id | select(type == "number")' <<< "$run")
if [[ "$(jq -r '.status' <<< "$run")" != completed ]]; then
  printf 'Waiting for prior validation run %s.\n' "$run_id"
  while [[ "$(jq -r '.status' <<< "$run")" != completed ]]; do
    sleep 10
    run=$(gh api "$repo/actions/runs/$run_id")
  done
fi

if [[ "$(jq -r '.conclusion' <<< "$run")" != success ]] ||
   ! gh api "$repo/actions/runs/$run_id/jobs?filter=latest&per_page=100" |
     jq -e --arg head "$head" --arg name "$check_name" '
       any(.jobs[]; .name == $name and .head_sha == $head and .conclusion == "success")' >/dev/null; then
  printf '::error::Prior run %s did not pass %s for this PR merge commit.\n' "$run_id" "$check_name" >&2
  exit 1
fi

printf 'Reused %s from run %s for the same PR merge commit.\n' "$check_name" "$run_id"
printf 'reused=true\n' >> "$GITHUB_OUTPUT"
