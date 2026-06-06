###############################################################################
# Created by write_sdc
###############################################################################
current_design chip_top
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk -period 20.0000 [get_ports {clk}]
set_clock_uncertainty 0.5000 clk
set_propagated_clock [get_clocks {clk}]
create_clock -name sclk_virt -period 1000.0000 [get_ports {sclk}]
set_propagated_clock [get_clocks {sclk_virt}]
set_clock_groups -name group1 -asynchronous \
 -group [get_clocks {clk}]\
 -group [get_clocks {sclk_virt}]
set_input_delay 5.0000 -clock [get_clocks {sclk_virt}] -rise -max -add_delay [get_ports {mosi}]
set_input_delay 5.0000 -clock [get_clocks {sclk_virt}] -fall -max -add_delay [get_ports {mosi}]
set_input_delay 4.0000 -clock [get_clocks {clk}] -rise -max -add_delay [get_ports {rst}]
set_input_delay 4.0000 -clock [get_clocks {clk}] -fall -max -add_delay [get_ports {rst}]
set_input_delay 5.0000 -clock [get_clocks {sclk_virt}] -rise -max -add_delay [get_ports {ss}]
set_input_delay 5.0000 -clock [get_clocks {sclk_virt}] -fall -max -add_delay [get_ports {ss}]
set_output_delay -2.0000 -clock [get_clocks {sclk_virt}] -min -add_delay [get_ports {miso}]
set_output_delay 5.0000 -clock [get_clocks {sclk_virt}] -max -add_delay [get_ports {miso}]
set_false_path\
    -from [list [get_ports {mosi}]\
           [get_ports {sclk}]\
           [get_ports {ss}]]\
    -to [get_clocks {clk}]
###############################################################################
# Environment
###############################################################################
set_load -pin_load 0.1000 [get_ports {miso}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {clk}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {mosi}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {rst}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {sclk}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {ss}]
###############################################################################
# Design Rules
###############################################################################
