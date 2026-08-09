# RTL-Design-Workshop
RTL Design, Simulation, and Synthesis Workshop

_Day 1 and Day 2 Report - Verilog RTL to SKY130 Gate-Level Netlist_

_Figures below are the actual workshop screenshots captured for each step. Two steps (the multiply-by-8 netlist and the flattened netlist) have no corresponding screenshot and are marked accordingly._

# Day 1 - Exploring Verilog RTL Design Through Simulation and Synthesis

## Overview

The objective of this experiment was to understand the fundamentals of Register Transfer Level (RTL) design using Verilog. The experiment focused on understanding the roles of a design, testbench, and simulator, followed by compiling and simulating a Verilog design using Icarus Verilog (iverilog). The simulated output was verified using GTKWave, and the RTL design was subsequently synthesized using Yosys to observe its corresponding gate-level netlist.

A 2-to-1 Multiplexer was implemented as the practical RTL design for this experiment. The complete process provided an introduction to the RTL-to-netlist workflow used in digital IC design.

## 1\. RTL Verification Fundamentals

### Simulator

A simulator is a software application used to execute a digital design in a virtual environment and observe its behavior without physically implementing the circuit. It allows different input conditions to be applied to the design and helps verify whether the outputs behave as expected. In this experiment, Icarus Verilog was used as the simulator.

### Design

The design is the Verilog RTL module that describes the functionality of the digital circuit. It defines the inputs, outputs, and logical behavior of the circuit. In this experiment, the design represents a 2-to-1 Multiplexer, where the output is selected from two input signals based on a select signal.

### Testbench

A testbench is a separate Verilog module used to verify the functionality of the design. It provides different combinations of input signals to the Design Under Test (DUT) and allows the resulting output to be observed. The testbench also generates the Value Change Dump (.vcd) file used for waveform analysis in GTKWave.

## 2\. Simulation Workflow with Icarus Verilog

Icarus Verilog (iverilog) is an open-source Verilog compiler and simulator used to compile and execute Verilog designs. The design and its testbench are compiled together, after which the simulation is executed to generate a waveform file in VCD (Value Change Dump) format. This file can then be opened and analyzed using GTKWave.

### Simulation Flow

_\[Figure: Icarus Verilog simulation flow diagram - no screenshot was captured for this step, so it is not included here.\]_

## 3\. 2:1 Multiplexer - Simulation

### Step 1 - Compile the Design

The Verilog design and its testbench were compiled using Icarus Verilog.

iverilog good_mux.v tb_good_mux.v

The command compiles the RTL design and testbench and generates the simulation executable.

### Step 2 - Execute the Simulation

The compiled simulation was executed using:

./a.out

The testbench applies different input combinations during simulation and generates the corresponding VCD waveform file.

### Step 3 - Open the Waveform

The generated waveform file was opened using GTKWave:

gtkwave tb_good_mux.vcd

The input signals, select signal, and output signal were then observed to verify the functional behavior of the multiplexer.


_GTKWave waveform, sel = 0: output y correctly tracks i0._


_GTKWave waveform, marker at 75 ns: sel transitions to 1 and y switches to track i1._


_GTKWave waveform, marker at 225 ns: y = i1 continues to hold while sel remains 1._

## 4\. Multiplexer Design Explanation

### 2-to-1 Multiplexer

A 2-to-1 Multiplexer is a combinational digital circuit that selects one of two input signals and connects the selected signal to the output. The selection is controlled by a single select signal.

**Inputs:**

- i0 - First input
- i1 - Second input
- sel - Select signal

**Output:**

- y - Multiplexer output

**Operation:**

- When sel = 0, the output y follows i0.
- When sel = 1, the output y follows i1.

### Verilog RTL Design

The 2-to-1 multiplexer was implemented using an always @(\*) combinational block.

module good_mux (

input i0,

input i1,

input sel,

output reg y

);

always @(\*)

begin

if (sel)

y <= i1;

else

y <= i0;

end

endmodule


_good_mux.v and tb_good_mux.v source, viewed in vim._

## 5\. RTL Synthesis Using Yosys

After verifying the functionality of the RTL design through simulation, the good_mux design was synthesized using Yosys. Yosys reads the Verilog RTL, performs synthesis and technology mapping using the SkyWater SKY130 standard-cell library, and generates a gate-level netlist. The synthesis process was performed using the following Yosys commands.

### Step 1 - Load the Standard Cell Library

read_liberty -lib ../lib/sky130_fd_sc_hd_\_tt_025C_1v80.lib

This command loads the timing and cell information from the SKY130 standard-cell library into Yosys for use during technology mapping.

### Step 2 - Read the Verilog RTL

