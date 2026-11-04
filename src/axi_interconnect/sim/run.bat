@set modelsim=D:\IdeApp\modeltech64_10.5\win64\vsim.exe
@if exist vsim.wlf del vsim.wlf
%modelsim% -do tcl.do
