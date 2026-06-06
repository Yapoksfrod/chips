set ::env(LIB) "\"*_tt_025C_1v80\" /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib \"*_ss_100C_1v60\" /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib \"*_ff_n40C_1v95\" /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ff_n40C_1v95.lib"
set ::env(STEP_ID) OpenROAD.STAPrePNR
set ::env(TECH_LEF) /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
set ::env(MACRO_LEFS) ""
set ::env(STD_CELL_LIBRARY) sky130_fd_sc_hd
set ::env(VDD_PIN) VPWR
set ::env(VDD_PIN_VOLTAGE) 1.80
set ::env(GND_PIN) VGND
set ::env(TECH_LEFS) "\"nom_*\" /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef \"min_*\" /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__min.tlef \"max_*\" /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__max.tlef"
set ::env(GPIO_PADS_LEF) "/foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_io/lef/sky130_fd_io.lef /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_io/lef/sky130_ef_io.lef"
set ::env(GPIO_PADS_LEF_CORE_SIDE) "/foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.tech/openlane/custom_cells/lef/sky130_fd_io_core.lef /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.tech/openlane/custom_cells/lef/sky130_ef_io_core.lef"
set ::env(GPIO_PADS_VERILOG) /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_io/verilog/sky130_ef_io.v
set ::env(GPIO_PAD_CELLS) "\"sky130_fd_io*\" \"sky130_ef_io*\""
set ::env(PRIMARY_GDSII_STREAMOUT_TOOL) magic
set ::env(DEFAULT_CORNER) nom_tt_025C_1v80
set ::env(STA_CORNERS) "nom_tt_025C_1v80 nom_ss_100C_1v60 nom_ff_n40C_1v95 min_tt_025C_1v80 min_ss_100C_1v60 min_ff_n40C_1v95 max_tt_025C_1v80 max_ss_100C_1v60 max_ff_n40C_1v95"
set ::env(FP_TRACKS_INFO) /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.tech/openlane/sky130_fd_sc_hd/tracks.info
set ::env(FP_TAPCELL_DIST) 13
set ::env(FP_IO_HLAYER) met3
set ::env(FP_IO_VLAYER) met2
set ::env(RT_MIN_LAYER) met1
set ::env(RT_MAX_LAYER) met5
set ::env(SCL_GROUND_PINS) "VGND VNB"
set ::env(SCL_POWER_PINS) "VPWR VPB"
set ::env(TRISTATE_CELLS) "\"sky130_fd_sc_hd__ebuf*\""
set ::env(FILL_CELL) "sky130_fd_sc_hd__fill_2 sky130_fd_sc_hd__fill_1"
set ::env(DECAP_CELL) sky130_fd_sc_hd__decap_3
set ::env(CELL_LEFS) "/foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_ef_sc_hd.lef"
set ::env(CELL_GDS) /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds
set ::env(CELL_VERILOG_MODELS) "/foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"
set ::env(CELL_BB_VERILOG_MODELS) "/foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd__blackbox.v /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd__blackbox_pp.v"
set ::env(CELL_SPICE_MODELS) "/foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_ef_sc_hd__decap_12.spice /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_ef_sc_hd__decap_20_12.spice /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_ef_sc_hd__decap_40_12.spice /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_ef_sc_hd__decap_60_12.spice /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_ef_sc_hd__decap_80_12.spice /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_ef_sc_hd__fill_12.spice /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_ef_sc_hd__fill_2.spice /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_ef_sc_hd__fill_4.spice /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_ef_sc_hd__fill_8.spice /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_fd_sc_hd.spice"
set ::env(SYNTH_EXCLUDED_CELL_FILE) /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.tech/openlane/sky130_fd_sc_hd/no_synth.cells
set ::env(PNR_EXCLUDED_CELL_FILE) /foss/pdks/ciel/sky130/versions/d400e26845538beaeb7cc5fdb9bfc06c30ea27cb/sky130A/libs.tech/openlane/sky130_fd_sc_hd/drc_exclude.cells
set ::env(OUTPUT_CAP_LOAD) 33.442
set ::env(MAX_FANOUT_CONSTRAINT) 10
set ::env(MAX_TRANSITION_CONSTRAINT) 0.75
set ::env(MAX_CAPACITANCE_CONSTRAINT) 0.2
set ::env(CLOCK_UNCERTAINTY_CONSTRAINT) 0.25
set ::env(CLOCK_TRANSITION_CONSTRAINT) 0.1499999999999999944488848768742172978818416595458984375
set ::env(TIME_DERATING_CONSTRAINT) 5
set ::env(IO_DELAY_CONSTRAINT) 20
set ::env(SYNTH_DRIVING_CELL) sky130_fd_sc_hd__inv_2/Y
set ::env(SYNTH_TIEHI_CELL) sky130_fd_sc_hd__conb_1/HI
set ::env(SYNTH_TIELO_CELL) sky130_fd_sc_hd__conb_1/LO
set ::env(SYNTH_BUFFER_CELL) sky130_fd_sc_hd__buf_2/A/X
set ::env(WELLTAP_CELL) sky130_fd_sc_hd__tapvpwrvgnd_1
set ::env(ENDCAP_CELL) sky130_fd_sc_hd__decap_3
set ::env(PLACE_SITE) unithd
set ::env(CELL_PAD_EXCLUDE) "\"sky130_fd_sc_hd__tap*\" \"sky130_fd_sc_hd__decap*\" \"sky130_ef_sc_hd__decap*\" \"sky130_fd_sc_hd__fill*\""
set ::env(DIODE_CELL) sky130_fd_sc_hd__diode_2/DIODE
set ::env(DESIGN_NAME) chip_top
set ::env(CLOCK_PERIOD) 20.0
set ::env(CLOCK_PORT) clk
set ::env(CLOCK_NET) clk
set ::env(FALLBACK_SDC_FILE) /foss/designs/chip_top/constraints.sdc
set ::env(PDN_CONNECT_MACROS_TO_GRID) 1
set ::env(PDN_ENABLE_GLOBAL_CONNECTIONS) 1
set ::env(PNR_SDC_FILE) /foss/designs/chip_top/constraints.sdc
set ::env(STA_MACRO_PRIORITIZE_NL) 1
set ::env(CURRENT_NETLIST) /foss/designs/chip_top/runs/RUN_2026-06-06_06-39-23/06-yosys-synthesis/chip_top.nl.v
set ::env(SAVE_SDC) /foss/designs/chip_top/runs/RUN_2026-06-06_06-39-23/12-openroad-staprepnr/chip_top.sdc
set ::env(OPENLANE_SDC_IDEAL_CLOCKS) 1
