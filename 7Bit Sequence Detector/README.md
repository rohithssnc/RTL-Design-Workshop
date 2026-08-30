# Sequence Detector — RTL to GLS Verification Report

*Pattern 0101111 detector — RTL simulation, synthesis, and gate-level verification*

## 1. Design Overview

The `sequence_detector` module is a synchronous Mealy FSM that detects the 7-bit pattern **0101111** on serial input `din`, asserting the registered output `detected` one clock cycle after the final bit of a match is sampled. The FSM supports overlapping matches.

## 2. RTL Simulation Results

| Item | Value |
|---|---|
| Clock period / frequency | 10 ns period (100 MHz), half-period = 5 ns |
| Reset | Asserted at t=0, held 2 clock cycles, released ~20 ns |
| First pattern occurrence | Bits 43–49 (starts bit 43, ends bit 49) |
| Total detections | 4 (matches FINAL_DETECTION_COUNT=4) |
| First `detected=1` event | 49th clock cycle after reset, t = 515 ns |

**Figure 1: RTL waveform** — `detected` pulses and `detection_count` stepping 0→1→2→3→4.

![alt text](<Screenshot 2026-08-29 104920.png>)

## 3. Synthesis Results

| Item | Value |
|---|---|
| Synthesis status | Successful — 0 problems (CHECK pass) |
| Sequential cells | 8 total (7x `$_DFF_P_` + 1x `$_SDFF_PP0_`) |
| Combinational cells | 18 total |
| Total cells | 26 |
| State encoding | 7 bits, one-hot (Yosys default `fsm_recode`) |

**Figure 2: `yosys stat` output** — cell counts and CHECK pass result.

![alt text](<Screenshot 2026-08-29 110527.png>)

**Figure 3: Post-synthesis schematic (`show` command)** — the `$_SDFF_PP0_` cell drives `detected`; seven `$_DFF_P_` cells form the one-hot state register.
![alt text](<Screenshot 2026-08-29 112114.png>)

**Note on state encoding:** This netlist uses one-hot encoding (7 flip-flops), not binary. With binary encoding, 3 bits would suffice since 2³ = 8 ≥ 7 states, with 1 unused code safely handled by the RTL's `default` case. One-hot instead uses 1 flip-flop per state, trading extra registers for simpler next-state logic.

## 4. Gate-Level Simulation (GLS) Verification

### First GLS detection

The first `detected` event in GLS occurs at the same point as RTL: the 49th post-reset clock cycle, at t = 515 ns. GLS was run as functional (zero-delay) simulation with no SDF timing back-annotation.

### RTL vs GLS — same sequence?

Yes. Both waveforms show 4 detection pulses at identical simulation times, with `detection_count` stepping 0→1→2→3→4 at matching points, driven by the same testbench stimulus.

### Timing difference

No timing difference is observed. GLS used zero-delay simulation of Yosys's generic cells with no SDF back-annotation, so no real gate propagation delay was modeled. A genuine timing skew would only appear with SDF-annotated GLS using a real standard-cell library.

**Figure 4: RTL vs GLS comparison** — top = GLS waveform, bottom = RTL waveform. `detected` and `detection_count` align exactly.

![alt text](<Screenshot 2026-08-29 115311.png>)

## 5. Final Conclusion

Yes — the synthesized implementation preserves the functional behavior of the RTL for this testbench. GLS reproduces the identical detection sequence as RTL: 4 detections of pattern 0101111, first occurring at the 49th clock cycle (t = 515 ns), with `detection_count` tracking identically in both runs (Figure 4). Combined with a clean synthesis CHECK pass (Figure 2) and a structurally consistent netlist (26 cells: 8 flip-flops + 18 combinational, Figure 3), this confirms synthesis correctly preserved RTL functionality despite re-encoding the FSM state from 3-bit binary to 7-bit one-hot.
