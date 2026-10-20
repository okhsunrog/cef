#!/usr/bin/env bash
set -uo pipefail
root=/home/okhsunrog/tmp_zfs/codex_tmp/cef-wayland-build
stamp=$(date -u +%Y%m%dT%H%M%SZ)
/opt/cef-docker/docker -H unix:///run/cef-docker.sock run --name "cef-incremental-$stamp" \
  --network=none --shm-size=2g \
  --mount "type=bind,src=$root/offline-source,dst=/build" \
  cef-builder:154-fixed bash -c '
    set -Eeuo pipefail
    cd /build/work/chromium/src/cef
    uv run --no-project --python /usr/bin/python3 tools/version_manager.py -u --fast-check
    cd ..
    gn gen out/Release_GN_x64
    exec bash /build/offline-build.sh
  '
result=$?
if ! test -f "$root/offline-source/exit-code"; then
  printf '%s\n' "$result" > "$root/offline-source/exit-code"
  date -u > "$root/offline-source/finished-at"
fi
delay=45m
if [ "$result" -ne 0 ]; then delay=2m; fi
systemd-run --unit="cef-build-exit-poweroff-$stamp" --on-active="$delay" /usr/sbin/poweroff
exit "$result"
