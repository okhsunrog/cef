#!/usr/bin/env bash
set -Eeuo pipefail
export TMPDIR=/build/tmp
export GN_OUT_CONFIGS=Release_GN_x64
trap 'code=$?; printf "%s\n" "$code" > /build/preparation-exit-code' EXIT
/opt/depot_tools/ensure_bootstrap
if ! pkg-config --exists libpipewire-0.3; then
  sudo apt-get -o "Acquire::http::Proxy=$HTTP_PROXY" -o "Acquire::https::Proxy=$HTTPS_PROXY" update
  sudo apt-get -o "Acquire::http::Proxy=$HTTP_PROXY" -o "Acquire::https::Proxy=$HTTPS_PROXY" install -y --no-install-recommends libpipewire-0.3-dev
fi
cd /build/work/chromium/src
gn gen out/Release_GN_x64
cp out/Release_GN_x64/args.gn /build/artifacts/args.gn
git -C cef rev-parse HEAD > /build/artifacts/cef-revision.txt
git rev-parse HEAD > /build/artifacts/chromium-revision.txt
git -C /opt/depot_tools rev-parse HEAD > /build/artifacts/depot-tools-revision.txt
printf 'ready-for-offline-check\n' > /build/preparation-phase
