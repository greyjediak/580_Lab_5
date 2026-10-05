`timescale 1ns / 1ps
// similar to our register bank, except this time the read ports are synchronous


module ram #(parameter int WIDTH = 4, parameter int DEPTH = 2, parameter int ADDR_W = $clog2(DEPTH))(
    input logic clk,
    input logic rst,
    input logic wr_en,
    input logic[ADDR_W-1:0] wr_addr,
    input logic [WIDTH-1:0] wr_data,
    input logic rd_en,
    input logic [ADDR_W-1:0] rd_addr,
    output logic [WIDTH-1:0] rd_data
    );
    
    logic [WIDTH-1:0] mem [0:DEPTH-1]; //
    always_ff @(posedge clk) begin
        if(rst)
            rd_data <= '0; // clear to zero at rising edge
        else begin
            if (wr_en) // if write enables
                mem[wr_addr] <= wr_data; // the value on wrdata must be written to the location selected by wr_addr at rising ege of clk
            if (rd_en)
                rd_data <= mem[rd_addr];
        end // end else begin
   end // end always begin
endmodule
