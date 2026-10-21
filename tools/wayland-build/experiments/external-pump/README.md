# CEF external message pump experiments

Two independent changes to `libcef/browser/browser_message_loop.cc`. Apply
`next-deadline.patch` first and `pump-yield.patch` second from the CEF root.
These files preserve the exact source patches used for the candidate builds.
They are not applied to the normal SDK by this documentation commit.

The first patch forwards a finite `Delegate::DoWork()` deadline when the
external pump yields after its time slice. Chromium's delegate returns that
deadline directly to the pump; it need not also call `ScheduleDelayedWork()`.
Only an actual finite delayed task is forwarded. The synthetic timestamp used
by the existing loop when no delayed task exists must not become an immediate
rescheduling request. Remaining delays round up to milliseconds.

The second patch adds the opt-in `--external-pump-yield` switch. Once no
immediate work remains, the pump returns control to the host instead of
spinning until the 10 ms slice ends. It preserves the finite deadline, and
requests an immediate continuation if immediate work exhausts the slice.
The existing no-task `DoIdleWork()` call remains in place. With the switch
absent, behavior matches the first candidate.

Periodic host pumping is still required. These changes do not announce every
kind of native work and do not guarantee rendering at any frame rate.

## Evidence, 2026-10-21

All timing comparisons use one immutable application binary, a 4 million
frames/second bounded WebSocket stream, Worker buffer reclamation, hardware
WebGPU with passing compute checks, a 33 ms host fallback and an isolated
KWin Wayland compositor. The GTK reader and Wayland frame source are enabled;
FIFO and per-object finalizer tracing are disabled. Each sample lasts 30 s
following warmup. Native presentation feedback is measured separately from RAF.

| Candidate sequence | Native intervals over 25 ms | App CPU, cores |
| --- | --- | --- |
| Original pump | 5 | 1.002 |
| Finite deadline | 1 | 1.044 |
| Finite deadline | 1 | 0.984 |
| Original pump | 7 | 1.050 |

The host remained relatively quiet (sample maximum aggregate CPU 12–14%).
The finite-deadline candidate reduced misses in this sequence but did not
eliminate them. This is partial evidence, not a physical-display result.

The yield switch comparison uses the same second SDK with only its switch
changed:

| Switch sequence | RAF intervals over 25 ms | Native intervals over 25 ms | App CPU, cores |
| --- | --- | --- | --- |
| Off | 3 | 2 | 1.025 |
| On | 2 | 3 | 0.951 |
| On | 0 | 0 | 0.964 |
| Off | 1 | 1 | 1.021 |

It reduced CPU use by roughly 6% in this pair, without a demonstrated
presentation advantage. A separate scoped scheduler trace confirms the
mechanism: the longest uninterrupted UI running slice was 10.273 ms with the
switch off and 1.518 ms with it on. Maximum runnable waits were below 0.2 ms.
Tracer setup/dump are excluded from the recorded intervals and these diagnostic
runs are not ranked as performance samples.

Resize, 4/8/4 million frames/second restarts, minimize/restore, fractional scales
125%/150%/100%, canvas dimensions, compute correctness, sequence integrity and
graceful close passed with the yield switch enabled. The physical desktop was
locked, so physical presentation/discard acceptance remains pending. The FIFO
experiment separately documents why a virtual compositor cannot establish a
reduction of physical compositor discards.

`artifact-provenance.json` records original library/archive and source hashes.
SDKs share the earlier reader, cppgc and presentation diagnostic build cache;
these independent Chromium/V8 patches are retained in the sibling experiment
directories. No full Chromium rebuild is needed to iterate this one CEF source
file. Do not treat the diagnostic SDK as a default or stable release.
