set ::env(DESIGN_NAME) "battery_protect"
set ::env(VERILOG_FILES) "$::env(DESIGN_DIR)/src/battery_protect.v"
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "10.0"
set ::env(BASE_SDC_FILE) "$::env(DESIGN_DIR)/src/battery_protect.sdc"

set ::env(FP_SIZING) "absolute"
set ::env(DIE_AREA) "0 0 100 100"
set ::env(CORE_AREA) "5 5 95 95"
set ::env(PL_TARGET_DENSITY) 0.5

set ::env(FP_PDN_VPITCH) 40
set ::env(FP_PDN_HPITCH) 40
set ::env(FP_PDN_VOFFSET) 10
set ::env(FP_PDN_HOFFSET) 10
