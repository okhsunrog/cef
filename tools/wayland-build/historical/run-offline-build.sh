#!/usr/bin/env bash
set -uo pipefail
root=/home/okhsunrog/tmp_zfs/codex_tmp/cef-wayland-build
/opt/cef-docker/docker -H unix:///run/cef-docker.sock run --name cef-offline-build-3 \
  --network=none --shm-size=2g \
  --mount "type=bind,src=$root/offline-source,dst=/build" \
  cef-builder:154-fixed bash /build/offline-build.sh
result=$?
if ! test -f "$root/offline-source/exit-code"; then
  printf '%s\n' "$result" > "$root/offline-source/exit-code"
  date -u > "$root/offline-source/finished-at"
fi
# This guard runs on the VM and survives the laptop losing connectivity.
delay=10m
if [ "$result" -ne 0 ]; then delay=2m; fi
systemd-run --unit=cef-build-exit-poweroff --on-active="$delay" /usr/sbin/poweroff
exit "$result"
