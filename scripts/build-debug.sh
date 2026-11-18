#!/bin/bash
set -euo pipefail

usage() {
  printf '用法：%s [--open] [工作树目录]\n' "${0##*/}"
  printf '构建 macOS Debug 版并打印 .app 路径。默认构建脚本所在的工作树。\n'
  printf '  --open  构建成功后打开应用\n'
}

open_app=false
case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  --open)
    open_app=true
    shift
    ;;
esac

if [[ $# -gt 1 || "${1:-}" == -* ]]; then
  usage >&2
  exit 2
fi

source_dir="${1:-$(dirname -- "$0")/..}"
if ! project_root="$(cd -- "$source_dir" && pwd -P)" ||
  [[ ! -d "$project_root/FlutterRunlet.xcodeproj" ]]; then
  printf '未在此目录找到 FlutterRunlet.xcodeproj：%s\n' "$source_dir" >&2
  exit 1
fi

derived_data="$project_root/.build/debug"
app="$derived_data/Build/Products/Debug/FlutterRunlet.app"

xcodebuild -quiet \
  -project "$project_root/FlutterRunlet.xcodeproj" \
  -scheme FlutterRunlet \
  -configuration Debug \
  -destination "platform=macOS,arch=$(uname -m)" \
  -derivedDataPath "$derived_data" \
  build >&2

if [[ ! -x "$app/Contents/MacOS/FlutterRunlet" ]]; then
  printf '未找到可执行的构建产物：%s\n' "$app" >&2
  exit 1
fi

printf '%s\n' "$app"
if [[ "$open_app" == true ]]; then
  open "$app"
fi
