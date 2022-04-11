# TCL File Generated by Component Editor 18.1
# Sun Apr 03 23:18:40 EDT 2022
# DO NOT MODIFY


# 
# de10_vga_raster "de10_vga_raster" v1.0
#  2022.04.03.23:18:40
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module de10_vga_raster
# 
set_module_property DESCRIPTION ""
set_module_property NAME de10_vga_raster
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME de10_vga_raster
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL de10_vga_raster
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file de10_vga_raster.vhd VHDL PATH de10_vga_raster.vhd TOP_LEVEL_FILE


# 
# parameters
# 


# 
# display items
# 


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset reset Input 1


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point avalon_slave_0
# 
add_interface avalon_slave_0 avalon end
set_interface_property avalon_slave_0 addressUnits WORDS
set_interface_property avalon_slave_0 associatedClock clock
set_interface_property avalon_slave_0 associatedReset reset
set_interface_property avalon_slave_0 bitsPerSymbol 8
set_interface_property avalon_slave_0 burstOnBurstBoundariesOnly false
set_interface_property avalon_slave_0 burstcountUnits WORDS
set_interface_property avalon_slave_0 explicitAddressSpan 0
set_interface_property avalon_slave_0 holdTime 0
set_interface_property avalon_slave_0 linewrapBursts false
set_interface_property avalon_slave_0 maximumPendingReadTransactions 0
set_interface_property avalon_slave_0 maximumPendingWriteTransactions 0
set_interface_property avalon_slave_0 readLatency 0
set_interface_property avalon_slave_0 readWaitTime 1
set_interface_property avalon_slave_0 setupTime 0
set_interface_property avalon_slave_0 timingUnits Cycles
set_interface_property avalon_slave_0 writeWaitTime 0
set_interface_property avalon_slave_0 ENABLED true
set_interface_property avalon_slave_0 EXPORT_OF ""
set_interface_property avalon_slave_0 PORT_NAME_MAP ""
set_interface_property avalon_slave_0 CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave_0 SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave_0 read read Input 1
add_interface_port avalon_slave_0 write write Input 1
add_interface_port avalon_slave_0 chipselect chipselect Input 1
add_interface_port avalon_slave_0 address address Input 4
add_interface_port avalon_slave_0 readdata readdata Output 16
add_interface_port avalon_slave_0 writedata writedata Input 16
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point vga_b
# 
add_interface vga_b conduit end
set_interface_property vga_b associatedClock clock
set_interface_property vga_b associatedReset ""
set_interface_property vga_b ENABLED true
set_interface_property vga_b EXPORT_OF ""
set_interface_property vga_b PORT_NAME_MAP ""
set_interface_property vga_b CMSIS_SVD_VARIABLES ""
set_interface_property vga_b SVD_ADDRESS_GROUP ""

add_interface_port vga_b VGA_B export Output 8


# 
# connection point vga_g
# 
add_interface vga_g conduit end
set_interface_property vga_g associatedClock clock
set_interface_property vga_g associatedReset ""
set_interface_property vga_g ENABLED true
set_interface_property vga_g EXPORT_OF ""
set_interface_property vga_g PORT_NAME_MAP ""
set_interface_property vga_g CMSIS_SVD_VARIABLES ""
set_interface_property vga_g SVD_ADDRESS_GROUP ""

add_interface_port vga_g VGA_G export Output 8


# 
# connection point vga_blank
# 
add_interface vga_blank conduit end
set_interface_property vga_blank associatedClock clock
set_interface_property vga_blank associatedReset ""
set_interface_property vga_blank ENABLED true
set_interface_property vga_blank EXPORT_OF ""
set_interface_property vga_blank PORT_NAME_MAP ""
set_interface_property vga_blank CMSIS_SVD_VARIABLES ""
set_interface_property vga_blank SVD_ADDRESS_GROUP ""

add_interface_port vga_blank VGA_BLANK export Output 1


# 
# connection point vga_clk
# 
add_interface vga_clk conduit end
set_interface_property vga_clk associatedClock clock
set_interface_property vga_clk associatedReset ""
set_interface_property vga_clk ENABLED true
set_interface_property vga_clk EXPORT_OF ""
set_interface_property vga_clk PORT_NAME_MAP ""
set_interface_property vga_clk CMSIS_SVD_VARIABLES ""
set_interface_property vga_clk SVD_ADDRESS_GROUP ""

add_interface_port vga_clk VGA_CLK export Output 1


# 
# connection point vga_hs
# 
add_interface vga_hs conduit end
set_interface_property vga_hs associatedClock clock
set_interface_property vga_hs associatedReset ""
set_interface_property vga_hs ENABLED true
set_interface_property vga_hs EXPORT_OF ""
set_interface_property vga_hs PORT_NAME_MAP ""
set_interface_property vga_hs CMSIS_SVD_VARIABLES ""
set_interface_property vga_hs SVD_ADDRESS_GROUP ""

add_interface_port vga_hs VGA_HS export Output 1


# 
# connection point vga_r
# 
add_interface vga_r conduit end
set_interface_property vga_r associatedClock clock
set_interface_property vga_r associatedReset ""
set_interface_property vga_r ENABLED true
set_interface_property vga_r EXPORT_OF ""
set_interface_property vga_r PORT_NAME_MAP ""
set_interface_property vga_r CMSIS_SVD_VARIABLES ""
set_interface_property vga_r SVD_ADDRESS_GROUP ""

add_interface_port vga_r VGA_R export Output 8


# 
# connection point vga_sync
# 
add_interface vga_sync conduit end
set_interface_property vga_sync associatedClock clock
set_interface_property vga_sync associatedReset ""
set_interface_property vga_sync ENABLED true
set_interface_property vga_sync EXPORT_OF ""
set_interface_property vga_sync PORT_NAME_MAP ""
set_interface_property vga_sync CMSIS_SVD_VARIABLES ""
set_interface_property vga_sync SVD_ADDRESS_GROUP ""

add_interface_port vga_sync VGA_SYNC export Output 1


# 
# connection point vga_vs
# 
add_interface vga_vs conduit end
set_interface_property vga_vs associatedClock clock
set_interface_property vga_vs associatedReset ""
set_interface_property vga_vs ENABLED true
set_interface_property vga_vs EXPORT_OF ""
set_interface_property vga_vs PORT_NAME_MAP ""
set_interface_property vga_vs CMSIS_SVD_VARIABLES ""
set_interface_property vga_vs SVD_ADDRESS_GROUP ""

add_interface_port vga_vs VGA_VS export Output 1

