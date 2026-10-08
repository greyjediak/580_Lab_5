`timescale 1ns / 1ps

module ram_wrapper #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 16,
    parameter int ADDR_W = $clog2(DEPTH)
)(
    input logic clk,
    input logic rst,
    input logic wr_en,
    input logic [ADDR_W-1:0] wr_addr,
    input logic [WIDTH-1:0] wr_data,
    input logic rd_en,
    input logic [ADDR_W-1:0] rd_addr,
    output logic [WIDTH-1:0] rd_data
);

    ram #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) ram_inst (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

endmodule