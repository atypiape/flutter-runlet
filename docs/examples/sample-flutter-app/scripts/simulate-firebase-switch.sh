#!/bin/sh
set -eu

case "$#:${1-}:${2-}" in
    2:dev:--quiet|2:test:--quiet|2:prod:--quiet) ;;
    *)
        printf '%s\n' 'Usage: simulate-firebase-switch.sh {dev|test|prod} --quiet' >&2
        exit 64
        ;;
esac

environment=$1
state_dir=.runlet-fixture
if [ -f "$state_dir/fail-before-$environment" ]; then
    printf 'Sample Firebase switch to %s failed before writing.\n' "$environment" >&2
    exit 1
fi

mkdir -p "$state_dir"
printf '%s\n' "$environment" > "$state_dir/firebase-environment"

if [ -f "$state_dir/fail-after-$environment" ]; then
    printf 'Sample Firebase switch to %s failed after writing.\n' "$environment" >&2
    exit 1
fi
