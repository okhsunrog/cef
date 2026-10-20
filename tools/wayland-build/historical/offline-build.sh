#!/usr/bin/env bash
set -Eeuo pipefail
export TMPDIR=/build/tmp
export NINJA_STATUS='[%f/%t %es] '
mkdir -p "$TMPDIR" /build/artifacts
trap 'code=$?; printf "%s\n" "$code" > /build/exit-code; date -u > /build/finished-at' EXIT
date -u > /build/started-at
rm -f /build/exit-code /build/finished-at
printf 'compile\n' > /build/phase
cd /build/work/chromium/src
autoninja -C out/Release_GN_x64 -j32 cefsimple cefembed_wayland chrome_sandbox
printf 'package\n' > /build/phase
cd cef
uv run --no-project --python /usr/bin/python3 tools/make_distrib.py \
  --output-dir=/build/distrib --minimal --allow-partial --ninja-build \
  --x64-build --no-symbols --no-docs --no-archive
cp ../out/Release_GN_x64/cefembed_wayland ../out/Release_GN_x64/cefsimple /build/artifacts/
tar -I 'zstd -T4 -3' -cf /build/artifacts/cef-wayland-154-linux-x86_64.tar.zst -C /build/distrib .
cd /build/artifacts
sha256sum cef-wayland-154-linux-x86_64.tar.zst cefembed_wayland cefsimple > SHA256SUMS
printf 'complete\n' > /build/phase
