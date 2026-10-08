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
        check(empty_1 === 0, "dut2 should not be empty after writing");
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
        for (int i = 0; i < DEPTH4-1; i++) begin
            wr_data8 = 8'hA5 + i;
            @(posedge clk); #1;
        end
        wr_en4 = 0;
        wr_en5 = 1;
        for (int i = 0; i < DEPTH5-1; i++)begin
            wr_data4 = 4'hA + i;
            @(posedge clk); #1;
        end
        wr_en5 = 0;
        
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
        rd_en5 = 1;
        for (int i = 0; i < DEPTH5-1; i++) begin
            @(posedge clk); #1;
            check(rd_data4 === (8'hA5 + i), "Incorrect word, dut2");
        end
        rd_en5 = 0;
        wr_en5 = 0;
    // pointer wraparound
    // Transition from empty to nonempty
    // transition from not-full to full
    // transition from full to not full
    // transition from one stored word to empty
    // attempted write while full
    end // end initial begin
    // attempted read while empty
    // siumultanious valid read and write
    // simultaneous wr_en and rd_en while full
    // sumultaneious wr+en and rd_en while empty
    // correct synchronous timing of rd_data
endmodule
