read_liberty $::env(LIB)
read_verilog battery_protect_final.synthesis.v
link_design battery_protect
read_sdc battery_protect.sdc

puts "=== corner: $::env(CORNER) ==="
puts "--- setup (max) ---"
report_checks -path_delay max -digits 3
puts "--- hold (min) ---"
report_checks -path_delay min -digits 3
puts "--- summary ---"
report_worst_slack -max
report_worst_slack -min
report_tns
