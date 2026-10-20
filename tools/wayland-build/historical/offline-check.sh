#!/usr/bin/env bash
set -Eeuo pipefail
export TMPDIR=/build/tmp
cd /build/work/chromium/src
third_party/llvm-build/Release+Asserts/bin/clang --version
gn gen out/Release_GN_x64
autoninja -C out/Release_GN_x64 -n cefsimple cefembed_wayland chrome_sandbox > /build/offline-dry-run.log
tail -n 5 /build/offline-dry-run.log
