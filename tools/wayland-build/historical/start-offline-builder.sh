#!/usr/bin/env bash
set -Eeuo pipefail
root=/home/okhsunrog/tmp_zfs/codex_tmp/cef-wayland-build
cd "$root/transfer"
sha256sum -c SHA256SUMS
sudo mkdir -p /opt/cef-docker
sudo tar -xzf docker-static.tgz --strip-components=1 -C /opt/cef-docker
sudo systemd-run --unit=cef-docker \
  --property=Environment=PATH=/opt/cef-docker:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  /opt/cef-docker/dockerd --iptables=false --bridge=none --ip-forward=false --ip-masq=false \
  --host=unix:///run/cef-docker.sock --data-root="$root/docker-data" \
  --exec-root=/run/cef-docker --pidfile=/run/cef-docker.pid
for attempt in $(seq 1 60); do
  if sudo /opt/cef-docker/docker -H unix:///run/cef-docker.sock info > /dev/null 2>&1; then break; fi
  sleep 1
done
zstd -dc cef-builder-154.tar.zst | sudo /opt/cef-docker/docker -H unix:///run/cef-docker.sock load
mkdir -p "$root/offline-source"
tar --zstd -xf cef-sources-154.tar.zst -C "$root/offline-source"
cp offline-build.sh "$root/offline-source/offline-build.sh"
rm -f "$root/offline-source/exit-code" "$root/offline-source/finished-at"
# Stop the VM if the laptop disconnects for the rest of the build and collection.
sudo systemd-run --unit=cef-emergency-poweroff --on-active=9h /usr/sbin/poweroff
sudo systemd-run --unit=cef-offline-build \
  --property="StandardOutput=append:$root/offline-source/build.log" \
  --property=StandardError=inherit \
  /opt/cef-docker/docker -H unix:///run/cef-docker.sock run --name cef-offline-build \
  --network=none --shm-size=2g \
  --mount "type=bind,src=$root/offline-source,dst=/build" \
  cef-builder:154-ready bash /build/offline-build.sh