read_verilog good_mux.v

Yosys parses the Verilog source and generates an internal RTL representation of the good_mux module.

### Step 3 - Perform RTL Synthesis

synth -top good_mux

The -top good_mux option specifies good_mux as the top-level module for synthesis. Yosys performs several synthesis passes to optimize and prepare the design for technology mapping.

### Step 4 - Visualize the Synthesized Design

show

This command generates a Graphviz representation of the current design and opens the resulting schematic using the available graphical viewer.


_Yosys show output: the generic \$mux cell driven by i0, i1, and sel, prior to final technology mapping._

### Step 5 - Technology Mapping Using ABC

abc -liberty ../lib/sky130_fd_sc_hd_\_tt_025C_1v80.lib

The abc command performs technology mapping using the specified Liberty library. This converts the synthesized logic into available standard cells from the target technology.

### Step 6 - Generate the Gate-Level Netlist

write_verilog good_mux_netlist.v

This generates the synthesized gate-level Verilog file, good_mux_netlist.v. A version without synthesis attributes was also generated using:

write_verilog -noattr good_mux_netlist.v

The -noattr option removes additional synthesis attributes from the generated Verilog netlist.

## 6\. Synthesized Netlist

The synthesized design was visualized as a gate-level netlist. The netlist represents the structural implementation of the original RTL design using cells from the target technology library. For the 2-to-1 multiplexer, the synthesized netlist shows the input signals i0, i1, and sel connected to the corresponding multiplexer cell, with the resulting signal connected to the output y.


_good_mux_netlist.v mapped to a single sky130_fd_sc_hd_\_mux2_1 cell, alongside its Yosys schematic._

## 7\. Observation

The simulation confirmed the expected behavior of the 2-to-1 multiplexer. When the select signal was low, the output followed i0, and when the select signal was high, the output followed i1. The GTKWave waveform was used to verify these signal transitions. The RTL design was then successfully synthesized using Yosys. The resulting netlist provided a structural representation of the multiplexer using a technology-specific standard cell.

## 8\. What I Learned

- Fundamentals of RTL design using Verilog.
- The purpose of a design module, testbench, and simulator.
- How to compile Verilog designs using Icarus Verilog.
- How to execute a Verilog simulation.
- How to generate and analyze VCD waveform files.
- How to use GTKWave for functional verification.
- The basic concept of RTL synthesis.
- How Yosys is used for synthesizing Verilog RTL.
- How RTL can be converted into a gate-level netlist.
- The role of a standard-cell library during technology mapping.
- How ABC performs technology mapping using a Liberty library.
- The difference between simulation/verification and synthesis.

## 9\. Conclusion

This experiment provided a practical introduction to the RTL design, simulation, verification, and synthesis workflow. A 2-to-1 multiplexer was designed using Verilog and verified through simulation using Icarus Verilog and GTKWave. The same RTL design was subsequently synthesized using Yosys, technology mapped using the SKY130 standard-cell library, and converted into a gate-level netlist. The experiment established a foundation for understanding how a Verilog RTL description progresses from functional simulation to a synthesized hardware representation.

# Day 2 - Sequential Logic, Hierarchical Design and RTL Synthesis

## 1\. RTL Verification Fundamentals

Sequential logic is a type of digital logic in which the output depends on the present input as well as the previously stored state. A D Flip-Flop is a basic sequential circuit used to store one bit of data. The input D is transferred to the output Q at the active edge of the clock.

In this experiment, different D Flip-Flop configurations were implemented and verified:

- D Flip-Flop with synchronous reset
- D Flip-Flop with asynchronous set
- D Flip-Flop with asynchronous reset

The designs were simulated using Icarus Verilog and verified using GTKWave. The designs were then synthesized using Yosys and mapped to the SKY130 standard-cell library.

## 2\. D Flip-Flop Designs

### D Flip-Flop with Synchronous Reset

A synchronous reset affects the output only at the active edge of the clock.

module dff_syncres (

input clk,

input async_reset,

input sync_reset,

input d,

output reg q

);

always @(posedge clk)

begin

if (sync_reset)

q <= 1'b0;

else

q <= d;

end

endmodule

### D Flip-Flop with Asynchronous Set

An asynchronous set can force the output to logic 1 independently of the clock.

module dff_async_set (

input clk,

input async_set,

input d,

output reg q

);

always @(posedge clk, posedge async_set)

begin

if (async_set)

q <= 1'b1;

else

q <= d;

end

endmodule

### D Flip-Flop with Asynchronous Reset

An asynchronous reset can force the output to logic 0 independently of the clock.

module dff_asyncres (

input clk,

input async_reset,

input d,

output reg q

);

