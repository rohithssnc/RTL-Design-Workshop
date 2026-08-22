# Day 3 — Combinational and Sequential RTL Optimizations

## Overview

Day 3 focuses on the optimization of RTL designs using Yosys. The module covers both combinational and sequential optimization techniques and demonstrates how synthesis tools identify redundant logic, propagate constants, simplify Boolean expressions, and remove hardware that does not contribute to the required outputs.

The experiments use the SKY130 standard-cell library to observe how optimized RTL can be transformed into technology-specific hardware.

---

## 1. Introduction to RTL Optimization

RTL optimization is the process of improving a hardware description while preserving its intended functionality. The synthesis tool analyzes the RTL and identifies opportunities to reduce unnecessary hardware.

**Main Objectives of Optimization**

- Reduce hardware area
- Remove redundant logic
- Simplify Boolean expressions
- Eliminate unused registers
- Reduce circuit complexity
- Improve power efficiency
- Enable efficient technology mapping

---

## 2. Yosys Optimization Setup

```bash
yosys
read_liberty -lib ../lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog <design_name>.v
synth -top <module_name>
opt_clean -purge
dfflibmap -liberty ../lib/sky130_fd_sc_hd__tt_025C_1v80.lib
abc -liberty ../lib/sky130_fd_sc_hd__tt_025C_1v80.lib
show
```

---

## 3. Combinational Logic Optimizations

### Example 1 — Constant Propagation (`opt_check`)

```verilog
module opt_check (
    input a,
    input b,
    output y
);

assign y = a ? b : 1'b0;

endmodule
```

`a ? b : 1'b0` is equivalent to `y = a & b`. The synthesized schematic below confirms this: a single `sky130_fd_sc_hd__and2_0` cell with `a` and `b` feeding it directly.

### Example 2 — Hardwired Constant Optimization (`opt_check2`)

```verilog
module opt_check2 (
    input a,
    input b,
    output y
);

assign y = a ? 1'b1 : b;

endmodule
```

`a ? 1'b1 : b` is equivalent to `y = a | b`. The schematic shows exactly that: a single `sky130_fd_sc_hd__or2_0` cell.

### Example 3 — Redundant Multiplexer Optimization (`opt_check3`)

```verilog
module opt_check3 (
    input a,
    input b,
    input c,
    output y
);

assign y = a ? (c ? 1'b1 : b) : 1'b0;

endmodule
```

The nested conditional was expected to reduce to `y = a & (c | b)`. What Yosys actually produced for this design was a single three-input `sky130_fd_sc_hd__and3_1` cell driven directly by `a`, `b`, and `c` — a further logic-minimization step beyond the OR/AND split, collapsing the whole expression into one gate.

### Example 4 — Multi-bit Logic Optimization (`opt_check4`)

```verilog
module opt_check4 (
    input a,
    input b,
    input c,
    output y
);

assign y = a ? (b ? (c ? 1'b1 : 1'b0) : 1'b0) : 1'b0;

endmodule
```

The captured schematic for `opt_check4` shows a `sky130_fd_sc_hd__xnor2_1` cell driven by `a` and `c`, with `b` appearing as a separate, disconnected node (`$b`) off to the side. This is a different final mapping than the simple three-input AND one might expect from the nested-ternary RTL above — worth double-checking against the exact RTL that was actually synthesized for this run if the mismatch matters for your writeup.

---

## 4. Sequential Logic Optimizations

### Example 1 — Constant D-Input Flip-Flop (`dff_const1`)

```verilog
module dff_const1 (
    input clk,
    input reset,
    output reg q
);

always @(posedge clk or posedge reset)
begin
    if (reset)
        q <= 1'b0;
    else
        q <= 1'b1;
end

endmodule
```

Because `q` depends on `reset`, the flip-flop cannot be replaced by a constant — a real sequential cell is required. The waveform confirms `q` stays at 0 while `reset = 1`, as expected.

### Example 2 — Flip-Flop Permanently Tied to a Constant (`dff_const2`)

```verilog
module dff_const2 (
    input clk,
    input reset,
    output reg q
);

always @(posedge clk or posedge reset)
begin
    if (reset)
        q <= 1'b1;
    else
        q <= 1'b1;
end

endmodule
```

Both branches assign `1`, so `q` is always `1` regardless of `reset`. The waveform shows exactly that: `q = 1` holds continuously even while `reset` toggles.

### Example 3 — Multi-Flop Constant Chain (`dff_const3`)

```verilog
module dff_const3 (
    input clk,
    input reset,
    output reg q
);

reg q1;

always @(posedge clk or posedge reset)
begin
    if (reset) begin
        q  <= 1'b0;
        q1 <= 1'b0;
    end
    else begin
        q1 <= 1'b1;
        q  <= q1;
    end
end

endmodule
```

The waveform shows the one-cycle propagation delay this design is meant to demonstrate: `q1` rises to 1 first, and `q` follows one clock cycle later, tracking `q1`'s previous value.

---

## 5. Sequential Optimization for Unused Outputs (`counter_opt`)

```verilog
module counter_opt (
    input clk,
    input reset,
    output q
);

reg [2:0] count;

assign q = count[0];

always @(posedge clk or posedge reset)
begin
    if (reset)
        count <= 3'b000;
    else
        count <= count + 1;
end

endmodule
```

The captured schematic shows the full, non-reduced counter_opt structure: three `$_DFF_PP0_` flip-flops (one per count bit) built from NOR, AND2, NAND2, NAND3, and a clock-inverter gate, with `q` tapped from bit 0 through a buffer. This view captures the counter *before* the unused-bit optimization is applied — useful as a "before" reference to compare against the reduced single-flip-flop version once `count[1]` and `count[2]` are trimmed away as unobservable.

---
