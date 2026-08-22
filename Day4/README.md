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

## 2. RTL Simulation vs Gate-Level Simulation

### RTL Simulation

RTL simulation executes the original Verilog code.

It includes constructs such as:

- `always`
- `if`
- `case`
- Blocking assignments
- Non-blocking assignments
- Continuous assignments

### Gate-Level Simulation

Gate-Level Simulation executes the synthesized netlist containing gates and standard-cell models.

### Main Difference

RTL simulation verifies the behavior of the RTL description, while GLS verifies the behavior of the synthesized hardware structure.

## 3. Incomplete Sensitivity List

Consider the following RTL:

```verilog
module ternary_operator_mux (
    input i0,
    input i1,
    input sel,
    output reg y
);

always @(sel) begin
    if (sel)
        y = i1;
    else
        y = i0;
end

endmodule
```

The intended functionality is:

- `sel = 0` → `y = i0`
- `sel = 1` → `y = i1`

However, the sensitivity list contains only:

```
@(sel)
```

The inputs `i0` and `i1` are missing.

### Problem

The always block executes only when `sel` changes.

If `i0` changes while `sel` remains unchanged:

```
i0 changes
     ↓
sel does not change
     ↓
always block is not triggered
     ↓
y does not update
```

This can cause incorrect RTL simulation behavior.

### Correct Sensitivity List

Traditional Verilog:

```verilog
always @(i0 or i1 or sel)
```

Preferred Verilog:

```verilog
always @(*)
```

SystemVerilog:

```verilog
always_comb
```

For combinational logic, `always @(*)` is preferred when using Verilog.

## 4. Practical Sensitivity-List Experiment

### Testbench

```verilog
`timescale 1ns / 1ps

module tb_ternary_operator_mux;

reg i0, i1, sel;
wire y;

ternary_operator_mux uut (
    .i0(i0),
    .i1(i1),
    .sel(sel),
    .y(y)
);

initial begin

    $dumpfile("tb_ternary_operator_mux.vcd");
    $dumpvars(0, tb_ternary_operator_mux);

    sel = 0;
    i0 = 0;
    i1 = 0;
    #10;

    i0 = 1;
    #10;

    sel = 1;
    #10;

    i1 = 1;
    #10;

    $finish;

end

endmodule
```

### Simulation

```bash
iverilog ternary_operator_mux.v tb_ternary_operator_mux.v -o rtl_mux.out
./rtl_mux.out
gtkwave tb_ternary_operator_mux.vcd
```

## 5. Synthesis Using Yosys

The RTL can be synthesized using Yosys.

```
yosys

read_liberty -lib ../my_lib/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog ternary_operator_mux.v

synth -top ternary_operator_mux

abc -liberty ../my_lib/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

write_verilog -noattr ternary_operator_mux_netlist.v

exit
```

The synthesized design represents the hardware structure generated from the RTL.

Conceptually:

```
           +-------+
i0 ------->|       |
i1 ------->|  MUX  |------> y
sel ------>|       |
           +-------+
```

## 6. Gate-Level Simulation

The synthesized netlist can be simulated using the standard-cell Verilog models.

### Compile

```bash
iverilog \
../my_lib/verilog_model/primitives.v \
../my_lib/verilog_model/sky130_fd_sc_hd.v \
ternary_operator_mux_netlist.v \
tb_ternary_operator_mux.v \
-o gls_mux.out
```

### Run

```bash
./gls_mux.out
```

### View Waveform

```bash
gtkwave tb_ternary_operator_mux.vcd
```

The RTL and GLS waveforms can then be compared.

## 7. Blocking Assignment Execution Order

Blocking assignment uses:

```
=
```

Consider:

```verilog
module blocking_caveat (
    input a,
    input b,
    input c,
    output reg d
);

reg x;

always @(*) begin
    d = x & c;
    x = a | b;
end

endmodule
```

The simulator executes the statements sequentially.

First:

```verilog
d = x & c;
```

Then:

```verilog
x = a | b;
```

Therefore, `d` uses the previous value of `x`.

The intended data flow is:

```
x = a | b
d = x & c
```

which is equivalent to:

```
d = (a | b) & c
```

## 8. Correct Blocking Assignment Order

A safer implementation is:

```verilog
always @(*) begin
    x = a | b;
    d = x & c;
end
```

The data flow becomes:

```
a,b
 ↓
OR
 ↓
x
 ↓
AND ← c
 ↓
d
```

Another option is continuous assignment.