always @(posedge clk, posedge async_reset)

begin

if (async_reset)

q <= 1'b0;

else

q <= d;

end

endmodule

## 3\. RTL Simulation and Waveform Verification

The D Flip-Flop designs were compiled and simulated using Icarus Verilog. The generated VCD files were opened using GTKWave to verify the behavior of the sequential circuits.

### Simulation Commands

**Synchronous Reset**

iverilog dff_syncres.v tb_dff_syncres.v

./a.out

gtkwave tb_dff_syncres.vcd

**Asynchronous Set**

iverilog dff_async_set.v tb_dff_async_set.v

./a.out

gtkwave tb_dff_async_set.vcd

**Asynchronous Reset**

iverilog dff_asyncres.v tb_dff_asyncres.v

./a.out

gtkwave tb_dff_asyncres.vcd

### GTKWave - Synchronous Reset


_q changes only on the next clk edge after sync_reset asserts, not immediately._

### GTKWave - Asynchronous Set


_q is held at 1 by a prior async_set pulse, independent of the clock._

### GTKWave - Asynchronous Reset


_q is forced to 0 on every async_reset pulse, independent of the clock edge._

## 4\. RTL Synthesis Using Yosys

After functional verification, the RTL designs were synthesized using Yosys. Yosys converts the Verilog RTL into a gate-level representation and maps the design to standard cells from the selected technology library.

### Load the SKY130 Standard-Cell Library

read_liberty -lib ../lib/sky130_fd_sc_hd_\_tt_025C_1v80.lib

### Read the Verilog RTL

For example:

read_verilog dff_syncres.v

The corresponding Verilog file was used for each design.

### Perform RTL Synthesis

synth -top dff_syncres

The top-level module is specified using the -top option.

### Map Flip-Flops to SKY130 Cells

dfflibmap -liberty ../lib/sky130_fd_sc_hd_\_tt_025C_1v80.lib

This maps generic flip-flop cells to equivalent sequential cells available in the SKY130 library.

### Technology Mapping

abc -liberty ../lib/sky130_fd_sc_hd_\_tt_025C_1v80.lib

The abc command performs logic optimization and technology mapping using the selected standard-cell library.

### Visualize the Synthesized Design

show

The synthesized design can be viewed as a graphical representation using Graphviz. The resulting schematics for each of the three flip-flop variants are shown below.


_dff_asyncres mapped to sky130_fd_sc_hd_\_dfrtp_1, with async_reset inverted via a clkinv cell into RESET_B._


_dff_async_set mapped to sky130_fd_sc_hd_\_dfstp_2, with async_set inverted via a \$\_NOT_cell into SET_B._


_dff_syncres mapped to a plain sky130_fd_sc_hd_\_dfxtp_1 (no reset pin); sync_reset implemented via a MUX in front of D._

### Generate the Synthesized Netlist

write_verilog -noattr dff_syncres_net.v

The generated Verilog file represents the synthesized gate-level implementation.

## 5\. Multiplier Designs

Simple multiplier circuits were also implemented using Verilog RTL and synthesized using Yosys.

### Multiplier by 2

The input is a 3-bit signal and the output is a 4-bit signal. Multiplication by 2 can be represented by shifting the input one bit to the left.

module mul2 (

input \[2:0\] a,

output \[3:0\] y

);

assign y = a \* 2;

endmodule


_mul2 optimized to pure wiring: input bits \[2:0\] rewired to output \[3:1\], LSB tied to constant 0 - no gates needed._

### Multiplier by 8

The input is a 3-bit signal and the output is a 6-bit signal. Multiplication by 8 can be represented by shifting the input three bits to the left.

module mult8 (

input \[2:0\] a,

output \[5:0\] y

);

assign y = a \* 8;

endmodule

Note: the synthesized implementation represents the required multiplication operation through the optimized hardware structure generated by Yosys.

_\[Figure: Synthesized netlist of the multiply-by-8 module - no screenshot was captured for this step, so it is not included here.\]_

## 6\. Hierarchical Design

A hierarchical RTL design consists of multiple modules where a top-level module instantiates and connects lower-level submodules. In this experiment, a design containing two submodules was created: sub_module1 performs an AND operation, sub_module2 performs an OR operation, and multiple_modules acts as the top-level module.

### Submodule 1

module sub_module1 (

input a,

input b,

output y

);

assign y = a & b;

endmodule

### Submodule 2

module sub_module2 (

input a,

input b,

output y

);

assign y = a | b;

endmodule

### Top-Level Module

module multiple_modules (

input a,

input b,

input c,

output y

);

wire net1;

sub_module1 u1 (

.a(a),

.b(b),

.y(net1)

);

