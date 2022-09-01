
iverilog -o TrainLED.vvp user_module_341631485498884690.v user_module_341631485498884690_tb.vtb
vvp TrainLED.vvp
# yosys synthtest.ys | grep -i 'Printing' -A 20
gtkwave.exe MCPU5_tb.vcd gtkwave_settings.gtkw
