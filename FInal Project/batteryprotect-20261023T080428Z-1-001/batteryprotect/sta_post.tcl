read_liberty $::env(LIB)
read_verilog $::env(NETLIST)
link_design battery_protect
read_sdc src/battery_protect.sdc
set_propagated_clock [all_clocks]
read_spef $::env(SPEF)
puts "=== POST-ROUTE corner: $::env(CORNER) ==="
puts "--- SETUP (max) ---"
report_checks -path_delay max -format full_clock_expanded -digits 3
puts "--- HOLD (min) ---"
report_checks -path_delay min -format full_clock_expanded -digits 3
puts "--- SUMMARY ---"
report_worst_slack -max
report_worst_slack -min
report_tns
report_clock_skew
