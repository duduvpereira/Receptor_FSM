vcom -cover sbcexf ./rcv_fsm.vhd
vcom -cover sbcexf ./testbench.vhd

vsim -novopt -coverage -wlf /tmp/testbench -wlfdeleteonquit work.rcv_fsm_tb

do /home/vlsi1_g07/TP3_FSM/wave.do

run 100000 ns

coverage report -file report_code_coverage.txt
