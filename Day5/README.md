# Day 5 – Incomplete If/Case Statements, Latch Inference, For-Loops and For-Generate

---

## 1. Incomplete `if` Statement → Inferred Latch

### Lab: `incomp_if`

```verilog
module incomp_if (input i0, input i1, input i2, output reg y);
always @ (*)
begin
  if (i0)
    y <= i1;
end
endmodule
```

This `if` statement has **no `else` branch**. When `i0 = 0`, no assignment is
made to `y` inside the `always` block. Since this is a combinational block
(`always @(*)`), the tool must "hold" the previous value of `y` when the
condition is false — the only way hardware can do this is by inferring a
**latch** (a `D_LATCH` with `E` = enable = `i0`, `D` = `i1`).

- Yosys synthesizes this into a `$_DLATCH_P_` cell: `D = i1`, `E = i0`,
  `Q = y`.
- This is generally **unintentional / undesirable** in combinational design —
  it creates extra sequential elements, timing/glitch issues, and can cause
  synthesis-simulation mismatches.

![alt text](<Screenshot 2026-08-24 221159.png>) 
![alt text](<Screenshot 2026-08-24 221421.png>)

**Fix:** always add a complete `else` (or default) branch so every input
combination produces a defined, combinational output.

---

## 2. Incomplete Nested `if` Statement → Inferred Latch

### Lab: `incomp_if2`

```verilog
module incomp_if2 (input i0, input i1, input i2, input i3, output reg y);
always @ (*)
begin
  if (i0)
    y <= i1;
  else if (i2)
    y <= i3;
end
endmodule
```

Here there is an `else if` but still **no final `else`** — so when
`i0 = 0` and `i2 = 0`, `y` is left unassigned for that path, and a latch is
again inferred to hold the last value.

- Yosys maps this to a MUX (`sky130_fd_sc_hd__mux2_1`) and a NOR gate
  feeding into a `$_DLATCH_N_` cell (enable = combination of `i0`, `i2`).

![alt text](<Screenshot 2026-08-24 222009.png>) 
![alt text](<Screenshot 2026-08-24 222133.png>) 

**Fix:** add a final `else` branch to cover all remaining conditions.

---

## 3. Incomplete `case` Statement → Inferred Latch

### Lab: `comp_case` vs `incomp_case`

**Complete case (`comp_case`)** — covers all 4 combinations of a 2-bit
select:

```verilog
module comp_case (input i0, input i1, input i2, input [1:0] sel, output reg y);
always @ (*)
begin
  case(sel)
    2'b00 : y = i0;
    2'b01 : y = i1;
    default : y = i2;
  endcase
end
endmodule
```

**Incomplete case (`incomp_case`)** — only handles two of the four possible
`sel` values, with no `default`:

```verilog
module incomp_case (input i0, input i1, input i2, input [1:0] sel, output reg y);
always @ (*)
begin
  case(sel)
    2'b00 : y = i0;
    2'b01 : y = i1;
  endcase
end
endmodule
```

Just like the incomplete `if`, when `sel = 2'b10` or `2'b11`, `y` is left
undriven for that combinational block → a **latch** is inferred to hold the
last driven value.

- `comp_case` synthesizes into pure combinational logic (NAND/mux/OAI gates,
  **no latch**).
- `incomp_case` synthesizes with a `$_DLATCH_N_` cell (enable derived from
  `sel`).
 
![alt text](<Screenshot 2026-08-24 223651.png>) 
![alt text](<Screenshot 2026-08-24 223543.png>) 
![alt text](<Screenshot 2026-08-24 223302.png>) 
![alt text](<Screenshot 2026-08-24 223140.png>)
**Fix:** always add a `default` case so every possible value of the select
line drives the output.

---

## 4. Overlapping / Bad `case` Statement → Synthesis-Simulation Mismatch

### Lab: `bad_case`

```verilog
module bad_case (input i0, input i1, input i2, input i3, input [1:0] sel, output reg y);
always @ (*)
begin
  case(sel)
    2'b00 : y = i0;
    2'b01 : y = i1;
    2'b10 : y = i2;
    2'b1?  : y = i3;   // partial/overlapping bit pattern
  endcase
end
endmodule
```

