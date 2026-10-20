#!/usr/bin/env bash
set -Eeuo pipefail
root=/home/okhsunrog/tmp_zfs/codex_tmp/cef-wayland-build
source_root="$root/offline-source"
if systemctl is-active --quiet cef-offline-build.service; then
  echo 'Build is already running; refusing to interrupt it.' >&2; exit 1
fi
sudo systemctl stop 'cef-build-exit-poweroff*.timer' 'cef-emergency-poweroff*.timer' 2>/dev/null || true
sudo systemctl reset-failed cef-offline-build.service 2>/dev/null || true
if ! sudo /opt/cef-docker/docker -H unix:///run/cef-docker.sock info >/dev/null 2>&1; then
  sudo systemd-run --unit=cef-docker \
    --property=Environment=PATH=/opt/cef-docker:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    /opt/cef-docker/dockerd --iptables=false --bridge=none --ip-forward=false --ip-masq=false \
    --host=unix:///run/cef-docker.sock --data-root="$root/docker-data" \
    --exec-root=/run/cef-docker --pidfile=/run/cef-docker.pid
  for attempt in $(seq 1 60); do
    if sudo /opt/cef-docker/docker -H unix:///run/cef-docker.sock info >/dev/null 2>&1; then break; fi
    sleep 1
  done
fi
patch=${1:-}
if [ -n "$patch" ]; then
  # Patch paths are relative to CEF. Chromium patches must be applied separately
  # to chromium/src and validated there; never replay all patches over a live tree.
  git -C "$source_root/work/chromium/src/cef" apply --check "$patch"
  git -C "$source_root/work/chromium/src/cef" apply "$patch"
fi
stamp=$(date -u +%Y%m%dT%H%M%SZ)
for file in exit-code finished-at; do
  if test -f "$source_root/$file"; then mv "$source_root/$file" "$source_root/$file.$stamp"; fi
done
printf 'compile\n' | sudo tee "$source_root/phase" >/dev/null
# Do not delete out/, .ninja_log, object files, Docker layers or source dependencies.
sudo systemd-run --unit="cef-emergency-poweroff-$stamp" --on-active=8h /usr/sbin/poweroff
sudo systemd-run --unit=cef-offline-build \
  --property="StandardOutput=append:$source_root/build.log" --property=StandardError=inherit \
  /bin/bash "$root/run-incremental-build.sh"
