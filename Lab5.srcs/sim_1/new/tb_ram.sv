`timescale 1ns / 1ps
// "It is a universal truth that, a single man in possession of a good fortune must be in want of a wife."
//  - Jane Austen, Pride and Prejudice

module tb_ram;
    logic clk, rst, wr_en, rd_en;
    logic [$clog2(8)-1:0] wr_addr8, rd_addr8;
    logic [7:0] wr_data8, rd_data8;
    
    logic [$clog2(16)-1:0] wr_addr16, rd_addr16;
    logic [3:0] wr_data4, rd_data4;
    
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
    
    ram #(.WIDTH(4), .DEPTH(16))dut2 (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .wr_addr(wr_addr16),
        .wr_data(wr_data4),
        .rd_en(rd_en),
        .rd_addr(rd_addr16),
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
    
    // One shot clear duts:
    task automatic reset();
        begin
            wr_en = 0;
            rd_en = 0;
            rst = 1;
            @(posedge clk); #1;
            rst = 0;
         end
    endtask
    
    // Tasks to set the dut values easily
    task automatic set_vals_dut1 (
        input logic [$clog2(8)-1:0]wr_addr,
        input logic [7:0] wr_data,
        input logic [$clog2(8)-1:0]rd_addr
    );
        wr_addr8 = wr_addr;
        wr_data8 = wr_data;
        rd_addr8 = rd_addr;
    endtask
    
    task automatic set_vals_dut2 (
        input logic [$clog2(16)-1:0]wr_addr,
        input logic [3:0] wr_data,
        input logic [$clog2(16)-1:0] rd_addr
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

        wr_en = 1; // allow writing to occur
        rd_en = 0;
        
        // Write multiples of 8 to every valid memory location
        for (int i = 0; i < 8; i++) begin
            wr_addr8 = i;
            wr_data8 = i * 8;
            @(posedge clk); #1;
        end
        
        wr_en = 0; //turn write off
        rd_en = 1;//start reading
        
        // Read back in written order
        for (int i = 0; i < 8; i++) begin
            rd_addr8 = i;
            @(posedge clk); #1;
            check(rd_data8 === i * 8,
                  $sformatf("Address %0d should contain %0d", i, i * 8));
        end
        
        test_cnt++;
        
        /*  Test 2: Read those values in a different order than they're written */
        // Read back in reverse order
        for (int i = 7; i >= 0; i--) begin
            rd_addr8 = i;
            @(posedge clk); #1;
            check(rd_data8 === i * 8,
                  $sformatf("Address %0d should still contain %0d", i, i * 8));
        end
        
        test_cnt++;
        
        /*  Test 3: Synchronous reset of rd_data*/
        // rd_data8 currently contains address 0 = 0
        // read address 1 first so rd_data8 contains a nonzero value
        rd_addr8 = 1;
        @(posedge clk); #1;
        check(rd_data8 === 8, "Address 1 should contain 8 before reset");
        
        rst = 1;
        #1;
        check(rd_data8 === 8, "Read data changed before clock edge");
        @(posedge clk); #1;
        check(rd_data8 === 0, "Read data supposed to go to 0 after clock edge and rst");
        rst = 0;
        test_cnt++;
        
        /*  Test 4: Test the one-clock synchronous read behavior*/
        // dut 1 still contains multiples of 8 in addresses 0 through 7
        rd_en = 1;
        rd_addr8 = 1;
        // output should still be reset value before clock edge
        #1;
        check(rd_data8 === 0, "rd_data changed before rising edge");
        @(posedge clk); #1;
        // address 1 should now be present
        check(rd_data8 === 8, "synchronous read failed after the clock edge");
        test_cnt++;
        
        /*  Test 5: Test retention of rd_data when rd_en = 0    */
        $display("Test 5");
         // rd_data8 currently = 8
        rd_en = 0;

        // Change address and don't enable read
        rd_addr8 = 3;
        @(posedge clk); #1;
        check(rd_data8 === 8, "rd_data changed while rd_en was low");
        test_cnt++;

        /*  Test 6: Test persistence of memory locations that are not written */
        $display("Test 6");
        rd_en = 0;
        wr_en = 1;
        // change ONLY address 4
        wr_addr8 = 4;
        wr_data8 = 100;
        @(posedge clk); #1;
        wr_en = 0;
        rd_en = 1;
        
        // check any other address
        rd_addr8 =3;
        @(posedge clk); #1;
        check(rd_data8 === 24, "Address 3 changed when Address 4 was supposed to");
        rd_addr8 = 4; // check the actual changed address
        @(posedge clk); #1;
        check(rd_data8 === 100, "Address 4 did not successfully change");
        test_cnt++;
        
        /*  Test 7: Test overwritting a previously written location */
        $display("Test 7");
        rd_en = 0;
        wr_en = 1;

        // Address 2 originally contains 16
        wr_addr8 = 2;
        wr_data8 = 99;
        @(posedge clk); #1;
        wr_en = 0;
        rd_en = 1;
        rd_addr8 = 2;
        @(posedge clk); #1;

        check(rd_data8 === 99, "Address 2 was not overwritten correctly");
        test_cnt++;

        /*  Test 8: Test simultaneoous reads and writes to different addresses*/
        $display("Test 8");
        // Write 55 to address 4 while reading address 1
        // Address 1 should still contain 8.
        wr_en = 1;
        rd_en = 1;

        wr_addr8 = 4;
        wr_data8 = 55;
        rd_addr8 = 1;

        @(posedge clk); #1;

        check(rd_data8 === 8,
              "Simultaneous read returned incorrect data");

        // Now verify that the write also happened
        wr_en = 0;
        rd_addr8 = 4;

        @(posedge clk); #1;

        check(rd_data8 === 55,
              "Simultaneous write did not store data");

        test_cnt++;
        
        if (error_cnt == 0)
            $display("PASS: all %d implemented tests completed with no errors.", test_cnt);
        else    
            $display("FAIL: %0d error(s) detected.", error_cnt);
        $finish;
    end // end inital begin

endmodule