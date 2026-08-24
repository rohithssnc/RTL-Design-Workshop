# Day 4 — Gate-Level Simulation, Blocking vs Non-Blocking Assignments, and Synthesis-Simulation Mismatch

## Overview

This experiment introduces:

- Gate-Level Simulation (GLS)
- RTL vs GLS simulation
- Synthesis-simulation mismatch
- Incomplete sensitivity lists
- Blocking assignments
- Non-blocking assignments
- Yosys synthesis
- SDF-based timing simulation

The main objective is to understand how RTL coding practices affect simulation and synthesized hardware behavior.

## 1. Gate-Level Simulation

### What is Gate-Level Simulation?

Gate-Level Simulation (GLS) is the simulation of the synthesized gate-level netlist instead of the original RTL.

The synthesized design may contain:

- Multiplexers
- AND gates
- OR gates
- NOT gates
- Flip-flops
- Standard cells

GLS is used to check:

- Post-synthesis functionality
- RTL-to-netlist behavior
- Synthesis mismatches
- Standard-cell behavior
- Timing behavior when SDF is used

### GLS Flow

```
RTL Design
     ↓
RTL Simulation
     ↓
Synthesis
     ↓
Gate-Level Netlist
     ↓
Gate-Level Simulation
     ↓
Waveform Comparison
```
## 1. GLS (Gate Level Simulation) – Concepts

**Gate Level Simulation (GLS)** is the process of running the testbench not
against the RTL (behavioral) design, but against the **synthesized gate-level
netlist**, using the same testbench.

Why GLS is done:

- To verify that the **logical correctness** of the design is preserved after
  synthesis (netlist behaves the same as RTL).
- To verify **timing** of the design (only possible if the simulation is run
  with delay annotation, e.g., SDF).
- Netlist is logically equivalent to RTL, so the **same testbench** can be
  reused for both RTL simulation and GLS.

**GLS is run using the synthesized netlist as the design under test (DUT)
along with the gate-level (standard cell) models**, for example:

```bash
iverilog ../my_lib/verilog_model/primitives.v \
         ../my_lib/verilog_model/sky130_fd_sc_hd.v \
         ternary_operator_mux_net.v \
         tb_ternary_operator_mux.v
./a.out
gtkwave tb_ternary_operator_mux.vcd
```

- `primitives.v` and `sky130_fd_sc_hd.v` – Verilog behavioral models of the
  standard cells (from the SKY130 library) needed to simulate the gates used
  in the netlist.
- `ternary_operator_mux_net.v` – the **synthesized netlist** (output of
  Yosys), instead of the RTL file.
- `tb_ternary_operator_mux.v` – the **same testbench** used for RTL
  simulation.

![alt text](<Screenshot 2026-08-24 184103.png>)
> showing the `iverilog ... ternary_operator_mux_net.v tb_ternary_operator_mux.v`

---

## 2. Synthesis–Simulation Mismatch

A **synthesis-simulation mismatch** occurs when the RTL simulation waveform
and the GLS (netlist) simulation waveform **do not match** for the same
testbench/inputs.

Common causes of mismatch:

1. **Missing sensitivity list** in RTL (e.g., using `always @(sel)` instead of
   `always @(*)`), which the simulator interprets literally but the
   synthesizer treats as combinational logic sensitive to all inputs.
2. **Blocking vs. non-blocking assignment misuse** inside `always` blocks
   causing simulation mismatches due to ordering of statements.
3. Use of **non-synthesizable constructs** (e.g., delays `#5`, initial blocks
   with delays) that behave one way in simulation but are ignored by
   synthesis.

### Lab: `good_mux` (Ternary Operator MUX)

RTL code (`ternary_operator_mux.v`):

```verilog
module ternary_operator_mux (input i0, input i1, input sel, output y);
  assign y = sel ? i1 : i0;
endmodule
```

This is a clean, synthesizable 2:1 MUX described with a continuous
assignment and the ternary operator.

**Steps performed:**

1. RTL simulation using `iverilog` + `tb_ternary_operator_mux.v` → view in
   GTKWave.
2. Synthesize using **Yosys** with the SKY130 standard cell library.
3. View the synthesized gate-level schematic with `show` (Yosys → dot/xdot
   viewer). The design maps to a single `sky130_fd_sc_hd__mux2_1` cell.
4. Write out the gate-level netlist: `write_verilog -noattr ternary_operator_mux_net.v`.
5. Run **GLS**: simulate the netlist (`ternary_operator_mux_net.v`) with the
   same testbench and the SKY130 primitive/cell models.
6. Compare the RTL-simulation waveform and the GLS waveform — for `good_mux`
   they **match exactly**, confirming no synthesis-simulation mismatch.

---

## 3. Lab: `bad_mux` – Demonstrating a Synthesis-Simulation Mismatch

RTL code (`bad_mux.v`):

```verilog
module bad_mux (input i0, input i1, input sel, output reg y);
always @ (sel)
begin
  if (sel)
    y <= i1;
  else
    y <= i0;
end
endmodule
```

