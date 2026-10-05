`timescale 1ns / 1ps



module tb_ram;
    logic clk, rst, wr_en, rd_en;
    logic [$clog2(8)-1:0] wr_addr8, rd_addr8;
    logic [7:0] wr_data8, rd_data8;
    
    logic [$clog2(16)-1:0] wr_addr16, rd_addr16;
    logic [4:0] wr_data4, rd_data4;
    
    ram #(.WIDTH(8), .DEPTH(8))dut1 (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .wr_addr(wr_addr8),
        .wr_data(wr_data8),
        .rd_en(rd_en),
        .rd_addr(rd_addr8),
        .rd_data(rd_data8)
    );
    
        ram #(.WIDTH(16), .DEPTH(4))dut2 (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .wr_addr(wr_addr16),
        .wr_data(wr_data16),
        .rd_en(rd_en),
        .rd_addr(rd_addr4),
        .rd_data(rd_data4)
    );
    
    // Clock it
    localparam T = 10;
    initial clk = 0;
    always #(T/2) clk = ~clk;
    
    int error_cnt;
    int test_cnt;
    
    task automatic check(
        input logic condition,
        input string message
    );
            if (condition !== 1'b1) begin
                $error("%s", message);
                error_cnt++;
            end
    endtask
    
    task automatic set_vals_dut1 (
        input logic wr_addr,
        input logic wr_data,
        input logic rd_addr
    );
        wr_addr8 = wr_addr;
        wr_data8 = wr_data;
        rd_addr8 = rd_addr;
    endtask
    
    task automatic set_vals_dut2 (
        input logic wr_addr,
        input logic wr_data,
        input logic rd_addr
    );
        wr_addr16 = wr_addr;
        wr_data4 = wr_data;
        rd_addr16 = rd_addr;
    endtask
    
    initial begin   
        error_cnt = 0;
        test_cnt = 0;
        wr_en = 0; rd_en = 0;
        rst = 0;
        
        /*  Test 1: Write known values to every valid memory location */
        // Read locations in written order
        @(posedge clk);
        #1;
        
        wr_en = 1; // allow writing to occur
        wr_data = 
        
        /*  Test 2: Read those values in a different order than they're written */
        
         /*  Test 3: Synchronous reset of rd_data*/
        // reset the known vals from the previous
        
        /*  Test 4: Test the one-clock synchronous read behavior*/
        
        /*  Test 5: Test retention of rd_data when rd_en = 0    */
        
        /*  Test 6: Test persistence of memory locations that are not written */
        
        /*  Test 7: Test overwritting a previously written location */
        
        /*  Test 8: Test simultaneoous reads and writes to different addresses*/
        
        if (error_cnt == 0)
            $display("PASS: all %d implemented tests completed with no errors.", test_cnt);
        else    
            $display("FAIL: %0d error(s) detected.", error_cnt);
        $finish;
    end // end inital begin

endmodule
