# cppgc object finalization and Wayland presentation diagnostics

Optional diagnostic overlays on the per-page deadline candidate. The normal
CEF patch.cfg and SDK recipe are unchanged. The preceding reader and deadline
patches must already be applied. Base revisions and exact source hashes are in
artifact-provenance.json.

- `finalizer-profile.patch`: traces each actual cppgc finalizer callback with
  its object type and GCInfo index, plus enclosing page-finalization scopes.
  Resolve names before destruction. Object tracing requires the process env
  `WAVEBENCH_CPPGC_FINALIZERS=1`, Perfetto support, and the existing
  `disabled-by-default-cppgc` category. No heap-path file I/O is added.
- `presentation-feedback.patch`: records raw and sanitized feedback flags,
  timestamp, display trace ID and refresh interval at Viz.
- `wayland-presented.patch`: records `wp_presentation_feedback.presented`
  directly, with its converted presentation timestamp and Wayland flags.
  Chromium can fabricate feedback, so the Viz event alone is insufficient to
  establish that an actual Wayland presentation callback occurred.

From the Chromium source root, with PATCHDIR pointing here:

```sh
git -C v8 apply --check -p2 "$PATCHDIR/finalizer-profile.patch"
git -C v8 apply -p2 "$PATCHDIR/finalizer-profile.patch"
git apply --check "$PATCHDIR/presentation-feedback.patch"
git apply "$PATCHDIR/presentation-feedback.patch"
git apply --check "$PATCHDIR/wayland-presented.patch"
git apply "$PATCHDIR/wayland-presented.patch"
```

Build incrementally while retaining out/ and Ninja state. Use the complete SDK
with matching V8 snapshots/resources. API 999999 remains unchanged. These
patches do not enforce a GC deadline or change object lifetime.

Object tracing introduces observer overhead and can affect GC cadence. It is
for attribution, not a clean SDK benchmark. Collect a control with object
tracing disabled. Counts represent finalized objects, not an allocation census.
Some native classes may have hidden names; GCInfo indices are local to a
process and must not be treated as stable type IDs across runs.

The Wayland callback is compositor feedback. In virtual KWin it does not
establish physical display scanout. Trace capture must use a common clock,
keep raw timestamps, and distinguish feedback arrival from presentation time.

## Runtime findings

In the video-paused physical-display object profile, ArrayBuffer finalizer
scopes account for 220.83/293.92 ms (75.1%), versus 37.71 ms for all GPU-named
types together. This is inclusive wall-time attribution with observer overhead.
The flanking controls, with object scopes disabled, have longest cppgc unions
of 12.39 and 11.39 ms. RAF alone misses residual presentation irregularity.

An additional ten-second run enables the existing `wayland` category. Five of
599 feedback frames fail, all five matching StoreFeedback(flags=16) inside
HandleFeedback(discarded=true), proving actual protocol discard notifications
rather than internal fallback failures in that sample. It has 600 steady RAF
callbacks and six gaps near 33 ms between confirmed presentations. This does
not establish a compositor bug or identify the exact pacing/fence cause.

Full conditions, exploratory-load caveats, fractional scaling, repeat tables
and reproducible Python analysis:
https://github.com/okhsunrog/slint_realtime_plotting_experiments/blob/feat/tauri-cef-wayland/tauri-webgpu/FINALIZER_PRESENTATION_VALIDATION.md.
