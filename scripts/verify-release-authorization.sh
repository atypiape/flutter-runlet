#!/bin/bash
set -euo pipefail

mode="${1:?Expected auto or the authorized manual version}"
repo="repos/$GITHUB_REPOSITORY"
sha="$(git rev-parse HEAD)"
[[ "$sha" == "$GITHUB_SHA" ]] || { echo 'Release checkout does not match main CI.' >&2; exit 1; }
pr="$(gh api --paginate --slurp "$repo/commits/$sha/pulls?per_page=100" |
  jq -ce --arg repo "$GITHUB_REPOSITORY" --arg sha "$sha" '
    [.[][] | select(.merged_at and .merge_commit_sha == $sha and .base.ref == "main"
      and .base.repo.full_name == $repo and .head.repo.full_name == $repo
      and (.head.ref == "dev" or (.head.ref | startswith("hotfix/"))))]
    | if length == 1 then .[0] else error("Expected one merged release PR") end')"
number="$(jq -er '.number' <<< "$pr")"
merged_at="$(jq -er '.merged_at' <<< "$pr")"
head="$(jq -er '.head.sha' <<< "$pr")"
branch="$(jq -er '.head.ref' <<< "$pr")"
# Read the recorded parents even in a shallow checkout.
parents="$(git cat-file -p "$sha" | awk '/^$/ { body = 1 } !body && /^parent / { print $2 }')"
base="$(sed -n '1p' <<< "$parents")"
if [[ "$branch" == dev ]]; then
  [[ "$parents" == "$(printf '%s\n%s' "$base" "$head")" ]] ||
    { echo 'The dev release PR must use a Merge Commit.' >&2; exit 1; }
else
  [[ "$parents" == "$base" ]] || { echo 'A hotfix release PR must use Squash Merge.' >&2; exit 1; }
fi
[[ "$head" =~ ^[0-9a-f]{40}$ && "$base" =~ ^[0-9a-f]{40}$ ]]
approval="release-approved $head $base $mode"
gh api --paginate --slurp "$repo/issues/$number/comments?per_page=100" |
  jq -e --arg approval "$approval" --arg merged "$merged_at" --argjson owner "$GITHUB_REPOSITORY_OWNER_ID" '
    any(.[][]; .user.type == "User" and .user.id == $owner and .body == $approval
      and .created_at < $merged and .updated_at < $merged)
  ' >/dev/null || {
    printf '::error::PR #%s is missing the owner approval recorded before merge. Expected: %s\n' "$number" "$approval" >&2
    exit 1
  }
printf 'Release authorization verified on PR #%s.\n' "$number"
