connect -url tcp:127.0.0.1:3121
source C:/Users/WH/Amro_PZ101/1030_latest/pz101_NO_OS_PPS_1030_intr_udp/PZ_PZP101_NO_OS.sdk/system_top_hw_platform_0/ps7_init.tcl
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent JTAG-SMT1 210203859289A"} -index 0
loadhw -hw C:/Users/WH/Amro_PZ101/1030_latest/pz101_NO_OS_PPS_1030_intr_udp/PZ_PZP101_NO_OS.sdk/system_top_hw_platform_0/system.hdf -mem-ranges [list {0x40000000 0xbfffffff}]
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent JTAG-SMT1 210203859289A"} -index 0
stop
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent JTAG-SMT1 210203859289A"} -index 0
rst -processor
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent JTAG-SMT1 210203859289A"} -index 0
dow C:/Users/WH/Amro_PZ101/1030_latest/pz101_NO_OS_PPS_1030_intr_udp/PZ_PZP101_NO_OS.sdk/test/Debug/test.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent JTAG-SMT1 210203859289A"} -index 0
con