Using a **don't-care (`?`) or overlapping case item** (`2'b1?` overlapping
with `2'b10`) causes ambiguous case-item matching:

- In **RTL simulation**, the simulator evaluates case items top-to-bottom
  and picks the *first* match, so behavior may not be what's intended for
  overlapping bit patterns.
- After **synthesis**, Yosys treats this as a straightforward 4:1 MUX
  (`sky130_fd_sc_hd__mux4_2`) based on the truth table it derives, which can
  behave differently from the simulator's first-match interpretation.
- This mismatch between RTL sim (case semantics honored literally) and GLS
  (netlist behaves per synthesized truth table) is a classic
  **synthesis-simulation mismatch** caused by overlapping/bad case coding.

![alt text](<Screenshot 2026-08-24 225020-1.png>)
![alt text](<Screenshot 2026-08-24 224909.png>)

**Fix:** avoid don't-cares/overlapping patterns in `case` items; ensure each
case item is mutually exclusive and the full range of the select is covered
(with a `default`).

---

## 5. `for` Loop inside `always` Block

### Lab: `mux_generate` (4:1 MUX using a `for` loop)

```verilog
module mux_generate (input i0, input i1, input i2, input i3, input [1:0] sel, output reg y);
wire [3:0] i_int;
assign i_int = {i3, i2, i1, i0};
integer k;
always @ (*)
begin
  for (k = 0; k < 4; k = k+1) begin
    if (k == sel)
      y = i_int[k];
  end
end
endmodule
```

A `for` loop inside an `always` block is a **procedural loop** — it is fully
unrolled at synthesis/elaboration time (not a hardware "loop" that executes
over time). Here it is used to select one of 4 inputs based on `sel`,
functionally equivalent to a 4:1 MUX. This is a compact way to write
selection/decode logic without writing out every case item by hand.

![alt text](<Screenshot 2026-08-24 225623.png>)
---

## 6. `for-generate` vs `case` for Demux Design

### Lab: `demux_case` (case-based 1:8 demux)

```verilog
module demux_case (output o0, output o1, output o2, output o3,
                    output o4, output o5, output o6, output o7,
                    input [2:0] sel, input i);
reg [7:0] y_int;
assign {o7,o6,o5,o4,o3,o2,o1,o0} = y_int;
integer k;
always @ (*)
begin
  y_int = 8'b0;
  case(sel)
    3'b000 : y_int[0] = i;
    3'b001 : y_int[1] = i;
    3'b010 : y_int[2] = i;
    3'b011 : y_int[3] = i;
    3'b100 : y_int[4] = i;
    3'b101 : y_int[5] = i;
    3'b110 : y_int[6] = i;
    3'b111 : y_int[7] = i;
  endcase
end
endmodule
```

### Lab: `demux_generate` (for-loop based 1:8 demux)

```verilog
module demux_generate (output o0, output o1, output o2, output o3,
                        output o4, output o5, output o6, output o7,
                        input [2:0] sel, input i);
reg [7:0] y_int;
assign {o7,o6,o5,o4,o3,o2,o1,o0} = y_int;
integer k;
always @ (*)
begin
  y_int = 8'b0;
  for (k = 0; k < 8; k = k+1) begin
    if (k == sel)
      y_int[k] = i;
  end
end
endmodule
```
![alt text](<Screenshot 2026-08-24 231335-1.png>)
![alt text](<Screenshot 2026-08-24 230504.png>)

Both describe the exact same **1-to-8 demultiplexer** — one written the
long way with a fully-enumerated `case`, and the other written compactly
with a `for` loop. Both:

- Default `y_int` to all-zero (`8'b0`) first, so every case/loop iteration
  that doesn't match `sel` leaves that output bit safely at `0` — avoiding
  the incomplete-case latch problem seen in Sections 2–3.
- Route input `i` to exactly one of the 8 outputs based on `sel`, and
  produce **identical waveforms** in simulation, since they are functionally
  equivalent descriptions.

