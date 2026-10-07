`timescale 1ns / 1ps
// 


module fifo_buffer#(parameter int WIDTH = 8, parameter int DEPTH  = 2)(
    input logic clk,
    input logic rst,
    input logic wr_en,
    input logic [WIDTH-1:0]wr_data,
    input logic rd_en,
    output logic [WIDTH-1:0] rd_data,
    output logic empty,
    output logic full
    );
    
    localparam COUNT_W = $clog2(DEPTH +1); //represent every value from 0 through DEPTH
    localparam ADDR_WIDTH = $clog2(DEPTH);
    logic [COUNT_W:0] count; // occupancy count must be capable of representing 0->DEPTH
    logic [ADDR_WIDTH-1:0]write_ptr, write_ptr_next, write_ptr_succ;
    logic [ADDR_WIDTH-1:0] rd_ptr, rd_ptr_next, rd_ptr_succ;
    
//    logic [ADDR_WIDTH-1:0] write_addr; // do we need this??
//    logic [ADDR_WIDTH-1:0] rd_addr; // do we need this??

    logic write;
    logic read; // internal signals so that we can ignre write if full
    assign write = wr_en && !full;
    assign read = rd_en && !empty;
    
    // observers
    output logic [COUNT_W-1:0] level;
    input logic [COUNT_W-1:0] almost_full_threshold;
    
    ram #(.WIDTH(WIDTH), .DEPTH(DEPTH), .ADDR_WIDTH(ADDR_WIDTH))ram_mod (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .wr_addr(write_ptr),
        .wr_data(wr_data),
        .rd_en(rd_en),
        .rd_addr(rd_ptr),
        .rd_data(rd_data)
    );
    
    // registers for status and read and write pointers
    always_ff @(posedge clk)
        if (rst) begin
            write_ptr <= 0;
            rd_ptr <= 0;
            count <= '0;
        end
        else begin
            write_ptr <= write_ptr_next;
            rd_ptr <= rd_ptr_next;
        end // end else begin
    // next-state logic for read and write
    always_comb begin
        //successive pointer values
        if (write_ptr == DEPTH-1)
            write_ptr_succ = '0;
        else
            write_ptr_succ = write_ptr + 1;
            
        if (rd_ptr == DEPTH-1)
            rd_ptr_succ = '0;
        else
            rd_ptr_succ = rd_ptr + 1;
        
        // default: keep old vals
        write_ptr_next = write_ptr;
        rd_ptr_next = rd_ptr;
        
        // if the fifo is full and both requests asserted:
        // read accepted, write ignored
        // accepted read should advance read pointer
        if (write)
            write_ptr_next = write_ptr_succ;
        if(read)
            rd_ptr_next = rd_ptr_succ;
    end // end always begin
    
    
    // if the fifo is empty and both requests are asserted:
    // write accepted, read ignored
    assign empty = (count == 0);
    assign full = (count == DEPTH);
endmodule
