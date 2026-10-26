
create_clock -name clk_50MHz -period 20.000 [get_ports {clk_50MHz}]

derive_clock_uncertainty
