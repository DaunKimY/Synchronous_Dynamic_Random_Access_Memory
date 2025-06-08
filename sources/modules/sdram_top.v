`timescale 1ns / 1ps

module sdram_top(
    input        clk,       // clock
    input        rst,       // reset (on posedge)
    input        write,     // operation (read/write) indicator 
    input        sel,       // chip operation enable == chip select
    input [31:0] in_data,   // data input
    input [31:0] addr,      // address input for read or write
    
    output [31:0] out_data, // data output
    output        ready     // flag of whether data is completely processed
);

    wire [31:0] read_data;    // DRAM output of read operation
    wire        cs;           // chip select
    wire        we;           // write enable
    wire        ras;          // row address strobe
    wire        cas;          // column address strobe
    wire [1:0]  bank_select;  // bank selection bits, 2 bits for 4 banks 
    wire [13:0] dram_addr;    // DRAM address to read or write
    wire [31:0] write_data;    // DRAM input of write operation
    
    sdram_controller sdram_controller(
        .clk(clk),
        .rst(rst),
        .write(write),
        .sel(sel),
        .in_data(in_data),
        .addr(addr),
        .ready(ready),
        .out_data(out_data),
        
        .read_data(read_data),
        .cs(cs),
        .we(we),
        .ras(ras),
        .cas(cas),
        .bank_select(bank_select),
        .dram_addr(dram_addr),
        .write_data(write_data)
    ); 
                                          
    sdram_model sdram_model(
        .clk(clk),
        .cs(cs),
        .we(we),
        .ras(ras),
        .cas(cas),
        .bank_select(bank_select),
        .dram_addr(dram_addr),
        .write_data(write_data),
        .read_data(read_data)
    ); 
endmodule