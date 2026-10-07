`timescale 1ns / 1ps
//


module tb_fifo_buffer;
    
    // verify synchronous reset
    // correct initial empty and full values
    // write one word into an empty FIFO,
    // write several words
    // read words in the write order
    // pointer wraparound
    // Transition from empty to nonempty
    // transition from not-full to full
    // transition from full to not full
    // transition from one stored word to empty
    // attempted write while full
    // attempted read while empty
    // siumultanious valid read and write
    // simultaneous wr_en and rd_en while full
    // sumultaneious wr+en and rd_en while empty
    // correct synchronous timing of rd_data
endmodule
