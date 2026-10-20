#!/usr/bin/env bash
# Run inside the Docker image with a persistent /build mount.
set -Eeuo pipefail
export TMPDIR=/build/tmp GN_OUT_CONFIGS=Release_GN_x64
export DEPOT_TOOLS_UPDATE=0
mkdir -p "$TMPDIR" /build/artifacts
# Bind-mounted source ownership can differ from the container user.
git config --global --add safe.directory /cef-source
git config --global --add safe.directory /build/work/chromium/src/cef
case "${1:-}" in
prepare)
  export GN_DEFINES='is_official_build=false is_component_build=false symbol_level=0 blink_symbol_level=0 v8_symbol_level=0 use_thin_lto=false chrome_pgo_phase=0 use_remoteexec=false use_siso=false ozone_platform_wayland=true ozone_platform_x11=true enable_vulkan=true use_sysroot=false use_qt5=false use_qt6=false'
  /opt/depot_tools/ensure_bootstrap
  uv run --no-project --python /usr/bin/python3 /cef-source/tools/automate/automate-git.py \
    --download-dir=/build/work --depot-tools-dir=/opt/depot_tools \
    --url=/cef-source --checkout=a09c27de3f5bb45f4cfb8656a46d85d272e1587e \
    --branch=8037 --no-chromium-history --no-depot-tools-update --x64-build --no-build --no-distrib
  cd /build/work/chromium/src/cef
  uv run --no-project --python /usr/bin/python3 tools/gclient_hook.py
  cp ../out/Release_GN_x64/args.gn /build/artifacts/args.gn
  ;;
build)
  cd /build/work/chromium/src
  gn gen out/Release_GN_x64
  exec bash /cef-source/tools/wayland-build/historical/offline-build.sh
  ;;
*) echo 'Usage: build.sh prepare|build' >&2; exit 2 ;;
esac
