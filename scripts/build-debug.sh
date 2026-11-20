#!/bin/bash
set -euo pipefail

usage() {
  printf '用法：%s [--open | --wait | --stop] [工作树目录]\n' "${0##*/}"
  printf '构建 macOS Debug 版并打印 .app 路径。默认构建脚本所在的工作树。\n'
  printf '  --open  构建成功后打开应用\n'
  printf '  --wait  构建并打开应用，等待应用退出\n'
  printf '  --stop  请求退出此工作树运行的 Debug 应用\n'
}

mode=build
case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  --open|--wait|--stop)
    mode="${1#--}"
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

if [[ "$mode" == stop ]]; then
  /usr/bin/osascript -l JavaScript - "$app" <<'JXA'
ObjC.import("AppKit");

function run([appPath]) {
    const expectedPath = ObjC.unwrap($.NSURL.fileURLWithPath(appPath).URLByResolvingSymlinksInPath.path);
    const applications = $.NSWorkspace.sharedWorkspace.runningApplications;
    let requested = false;
    for (let index = 0; index < applications.count; index++) {
        const application = applications.objectAtIndex(index);
        const bundleURL = application.bundleURL;
        if (typeof ObjC.unwrap(bundleURL.path) !== "string") continue;
        const bundlePath = ObjC.unwrap(bundleURL.URLByResolvingSymlinksInPath.path);
        if (bundlePath !== expectedPath || application.terminated) continue;
        application.activateWithOptions(0);
        if (!application.terminate && !application.terminated) {
            throw new Error("无法向 FlutterRunlet 发送退出请求。");
        }
        requested = true;
    }
    return requested ? "已请求 FlutterRunlet 正常退出。" : "当前工作树的 FlutterRunlet 未在运行。";
}
JXA
  exit
fi

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
case "$mode" in
  open) /usr/bin/open "$app" ;;
  wait) exec /usr/bin/open -W "$app" ;;
esac
