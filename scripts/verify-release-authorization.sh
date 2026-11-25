#!/bin/bash
set -euo pipefail

mode="${1:?Expected auto or the authorized manual version}"
repo="repos/$GITHUB_REPOSITORY"
sha="$(git rev-parse HEAD)"
[[ "$sha" == "$GITHUB_SHA" ]] || { echo 'Release checkout does not match main CI.' >&2; exit 1; }
number="$(gh api --paginate --slurp "$repo/commits/$sha/pulls?per_page=100" |
  jq -ce --arg repo "$GITHUB_REPOSITORY" --arg sha "$sha" '
    [.[][] | select(.merged_at and .merge_commit_sha == $sha and .base.ref == "main"
      and .base.repo.full_name == $repo and .head.repo.full_name == $repo
      and (.head.ref == "dev" or (.head.ref | startswith("hotfix/"))))]
    | if length == 1 then .[0].number else error("Expected one merged release PR") end')"
pr="$(gh api "$repo/pulls/$number")"
jq -e --arg sha "$sha" --arg repo "$GITHUB_REPOSITORY" \
  --argjson owner "$GITHUB_REPOSITORY_OWNER_ID" '
    .merged == true and .merge_commit_sha == $sha and
    .base.ref == "main" and .base.repo.full_name == $repo and
    .head.repo.full_name == $repo and
    (.head.ref == "dev" or (.head.ref | startswith("hotfix/"))) and
    .merged_by.type == "User" and .merged_by.id == $owner
  ' <<< "$pr" >/dev/null || {
    printf '::error::The repository owner must merge release PR #%s.\n' "$number" >&2
    exit 1
  }
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
# A manual version is fixed by the newly added notes in the merged tree.
notes="$(git diff --no-renames --diff-filter=A --name-only "$base" "$sha" -- ':(glob)docs/releases/v*.md')"
case "$mode" in
  auto)
    [[ -z "$notes" ]] || {
      echo '::error::This PR adds version-specific notes. Dispatch the named prerelease manually.' >&2
      exit 1
    }
    ;;
  *)
    [[ "$mode" =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ &&
      "$notes" == "docs/releases/$mode.md" ]] || {
      echo '::error::The release PR must add the notes for exactly the requested version.' >&2
      exit 1
    }
    ;;
esac
printf 'Release authorization verified on PR #%s.\n' "$number"
