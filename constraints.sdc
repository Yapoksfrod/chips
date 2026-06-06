create_clock -name clk -period 20.0 -waveform {0 10} [get_ports clk]
create_clock -name sclk_virt -period 1000.0           [get_ports sclk]

set_clock_groups -asynchronous \
    -group [get_clocks clk] \
    -group [get_clocks sclk_virt]

set_clock_uncertainty 0.5 [get_clocks clk]

set_input_delay  -clock sclk_virt -max  5.0 [get_ports mosi]
set_input_delay  -clock sclk_virt -max  5.0 [get_ports sclk]
set_input_delay  -clock sclk_virt -max  5.0 [get_ports ss]
set_input_delay  -clock clk       -max  4.0 [get_ports rst]

set_output_delay -clock sclk_virt -max  5.0 [get_ports miso]
set_output_delay -clock sclk_virt -min -2.0 [get_ports miso]

set_load 0.1 [get_ports miso]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y \
    [get_ports {clk rst sclk ss mosi}]

set_false_path -from [get_ports {sclk ss mosi}] -to [get_clocks clk]