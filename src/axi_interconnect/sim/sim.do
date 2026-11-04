
vlib work

vlog -f vlog-rtl.list 
vopt +acc=npr tb_top -o tb_top_opt

vsim tb_top_opt
do wave.do
run 2us
