## Project Overview
This project contains a parameterized synchronous RAM and a parameterized FIFO buffer.
The _ext versions of the FIFO add a level output and programmable almost-full and
almost-empty flags for the 581 implementation.

## File Hierarchy
src/ram.sv // parameterized RAM with synchronous read
src/top_ram.sv // top level module for RAM (8-bit x 1024)
src/fifo_buffer.sv // used for 481
src/top_fifo_buffer.sv // top level module for FIFO (8-bit x 16)
src/fifo_ext.sv // 581 FIFO with level, almost_full, and almost_empty
src/top_fifo_ext.sv // updated top level module for 581
sim/tb_ram.sv // parameterized 8x8 and 4x16 implementations testing
sim/tb_fifo_buffer.sv // 481 testbench, parameterized 8x4 and 4x5 implementations testing
sim/tb_fifo_ext.sv // 581 testbench
lab5_report.pdf
constr/Basys-3-Master.xdc //constraints file for this project

## AI Disclosure and Overview
Claude was used to write this README based off of my own READMEs from previous labs. No AI was used to generate the lab report, figures, or solutions.