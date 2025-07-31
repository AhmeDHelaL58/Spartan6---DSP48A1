vlib work
vlog reg_or_wire.v
vlog DSP_48_A1.v
vlog TB_DSP_48_A1.v

vsim -voptargs=+acc work.DSP48A1_tb

add wave *

run -all

# quit -sim
