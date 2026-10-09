`timescale 1ns / 1ps

module top_fifo_ext (
    input logic clk,
    input logic rst,
    input logic wr_en,
    input logic [7:0] wr_data,
    input logic rd_en,
    output logic [7:0] rd_data,
    output logic empty,
    output logic full,
    output logic [4:0]level,
    input logic [4:0] almost_full_threshold,
    input logic [4:0] almost_empty_threshold,
    output logic almost_full,
    output logic almost_empty
);

    fifo_ext #(
        .WIDTH(8),
        .DEPTH(16)
    ) fifo_inst (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .empty(empty),
        .full(full),
        .level(level),
        .almost_full_threshold(almost_full_threshold),
        .almost_empty_threshold(almost_empty_threshold),
        .almost_full(almost_full),
        .almost_empty(almost_empty)
    );

endmodule