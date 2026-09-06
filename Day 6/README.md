# Day 6 — Complete RTL to GDSII Flow using OpenLANE (picorv32a)

## Table of Contents
1. [Objective](#objective)
2. [Recap: Setting up the Environment](#recap-setting-up-the-environment)
3. [The OpenLANE ASIC Flow — Big Picture](#the-openlane-asic-flow--big-picture)
4. [Stage 1: RTL Synthesis](#stage-1-rtl-synthesis)
5. [Stage 2: Floorplanning](#stage-2-floorplanning)
6. [Stage 3: Placement](#stage-3-placement)
7. [Stage 4: Clock Tree Synthesis (CTS)](#stage-4-clock-tree-synthesis-cts)
8. [Stage 5: Routing](#stage-5-routing)
9. [Stage 6: Static Timing Analysis (STA)](#stage-6-static-timing-analysis-sta)
10. [Stage 7: Physical Verification — DRC & LVS](#stage-7-physical-verification--drc--lvs)
11. [Handling Antenna Rule Violations](#handling-antenna-rule-violations)
12. [Design for Test (DFT)](#design-for-test-dft)
13. [OpenLANE Regression Testing](#openlane-regression-testing)
14. [Is Sky130 (130nm) Outdated?](#is-sky130-130nm-outdated)
15. [Standard Cell Design Flow (Library Characterization)](#standard-cell-design-flow-library-characterization)
16. [SPICE Models & MOSFET Device Equations](#spice-models--mosfet-device-equations)
17. [Timing Characterization of a Standard Cell](#timing-characterization-of-a-standard-cell)
18. [Lab Walkthrough — What Was Actually Run](#lab-walkthrough--what-was-actually-run)
19. [Errors Faced & How They Were Resolved](#errors-faced--how-they-were-resolved)
20. [Key Takeaways](#key-takeaways)

---

## Objective

Day 6 focuses on running the **complete RTL-to-GDSII flow** on the `picorv32a` design using **OpenLANE**, an open-source ASIC implementation flow built on top of several open-source tools (Yosys, OpenROAD, Magic, Netgen, Fault, OpenSTA, etc.) targeting the **SkyWater Sky130 PDK**. The goal is to understand *what each stage of the flow does*, *why it is needed*, and *how to read/debug the logs and outputs it produces* — not just to execute commands blindly.

---

## Recap: Setting up the Environment

Before the flow can be run, OpenLANE needs three things set up correctly:

- **PDK_ROOT** — path to the installed process design kit (`sky130A`), containing standard cell libraries (`libs.ref`), technology LEF files, and Magic tech files.
- **OpenLANE flow scripts** — the `openLANE_flow` (or `openlane`) directory containing `flow.tcl`, `designs/`, `scripts/`, and `configuration/`.
- **Docker** — OpenLANE ships as a Docker container so that every user gets the exact same tool versions regardless of host OS.

The standard way to launch OpenLANE interactively is:

```bash
docker run -it \
  -v $(pwd):/openLANE_flow \
  -v $PDK_ROOT:$PDK_ROOT \
  -e PDK_ROOT=$PDK_ROOT \
  -u $(id -u):$(id -g $USER) \
  efabless/openlane:rc2
```

Inside the container:

```tcl
% ./flow.tcl -interactive
% package require openlane 0.9
% prep -design picorv32a
```

### Directory Structure Sanity Check
A quick `ls` through the working tree confirms the PDK and standard cell libraries are correctly placed:

```
~/Desktop/work/tools/openlane_working_dir/
├── openlane            # the flow itself (flow.tcl, scripts, designs)
├── openlane_old
└── pdks/
    ├── open_pdks
    ├── skywater-pdk
    └── sky130A/
        ├── libs.ref/    # .lib, .lef, .gds, .spice, .mag views per corner
        └── libs.tech/   # magic, klayout, ngspice tech files
```

Each standard-cell flavor (`sky130_fd_sc_hd`, `_hs`, `_ms`, `_ls`, `_lp`, `_hvl`) has sub-folders for `lib` (timing), `lef` (abstract layout), `gds` (layout), `mag` (Magic layout), `spice` (extracted netlists), and `verilog` (behavioral models) — this is what gives OpenLANE everything it needs across every stage of the flow.

---

## The OpenLANE ASIC Flow — Big Picture

At the highest level, OpenLANE converts an **RTL description (Verilog)** plus a **PDK** into a **GDSII** layout ready for fabrication:

```
RTL ──► Synth ──► FP+PP ──► Place ──► CTS ──► Route ──► Sign-off ──► GDSII
```

Expanded, the actual internal flow looks like this:

```
Design RTL ─┐                                   SKY130 PDK
            │                                        │
            ▼                                        ▼
     RTL Synthesis (Yosys+abc) ──► STA (OpenSTA) ──► DFT (Fault)
            │
            ▼
   ┌────────────────────────────────────────────┐
   │  OpenROAD App:                              │
   │  Floorplanning → Placement → CTS →          │
   │  Optimization → Fake antenna diode           │
   │  insertion → Global Routing                  │
   └────────────────────────────────────────────┘
            │
            ▼
   LEC (yosys) ──► Detailed Routing (TritonRoute) ──► Fake antenna
                                                        diode swap
            │
            ▼
   RC Extraction ──► STA (OpenSTA) ──► Physical Verification
                                        (Magic & Netgen) ──► GDS2 Streaming (Magic) ──► GDSII
```

Every box is a separate open-source tool stitched together by OpenLANE's Tcl scripts, and **Design Exploration** loops the whole thing so that different configurations can be swept and compared (this is also reused for regression/CI testing — see later section).

---

## Stage 1: RTL Synthesis

**Tool:** Yosys (logic synthesis) + ABC (technology mapping/optimization)

**What it does:** Synthesis converts the behavioral/RTL Verilog description into a **gate-level netlist** made purely of standard cells from the target library (`sky130_fd_sc_hd`). This involves:
- Elaboration — parsing Verilog and building an internal RTL representation.
- Generic technology-independent optimization (constant propagation, dead code elimination, FSM extraction).
- **Technology mapping** — mapping generic logic (AND/OR/MUX/flip-flops) onto the actual standard cells available in the `.lib` file, guided by ABC for area/delay optimization.

The synthesis log for `picorv32a` reports the final gate-level cell histogram, e.g.:

```
Number of wires:        14596
Number of wire bits:    14978
Number of cells:        14876
   sky130_fd_sc_hd__dfxtp_2   1613   (flip-flops)
   sky130_fd_sc_hd__buf_1     1656
   sky130_fd_sc_hd__inv_2     1615
   sky130_fd_sc_hd__mux2_1    1224
   sky130_fd_sc_hd__a2bb2o_2  1748
   ...
Chip area for module '\picorv32a': 147712.9184
```

This "chip area" number is the **first real, cell-based area estimate** of the design (as opposed to any RTL-level guess), and it directly determines how big the floorplan needs to be.

After synthesis, OpenLANE also invokes **OpenSTA** to run a first static timing analysis pass on the *synthesized* netlist (pre-layout, wireload-model-based), so that gross timing problems are caught immediately rather than after placement/routing.

---

## Stage 2: Floorplanning

**Tool:** OpenROAD `init_fp` / custom Tcl scripts inside OpenLANE

**What it does:** Floorplanning decides:
1. **The die area** — the total silicon area allocated to the design.
2. **The core area** — the area inside the die where standard cells will actually be placed (die area minus margins).
3. **Row structure** — standard cells are placed in horizontal "rows" that alternate orientation (`FS`/`N`) so that abutting `VDD`/`VSS` rails line up (Flip-and-abut technique).
4. **I/O pin placement** — where the top-level ports land around the periphery of the die.
5. **Power Distribution Network (PDN)** planning — where the power straps/rings will be routed.

### Key Floorplan Configuration Variables

| Variable | Meaning |
|---|---|
| `FP_CORE_UTIL` | Target core utilization % — ratio of area occupied by standard cells to total core area (default 50%). Lower utilization leaves more room for routing but wastes die area; higher utilization risks routing congestion. |
| `FP_ASPECT_RATIO` | Height/width ratio of the core (default 1 = square die). |
| `FP_SIZING` | `relative` (derive die size from `FP_CORE_UTIL`) or `absolute` (use an explicit `DIE_AREA`). |
| `DIE_AREA` | Explicit 4-corner rectangle in microns, when `FP_SIZING=absolute`. |
| `FP_IO_HMETAL` / `FP_IO_VMETAL` | Metal layers used for horizontal (top/bottom) and vertical (left/right) I/O pins. |
| `FP_IO_MODE` | 0 = matching mode, 1 = random-equidistant pin placement. |
| `FP_PDN_VOFFSET`/`VPITCH`, `FP_PDN_HOFFSET`/`HPITCH` | Offset & pitch of vertical/horizontal power straps in the PDN (on metal layers 4/5). |
| `FP_TAPCELL_DIST` | Spacing between tap-cell columns — tap cells prevent latch-up by tying the substrate/well to VDD/VSS regularly across the core. |
| `FP_IO_VEXTEND` / `FP_IO_HEXTEND` | How far I/O pins extend outside the die boundary. |
| `FP_IO_VTHICKNESS_MULT` / `HTHICKNESS_MULT` | Multiplier on minimum layer width to set I/O pin thickness. |
| `BOTTOM/TOP/LEFT/RIGHT_MARGIN_MULT` | Core margins from the die edges, expressed in multiples of site height/width. |
| `FP_PDN_CORE_RING` | Whether to add a ring of power routing around the core. |
| `FP_HORIZONTAL_HALO` / `FP_VERTICAL_HALO` | Keep-out halo (in microns) enforced around tap/decap cells. |

### Reading the Floorplan DEF

The generated `floorplan.def` for `picorv32a` shows the concrete result of these settings:

```
DESIGN picorv32a ;
UNITS DISTANCE MICRONS 1000 ;
DIEAREA ( 0 0 ) ( 660685 671405 ) ;
ROW ROW_0 unithd 5520 10880 FS DO 1412 BY 1 STEP 460 0 ;
ROW ROW_1 unithd 5520 13600 N  DO 1412 BY 1 STEP 460 0 ;
...
```

- `DIEAREA` gives the die's bottom-left and top-right corners in **database units** (1000 units = 1 micron here), so the die is roughly `660.7 µm × 671.4 µm`.
- Each `ROW` statement defines one placement row: the site name (`unithd`), the (x,y) origin, the orientation (`FS` = flipped-south, `N` = north/normal — alternating so abutting rows share power rails), the number of sites (`DO 1412`), and the site pitch (`STEP 460 0`, i.e. 0.46 µm per site in X).
- 39 rows (`ROW_0` … `ROW_38` and beyond) tile the entire core height.

---

## Stage 3: Placement

**Tool:** OpenROAD (RePlAce for global placement, OpenDP for detailed/legalization)

**What it does:** Placement decides the exact (x, y) location of every standard cell inside the rows defined by the floorplan.

- **Global placement** treats the netlist as a force-directed system (cells connected by nets pull toward each other) and produces an approximate, possibly overlapping, placement that minimizes total wirelength/congestion.
- **Detailed placement (legalization)** then snaps every cell onto a legal row/site position with zero overlap, respecting cell orientation and site boundaries.

Good placement is critical because it directly determines:
- Wire lengths (and hence RC delay/timing)
- Routing congestion in later stages
- Power grid IR drop characteristics

### Reading OpenROAD's Placement Report

After running placement (and resizing/optimization) on `picorv32a`, OpenROAD prints a **Design Stats** block followed by a **Placement Analysis** block:

```
Notice 0:   Created 2 special nets and 0 connections.
Notice 0:   Created 15447 nets and 56989 connections.
Notice 0: Finished DEF file: .../tmp/placement/8-resizer.def

Design Stats
------------------------------
total instances          21699
multi row instances          0
fixed instances            6354
nets                      15449
design area          420473.3 u^2
fixed area              9141.3 u^2
movable area           147800.5 u^2
utilization                 36 %
utilization padded          55 %
rows                        238
row height                 2.7 u

Placement Analysis
------------------------------
total displacement          0.0 u
average displacement        0.0 u
max displacement            0.0 u
original HPWL           766080.0 u
legalized HPWL           779196.5 u
delta HPWL                    2 %

[INFO DPL-0020] Mirrored 6193 instances
[INFO DPL-0021] HPWL before      779196.5 u
[INFO DPL-0022] HPWL after       766080.0 u
[INFO DPL-0023] HPWL delta          -1.7 %
```

Key terms explained:

- **Total / fixed / movable instances** — `total instances` is every standard cell in the design; `fixed instances` are cells that placement is *not* allowed to move (e.g., tap cells, decap cells, or IO-adjacent cells locked earlier in the flow); `movable area` is the silicon area available for placement to actually optimize the position of the remaining cells.
- **Utilization vs. utilization padded** — plain *utilization* is the fraction of the core area actually occupied by cell footprints; *utilization padded* additionally reserves extra "halo" space around cells (spacing/routing margin), which is why the padded number (55%) is always ≥ the raw number (36%). This padded value is what the placer actually targets to leave enough room for routing later.
- **Rows / row height** — confirms the row structure created during floorplanning (`row height` here is 2.7 µm, matching a `unithd` site).
- **HPWL (Half-Perimeter Wire Length)** — the standard, cheap-to-compute proxy for total wirelength: for each net, take the bounding box around all its pins and sum half its perimeter (width + height). Lower HPWL generally means shorter wires, lower RC delay, and easier routing. OpenROAD reports it **before** legalization (`original HPWL`, from the raw/optimized global placement) and **after** legalization (`legalized HPWL`), because snapping cells onto legal grid sites necessarily perturbs the "ideal" placement slightly — the **delta HPWL** (here 2%) quantifies how much wirelength was sacrificed for legality.
- **Displacement (total/average/max)** — how far, on average and at most, cells moved from their global-placement position during legalization/detailed placement. Large displacement values would indicate the legalizer had to fight hard to find legal positions (often a sign of over-utilization or poor global placement); here all values are `0.0 u`, meaning legalization required essentially no movement.
- **Mirrored instances** — as a further optimization pass, the placer may **mirror** (flip) certain cells about the Y-axis. Mirroring a cell can align its pins more favorably with neighboring cells/nets without moving it, reducing wirelength for "free." Here, mirroring 6193 instances reduced HPWL from 779,196.5 µm to 766,080.0 µm — a further **-1.7%** improvement, and notably brings the post-mirror HPWL back down to match the pre-legalization `original HPWL` value.
- **Klayout screenshot generation** — at the end of this stage, OpenLANE automatically invokes **KLayout** (using the PDK's `.lyt` layer/technology file) to render and save a visual screenshot of the current layout, which is how progress can be sanity-checked visually after every major stage (placement, CTS, routing) without needing to open Magic manually.

---

## Stage 4: Clock Tree Synthesis (CTS)

**Tool:** OpenROAD (TritonCTS)

**What it does:** CTS builds a **balanced clock distribution network** (typically an H-tree or clock-mesh-like structure) from the single clock source to every sequential element (flip-flop) in the design, inserting clock buffers/inverters along the way.

Goals of CTS:
- Minimize **clock skew** (difference in arrival time of the clock edge at different flip-flops).
- Minimize **clock latency** while keeping buffer insertion delay under control.
- Balance **insertion delay** so that setup/hold timing margins are met uniformly across the chip.

CTS happens *after* placement (so the tool knows where every flop physically is) and *before* final routing (so the clock nets can be routed alongside the rest of the design).

---

## Stage 5: Routing

**Tools:** FastRoute (global routing, inside OpenROAD) + TritonRoute (detailed routing)

Routing implements the actual metal-layer interconnect between placed cells, using the available metal stack (for Sky130: `li1`, `met1`–`met5`).

- **Global routing** decides, at a coarse (gcell-grid) level, which routing "tracks"/regions each net will pass through, balancing congestion across the chip.
- **Detailed routing** converts that global routing plan into actual, DRC-clean metal shapes and vias on real tracks, obeying minimum width/spacing rules, layer-direction preferences (e.g. `met1` = horizontal-preferred, `met2` = vertical-preferred), and pitch constraints (`M1 Pitch`, `M2 Pitch`).

This is the stage after which the chip is a **fully routed, DRC-correct** (in principle) layout — the flow moves from `Route` to `Sign Off` in the high-level `Synth → FP+PP → Place → CTS → Route → Sign Off` pipeline shown in the slides.

---

## Stage 6: Static Timing Analysis (STA)

**Tool:** OpenSTA (part of the OpenROAD project)

**Flow:** `RC Extraction (DEF2SPEF) → STA (OpenSTA)`

Unlike the earlier wireload-based STA done right after synthesis, this pass happens **after routing**, using **actual parasitic RC extracted from the real routed geometry** (converted from DEF to SPEF format). This gives a much more accurate picture of real silicon timing.

A typical timing path report looks like:

```
Startpoint: _5435_ (rising edge-triggered flip-flop clocked by vclk)
Endpoint:   _5435_ (rising edge-triggered flip-flop clocked by vclk)
Path Group: vclk
Path Type: min

 Delay   Time   Description
--------------------------------------------------------
  0.00   0.00   clock vclk (rise edge)
  0.00   0.00   clock network delay (ideal)
  0.00   0.00 ^ _5435_/CLK (sky130_fd_sc_hd__dfrtp_4)
  0.78   0.78 ^ _5435_/Q  (sky130_fd_sc_hd__dfrtp_4)
  0.22   0.99 ^ _4647_/X  (sky130_fd_sc_hd__o2lbo_4)
  0.00   0.99 ^ _5435_/D  (sky130_fd_sc_hd__dfrtp_4)
         0.99   data arrival time

  0.00   0.00   clock vclk (rise edge)
  0.00   0.00   clock network delay (ideal)
  0.00   0.00   clock reconvergence pessimism
 -0.08  -0.08   library hold time
        -0.08   data required time
--------------------------------------------------------
        -0.08   data required time
        -0.99   data arrival time
--------------------------------------------------------
        1.08    slack (MET)
```

Key terms:
- **Data arrival time** — the time it takes a signal to actually travel from the clock edge at the launching flop through combinational logic to the capturing flop's D input.
- **Data required time** — the latest/earliest time the signal is *allowed* to arrive to satisfy setup/hold timing.
- **Slack = required time − arrival time.** Positive slack ("MET") means timing is satisfied; negative slack is a violation that must be fixed (via resizing, buffering, re-placement, etc.).
- This example is a **min-delay (hold) check** — hold violations are checked with zero/near-zero delay assumptions and are especially sensitive to clock skew and short logic paths.

---

## Stage 7: Physical Verification — DRC & LVS

**Tools:** Magic (DRC + SPICE extraction) and Netgen (LVS comparison)

After (or interleaved with) routing, the layout must be verified against two independent checks before it can be trusted as manufacturable:

1. **DRC (Design Rule Check)** — Magic checks every shape on every layer against the foundry's design rules (minimum width, minimum spacing, enclosure rules, etc., as encoded in the Sky130 tech file `sky130A.tech`). Any violation means the layout might not print correctly in silicon.

2. **LVS (Layout Versus Schematic)** — Magic first performs **SPICE extraction** from the physical layout (transistor-level netlist derived purely from geometry), and then **Netgen** compares this extracted SPICE netlist against the original synthesized Verilog netlist. LVS confirms that "what was drawn" electrically matches "what was intended" — catching issues like shorted nets, missing connections, or extra/missing devices that DRC alone cannot catch.

A typical Magic invocation for this purpose (loading the tech file, merged LEF, and the routed design) looks like:

```tcl
magic -T /path/to/sky130A/libs.tech/magic/sky130A.tech \
      lef read /path/to/openlane/designs/my_inv/runs/.../tmp/merged.lef \
      def read picorv32a...
```

---

## Handling Antenna Rule Violations

**The problem:** During fabrication, long metal wires act as unintended antennas that collect charge during plasma-etching steps. If too much charge accumulates on a wire connected directly to a sensitive transistor gate before the rest of the circuit (including protective diodes) is built, it can cause **gate oxide damage** — this is the "antenna effect."

**OpenLANE's preventive strategy** (rather than reactive fixing after detecting a violation):

1. **Add a "fake" antenna diode** next to *every* cell input, immediately after placement — regardless of whether that particular net will actually violate the rule.
2. Route the design normally, then **run the Antenna Checker (built into Magic)** on the fully routed layout.
3. **Only where the checker reports an actual violation** on a cell input pin, swap the fake/placeholder diode cell for a **real antenna diode cell** at that location.

This is efficient because inserting a real diode everywhere would waste area, but checking for violations before placing *any* diodes would require expensive rip-up-and-reroute. By reserving the physical footprint everywhere but only "activating" real diodes where needed, OpenLANE avoids both problems. This corresponds to the `Fake ant. diodes Insertion Script` (during placement/CTS/optimization) and `Fake ant. diodes Swapping Script` (after detailed routing) blocks in the OpenLANE ASIC flow diagram.

---

## Design for Test (DFT)

**Tool:** Fault

DFT modifies/augments the synthesized netlist to make the manufactured chip **testable** after fabrication, since internal state (flip-flops) is otherwise unobservable/uncontrollable from the chip's primary I/O. Key concepts:

- **Scan Insertion** — every flip-flop is replaced with a "scan flip-flop" that can be chained together into one or more **scan chains**. In test mode, these chains act like giant shift registers, letting external test equipment shift arbitrary values into every flop (**controllability**) and shift internal state out for observation (**observability**), via extra `sin`, `sout`, `Clock`, and `TCK` (test clock) signals.
- **Automatic Test Pattern Generation (ATPG)** — algorithmically generates a minimal set of input vectors that will excite and propagate the effect of possible manufacturing defects (typically modeled as "stuck-at faults") to an observable output.
- **Test Pattern Compaction** — reduces the number of generated patterns while preserving fault coverage, to minimize test time/cost in production.
- **Fault Coverage** — the percentage of all modeled faults that the generated test patterns are able to detect; a key quality/yield metric.
- **Fault Simulation** — simulates the generated patterns against fault models to verify/measure the achieved fault coverage before committing to expensive production test programs.

---

## OpenLANE Regression Testing

OpenLANE's **design exploration utility** (the same tool used to sweep floorplan/config parameters for a single design) is reused as the backbone of **regression testing / CI**. The flow is run end-to-end on a large corpus of reference designs (~70 designs, e.g. `jpeg_encoder`, `striVe_soc`, `aes256`, `genericfir`, `TEA`, `rc6_core`, `y_huff`, `sha3`, `cordic`, etc.), and each run's results (runtime, final cell count, and **timing/routing violation count**) are automatically compared against previously recorded "best known" results.

```
Design         Runtime      Cell Count   TR Vios
jpeg_encoder   3h16m7s      73624        0
striVe_soc     3h14m0s      73271        0
aes256         1h35m51s     64435        0
genericfir     1h2m36s      48849        0
...
```

A `TR Vios` (timing/routing violations) count of `0` across the whole suite is the signal that a change to the OpenLANE flow scripts, tool versions, or PDK has not silently broken the pipeline for any known design — this is exactly what continuous integration is meant to catch.

---

## Is Sky130 (130nm) Outdated?

A common question when starting out with an open-source 130nm PDK is whether it's even relevant industrially. Data on the **distribution of pure-play IC foundry sales by feature size (2019, IC Insights)** shows:

- **47%** of foundry sales were still on **> 40 nm nodes combined** (i.e., mature/legacy nodes), while advanced **< 40 nm** nodes accounted for the other 47%+13% split shown.
- Specifically, **130 nm** alone accounted for **6%**, and **130–180 nm** for another **13%** of foundry revenue — a substantial, continuing share of the market.

This confirms that mature nodes like Sky130 remain **commercially significant** — they are widely used for analog/mixed-signal, power management, sensors, and cost-sensitive IoT designs — which is exactly why an open-source PDK at this node is so valuable for real, low-cost, and educational tapeouts.

---

## Standard Cell Design Flow (Library Characterization)

Everything OpenLANE places, routes, and times comes from a **standard cell library** — and it's worth understanding how each cell in that library (an inverter, a NAND, a flip-flop, etc.) is itself designed and verified *before* it ever becomes a `.lib`/`.lef`/`.gds` entry that OpenLANE consumes.

### Cell Design Flow — Inputs, Steps, Outputs

```
Inputs:  Process Design Kits (PDKs) — DRC & LVS rules, SPICE models,
         library & user-defined specifications (target Vt, drive
         strength, cell height, etc.)

Design
Steps:   Circuit design → Layout design → Characterization

Outputs: CDL (Circuit Description Language), GDSII, LEF,
         extracted SPICE netlist (.cir)
```

- **Inputs** — the PDK supplies the physical design rules (DRC), the connectivity-checking rules (LVS), and calibrated **SPICE transistor models** for every device the cell might use, plus any library-specific or user specifications (e.g., "this cell must fit in an `hd` — high density — row height").
- **Design steps:**
  1. **Circuit design** — deciding the transistor-level schematic that implements the target Boolean function (e.g., a CMOS inverter, or a complex gate like `Fn = (B+D)·(A+C) + E·F`).
  2. **Layout design** — converting that schematic into actual polygons on silicon layers, guided by the **Euler's path** technique (see below) to get an efficient, DRC-clean stick diagram/layout.
  3. **Characterization** — running SPICE simulations on the *extracted* layout to measure its real electrical behavior (delay, power, noise margins) across process/voltage/temperature (PVT) corners, producing the timing/power tables that eventually populate the `.lib` file.
- **Outputs** — a **CDL** netlist (a SPICE-like circuit description used specifically for LVS), the **GDSII** layout (the actual mask geometry), a **LEF** abstract (pins + blockages, hiding internal detail from the place-and-route tools), and the **extracted SPICE netlist** (`.cir`, derived purely from the drawn layout geometry, used to verify the layout matches intent and to re-characterize timing).

### Euler's Path and Stick Diagrams

Standard-cell layout (especially in a single-row, PMOS-on-top / NMOS-on-bottom CMOS style) is made far more compact and DRC-friendly by using **Euler's path** to decide the *order* in which transistors are placed along the row.

- Every CMOS gate's **pull-up network (PMOS)** and **pull-down network (NMOS)** can be represented as a **graph**, where nodes are internal circuit nodes and edges are transistors, labeled by the gate signal that controls them (e.g., for `Fn = (B+D)·(A+C) + E·F`, the PMOS network graph has nodes `1,2,3,4,5` connected by edges `A,B,C,D,E,F`, and the NMOS network graph is the dual graph over nodes `5,6,7,0`).
- An **Euler path** is a path that traverses **every edge of the graph exactly once**. If the *same* Euler path (same edge/signal ordering) can be found simultaneously in **both** the PMOS and NMOS graphs, then placing the transistors along a single row in that order allows the polysilicon gates of the PMOS and NMOS devices to align in a single vertical line for every signal — meaning a **single, uninterrupted polysilicon gate strip** can be shared by the top and bottom transistor of each stage, with **no need to break the diffusion region** to route around a misaligned gate.
- This is exactly why the layout is drawn as a **stick diagram** first: a simplified line-based sketch (no actual widths/spacing) showing just the topology — which diffusion runs are continuous, where poly gates cross them, and where metal contacts land — before committing to the full DRC-compliant polygon layout.
- Practically, an Euler's-path-optimized layout minimizes the number of **diffusion breaks** (which cost extra area and sometimes extra contacts), directly reducing the cell's width/area — which is why this technique is central to "the art of layout" for standard cells.

---

## SPICE Models & MOSFET Device Equations

Once a cell's layout is complete, its layout-extracted transistors need to be simulated using accurate **SPICE compact models** to characterize real electrical behavior. A PDK ships one of these models (e.g., **BSIM**-style models) per device flavor, containing dozens of calibrated parameters such as:

```
.model nmos PMOS ( LEVEL = 49
  TNOM = 27   TOX = 5.8E-9   NCH = 4.1589E17   VTH0 = -0.583228
  K2 = 6.150203E-3   K3 = 0   ...   VSAT = 2E5   ...
  UA = 2.023988E-9   UB = 1E-21   ...   PVAG = 0.8478443
  RSH = 3.6   MOBMOD = 1   ...   CGSO = 2.68E-10   CGBO = 1E-12
  ... )
```

These SPICE model parameters feed directly into the fundamental device equations that describe MOSFET behavior:

**Threshold Voltage Equation** (captures the body/substrate-bias effect):

```
Vt = Vt0 + γ( √|−2Φf + Vsb| − √|−2Φf| )

where   γ = √(2·q·NA·εsi) / Cox
        Φf = −ΦT · ln(NA / ni)
```

- `Vt0` is the zero-body-bias threshold voltage; `γ` (the **body-effect coefficient**) depends on substrate doping (`NA`), silicon permittivity (`εsi`), and gate oxide capacitance (`Cox`); `Vsb` is the source-to-body voltage; `Φf` is the Fermi potential (a function of doping and thermal voltage `ΦT`, and intrinsic carrier concentration `ni`). This equation is why a transistor's effective threshold shifts as its source is raised above the body/ground potential (the **body effect**), which matters especially for stacked transistors in complex gates.

**Linear (triode) region current:**

```
Id = kn · [ (Vgs − Vt)·Vds − Vds²/2 ]
```

Valid when `Vds < Vgs − Vt` — the transistor behaves like a voltage-controlled resistor.

**Saturation region current:**

```
Id = (Kn/2) · (W/L) · (Vgs − Vt)² · [1 + λ·Vds]
```

Valid when `Vds ≥ Vgs − Vt` — current becomes (to first order) independent of `Vds`, controlled mainly by the overdrive voltage `(Vgs − Vt)` and the transistor's aspect ratio `W/L`; the `[1 + λ·Vds]` term models **channel-length modulation**, a second-order effect where current still rises slightly with `Vds` even in "saturation."

These are exactly the equations SPICE evaluates (with the PDK's calibrated parameters) during transient/DC simulation to generate the voltage waveforms used for timing characterization (next section).

---

## Timing Characterization of a Standard Cell

Once a cell's SPICE netlist (from layout extraction) is available, it is characterized by driving it with a standard test bench and measuring its response — this is what ultimately produces the delay/slew numbers stored in every `.lib` timing arc.

### The Characterization Test Bench

A typical setup (e.g., to characterize a 2-inverter chain `mX1inv → mX2nv`) consists of:
- A **pulse voltage source** (`v1`, labeled `6` in the schematic) driving the input node `in1`, modeling a realistic input transition rather than an ideal step.
- The **device under test (DUT)**, here two cascaded inverter instances, powered from `vdd`/`GND` via a DC supply (`v2`, labeled `5`).
- A small **load capacitor** (`C1 = 10f`) at the final output (`out1`), representing the fan-out/wire capacitance the cell must drive in real use.
- **Voltage probes** (`U1`, `U2` — `plot_v1`) at the input and output nodes, whose recorded waveforms (`v(in)`/`v(inv_out)` and `v(buf_out)`) are what gets measured against defined thresholds.

### Timing Threshold Definitions

Because a real voltage transition is a continuous curve (not an instantaneous step), delay and slew must be measured relative to **defined threshold crossing points**, not the literal start/end of the transition:

| Threshold | Typical value | Meaning |
|---|---|---|
| `slew_low_rise_thr` | e.g. 20% | Lower threshold used to measure the *start* of a rising transition's slew window |
| `slew_high_rise_thr` | e.g. 80% | Upper threshold marking the *end* of a rising transition's slew window |
| `slew_low_fall_thr` | e.g. 20% | Lower threshold for a falling transition's slew window |
| `slew_high_fall_thr` | e.g. 80% | Upper threshold for a falling transition's slew window |
| `in_rise_thr` / `in_fall_thr` | 50% | The voltage crossing point on the **input** waveform used as the delay reference point |
| `out_rise_thr` / `out_fall_thr` | 50% | The voltage crossing point on the **output** waveform used as the delay reference point |

**Slew (transition time)** is measured as the time it takes a signal to cross from its low threshold to its high threshold (e.g., 20%→80% of the swing) on a rising edge, or high→low on a falling edge — this quantifies how "sharp" or "sluggish" an edge is, which strongly affects downstream delay and short-circuit power.

### Propagation Delay

Given the 50% threshold-crossing convention, **propagation delay** for a given transition is defined simply as:

```
Delay = time(out_*_thr) − time(in_*_thr)
```

i.e., the time difference between when the **output** crosses its 50% threshold and when the **input** crossed its own 50% threshold. Concretely, from an actual characterization run of the inverter chain:

```
time(in_rise_thr)  = 4.215 ns   (input crosses 50% on its rising edge)
time(out_fall_thr) = 4.207 ns   (output crosses 50% on its falling edge)

Delay = 4.207 − 4.215 = −8 ps
```

A **negative delay** here simply reflects that, for this particular pair of edges/thresholds in the plotted window, the output's 50%-crossing occurred slightly *before* the input's — in practice, cell delay is always characterized and reported per **edge combination** (rise-to-fall, fall-to-rise, etc.) and per **corner/load/slew**, and this exact process — sweep the input slew and output load across a range of values, measure delay and output slew for each combination via SPICE, and tabulate the results — is precisely how a `.lib` file's two-dimensional **NLDM (Non-Linear Delay Model)** lookup tables are populated for every timing arc of every cell in the library. This is the fundamental characterization data that OpenSTA later reads to compute the timing reports shown in the [Static Timing Analysis](#stage-6-static-timing-analysis-sta) section above.

---

## Lab Walkthrough — What Was Actually Run

1. Verified the folder structure under `openlane_working_dir/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib` to confirm all PVT-corner `.lib` files (`ff_100C_1v65`, `tt_025C_1v80`, `ss_100C_1v60`, etc.) were present.
2. Launched OpenLANE in Docker:
   ```bash
   docker run -it -v $(pwd):/openLANE_flow -v $PDK_ROOT:$PDK_ROOT \
     -e PDK_ROOT=$PDK_ROOT -u $(id -u):$(id -g $USER) efabless/openlane:rc2
   ```
3. Inside the container: `./flow.tcl -interactive`, then `package require openlane 0.9`.
4. Navigated to `designs/picorv32a/src` and confirmed `picorv32a.v` and `picorv32a.sdc` exist.
5. Ran `prep -design picorv32a`, which:
   - Sourced `config.tcl`
   - Located the PDK at the configured `PDK_ROOT`
   - Set standard cell library to `sky130_fd_sc_hd`
   - Extracted available metal layers from the `.tlef` (`li1, met1, met2, met3, met4, met5` — 6 layers)
   - Merged all LEF files (standard cells + fill/decap/fakediode cells) into one `merged.lef`
   - Created a new run directory, e.g. `runs/06-09_12-22/`
6. Ran `run_synthesis`, producing the Yosys stats and chip-area report shown above.
7. Continued through floorplanning, generating `results/floorplan/picorv32a.floorplan.def` with `DIEAREA`, `ROW`, etc.
8. Used Magic standalone (outside the interactive Tcl shell) to inspect the merged LEF/DEF for physical verification:
   ```bash
   magic -T .../sky130A/libs.tech/magic/sky130A.tech \
         lef read .../tmp/merged.lef \
         def read .../picorv32a...
   ```

---

## Errors Faced & How They Were Resolved

| Symptom | Root Cause | Fix |
|---|---|---|
| `bash: cd: work: No such file or directory` | Wrong current directory — `work` lives under `Desktop`, not the home folder directly. | `cd Desktop/work/tools/...` — always confirm location with `pwd`/`ls` before `cd`. |
| `docker: Error response from daemon: ... exec: "run": executable file not found in $PATH` | A stray `run` token was typed as if it were a shell command, or line-continuation (`\`) was broken across pasted lines so Docker's arguments got mis-split. | Retype the full `docker run -it -v ... efabless/openlane:rc2` command on one logical command (or with correct `\` continuations), verifying no extra bare words are left dangling. |
| `docker: ... unable to start container process: exec: "run": executable file not found in $PATH` (again, after `-u $(id -u):$(id -g $USER)`) | Docker daemon/user permissions or a malformed image tag/arg order. | Re-run `docker run` with arguments in the documented order, and confirm the Docker daemon is active (`sudo docker run ...` where required) and the image tag (`efabless/openlane:rc2`, or `openlane:rc2`) exists locally (`docker images`). |
| `ERROR: Can't open input file './designs/picorv32a/src/picorv32a.v' for reading: No such file or directory` during `run_synthesis` | `prep -design picorv32a` was run, but the `src/` folder for that design didn't actually contain the expected Verilog file (or `config.tcl` pointed to a mismatched `SOURCES` path). | `cd designs/picorv32a/src && ls` to confirm `picorv32a.v` and `picorv32a.sdc` actually exist at the expected path; check `config.tcl`'s `SOURCES` variable references the correct filename. |
| `config.tcl: No such file or directory` under `less config.tcl` right after `prep` | Ran `less config.tcl` from the wrong directory (e.g., `designs/picorv32a/src` instead of `designs/picorv32a`), since the per-run generated `config.tcl` is written under the design root/run directory, not `src/`. | `cd ..` back to `designs/picorv32a` (or the specific `runs/<run_id>/` folder) before inspecting `config.tcl`. |
| `invalid command name "sudo"` inside the OpenLANE Tcl shell | `sudo` was typed inside the **Tcl interactive prompt** (`%`), not a bash shell — Tcl has no concept of `sudo`. | Drop `sudo` when already inside `flow.tcl -interactive`; just run `less config.tcl` (or exit to bash first if elevated privileges are truly needed). |

**General debugging lesson:** almost every one of these errors was a **path/context confusion** — being in the wrong working directory, or mixing up the bash shell vs. the OpenLANE Tcl shell. Before running any OpenLANE or Magic command, always confirm with `pwd`/`ls` which shell and which directory you are actually in.

---

## Key Takeaways

- OpenLANE orchestrates a **fully open-source RTL-to-GDSII flow**: Yosys/ABC (synthesis) → OpenROAD (floorplan, placement, CTS, global route) → TritonRoute (detailed route) → OpenSTA (timing) → Fault (DFT) → Magic/Netgen (physical verification & GDS streaming).
- **Floorplanning** decisions (utilization, aspect ratio, margins, PDN pitch/offset) directly shape everything downstream — a bad floorplan means congested placement and poor timing no matter how good later stages are.
- **STA must be run at multiple points** — post-synthesis (wireload-based) and post-route (RC-extracted) — because delay estimates change drastically once real layout parasitics are known.
- **DRC and LVS are independent, complementary checks** — DRC verifies manufacturability of shapes; LVS verifies electrical correctness against intent.
- The **antenna-diode strategy** (insert everywhere, swap only where violated) is a clever compromise between area overhead and rip-up-reroute cost.
- **DFT (scan + ATPG)** is what makes a fabricated chip testable after it leaves the fab — without it, internal faults would be undetectable.
- **Regression testing across ~70 reference designs** is what gives confidence that flow/tool/PDK changes don't silently break correctness.
- Sky130 at 130nm is **not obsolete** — mature nodes still represent a large, real share of foundry revenue, which is exactly why an open PDK at this node has lasting value.
- **Placement quality is measured with HPWL and displacement**, not just "did it finish" — legalization and mirroring passes trade a small HPWL penalty for legal, DRC-clean cell positions, and OpenLANE auto-renders KLayout screenshots after each major stage for quick visual sanity checks.
- Every standard cell in the library was itself designed via **circuit design → layout design (guided by Euler's path/stick diagrams) → characterization**, producing the CDL/GDSII/LEF/SPICE views that the entire RTL-to-GDSII flow depends on.
- A cell's `.lib` timing arcs come from **SPICE-level device equations (threshold voltage, linear/saturation Id equations) evaluated against calibrated PDK model parameters**, then measured through a defined **50% in/out threshold + slew-window** methodology — this is the origin of every delay number OpenSTA later reports.
