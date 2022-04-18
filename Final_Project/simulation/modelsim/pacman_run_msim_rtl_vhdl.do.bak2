transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/map_vga8_640x480.vhd}
vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/red1_vga8_25x25.vhd}
vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/red2_vga8_25x25.vhd}
vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/cyan1_vga8_25x25.vhd}
vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/cyan2_vga8_25x25.vhd}
vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/orange1_vga8_25x25.vhd}
vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/orange2_vga8_25x25.vhd}
vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/pink1_vga8_25x25.vhd}
vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/pink2_vga8_25x25.vhd}
vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/scared1_vga8_25x25.vhd}
vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/scared2_vga8_25x25.vhd}
vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/pacmanopen_vga8_25x25.vhd}
vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/pacmanclosed_vga8_25x25.vhd}
vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/de10_vga_raster.vhd}

vcom -93 -work work {C:/Users/Jonathan/Documents/Complex_Digital_Logic/Final_Project/de10_vga_raster_tb.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cyclonev -L rtl_work -L work -voptargs="+acc"  de10_vga_raster_tb

add wave *
view structure
view signals
run -all
