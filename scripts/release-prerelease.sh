#!/bin/bash
set -euo pipefail
export LC_ALL=C

fail() {
  printf '::error::%s\n' "$1" >&2
  exit 1
}

[[ "$GITHUB_EVENT_NAME" == workflow_dispatch && "$GITHUB_REF" == refs/heads/main && "$GITHUB_RUN_ATTEMPT" == 1 ]] ||
  fail 'Publication requires a new manual run on main.'
[[ "$VERSION" =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] ||
  fail 'Invalid release version.'
[[ "$DMG_SHA256" =~ ^[0-9a-f]{64}$ ]] || fail 'Missing or invalid candidate digest.'
[[ "$(git rev-parse HEAD)" == "$GITHUB_SHA" ]] || fail 'Checkout does not match the reviewed commit.'

repo="repos/$GITHUB_REPOSITORY"
notes="docs/releases/$VERSION.md"
dmg="FlutterRunlet-$VERSION-macOS-universal.dmg"

# An unprotected or auto-created environment cannot supply this decision.
approval="audit-approved $VERSION $DMG_SHA256"
gh api "$repo/actions/runs/$GITHUB_RUN_ID/approvals" |
  jq -e --arg approval "$approval" 'any(.[]; .state == "approved" and .comment == $approval and
    any(.environments[]; .name == "release"))' >/dev/null ||
  fail 'The release environment must approve this version and DMG digest after audit.'

gh api --method GET "$repo/actions/workflows/ci.yml/runs"   -f branch=main -f event=push -f head_sha="$GITHUB_SHA" -F per_page=1 |
  jq -e --arg sha "$GITHUB_SHA" '.workflow_runs[0] |
    .head_sha == $sha and .head_branch == "main" and .event == "push" and .conclusion == "success"' >/dev/null ||
  fail 'The exact main commit must pass the push CI workflow.'

if ! [[ -s "$notes" ]] || ! grep -qxF '## 简体中文' "$notes" || ! grep -qxF '## English' "$notes"; then
  fail 'Commit the bilingual version notes under docs/releases/ before publishing.'
fi
notes_file="$(mktemp)"
trap 'rm -f -- "$notes_file"' EXIT
cat "$notes" > "$notes_file"
cat >> "$notes_file" <<'NOTES'

### 安装 / Installation

通用 DMG 包含 Apple Silicon 和 Intel，最低部署目标为 macOS 15.0。请用配套 SHA-256 文件核验下载。本预发布包使用临时签名，未经 Apple 公证，需手动安装。

The Universal DMG includes Apple Silicon and Intel slices and targets macOS 15.0 or later. Verify the download with the accompanying SHA-256 file. This prerelease is ad hoc signed, is not Apple notarized, and requires manual installation.
NOTES

cd "$1"
[[ "$(sha256sum "$dmg")" == "$DMG_SHA256  $dmg" ]] || fail 'The downloaded DMG differs from the reviewed candidate.'
printf '%s  %s\n' "$DMG_SHA256" "$dmg" | cmp - "$dmg.sha256" ||
  fail 'The checksum file does not describe the reviewed DMG.'
sidecar_sha="$(sha256sum "$dmg.sha256" | cut -d ' ' -f 1)"

# Include drafts in the duplicate check. Errors from GitHub also block publication.
gh api --paginate --slurp "$repo/releases?per_page=100" |
  jq -e --arg version "$VERSION" 'all(.[][]; .tag_name != $version)' >/dev/null ||
  fail 'This version already has a Release, or Release state could not be verified.'
[[ "$(gh api "$repo/git/ref/heads/main" --jq '.object.sha')" == "$GITHUB_SHA" ]] ||
  fail 'main moved after dispatch. Build and review a new candidate.'

# Create the ref atomically; GitHub rejects an existing tag, even at the same commit.
gh api --method POST "$repo/git/refs" -f ref="refs/tags/$VERSION" -f sha="$GITHUB_SHA" --silent
gh release create "$VERSION" "$dmg" "$dmg.sha256" --repo "$GITHUB_REPOSITORY" \
  --verify-tag --draft --prerelease --latest=false --title "FlutterRunlet $VERSION" --notes-file "$notes_file"

release_id="$(gh release view "$VERSION" --repo "$GITHUB_REPOSITORY" --json databaseId,isDraft,isPrerelease |
  jq -er 'select(.isDraft and .isPrerelease) | .databaseId')"
gh api "$repo/releases/$release_id/assets?per_page=3" |
  jq -e --arg dmg "$dmg" --arg image "sha256:$DMG_SHA256" --arg sidecar "sha256:$sidecar_sha" '
    length == 2 and
    any(.[]; .name == $dmg and .state == "uploaded" and .digest == $image) and
    any(.[]; .name == ($dmg + ".sha256") and .state == "uploaded" and .digest == $sidecar)
  ' >/dev/null || fail 'The uploaded draft assets did not match the reviewed checksums. Inspect the draft.'
[[ "$(gh api "$repo/git/ref/tags/$VERSION" --jq '.object.sha')" == "$GITHUB_SHA" ]] ||
  fail 'The release tag no longer points to the reviewed commit.'
gh api --method PATCH "$repo/releases/$release_id" -F draft=false -F prerelease=true -f make_latest=false \
  --jq '.html_url'
