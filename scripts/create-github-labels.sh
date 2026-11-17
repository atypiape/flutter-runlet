#!/bin/bash
set -euo pipefail

usage() {
  printf '用法：bash scripts/create-github-labels.sh --repo OWNER/REPO\n'
}

if [[ $# -eq 1 && ( $1 == --help || $1 == -h ) ]]; then
  usage
  exit 0
fi
if [[ $# -ne 2 || $1 != --repo || ! $2 =~ ^[a-zA-Z0-9-]+/[a-zA-Z0-9._-]+$ ]]; then
  usage >&2
  exit 2
fi

repo=$2
repo_name=${repo#*/}
if [[ $repo_name == . || $repo_name == .. ]]; then
  usage >&2
  exit 2
fi
actual_repo=$(gh api --hostname github.com --method GET "repos/$repo" --jq .full_name)
if [[ "$actual_repo" != "$repo" ]]; then
  printf '请显式指定 GitHub 返回的仓库全名：%s\n' "$actual_repo" >&2
  exit 1
fi
labels=$(gh api --hostname github.com --method GET --paginate "repos/$repo/labels?per_page=100" \
  --jq '.[].name')

ensure_label() {
  local name=$1 color=$2 description=$3
  if grep -Fqx -- "$name" <<< "$labels"; then
    printf '已存在：%s\n' "$name"
    return
  fi
  gh label create "$name" --repo "github.com/$repo" --color "$color" --description "$description"
  printf '已创建：%s\n' "$name"
}

ensure_label "task:ready"   "0E8A16" "已批准，允许 AI Agent 领取"
ensure_label "task:working" "0052CC" "AI Agent 正在处理"
ensure_label "task:review"  "D4C5F9" "已创建 PR，等待检查"
ensure_label "task:blocked" "B60205" "自动开发受阻，需要人工处理"
