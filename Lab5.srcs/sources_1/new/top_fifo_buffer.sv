`timescale 1ns / 1ps

module top_fifo_buffer (
    input logic clk,
    input logic rst,
    input logic wr_en,
    input logic [7:0] wr_data,
    input logic rd_en,
    output logic [7:0] rd_data,
    output logic empty,
    output logic full
);

    fifo_buffer #(
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
        .full(full)
    );

endmodule