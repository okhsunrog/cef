# Opt-in FIFO constraints for native Wayland frame pacing

Experimental; virtual-session validation passed, physical presentation validation
is pending. The normal path is unchanged.

`wayland-fifo.patch` adds the staging FIFO v1 protocol to Chromium's Wayland
backend. `--wayland-fifo` binds an advertised `wp_fifo_manager_v1`. Each nonempty
root buffer commit waits for the previous FIFO barrier and sets the next one.
The per-surface FIFO object is destroyed before its wl_surface. Existing frame
callbacks remain the independent throttle for occluded surfaces or compositors
which ignore FIFO constraints. An unsupported compositor retains the existing
path. This is intended for desynchronized embedded CEF roots; FIFO constraints
are ignored on synchronized subsurfaces by protocol definition.

Protocol source is already present at
`third_party/wayland-protocols/src/staging/fifo/fifo-v1.xml` in pinned Chromium
`b859317bf11f6be47f9b7799ec690a0a42a1fb33`. The patch applies over the Wayland
embedding/reader tree; object-finalizer instrumentation is not a requirement.
The first candidate is built on the finalizer/presentation diagnostic SDK to
reuse its cache and actual Wayland presentation probes.

`fifo-source-provenance.json` records patch and source hashes. Baseline
`wayland_frame_manager.cc` in that file excludes the independent OnPresented
probe; the remote build checks its known instrumented hash before applying.

The experiment is motivated by actual compositor `discarded` notifications
remaining after consumed ArrayBuffer cleanup moved to a Worker. A discarded
frame reached native commit without a long browser-side delay. Toggling
`WaylandExternalBeginFrameSource` did not eliminate the notifications. FIFO is
therefore a hypothesis to test against the same candidate SDK with the switch
off, not a proven fix or a reason to disable synchronization.

Required checks: frame delivery and sequence integrity, hardware WebGPU/Vulkan
and compute, confirmed Wayland presentation intervals and discard correlation,
throughput/latency, fractional DPI, resize, minimize/restore and teardown.
No default, published release or normal SDK selection changes until verified.

## Results on 2026-10-21

Four 30-second off/on/on/off runs on an isolated KWin Wayland compositor
retained hardware WebGPU, compute correctness and a lossless 4 million
frames/second WebSocket stream. Native presentation gaps were 9/14/7/7;
the second run also had substantial background CPU activity. Every run had
zero compositor discards, so these tests cannot establish whether FIFO
prevents the discards seen previously on the physical desktop. There was no
consistent frame-pacing improvement.

Resize, 4/8/4 million frames/second stream restarts, minimize/restore, 125%
and 150% fractional scale and graceful teardown passed with FIFO enabled.
The candidate remains opt-in and is not selected by the normal SDK package.

Candidate archive SHA256:
`f6b999f494fc831ce8c3fbc4ec21234b1a176a46380434530f59d95a06c3ea7b`.
Original libcef SHA256:
`2888934ebf39aeb556b745b6e0feb86bcd11bc41be946d019a1757c4096c2f16`.
