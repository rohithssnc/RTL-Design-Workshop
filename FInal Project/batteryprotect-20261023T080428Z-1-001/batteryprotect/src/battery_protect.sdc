# battery_protect.sdc - constraints for all 16 signal pins
# inputs : clk, rst_n, ov, uv, occ, ocd, tick, clear, dbn_sel[1:0]
# outputs: chg_en, dsg_en, fault[3:0]
current_design battery_protect

set clk_period 10.0
create_clock -name clk -period $clk_period [get_ports clk]

set in_delay  [expr {$clk_period * 0.2}]
set out_delay [expr {$clk_period * 0.2}]

set_input_delay  $in_delay  -clock clk [get_ports {rst_n ov uv occ ocd tick clear dbn_sel[*]}]
set_output_delay $out_delay -clock clk [get_ports {chg_en dsg_en fault[*]}]