sub_module2 u2 (

.a(net1),

.b(c),

.y(y)

);

endmodule

The resulting logic is:

net1 = a & b

y = net1 | c

Therefore:

y = (a & b) | c

## 7\. Hierarchical Synthesis and Netlist

The multi-module design was synthesized using Yosys while preserving its module hierarchy.

### Start Yosys

yosys

### Load the SKY130 Library

read_liberty -lib ../lib/sky130_fd_sc_hd_\_tt_025C_1v80.lib

### Read the Verilog Design

read_verilog multiple_modules.v

Yosys identifies the following modules:

sub_module1

sub_module2

multiple_modules

### Synthesize the Top-Level Module

synth -top multiple_modules

### Visualize the Hierarchical Design

show

The synthesized design shows sub_module1 and sub_module2 connected through the intermediate signal net1.

### Generate the Hierarchical Netlist

write_verilog -noattr multiple_modules_netlist.v

The generated netlist retains the module hierarchy.


_Hierarchy preserved in the Yosys schematic: u1/sub_module1 -> net1 -> u2/sub_module2._

## 8\. Flat Synthesis

A hierarchical design can also be converted into a flat representation. In a flat netlist, the lower-level modules are merged into the top-level design. The original module hierarchy is removed, allowing the complete logic to be represented at one level.

### Flatten the Design

flatten

### Visualize the Flat Design

show

The resulting representation directly shows the logic implemented by the complete design rather than separate submodule blocks.

### Generate the Flat Netlist

write_verilog multiple_modules_flat.v

A version without synthesis attributes was also generated:

write_verilog -noattr multiple_modules_flat.v

_\[Figure: Flat netlist of multiple_modules - no screenshot was captured for this step, so it is not included here.\]_

## 9\. Hierarchical vs Flat Netlist

### Hierarchical Netlist

The hierarchical netlist preserves the original module structure:

multiple_modules

|

+---- sub_module1

|

+---- sub_module2

This representation makes the design structure and individual module boundaries easier to understand.

### Flat Netlist

The flat netlist removes the submodule hierarchy and represents the complete logic at a single level. For this design:

a ----+

|

AND ----+

| |

b ----+ |

OR ---- y

c ------------+

The final logic is:

y = (a & b) | c

### Comparison

| **Feature**          | **Hierarchical Netlist**  | **Flat Netlist**                        |
| -------------------- | ------------------------- | --------------------------------------- |
| Module hierarchy     | Preserved                 | Removed                                 |
| Submodule instances  | Present                   | Removed                                 |
| Design structure     | Clearly visible           | Combined                                |
| Debugging            | Easier at module level    | More difficult for large designs        |
| Logic representation | Module-based              | Single-level                            |
| Optimization         | Module structure retained | Entire design can be optimized together |

## 10\. Observation

The D Flip-Flop designs were successfully simulated using Icarus Verilog and verified using GTKWave. The synchronous reset operated only at the active clock edge, while the asynchronous set and asynchronous reset could affect the output independently of the clock. The flip-flop designs were then synthesized using Yosys and mapped to cells from the SKY130 standard-cell library.

Multiplier designs for multiplication by 2 and 8 were also implemented using Verilog RTL and synthesized to observe their corresponding hardware representations.

A hierarchical multi-module design was created using sub_module1, sub_module2, and the top-level multiple_modules. The hierarchical netlist preserved the original module structure. The design was then flattened to remove the module hierarchy and obtain a single-level representation.

## 11\. What I Learned

- Difference between combinational and sequential logic.
- Working principle of a D Flip-Flop.
- Difference between synchronous and asynchronous reset.
- Operation of an asynchronous set.
- RTL simulation using Icarus Verilog.
- Waveform verification using GTKWave.
- RTL synthesis using Yosys.
- Use of the SKY130 standard-cell Liberty library.
- Flip-flop technology mapping using dfflibmap.
- Technology mapping using abc.
- Generation of synthesized Verilog netlists.
- Hierarchical RTL design using multiple modules.
- Module instantiation and interconnection.
- Difference between hierarchical and flat netlists.
- Use of the flatten command in Yosys.

## 12\. Conclusion

This experiment provided practical experience with sequential RTL design, simulation, synthesis, hierarchical design, and netlist generation. Different D Flip-Flop configurations were implemented and verified using Icarus Verilog and GTKWave. The designs were subsequently synthesized and technology-mapped using Yosys and the SKY130 standard-cell library.

Multiplier designs were also implemented and synthesized to observe their hardware representations. Finally, a hierarchical multi-module design was synthesized while preserving its hierarchy and was then flattened to obtain a single-level representation.
