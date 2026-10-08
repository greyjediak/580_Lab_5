`timescale 1ns / 1ps
//

module tb_fifo_buffer;
    logic clk;
    logic rst;
    logic wr_en4;
    logic rd_en4;
    localparam WIDTH8 = 8;
    localparam DEPTH4 = 4;
    
    logic [WIDTH8-1:0]wr_data8;
    logic [WIDTH8-1:0]rd_data8;
    logic empty_1; 
    logic full_1;
    
    // Dut 2 parameters
    logic wr_en5;
    logic rd_en5;
    localparam WIDTH4 = 4;
    localparam DEPTH5 = 5;
    
    logic [WIDTH4-1:0]wr_data4;
    logic [WIDTH4-1:0]rd_data4;
    logic empty_2; 
    logic full_2;
    
    
    fifo_buffer #(.WIDTH(WIDTH8), .DEPTH(DEPTH4))dut1 (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en4),
        .wr_data(wr_data8),
        .rd_en(rd_en4),
        .rd_data(rd_data8),
        .empty(empty_1),
        .full(full_1)    
    );
    
        fifo_buffer #(.WIDTH(WIDTH4), .DEPTH(DEPTH5))dut2 (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en5),
        .wr_data(wr_data4),
        .rd_en(rd_en5),
        .rd_data(rd_data4),
        .empty(empty_2),
        .full(full_2)    
    );
    
    // cloc it
    localparam T =10;
    initial clk = 0;
    always #(T/2) clk = ~clk;
    
    int error_cnt = 0;
    int test_cnt = 0;
    
    task automatic check(
        input logic condition, 
        input string message
    );
        if(condition !== 1'b1) begin
            $error("%s", message);
            error_cnt++;
        end
    endtask
    
    initial begin
        rst = 0;
        wr_en4 = 0;
        rd_en4 = 0;
        wr_data8 = 0;
        
        wr_en5 = 0;
        rd_en5 = 0;
        wr_data4 = 0;
    /* Test 1: verify synchrounous reset*/
        $display("Test 1");
        rst = 1;
        @(posedge clk); #1;
        check(empty_1 == 1,"DUT1 not empty after reset");
        check(full_1 === 0, "DUT1 full after reset");
        check(empty_2 == 1, "DUT2 not empty after reset");
        check(full_2 === 0, "Dut2 full after reset");
        rst = 0;
        test_cnt++;
    
    /* Test 2*/
    // write one word into an empty FIFO,
        $display("Test 2");
        wr_en4 = 1;
        rd_en4 =0;
        wr_data8 = 8'hA5;
        wr_en5 = 1;
        rd_en5 = 0;
        wr_data4 = 4'hA;
        @(posedge clk); #1;
        check(empty_1 === 0, "Dut1 shuld not be empty after writing");
        check(full_1 === 0, "dut1 should not be full after one write");
        check(empty_2 === 0, "dut2 should not be empty after writing");
        check(full_2 === 0, "dut2 should not be full after one write");
        wr_en4 = 0;
        wr_en5 = 0;
        test_cnt++;
        
    /*  Test 3 */
    // write several words
        $display("Test 3");
        // write 2 more words to fifo 1 and 4 into dut2
        wr_en4 =1;
        wr_en5 =0;
        for (int i = 1; i < DEPTH4-1; i++) begin
            wr_data8 = 8'hA5 + i;
            @(posedge clk); #1;
        end
        wr_en4 = 0;
        wr_en5 = 1;
        for (int i = 1; i < DEPTH5-1; i++)begin
            wr_data4 = 4'hA + i;
            @(posedge clk); #1;
        end
        wr_en5 = 0;
        
        check(empty_1 === 0 && full_1 === 0, "dut 1 should be partially full");
        check(empty_2 === 0 && full_2 === 0, "dut 2 should be partially full");
        test_cnt++;
        
     /*  Test 4 */
    // read words in the write order
        $display("Test 4");
        wr_en4 = 0;
        rd_en4 = 1;
        for (int i = 0; i < DEPTH4-1; i++) begin
            @(posedge clk); #1;

            check(rd_data8 === (8'hA5 + i), "Incorrect word");
        end
        rd_en4 = 0;
        wr_en5 = 0;
        check(empty_1 === 1, "DUT1 should be empty after reading all words");
        check(full_1 === 0, "DUT1 should not be full");
        rd_en5 = 1;
        for (int i = 0; i < DEPTH5-1; i++) begin
            @(posedge clk); #1;
            check(rd_data4 === (8'hA + i), "Incorrect word, dut2");
        end
        rd_en5 = 0;
        wr_en5 = 0;
        check(empty_2 === 1, "DUT2 should be empty after all reads");
        check(full_2 === 0, "DUT2 should not be full");
        test_cnt++;
        

    /* Test 5: Attempt to read from an empty FIFO */
        $display("Test 5");

        wr_en4 = 0;
        rd_en4 = 1;
        wr_en5 = 0;
        rd_en5 = 1;

        @(posedge clk); #1;

        check(empty_1 === 1, "DUT1 should remain empty after invalid read");
        check(full_1 === 0, "DUT1 should not be full after invalid read");

        rd_en4 = 0;
        rd_en5 = 0;
        test_cnt++;
        
    // Transition from empty to nonempty
        /* Test 6: Transition from empty to nonempty */
        $display("Test 6");

        wr_en4 = 1;
        wr_data8 = 8'h55;

        wr_en5 = 1;
        wr_data4 = 4'h5;

        @(posedge clk); #1;

        check(empty_1 === 0, "DUT1 should transition to nonempty");
        check(empty_2 === 0, "DUT2 should transition to nonempty");

        check(full_1 === 0, "DUT1 should not be full");
        check(full_2 === 0, "DUT2 should not be full");

        wr_en4 = 0;
        wr_en5 = 0;
        test_cnt++;
        
        /* Test 7 */
        // transition from not-full to full
        $display("Test 7");
        wr_en4 = 1;
        wr_en5 = 0;
        
        for (int i = 1; i < DEPTH4; i++)begin
            wr_data8 = 8'h55 + i;
            @(posedge clk); #1;
        end
        wr_en4 = 0;
        
        wr_en5 = 1;
        // fill dut2
        for (int i = 1; i < DEPTH5; i++) begin
            wr_data4 = 4'h5 + i;
            @(posedge clk); #1;
        end
        wr_en5 = 0;
        check(full_1 === 1, "Dut1 should be full after writing 4 things");
        check(full_2 === 1, "Dut2 should be full after writing 5 things");
        test_cnt++;
        
        /*  Test 8 */
       // attempted write while now that the buffer was full
       $display("Test 8");
        wr_en4 = 1;
        wr_data8 = 8'hFF;

        wr_en5 = 1;
        wr_data4 = 4'hF;

        @(posedge clk); #1;

        check(full_1 === 1, "DUT1 should remain full");
        check(full_2 === 1, "DUT2 should remain full");

        wr_en4 = 0;
        wr_en5 = 0;
        test_cnt++;
         
     /* Test 9*/   
    // transition from full to not full, read one word
        $display("Test 9");
        rd_en4 = 1;
        rd_en5 = 1;
        
        @(posedge clk);#1;
        
        check(rd_data8 === 8'h55, "Dut1 first word incorrect");
        check(rd_data4 === 4'h5, "Dut 2 first word in correct");
        check(full_1 === 0, "Dut 1 should no longer be full");
        check(full_2 === 0, "DUT2 should no longer be full");
        rd_en4 = 0; 
        rd_en5 = 0;
        test_cnt++;
    
    /*  Test 10 */
    // simultaneous valid read and write
        $display("Test 9");
        wr_en4 = 1; rd_en4 = 1;
        wr_data8 = 8'h77;
        wr_en5 = 1; rd_en5 = 1;
        wr_data4 = 4'hA;
        @(posedge clk); #1;
        check(rd_data8 === 8'h56, "DUT1 simultaneous read incorrect");
        check(rd_data4 === 4'h6, "Dut2 simultaneour read incorrect");
        check(full_1 === 0, "DUT1 should be not full");
        check(full_2 === 0, "DUT2 should not be full");
        wr_en4 = 0;
        rd_en4 = 0;
        wr_en5 = 0;
        rd_en5 = 0;
        test_cnt++;
        
        // simultaneous wr_en and rd_en while full
        /* Test 11: Simultaneous requests while full */
        $display("Test 11");

        // Fill remaining space
        wr_en4 = 1;
        wr_data8 = 8'h88;

        wr_en5 = 1;
        wr_data4 = 4'hB;

        @(posedge clk); #1;

        check(full_1 === 1, "DUT1 should be full");
        check(full_2 === 1, "DUT2 should be full");

        // Request read and write simultaneously
        wr_data8 = 8'hEE;
        wr_data4 = 4'hE;
        rd_en4 = 1;
        rd_en5 = 1;

        @(posedge clk); #1;

        check(rd_data8 === 8'h57, "DUT1 full simultaneous read incorrect");
        check(rd_data4 === 4'h7, "DUT2 full simultaneous read incorrect");

        check(full_1 === 0, "DUT1 should no longer be full");
        check(full_2 === 0, "DUT2 should no longer be full");

        wr_en4 = 0;
        wr_en5 = 0;
        rd_en4 = 0;
        rd_en5 = 0;
        test_cnt++;
        
        // Pointer wraparound
        /* Test 12 */
        $display("test 12");
        
        wr_en4 = 1;
        rd_en4 = 1;
        wr_en5 = 1;
        rd_en5 = 1;
        
        for (int i = 0; i < 20; i++) begin
            wr_data8 = 8'hA0 + i;
            wr_data4 = 4'(i);
            @(posedge clk); #1;
            
            if (i == 0) check(rd_data8 === 8'h58, "DUT1 expected 58");
            if (i == 1) check(rd_data8 === 8'h77, "DUT1 expected 77");
            if (i == 2) check(rd_data8 === 8'h88, "DUT1 expected 88");

            if (i == 0) check(rd_data4 === 4'h8, "DUT2 expected 8");
            if (i == 1) check(rd_data4 === 4'h9, "DUT2 expected 9");
            if (i == 2) check(rd_data4 === 4'hA, "DUT2 expected A");
            if (i == 3) check(rd_data4 === 4'hB, "DUT2 expected B");

            if (i >= 3) check(rd_data8 === 8'(8'hA0 + i - 3),"DUT1 wraparound data incorrect");

            if (i >= 4) check(rd_data4 === 4'(i - 4),"DUT2 wraparound data incorrect");
        end
            
            wr_en4 = 0;
            rd_en4 = 0;
            wr_en5 = 0;
            rd_en5 = 0;
            
            check(full_1 === 0 && empty_1 === 0, "DUT1 occupancy changed");
            check(full_2 === 0 && empty_2 === 0, "DUT2 occupancy changed");
            
            test_cnt++;
        
        // simultaneious wr_en and rd_en while empty
        /* Test 14: Simultaneous requests while empty */
        $display("Test 14");

        // Empty both FIFOs before testing simultaneous requests
        rd_en4 = 1;
        rd_en5 = 1;

        for (int i = 0; i < DEPTH5-1; i++) begin
            if (i == DEPTH4-1) rd_en4 = 0;

            @(posedge clk); #1;

            if (i < DEPTH4-1)
                check(rd_data8 === 8'(8'hB1 + i), "DUT1 remaining data incorrect");

            check(rd_data4 === 4'(i), "DUT2 remaining data incorrect");
        end

        rd_en4 = 0;
        rd_en5 = 0;

        check(empty_1 === 1, "DUT1 should be empty");
        check(empty_2 === 1, "DUT2 should be empty");

        // Now test simultaneous read/write while empty
        wr_en4 = 1;
        rd_en4 = 1;
        wr_data8 = 8'h91;

        wr_en5 = 1;
        rd_en5 = 1;
        wr_data4 = 4'h9;

        @(posedge clk); #1;

        check(empty_1 === 0, "DUT1 should contain one word");
        check(empty_2 === 0, "DUT2 should contain one word");

        // Read the accepted words
        wr_en4 = 0;
        wr_en5 = 0;

        @(posedge clk); #1;

        check(rd_data8 === 8'h91, "DUT1 accepted write incorrect");
        check(rd_data4 === 4'h9, "DUT2 accepted write incorrect");

        check(empty_1 === 1, "DUT1 should be empty");
        check(empty_2 === 1, "DUT2 should be empty");

        rd_en4 = 0;
        rd_en5 = 0;

        test_cnt++;
        
        // correct synchronous timing of rd_data
        /* Test 16: Verify synchronous reset */
        $display("Test 15");

        // Write one word
        wr_en4 = 1;
        wr_data8 = 8'hAB;

        wr_en5 = 1;
        wr_data4 = 4'hB;

        @(posedge clk); #1;

        wr_en4 = 0;
        wr_en5 = 0;

        // Assert reset between rising edges
        @(negedge clk);
        rst = 1;

        #1;
        check(empty_1 === 0, "DUT1 reset asynchronously");
        check(empty_2 === 0, "DUT2 reset asynchronously");
        // Reset should take effect at rising edge
        @(posedge clk); #1;

        check(empty_1 === 1, "DUT1 reset failed");
        check(empty_2 === 1, "DUT2 reset failed");
        check(rd_data8 === 0, "DUT1 read data not reset");
        check(rd_data4 === 0, "DUT2 read data not reset");

        rst = 0;
        // Verify synchronous read data timing
        wr_en4 = 1;
        wr_data8 = 8'hCC;
        wr_en5 = 1;
        wr_data4 = 4'hC;

        @(posedge clk); #1;

        wr_en4 = 0;
        wr_en5 = 0;

        // Output should remain unchanged without a read
        check(rd_data8 === 0, "DUT1 output changed without read");
        check(rd_data4 === 0, "DUT2 output changed without read");

        @(negedge clk);
        rd_en4 = 1;
        rd_en5 = 1;

        // Read data should not change before the clock
        #1;
        check(rd_data8 === 0, "DUT1 output changed before clock");
        check(rd_data4 === 0, "DUT2 output changed before clock");

        // Read occurs on rising edge
        @(posedge clk); #1;

        check(rd_data8 === 8'hCC, "DUT1 synchronous read incorrect");
        check(rd_data4 === 4'hC, "DUT2 synchronous read incorrect");

        rd_en4 = 0;
        rd_en5 = 0;

        // Read data should hold when read enable is low
        @(posedge clk); #1;

        check(rd_data8 === 8'hCC, "DUT1 output did not hold");
        check(rd_data4 === 4'hC, "DUT2 output did not hold");
        
        if (error_cnt == 0)
            $display("All tests passed.");
        else
            $display("failed with %d errors", error_cnt);
        $finish;
    end // end initial begin

endmodule
