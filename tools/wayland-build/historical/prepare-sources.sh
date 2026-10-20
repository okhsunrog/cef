#!/usr/bin/env bash
set -Eeuo pipefail
export TMPDIR=/build/tmp
export GN_OUT_CONFIGS=Release_GN_x64
export GN_DEFINES='is_official_build=false is_component_build=false symbol_level=0 blink_symbol_level=0 v8_symbol_level=0 use_thin_lto=false chrome_pgo_phase=0 use_remoteexec=false use_siso=false ozone_platform_wayland=true ozone_platform_x11=true enable_vulkan=true'
mkdir -p "$TMPDIR" /build/artifacts
/opt/depot_tools/ensure_bootstrap
trap 'code=$?; printf "%s\n" "$code" > /build/preparation-exit-code' EXIT
cd /build
if ! test -d cef-source/.git; then
  git clone /bootstrap/cef-154.bundle cef-source
fi
git -C cef-source checkout --detach edaadb655607aea65355ab46605b235e0928de38
cat > work/chromium/.gclient <<'EOF'
solutions = [{
  'managed': False,
  'name': 'src',
  'url': 'https://chromium.googlesource.com/chromium/src.git@154.0.8037.98',
  'custom_vars': {'checkout_pgo_profiles': False, 'source_tarball': False, 'siso_version': 'latest'},
  'custom_deps': {},
  'deps_file': 'DEPS',
  'safesync_url': '',
}]
EOF
printf 'sync\n' > preparation-phase
cd /build/work/chromium
# Limit concurrency to avoid Google source hosting HTTP 429 responses.
gclient sync -j2 --nohooks --no-history
printf 'hooks\n' > /build/preparation-phase
uv run --no-project --python /usr/bin/python3 /build/cef-source/tools/patcher.py \
  --patch-file /build/cef-source/patch/patches/runhooks --patch-dir /build/work/chromium/src
gclient runhooks -j2
cd /build
uv run --no-project --python /usr/bin/python3 cef-source/tools/automate/automate-git.py \
  --download-dir=/build/work --depot-tools-dir=/opt/depot_tools \
  --url=/build/cef-source --checkout=edaadb655607aea65355ab46605b235e0928de38 \
  --branch=8037 --no-chromium-history --no-depot-tools-update --x64-build --no-build --no-distrib
printf 'configure\n' > /build/preparation-phase
cd /build/work/chromium/src/cef
uv run --no-project --python /usr/bin/python3 tools/gclient_hook.py
cp ../out/Release_GN_x64/args.gn /build/artifacts/args.gn
git rev-parse HEAD > /build/artifacts/cef-revision.txt
git -C .. rev-parse HEAD > /build/artifacts/chromium-revision.txt
git -C /opt/depot_tools rev-parse HEAD > /build/artifacts/depot-tools-revision.txt
printf '%s\n' "$GN_DEFINES" > /build/artifacts/gn-defines.txt
printf 'ready-for-offline-check\n' > /build/preparation-phase
