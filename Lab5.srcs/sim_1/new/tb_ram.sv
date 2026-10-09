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
        set_vals_dut1(0, 0, 0);   // wr_addr8, wr_data8, rd_addr8
        set_vals_dut2(0, 0, 0);   // wr_addr16, wr_data4, rd_addr16
        reset();                  // rd_data8 and rd_data4 go to 0 here

        /*  Test 1: Write known values to every valid memory location */
        // Read locations in written order
        // dut 1: address i holds 8'hA0 + i  (8 locations)
        // dut 2: address i holds i          (16 locations)

        wr_en = 1; // allow writing to occur
        rd_en = 0;

        // Write A0..A7 to every valid dut 1 location, 0..F to every dut 2 location
        // dut 2 has 16 locations, so dut 1 stops updating after address 7
        for (int i = 0; i < 16; i++) begin
            if (i < 8) begin
                wr_addr8 = i;
                wr_data8 = 8'hA0 + i;
            end
            wr_addr16 = i;
            wr_data4 = 4'(i);
            @(posedge clk); #1;
        end

        wr_en = 0; //turn write off
        rd_en = 1;//start reading

        // Read back in written order
        for (int i = 0; i < 16; i++) begin
            if (i < 8) rd_addr8 = i;
            rd_addr16 = i;
            @(posedge clk); #1;
            if (i < 8)
                check(rd_data8 === 8'(8'hA0 + i),
                      $sformatf("Address %0d should contain %0h", i, 8'hA0 + i));
            check(rd_data4 === 4'(i),
                  $sformatf("DUT2 address %0d should contain %0h", i, i));
        end

        test_cnt++;

        /*  Test 2: Read those values in a different order than they're written */
        // Read back in reverse order
        for (int i = 15; i >= 0; i--) begin
            if (i < 8) rd_addr8 = i;
            rd_addr16 = i;
            @(posedge clk); #1;
            if (i < 8)
                check(rd_data8 === 8'(8'hA0 + i),
                      $sformatf("Address %0d should still contain %0h", i, 8'hA0 + i));
            check(rd_data4 === 4'(i),
                  $sformatf("DUT2 address %0d should still contain %0h", i, i));
        end

        test_cnt++;

        /*  Test 3: Synchronous reset of rd_data*/
        // read address 1 first so rd_data contains a nonzero value
        // dut 1 address 1 = A1, dut 2 address 1 = 1
        rd_addr8 = 1;
        rd_addr16 = 1;
        @(posedge clk); #1;
        check(rd_data8 === 8'hA1, "Address 1 should contain A1 before reset");
        check(rd_data4 === 4'h1, "DUT2 address 1 should contain 1 before reset");

        rst = 1;
        #1;
        check(rd_data8 === 8'hA1, "Read data changed before clock edge");
        check(rd_data4 === 4'h1, "DUT2 read data changed before clock edge");
        @(posedge clk); #1;
        check(rd_data8 === 0, "Read data supposed to go to 0 after clock edge and rst");
        check(rd_data4 === 0, "DUT2 read data supposed to go to 0 after clock edge and rst");
        rst = 0;
        test_cnt++;

        /*  Test 4: Test the one-clock synchronous read behavior*/
        // dut 1 still contains A0..A7 in addresses 0 through 7
        // dut 2 still contains 0..F in addresses 0 through 15
        rd_en = 1;
        rd_addr8 = 1;
        rd_addr16 = 1;
        // output should still be reset value before clock edge
        #1;
        check(rd_data8 === 0, "rd_data changed before rising edge");
        check(rd_data4 === 0, "DUT2 rd_data changed before rising edge");
        @(posedge clk); #1;
        // address 1 should now be present
        check(rd_data8 === 8'hA1, "synchronous read failed after the clock edge");
        check(rd_data4 === 4'h1, "DUT2 synchronous read failed after the clock edge");
        test_cnt++;

        /*  Test 5: Test retention of rd_data when rd_en = 0    */
        $display("Test 5");
         // rd_data8 currently = A1, rd_data4 currently = 1
        rd_en = 0;

        // Change address and don't enable read
        rd_addr8 = 3;
        rd_addr16 = 3;
        @(posedge clk); #1;
        check(rd_data8 === 8'hA1, "rd_data changed while rd_en was low");
        check(rd_data4 === 4'h1, "DUT2 rd_data changed while rd_en was low");
        test_cnt++;

        /*  Test 6: Test persistence of memory locations that are not written */
        $display("Test 6");
        rd_en = 0;
        wr_en = 1;
        // change ONLY address 4
        // dut 1 address 4: A4 -> B4, dut 2 address 4: 4 -> B
        wr_addr8 = 4;
        wr_data8 = 8'hB4;
        wr_addr16 = 4;
        wr_data4 = 4'hB;
        @(posedge clk); #1;
        wr_en = 0;
        rd_en = 1;

        // check any other address
        rd_addr8 =3;
        rd_addr16 = 3;
        @(posedge clk); #1;
        check(rd_data8 === 8'hA3, "Address 3 changed when Address 4 was supposed to");
        check(rd_data4 === 4'h3, "DUT2 address 3 changed when Address 4 was supposed to");
        rd_addr8 = 4; // check the actual changed address
        rd_addr16 = 4;
        @(posedge clk); #1;
        check(rd_data8 === 8'hB4, "Address 4 did not successfully change");
        check(rd_data4 === 4'hB, "DUT2 address 4 did not successfully change");
        test_cnt++;

        /*  Test 7: Test overwritting a previously written location */
        $display("Test 7");
        rd_en = 0;
        wr_en = 1;

        // Address 2 originally contains A2 -> C2
        // dut 2 address 2 originally contains 2 -> C
        wr_addr8 = 2;
        wr_data8 = 8'hC2;
        wr_addr16 = 2;
        wr_data4 = 4'hC;
        @(posedge clk); #1;
        wr_en = 0;
        rd_en = 1;
        rd_addr8 = 2;
        rd_addr16 = 2;
        @(posedge clk); #1;

        check(rd_data8 === 8'hC2, "Address 2 was not overwritten correctly");
        check(rd_data4 === 4'hC, "DUT2 address 2 was not overwritten correctly");
        test_cnt++;

        /*  Test 8: Test simultaneoous reads and writes to different addresses*/
        $display("Test 8");
        // Write D4 to address 4 while reading address 1
        // Address 1 should still contain A1.
        // dut 2: write D to address 4 while reading address 1 (should still contain 1)
        wr_en = 1;
        rd_en = 1;

        wr_addr8 = 4;
        wr_data8 = 8'hD4;
        rd_addr8 = 1;
        wr_addr16 = 4;
        wr_data4 = 4'hD;
        rd_addr16 = 1;

        @(posedge clk); #1;

        check(rd_data8 === 8'hA1,
              "Simultaneous read returned incorrect data");
        check(rd_data4 === 4'h1,
              "DUT2 simultaneous read returned incorrect data");

        // Now verify that the write also happened
        wr_en = 0;
        rd_addr8 = 4;
        rd_addr16 = 4;

        @(posedge clk); #1;

        check(rd_data8 === 8'hD4,
              "Simultaneous write did not store data");
        check(rd_data4 === 4'hD,
              "DUT2 simultaneous write did not store data");

        test_cnt++;

        if (error_cnt == 0)
            $display("PASS: all %d implemented tests completed with no errors.", test_cnt);
        else
            $display("FAIL: %0d error(s) detected.", error_cnt);
        $finish;
    end // end inital begin

endmodule