The `for`-loop version is much shorter and easier to scale (e.g. to a
1:16 or 1:32 demux) without manually writing every case item.

![alt text](<Screenshot 2026-08-24 231335.png>)
---

## 7. `for-generate` for Structural Module Instantiation — Ripple Carry Adder (RCA)

Unlike the procedural `for` loop used inside an `always` block (Sections 5–6,
which describes *behavioral* logic that gets unrolled), a `generate for`
loop is used **outside** any `always` block to structurally **instantiate
multiple copies of a module** — this is true hardware replication, not just
unrolled behavioral code.

### Full Adder (`fa`) — base building block

```verilog
module fa (input a, input b, input c, output co, output sum);
  assign {co, sum} = a + b + c;
endmodule
```

### 8-bit Ripple Carry Adder (`rca`) using `generate for`

```verilog
module rca (input [7:0] num1, input [7:0] num2, output [8:0] sum);
wire [7:0] int_sum;
wire [7:0] int_co;

genvar i;
generate
  for (i = 1; i < 8; i = i+1) begin
    fa u_fa_1 (.a(num1[i]), .b(num2[i]), .c(int_co[i-1]), .co(int_co[i]), .sum(int_sum[i]));
  end
endgenerate

fa u_fa_0 (.a(num1[0]), .b(num2[0]), .c(1'b0), .co(int_co[0]), .sum(int_sum[0]));

assign sum[7:0] = int_sum;
assign sum[8]   = int_co[7];
endmodule
```

How it works:

- `u_fa_0` is instantiated **separately** (outside the generate block) to
  handle bit 0, with the carry-in tied to `1'b0` (no incoming carry for the
  LSB).
- The `genvar i; generate for (i = 1; i < 8; i = i+1) ... endgenerate` block
  **structurally instantiates 7 more full-adder instances** (`u_fa_1`
  through the 7th), each wired so that `int_co[i-1]` (the carry-out of the
  previous stage) feeds into `c` of the next stage — this is the classic
  **ripple-carry** chaining, built automatically instead of writing out
  8 instances by hand.
- The final carry-out (`int_co[7]`) becomes the MSB of the 9-bit `sum`
  output.
- `genvar` is a synthesis-time-only loop variable (not a hardware signal),
  required for `generate for` loops, distinct from the `integer` used in a
  procedural `for` loop.

**Simulation:**

```bash
sudo iverilog fa.v rca.v tb_rca.v
./a.out
gtkwave tb_rca.vcd
```

The testbench drives `num1`, `num2` and observes `sum_out[8:0]`; the
waveform confirms `sum_out = num1 + num2` for every stimulus pair (e.g.
`num1 = 133`, `num2 = 24` → `sum_out = 157`), validating that the
`generate`-instantiated ripple-carry chain adds correctly.

![alt text](<Screenshot 2026-08-24 233703.png>)

---

## 8. Key Takeaways

1. **Incomplete `if`/`case` statements** in combinational (`always @(*)`)
   blocks cause the synthesis tool to infer **latches**, because the output
   must "hold" its value for uncovered input conditions — always add a
   final `else` or `default`.
2. **Overlapping or don't-care case items** (e.g. `2'b1?`) can cause
   **synthesis-simulation mismatches**, since simulation honors first-match
   case-item order while the synthesized netlist follows the derived truth
   table — keep case items mutually exclusive and fully covered.
3. **`for` loops** inside `always` blocks are unrolled at
   elaboration/synthesis time and are a concise way to describe repetitive
   MUX/DEMUX-style selection logic — they don't create actual hardware
   loops.
4. **`case`-based and `for`-loop-based** descriptions of the same logic
   (e.g. demux) are functionally equivalent and produce identical
   simulation waveforms; the loop form scales better for wide
   selectors/decoders.
5. **`generate for` loops** (with `genvar`) are used outside `always` blocks
   to structurally **instantiate multiple hardware module copies** (e.g.
   chaining full adders into a ripple-carry adder) — this is fundamentally
   different from a procedural `for` loop inside an `always` block, which
   only describes unrolled combinational behavior within a single module.
