# CEF 154 Wayland build inputs

The maintained CEF changes are in this branch and `patch/patches`, registered in
`patch/patch.cfg`. Base Chromium is `b859317bf11f6be47f9b7799ec690a0a42a1fb33`
(tag `154.0.8037.98`); depot_tools is pinned in the Dockerfile.

`validated/` records the SDK actually built and tested. The runtime source commit
is `a09c27de3f5bb45f4cfb8656a46d85d272e1587e`; later build-tool commits do not
change the library. The original SDK label contains `Unknown` because the old
container Git ownership check failed. Exact source revisions and hashes take
precedence over that generated label.

`validated/chromium-applied.patch` is a complete snapshot of tracked Chromium
changes and the five new Wayland source files from the local prepared tree,
including standard upstream CEF patches. It can be applied to the pristine
Chromium revision above. **Do not apply it over a tree already patched by CEF.**
Chromium dependencies remain pinned by its DEPS and fetched with gclient.

## Prepare on a machine with fast downloads

From the CEF checkout, choose a persistent directory on a large disk:

```sh
export CEF_BUILD_ROOT=/path/to/persistent/cef-build
mkdir -p "$CEF_BUILD_ROOT"
docker build -t cef-builder:154-fixed tools/wayland-build/historical
docker run --rm --network=host \
  --mount "type=bind,src=$PWD,dst=/cef-source,readonly" \
  --mount "type=bind,src=$CEF_BUILD_ROOT,dst=/build" \
  cef-builder:154-fixed bash /cef-source/tools/wayland-build/build.sh prepare
```

The directory must be writable by the image's `ubuntu` user. Dependencies and
compiler downloads happen during preparation. Verify offline readiness with:

```sh
docker run --rm --network=none \
  --mount "type=bind,src=$PWD,dst=/cef-source,readonly" \
  --mount "type=bind,src=$CEF_BUILD_ROOT,dst=/build" \
  cef-builder:154-fixed bash /cef-source/tools/wayland-build/historical/offline-check.sh
```

## Compile and retain the cache

```sh
set -o pipefail
docker run --rm --network=none --shm-size=2g \
  --mount "type=bind,src=$PWD,dst=/cef-source,readonly" \
  --mount "type=bind,src=$CEF_BUILD_ROOT,dst=/build" \
  cef-builder:154-fixed bash /cef-source/tools/wayland-build/build.sh build \
  2>&1 | tee -a "$CEF_BUILD_ROOT/build.log"
```

Compilation uses `-j32`. Repeating `build` preserves `out/`, Ninja state and
objects. For edits, update the prepared CEF/Chromium tree deliberately; do not
rerun preparation or replay patches over an existing patched tree. Run GN after
build-file changes. The SDK and SHA256SUMS are written to `artifacts/`.
For this workload the provisioned builder had 32 vCPUs, 64 GiB RAM, 500 GB disk.

For offline transfer, archive the prepared persistent directory (excluding only
temporary files, preserving `.git`, DEPS, and downloaded toolchains), and use
`docker save` for the image. Compress both with `zstd`, verify SHA256 after
transfer, and keep the extracted build directory for incremental rebuilds.

`historical/` preserves the scripts used during the original local-download /
cloud-build workflow. Some deliberately reference the old absolute task paths,
initial CEF commit, systemd services and automatic **poweroff** timers. They are
an audit trail; the portable commands above are the new entry points and have
only received syntax/source checks, not a second complete Chromium build.
Cloud credentials, keys, resource state and lifecycle/deletion scripts are kept
outside Git. No VM or volume is deleted by these build entry points.

## Consumer repositories

- https://github.com/okhsunrog/tauri/tree/feat/cef-wayland
- https://github.com/okhsunrog/cef-rs/tree/feat/wayland-154
- https://github.com/okhsunrog/slint_realtime_plotting_experiments/tree/feat/tauri-cef-wayland

The consumer branch contains the Nix SDK package, WebGPU streaming benchmark,
and the original smoke app. SDK binaries and build caches are not Git content.
Archive SHA256: `90ae4e47589368b446fb0e2312ee0b7ea6120f0591d770f939234a3ed7731cb2`.
