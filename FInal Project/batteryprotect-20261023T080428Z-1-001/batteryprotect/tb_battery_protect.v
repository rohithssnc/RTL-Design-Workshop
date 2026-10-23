`timescale 1ns/1ps
// Single self-checking testbench for battery_protect (16-pin version).
//   Part A tests the debounce module on its own   (skipped with -DGLS,
//          because a flattened gate-level netlist has no debounce module)
//   Part B tests the battery_protect top level
//
// Compile:  RTL  -> iverilog -o rtl_sim battery_protect.v tb_battery_protect.v
//           GLS  -> iverilog -DGLS -DFUNCTIONAL -o gls_sim <sky130 models> battery_protect_net.v tb_battery_protect.v
`ifdef GLS
    `define SETTLE #4      // gate-level: let unit delays settle before sampling
`else
    `define SETTLE #1
`endif
module tb_battery_protect;
    reg  clk = 0;
    always #5 clk = ~clk;

`ifndef GLS
    // ---------------- Part A signals: standalone debounce ----------------
    localparam DN = 4;
    reg  d_rst_n = 1, d_in = 0, d_tick = 1;
    wire d_trip;
    debounce dut_deb (.clk(clk), .rst_n(d_rst_n), .tick(d_tick), .in(d_in),
                      .limit(5'd4), .trip(d_trip));
`endif

    // ---------------- Part B signals: top level ----------------
    reg        rst_n = 1;
    reg        ov = 0, uv = 0, occ = 0, ocd = 0, clear = 0;
    reg  [1:0] dbn_sel = 2'b01;          // ov/uv = 4 ticks, occ/ocd = 2 ticks
    reg        tick_fast = 1;            // 1: tick high every cycle, 0: every 4th cycle
    reg  [1:0] tdiv = 0;
    always @(posedge clk) if (!rst_n) tdiv <= 0; else tdiv <= tdiv + 1;   // restarts at each reset so RTL and GLS line up
    wire       tick = tick_fast | (tdiv == 2'd0);
    wire       chg_en, dsg_en;
    wire [3:0] fault;

    battery_protect dut (
        .clk(clk), .rst_n(rst_n),
        .ov(ov), .uv(uv), .occ(occ), .ocd(ocd),
        .tick(tick), .clear(clear), .dbn_sel(dbn_sel),
        .chg_en(chg_en), .dsg_en(dsg_en), .fault(fault));

    integer errors = 0;
    integer i, s, vt, ct;

    // watch for any unwanted cut-off (used by the glitch tests)
    reg watch = 0, cut_seen = 0;
    always @(posedge clk)
        if (watch && (chg_en === 1'b0 || dsg_en === 1'b0)) cut_seen <= 1;

    // text log of the top-level signals, so RTL and gate-level runs can be diffed
    initial $monitor("%0t rst=%b ov=%b uv=%b occ=%b ocd=%b clr=%b sel=%b | chg=%b dsg=%b flt=%b",
                     $time, rst_n, ov, uv, occ, ocd, clear, dbn_sel, chg_en, dsg_en, fault);

    // ---- per-clock log for exact RTL-vs-GLS comparison (starts at the first reset of Part B) ----
    integer cyc = 0;
    reg     logging = 0;
    always @(negedge rst_n) logging <= 1;
    always @(negedge clk)
        if (logging) begin
            #3;                              // sample 8 ns after the rising edge, well after every input and output has settled
            cyc = cyc + 1;
            $display("CYC %0d rst=%b ov=%b uv=%b occ=%b ocd=%b clr=%b sel=%b tick=%b | chg=%b dsg=%b flt=%b",
                     cyc, rst_n, ov, uv, occ, ocd, clear, dbn_sel, tick, chg_en, dsg_en, fault);
        end

    task check(input cond, input [8*52-1:0] msg);
        begin
            if (!cond) begin
                errors = errors + 1;
                $display("FAIL @%0t: %0s", $time, msg);
            end
        end
    endtask

    task wait_cycles(input integer n);
        begin repeat (n) @(posedge clk); `SETTLE; end
    endtask

    // hold flags {ocd,occ,uv,ov} high for n cycles, then low
    task pulse(input [3:0] mask, input integer n);
        begin
            ov = mask[0]; uv = mask[1]; occ = mask[2]; ocd = mask[3];
            wait_cycles(n);
            ov = 0; uv = 0; occ = 0; ocd = 0;
        end
    endtask

    task do_clear;
        begin clear = 1; wait_cycles(3); clear = 0; end
    endtask

    task all_ok(input [8*52-1:0] tag);
        begin
            check(chg_en === 1 && dsg_en === 1, tag);
            check(fault === 4'b0000, tag);
        end
    endtask

    initial begin
        $dumpfile("tb_battery_protect.vcd");
        $dumpvars(0, tb_battery_protect);

`ifndef GLS
        // =========================================================
        // Part A: debounce module (reset signal starts at 1 so
        // asserting it is a real falling edge)
        // =========================================================
        #1 d_rst_n = 0;
        #11;
        check(d_trip === 1'b0, "A1 trip low during reset");
        d_rst_n = 1;
        @(posedge clk); #1;
        check(d_trip === 1'b0, "A1 trip low after reset, in=0");

        // glitch shorter than the limit: no trip
        d_in = 1;
        for (i = 1; i < DN; i = i + 1) begin
            @(posedge clk); #1;
            check(d_trip === 1'b0, "A2 no trip before limit reached");
        end
        d_in = 0; @(posedge clk); #1;
        check(d_trip === 1'b0, "A2 no trip after limit-1 pulse");

        // exactly the limit: trips, holds, drops with the input
        d_in = 1;
        repeat (DN) @(posedge clk);
        #1 check(d_trip === 1'b1, "A3 trip after exactly limit ticks");
        repeat (5) @(posedge clk);
        #1 check(d_trip === 1'b1, "A3 trip holds while input high");
        d_in = 0; @(posedge clk); #1;
        check(d_trip === 1'b0, "A3 trip drops when input drops");

        // interrupted count restarts
        d_in = 1; repeat (DN-1) @(posedge clk);
        #1 d_in = 0; @(posedge clk);
        #1 d_in = 1; repeat (DN-1) @(posedge clk);
        #1 check(d_trip === 1'b0, "A4 interrupted count must restart");
        d_in = 0; @(posedge clk);

        // counting only advances on tick
        d_tick = 0; d_in = 1;
        repeat (12) @(posedge clk);
        #1 check(d_trip === 1'b0, "A5 no counting while tick is low");
        d_tick = 1;
        repeat (DN) @(posedge clk);
        #1 check(d_trip === 1'b1, "A5 trips after limit ticks");
        d_in = 0; @(posedge clk); #1;

        // reset while tripped clears the output
        d_in = 1; repeat (DN+2) @(posedge clk);
        #1 check(d_trip === 1'b1, "A6 tripped before reset");
        d_rst_n = 0; #1;
        check(d_trip === 1'b0, "A6 async reset clears trip");
        #10 d_rst_n = 1; d_in = 0;
        @(posedge clk); #1;
        check(d_trip === 1'b0, "A6 trip low after second reset");
`endif

        // =========================================================
        // Part B: battery_protect top level (dbn_sel = 01: VT=4, CT=2)
        // =========================================================
        vt = 4; ct = 2;

        // B1: reset
        @(posedge clk);                      // start Part B on a clock edge, so RTL and GLS runs have the same phase
        #2 rst_n = 0;
        #11;
        check(chg_en === 0 && dsg_en === 0, "B1 outputs off in reset");
        check(fault === 4'b0000, "B1 no faults in reset");

        // B2: outputs switch on after reset
        rst_n = 1;
        wait_cycles(2);
        all_ok("B2 outputs on after reset");

        // B3: short glitches on every flag are ignored
        cut_seen = 0; watch = 1;
        pulse(4'b0001, vt - 1); wait_cycles(4);
        pulse(4'b0010, vt - 1); wait_cycles(4);
        pulse(4'b0100, ct - 1); wait_cycles(4);
        pulse(4'b1000, ct - 1); wait_cycles(4);
        watch = 0;
        check(cut_seen === 0, "B3 short glitches must not cut");
        all_ok("B3 still normal");

        // B4: OV exactly at the limit trips; cuts charge only; stays latched
        pulse(4'b0001, vt);
        wait_cycles(1);
        check(fault === 4'b0001 && chg_en === 0 && dsg_en === 1, "B4 OV trips at limit, cuts charge only");
        wait_cycles(10);
        check(fault === 4'b0001 && chg_en === 0, "B4 OV stays latched after flag drops");
        do_clear;
        all_ok("B4 clear releases OV");

        // B5: sustained OV: clear ignored while present, latched after it ends
        ov = 1; wait_cycles(vt + 4);
        check(fault === 4'b0001 && chg_en === 0 && dsg_en === 1, "B5 OV sustained");
        do_clear;
        check(fault === 4'b0001 && chg_en === 0, "B5 clear ignored while OV present");
        ov = 0; wait_cycles(5);
        check(fault === 4'b0001 && chg_en === 0, "B5 OV still latched after flag gone");
        do_clear;
        all_ok("B5 OV released by clear");

        // B6: UV cuts discharge only, same latching
        uv = 1; wait_cycles(vt + 4);
        check(fault === 4'b0010 && dsg_en === 0 && chg_en === 1, "B6 UV cuts discharge only");
        do_clear;
        check(fault === 4'b0010 && dsg_en === 0, "B6 clear ignored while UV present");
        uv = 0; wait_cycles(5);
        check(fault === 4'b0010 && dsg_en === 0, "B6 UV still latched after flag gone");
        do_clear;
        all_ok("B6 UV released by clear");

        // B7: charge over-current cuts charge only
        pulse(4'b0100, ct);
        wait_cycles(2);
        check(fault === 4'b0100 && chg_en === 0 && dsg_en === 1, "B7 OCC cuts charge only");
        wait_cycles(10);
        check(fault === 4'b0100 && chg_en === 0, "B7 OCC stays latched");
        do_clear;
        all_ok("B7 clear releases OCC");

        // B8: discharge over-current cuts discharge only; clear ignored while present
        ocd = 1; wait_cycles(ct + 4);
        check(fault === 4'b1000 && dsg_en === 0 && chg_en === 1, "B8 OCD cuts discharge only");
        do_clear;
        check(fault === 4'b1000 && dsg_en === 0, "B8 clear ignored while OCD present");
        ocd = 0; wait_cycles(10);
        check(fault === 4'b1000 && dsg_en === 0, "B8 OCD still latched after flag gone");
        do_clear;
        all_ok("B8 released by clear after OCD gone");

        // B9: all four at once
        pulse(4'b1111, vt + 2);
        wait_cycles(1);
        check(fault === 4'b1111, "B9 all four faults latched");
        check(chg_en === 0 && dsg_en === 0, "B9 both MOSFETs off");
        wait_cycles(4);
        check(fault === 4'b1111 && chg_en === 0 && dsg_en === 0, "B9 all still latched after flags gone");
        do_clear;
        all_ok("B9 recovered after clear");

        // B10: flag drops mid-debounce, count restarts
        cut_seen = 0; watch = 1;
        ov = 1; wait_cycles(vt - 1);
        ov = 0; wait_cycles(1);
        ov = 1; wait_cycles(vt - 1);
        ov = 0; wait_cycles(4);
        watch = 0;
        check(cut_seen === 0, "B10 split pulses must not trip");

        // B11: clear with no fault is harmless
        do_clear;
        all_ok("B11 clear with no fault changes nothing");

        // B12: clear releases only faults whose flag is gone
        pulse(4'b0001, vt);                  // OV latched, flag gone
        wait_cycles(4);
        uv = 1; wait_cycles(vt + 4);         // UV latched, flag still present
        do_clear;
        check(fault === 4'b0010 && chg_en === 1 && dsg_en === 0, "B12 OV released, UV held while present");
        uv = 0; wait_cycles(4);
        do_clear;
        all_ok("B12 UV released after flag gone");

        // B13: every dbn_sel setting trips at exactly its own limit
        for (s = 0; s < 4; s = s + 1) begin
            dbn_sel = s[1:0];
            vt = 2 << s;                     // ov / uv limit
            ct = 1 << s;                     // occ / ocd limit
            wait_cycles(2);

            cut_seen = 0; watch = 1;
            pulse(4'b0001, vt - 1); wait_cycles(4);
            pulse(4'b0010, vt - 1); wait_cycles(4);
            if (ct > 1) begin
                pulse(4'b0100, ct - 1); wait_cycles(4);
                pulse(4'b1000, ct - 1); wait_cycles(4);
            end
            watch = 0;
            check(cut_seen === 0, "B13 limit-1 pulse must not trip");

            pulse(4'b0001, vt); wait_cycles(2);
            check(fault === 4'b0001, "B13 OV trips at its limit");
            do_clear;
            pulse(4'b0010, vt); wait_cycles(2);
            check(fault === 4'b0010, "B13 UV trips at its limit");
            do_clear;
            pulse(4'b0100, ct); wait_cycles(2);
            check(fault === 4'b0100, "B13 OCC trips at its limit");
            do_clear;
            pulse(4'b1000, ct); wait_cycles(2);
            check(fault === 4'b1000, "B13 OCD trips at its limit");
            do_clear;
            all_ok("B13 clean after sel sweep");
        end
        dbn_sel = 2'b01; vt = 4; ct = 2;
        wait_cycles(2);

        // B14: slow tick (one tick every 4 cycles) stretches the debounce
        tick_fast = 0;
        wait_cycles(4);
        cut_seen = 0; watch = 1;
        ov = 1; wait_cycles(8);              // only 2 ticks, needs 4
        ov = 0; wait_cycles(8);
        watch = 0;
        check(cut_seen === 0, "B14 too few ticks must not trip");
        ov = 1; wait_cycles(24);             // at least 4 ticks
        check(fault === 4'b0001 && chg_en === 0, "B14 trips with enough ticks");
        ov = 0; wait_cycles(8);
        do_clear; wait_cycles(4);
        all_ok("B14 recovered");
        tick_fast = 1;
        wait_cycles(2);

        // B15: reset during faults clears everything and turns outputs off
        ov = 1; ocd = 1; wait_cycles(vt + 4);
        check(fault === 4'b1001, "B15 faults present");
        rst_n = 0; #2;                       // async reset; #2 lets gate-level unit delays settle
        check(chg_en === 0 && dsg_en === 0, "B15 reset forces outputs off");
        check(fault === 4'b0000, "B15 reset clears faults");
        wait_cycles(1); rst_n = 1; ov = 0; ocd = 0;   // release one clock later, so RTL and GLS see the same number of reset clocks
        wait_cycles(3);
        all_ok("B15 normal after reset");

        if (errors == 0) $display("tb_battery_protect: PASS");
        else             $display("tb_battery_protect: FAIL (%0d errors)", errors);
        $finish;
    end

    initial begin
        #400000;
        $display("tb_battery_protect: TIMEOUT");
        $finish;
    end
endmodule