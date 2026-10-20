#!/usr/bin/env bash
set -Eeuo pipefail
root=/home/okhsunrog/tmp_zfs/codex_tmp/cef-wayland-build
cd "$root"
sudo systemd-run --unit=cef-docker \
  --property=Environment=PATH=/opt/cef-docker:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  /opt/cef-docker/dockerd --iptables=false --bridge=none --ip-forward=false --ip-masq=false \
  --host=unix:///run/cef-docker.sock --data-root="$root/docker-data" \
  --exec-root=/run/cef-docker --pidfile=/run/cef-docker.pid
for attempt in $(seq 1 60); do
  if sudo /opt/cef-docker/docker -H unix:///run/cef-docker.sock info > /dev/null 2>&1; then break; fi
  sleep 1
done
docker=(sudo /opt/cef-docker/docker -H unix:///run/cef-docker.sock)
"${docker[@]}" run -d --name cef-dependency-fix --network=none --user root cef-builder:154-ready sleep infinity
"${docker[@]}" cp fix-packages/. cef-dependency-fix:/build/
"${docker[@]}" exec cef-dependency-fix bash -c 'dpkg -i /build/libx11-xcb-dev_*.deb && test -f /usr/include/X11/Xlib-xcb.h && pkg-config --modversion x11-xcb'
"${docker[@]}" commit cef-dependency-fix cef-builder:154-fixed
"${docker[@]}" stop cef-dependency-fix
"${docker[@]}" rm cef-dependency-fix
cp offline-source/exit-code offline-source/first-build-exit-code
cp offline-source/finished-at offline-source/first-build-finished-at
cp offline-source/build.log offline-source/first-build.log
rm offline-source/exit-code offline-source/finished-at
sudo systemd-run --unit=cef-emergency-poweroff --on-active=8h /usr/sbin/poweroff
sudo systemd-run --unit=cef-offline-build \
  --property="StandardOutput=append:$root/offline-source/build.log" \
  --property=StandardError=inherit \
  /bin/bash "$root/run-offline-build.sh"
