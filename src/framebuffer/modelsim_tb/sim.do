# cd D:/FPGA_Prj/Ti180/TI180_LPDDR4_EXAMPLE/efx_ti180M484_mem_test_lpddr4x_v6/src
vlib work 

vlog ./lpddr4_tb.v
vlog ./../ddr_wr_buffer.v
vlog ./../ddr_rd_buffer.v
vlog ./../frame_buffer.v
vlog ./../DC_FIFO.v
vlog ./axi_ram.v
vlog ./../ddr_buffer.v
vlog ./../rst_n_piple.v
vlog ./../ser2par_24_128_v1.v
vlog ./../vid_rx_align_v1.v
vlog ./../color_bar_rgb.v
vlog ./../frame_info_det.v
vlog ./../ser2par.v
vlog ./../data_tx.v
vlog ./../par2ser_512t128.v
vlog ./../par2ser_parse.v
vlog ./../par2ser_128_24_v1.v
vlog ./../par2ser_128_16_v1.v
vlog ./../par2ser_128_32_v1.v
vlog ./../fifo_d512t128.v
vlog ./../bank_switch.v
vlog ./../color_bar_checker.v
vsim -t ps  -voptargs=+acc work.lpddr4_tb

#virtual type { {4'b0000 IDLE} { 4'b0001 WRITE_ADDR} { 4'b0010 PRE_WRITE} { 4'b0011 WRITE} { 4'b0100 POST_WRITE}} state_type
#virtual function {(state_type)/checker0/u_ddr_buffer/u_axi_write/states} fsm_state

#virtual type { {4'b0000 IDLE} { 4'b0001 WRITE_ADDR} { 4'b0010 PRE_WRITE} { 4'b0011 WRITE} { 4'b0100 POST_WRITE}} nx_state
#virtual function {(nx_state)/checker0/u_ddr_buffer/u_axi_write/nstates} nxstate 
#add wave -color pink /u_mipi_dsi_rx/fsm_state 

#virtual type { {4'b0000 IDLE} { 4'b0001 READ_ADDR} { 4'b0010 READ}} rd_state_type
#virtual function {(rd_state_type)/checker0/u_ddr_buffer/u_axi_read/states} rd_state



do wave.do
run 5000us