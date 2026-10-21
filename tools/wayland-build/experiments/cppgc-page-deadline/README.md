# Experimental per-page cppgc deadline

This optional V8 overlay checks the incremental sweeper deadline after each
page instead of every fourth page. Each space creates its own checker; the
original code can finish fewer than four pages without checking its deadline.
The nominal foreground task budget is 5 ms. A single page remains indivisible,
so this is not a hard 5 ms bound and does not address other renderer/GPU delays.
It does not change object lifetime or the CEF ABI.

Apply only to the recorded V8 revision and source hash in artifact-provenance.json,
after preparing the normal CEF/Chromium baseline and reader overlay. From the
Chromium source directory, with PATCH pointing to this directory's patch:

```sh
git -C v8 apply --check -p2 "$PATCH"
git -C v8 apply -p2 "$PATCH"
```

Rebuild incrementally in the existing out/Release_GN_x64 directory. Preserve
Ninja state and objects. On the retained 16-vCPU/32-GiB builder, -j8 compiled,
linked and packaged the candidate in 3m54s. The patch is deliberately not
registered in patch.cfg or included in the default SDK recipe.

Use the complete candidate SDK, including regenerated V8 snapshots and resources.
The API hash remains a15420be190a255a6479f26806ed67fd59e1eeae (API 999999).
Artifact hashes refer to the original SDK before Nix ELF patching. The Nix
patched candidate libcef SHA256 is
726c04d8cafab04b98ec966ce3231542ad3ce7e8f8c4702a52e67a7eb7793262.

Runtime evaluation is recorded separately in the consumer benchmark repository.
Compilation and ABI smoke checks alone do not establish a frame-pacing benefit.

A/B/B/A runtime samples (30 s, requested 4 Mframes/s WebSocket, hardware WebGPU
compute, GTK reader, identical executable) observed finalization maxima of
42.42 / 18.54 / 15.78 / 41.75 ms. Foreground cppgc task maxima were
43.61 / 18.97 / 16.12 / 42.72 ms. No stream gaps or JavaScript errors occurred.
The last baseline had the fewest RAF outliers, so overall smoothness is not
established and this overlay remains experimental. Full delivery rates, host
load, method and limitations are in the consumer report:
https://github.com/okhsunrog/slint_realtime_plotting_experiments/blob/feat/tauri-cef-wayland/tauri-webgpu/CPPGC_VALIDATION.md.