**Why this is "bad":**

- The sensitivity list only contains `sel` — it is **missing `i0` and `i1`**.
- In **RTL simulation**, the simulator only re-evaluates the `always` block
  when `sel` changes. So if `i0` or `i1` toggle while `sel` is constant, the
  output `y` does **not** update — this is exactly what the simulator
  executes, literally.
- After **synthesis**, however, the tool infers a plain combinational MUX
  (correctly sensitive to all three inputs, `i0`, `i1`, `sel`), because
  synthesis tools treat `always @(...)` blocks as intent for a combinational
  circuit and re-synthesize full combinational sensitivity regardless of the
  incomplete sensitivity list.
- Net result: **RTL simulation output ≠ GLS output** → classic
  synthesis-simulation mismatch caused by an incomplete/incorrect
  sensitivity list.

**Fix:** always use `always @ (*)` for combinational logic so the simulator
re-evaluates the block whenever *any* input changes.
![alt text](<Screenshot 2026-08-24 201635.png>)
> (side-by-side GTKWave windows comparing
> `tb_bad_mux.vcd` RTL sim vs GLS waveform for `i0`, `i1`, `sel`, `y`) here to
> visually show the mismatch — note how `y` glitches/differs between the
> functional (behavioral) run and the gate-level run.

---

## 4. Blocking and Non-Blocking Assignments — Caveats

### Recap: Blocking (`=`) vs Non-Blocking (`<=`)

| | Blocking (`=`) | Non-Blocking (`<=`) |
|---|---|---|
| Execution | Sequential, statement-by-statement, **immediately** updates the LHS before moving to the next line | All RHS values are evaluated first (at the start of the time step), then **all LHS updates happen together** at the end of the time step |
| Typical use | Combinational logic (`always @(*)`) | Sequential logic (`always @(posedge clk)`) |
| Danger | Wrong statement **order** in combinational blocks can create unintended sequential-like behavior / use of stale values | Improper use in combinational blocks can infer unwanted latches |

### Lab: `blocking_caveat`

RTL code (`blocking_caveat.v`):

```verilog
module blocking_caveat (input a, input b, input c, output reg d);
reg x;
always @ (*)
begin
  d = x & c;
  x = a | b;
end
endmodule
```

**The caveat:** Inside the `always @(*)` block, the statements are written in
the **wrong order** for blocking assignment semantics:

- Line 1: `d = x & c;` — uses the value of `x` **at that instant**.
- Line 2: `x = a | b;` — updates `x` *after* `d` has already been computed.

Because blocking assignments execute top-to-bottom immediately, `d` is
computed using the **previous (stale) value of `x`**, not the new value
computed from the current `a` and `b`. This creates behavior similar to a
**one-cycle-delayed / sequential circuit**, even though the block is meant to
be purely combinational.

- Yosys, however, synthesizes this into pure combinational logic (a single
  `sky130_fd_sc_hd__o21a_1` gate combining `a`, `b`, `c`), which
  **correctly and immediately** reflects `a`, `b`, `c` on `d` in the
  gate-level netlist.
- The **RTL simulation** (which honors statement order / stale `x`) and the
  **GLS** (pure combinational gate, no stale value) therefore **do not
  match** — this is a synthesis-simulation mismatch caused entirely by
  **wrong ordering of blocking statements**.

**Fix:** Reorder the statements so dependent signals are computed first:

```verilog
always @ (*)
begin
  x = a | b;
  d = x & c;
end
```

![alt text](<Screenshot 2026-08-24 203908.png>) 
![alt text](<Screenshot 2026-08-24 203341.png>) 
![alt text](<Screenshot 2026-08-24 203251.png>) 
![alt text](<Screenshot 2026-08-24 202911.png>) 
![alt text](<Screenshot 2026-08-24 202855.png>)
> 
> 
> **GTKWave comparison** of RTL
>    simulation vs GLS for `tb_blocking_caveat.vcd`, with the **mismatch
>    region circled/annotated** (`a`, `b`, `c`, `d` signals)  this is the
>    key screenshot that visually proves the synthesis-simulation mismatch
>    caused by the blocking-assignment ordering caveat.

---

## 5. Key Takeaways

1. **GLS** validates that a synthesized netlist is functionally (and
   optionally timing-) equivalent to the RTL, using the same testbench.
2. **Synthesis-simulation mismatches** typically arise from:
   - Missing/incomplete sensitivity lists (`bad_mux` example).
   - Incorrect statement ordering with blocking assignments in
     combinational always blocks (`blocking_caveat` example).
   - Use of non-synthesizable constructs.
3. **Best practices** to avoid mismatches:
   - Always use `always @ (*)` for combinational logic blocks.
   - Use **blocking (`=`)** assignments for combinational logic, and
     **non-blocking (`<=`)** assignments for sequential logic.
   - Be careful about the **order of blocking statements** — always compute
     "helper"/intermediate signals before the signals that depend on them.
   - Always run GLS after synthesis to catch these mismatches early.

