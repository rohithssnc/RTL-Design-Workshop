// battery_protect.v  (single file: debounce + top level)
// Lithium battery pack protection with debounced fault latching.
//
// Pins (16 signal pins):
//   inputs : clk, rst_n, ov, uv, occ, ocd, tick, clear, dbn_sel[1:0]
//   outputs: chg_en, dsg_en, fault[3:0]
//
// Faults (flags are raw comparator outputs, active high):
//   ov  - over-voltage            -> cuts charge
//   uv  - under-voltage           -> cuts discharge
//   occ - over-current on charge  -> cuts charge
//   ocd - over-current on discharge -> cuts discharge
//
// Each flag is debounced (counted in `tick` pulses), then latched into
// fault[3:0] = {ocd, occ, uv, ov}. A latched fault is released only by a
// `clear` that arrives while that fault's raw flag is low.
//
// dbn_sel picks the debounce length in ticks (over-current is twice as fast):
//   dbn_sel   ov / uv    occ / ocd
//     00         2          1
//     01         4          2
//     10         8          4
//     11        16          8
//
// Both MOSFET enables are 0 in reset and switch on after the first clock.
// All inputs are assumed to be synchronous to clk.

// ---------------------------------------------------------------
// Debouncer: trip goes high once `in` has been high for `limit`
// counted ticks in a row. Any low sample restarts the count.
// ---------------------------------------------------------------
module debounce (
    input  wire       clk,
    input  wire       rst_n,    // async active-low reset
    input  wire       tick,     // count enable (slow time base)
    input  wire       in,
    input  wire [4:0] limit,    // ticks required, 1..16
    output wire       trip
);
    reg [4:0] cnt;

    assign trip = (cnt >= limit);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 5'd0;
        else if (!in)
            cnt <= 5'd0;
        else if (tick && !trip)
            cnt <= cnt + 5'd1;      // stops once the limit is reached
    end
endmodule

// ---------------------------------------------------------------
// Top level
// ---------------------------------------------------------------
module battery_protect (
    input  wire       clk,
    input  wire       rst_n,      // async active-low reset
    input  wire       ov,         // over-voltage flag
    input  wire       uv,         // under-voltage flag
    input  wire       occ,        // over-current on charge flag
    input  wire       ocd,        // over-current on discharge flag
    input  wire       tick,       // debounce time-base enable
    input  wire       clear,      // releases latched faults whose flag is gone
    input  wire [1:0] dbn_sel,    // debounce length select
    output reg        chg_en,     // charge MOSFET enable
    output reg        dsg_en,     // discharge MOSFET enable
    output reg  [3:0] fault       // latched faults {ocd, occ, uv, ov}
);
    // debounce limits chosen by dbn_sel
    wire [4:0] lim_v = 5'd2 << dbn_sel;     // ov, uv : 2, 4, 8, 16
    wire [4:0] lim_c = 5'd1 << dbn_sel;     // occ, ocd: 1, 2, 4, 8

    wire ov_trip, uv_trip, occ_trip, ocd_trip;

    debounce u_deb_ov  (.clk(clk), .rst_n(rst_n), .tick(tick), .in(ov),  .limit(lim_v), .trip(ov_trip));
    debounce u_deb_uv  (.clk(clk), .rst_n(rst_n), .tick(tick), .in(uv),  .limit(lim_v), .trip(uv_trip));
    debounce u_deb_occ (.clk(clk), .rst_n(rst_n), .tick(tick), .in(occ), .limit(lim_c), .trip(occ_trip));
    debounce u_deb_ocd (.clk(clk), .rst_n(rst_n), .tick(tick), .in(ocd), .limit(lim_c), .trip(ocd_trip));

    wire [3:0] trip = {ocd_trip, occ_trip, uv_trip, ov_trip};
    wire [3:0] raw  = {ocd,      occ,      uv,      ov};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            chg_en <= 1'b0;
            dsg_en <= 1'b0;
            fault  <= 4'b0000;
        end else begin
            // set on trip; release only on clear while the raw flag is low
            fault <= trip | (fault & ~({4{clear}} & ~raw));

            // ov and occ cut charge; uv and ocd cut discharge
            chg_en <= ~(trip[0] | trip[2] | fault[0] | fault[2]);
            dsg_en <= ~(trip[1] | trip[3] | fault[1] | fault[3]);
        end
    end
endmodule
