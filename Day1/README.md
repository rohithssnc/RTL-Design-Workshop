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
