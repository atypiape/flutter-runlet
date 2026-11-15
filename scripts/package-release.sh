#!/bin/bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "$0")/.." && pwd -P)"
output_root="$repo_root/.build/release"
output_dir=
mount_point=
version_pattern='^[0-9]+(\.[0-9]+){0,2}$'
requested_version=

if [[ "$#" -gt 1 ]]; then
  printf '用法：%s [版本号]\n示例：%s v0.1.1\n' "$0" "$0" >&2
  exit 2
fi

if [[ "$#" -eq 1 ]]; then
  requested_version="${1#v}"
  if [[ ! "$requested_version" =~ $version_pattern ]]; then
    printf '版本号须为一至三段数字，可带 v 前缀（例如 v0.1.1）。\n' >&2
    exit 2
  fi
fi

if ! shallow="$(git -C "$repo_root" rev-parse --is-shallow-repository)"; then
  printf '请从 Git 仓库检出项目，以便计算构建号。\n' >&2
  exit 1
fi
if [[ "$shallow" == true ]]; then
  printf '浅克隆缺少完整提交历史。请先运行 git fetch --unshallow，再打包。\n' >&2
  exit 1
fi
requested_build="$(git -C "$repo_root" rev-list --count HEAD)"
set -- "CURRENT_PROJECT_VERSION=$requested_build"
if [[ -n "$requested_version" ]]; then
  set -- "$@" "MARKETING_VERSION=$requested_version"
fi

if ! xcodebuild -version >/dev/null; then
  printf '请安装完整的 Xcode，并将它设为当前开发工具。\n' >&2
  exit 1
fi

mkdir -p "$output_root"
work_dir="$(mktemp -d "$output_root/.package.XXXXXXXX")"
cleanup() {
  local status=$?
  # 挂载期间收到信号也先卸载。未挂载时，验证目录和临时目录在同一个设备上。
  if [[ -n "$mount_point" && "$(stat -f '%d' "$mount_point")" != "$(stat -f '%d' "$work_dir")" ]] &&
    ! hdiutil detach -quiet "$mount_point"; then
    printf '无法卸载验证用 DMG，已保留临时目录：%s\n' "$work_dir" >&2
    exit 1
  fi
  rm -R -- "$work_dir"
  if [[ "$status" -ne 0 && -n "$output_dir" ]]; then
    rm -R -- "$output_dir"
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

printf '正在构建 FlutterRunlet Release（构建 %s，Apple Silicon 和 Intel）…\n' "$requested_build"
xcodebuild -quiet \
  -project "$repo_root/FlutterRunlet.xcodeproj" \
  -scheme FlutterRunlet \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$work_dir/DerivedData" \
  'ARCHS=arm64 x86_64' ONLY_ACTIVE_ARCH=NO 'CODE_SIGN_IDENTITY=-' \
  DEPLOYMENT_POSTPROCESSING=YES STRIP_INSTALLED_PRODUCT=YES STRIP_STYLE=debugging STRIP_SWIFT_SYMBOLS=NO \
  "$@" build

app="$work_dir/DerivedData/Build/Products/Release/FlutterRunlet.app"
version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")"
build="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$app/Contents/Info.plist")"
if [[ ! "$version" =~ $version_pattern ]]; then
  printf 'App 的版本号无效（%s）。\n' "$version" >&2
  exit 1
fi
if [[ "$build" != "$requested_build" || ( -n "$requested_version" && "$version" != "$requested_version" ) ]]; then
  printf 'App 的版本号或构建号与预期不符（实际为 %s，构建 %s）。\n' "$version" "$build" >&2
  exit 1
fi

verify_packaged_app() {
  local packaged_app="$1" executable architectures
  local helper='Contents/Helpers/FlutterRunletUpdateHelper.app'
  local worker='Contents/Helpers/FlutterRunletSessionWorker'
  codesign --verify --deep --strict --all-architectures "$packaged_app" || return 1
  codesign --verify --strict --all-architectures "$packaged_app/$worker" || return 1
  codesign --verify --strict --all-architectures "$packaged_app/$helper" || return 1

  for executable in Contents/MacOS/FlutterRunlet "$worker" "$helper/Contents/MacOS/FlutterRunletUpdateHelper"; do
    architectures="$(lipo -archs "$packaged_app/$executable")" || return 1
    case "$architectures" in
      'arm64 x86_64'|'x86_64 arm64') ;;
      *)
        printf '%s 缺少预期的双架构支持：%s\n' "$executable" "$architectures" >&2
        return 1
        ;;
    esac
    # 直接扫描二进制字节，覆盖 fat Mach-O 的两个切片及字符串表。
    if ! /usr/bin/perl -e '
      my ($file, @prefixes) = @ARGV;
      open my $input, "<:raw", $file or die "Cannot read Mach-O: $!\n";
      local $/;
      my $bytes = <$input>;
      die "Empty Mach-O\n" unless defined $bytes && length $bytes;
      for my $prefix (@prefixes) {
        exit 1 if index($bytes, $prefix) >= 0;
      }
      exit($bytes =~ m{/(?:Users|Volumes|home|(?:private/)?var/(?:folders|tmp)|(?:private/)?tmp)/[^/\x00\s]} ? 1 : 0);
    ' "$packaged_app/$executable" "$repo_root/" "$work_dir/"; then
      printf '%s 未通过构建机路径检查。\n' "$executable" >&2
      return 1
    fi
    printf '已核对 %s 的双架构、签名及构建机路径。\n' "${executable##*/}"
  done
}

stage="$work_dir/stage"
mkdir "$stage"
ditto "$app" "$stage/FlutterRunlet.app"
ln -s /Applications "$stage/Applications"

dmg="FlutterRunlet-v$version-macOS-universal.dmg"
printf '正在创建并校验 DMG…\n'
hdiutil create -quiet -srcfolder "$stage" -volname FlutterRunlet \
  -fs 'HFS+' -format UDZO "$work_dir/$dmg"
hdiutil verify -quiet "$work_dir/$dmg"
mkdir "$work_dir/mount"
mount_point="$work_dir/mount"
hdiutil attach -quiet -readonly -nobrowse -noautoopen -mountpoint "$mount_point" "$work_dir/$dmg"
verify_packaged_app "$mount_point/FlutterRunlet.app"
hdiutil detach -quiet "$mount_point"
mount_point=
(
  cd "$work_dir"
  shasum -a 256 "$dmg" > "$dmg.sha256"
)

output_dir="$(mktemp -d "$output_root/v$version-build$build.XXXXXXXX")"
mv "$work_dir/$dmg" "$work_dir/$dmg.sha256" "$output_dir/"
printf '\n打包完成（v%s，构建 %s）\n%s\n%s\n' \
  "$version" "$build" "$output_dir/$dmg" "$output_dir/$dmg.sha256"
