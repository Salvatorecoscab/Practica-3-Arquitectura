@echo off
REM ****************************************************************************
REM Vivado (TM) v2022.2 (64-bit)
REM
REM Filename    : compile.bat
REM Simulator   : Xilinx Vivado Simulator
REM Description : Script for compiling the simulation design source files
REM
<<<<<<< HEAD
REM Generated by Vivado on Mon Jun 05 02:17:09 -0600 2023
=======
REM Generated by Vivado on Thu Jun 01 01:01:23 -0600 2023
>>>>>>> f1ae9ff44921bf98f78904049001c8f4cba66535
REM SW Build 3671981 on Fri Oct 14 05:00:03 MDT 2022
REM
REM IP Build 3669848 on Fri Oct 14 08:30:02 MDT 2022
REM
REM usage: compile.bat
REM
REM ****************************************************************************
REM compile VHDL design sources
echo "xvhdl --incr --relax -prj main_vhdl.prj"
call xvhdl  --incr --relax -prj main_vhdl.prj -log xvhdl.log
call type xvhdl.log > compile.log
if "%errorlevel%"=="1" goto END
if "%errorlevel%"=="0" goto SUCCESS
:END
exit 1
:SUCCESS
exit 0
