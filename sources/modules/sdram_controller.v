`timescale 1ns / 1ps

module sdram_controller(
    // BUS INTERFACE
    input        clk,       // clock
    input        rst,       // reset (on posedge)
    input        write,     // operation (read/write) indicator 
    input        sel,       // chip operation enable == chip select
    input [31:0] in_data,   // data input
    input [31:0] addr,      // address input for read or write
    /* address mapping
    memory_mapped_I/O[31:30] | invalid[29:25] | column_address[24:16] | bank_selection[15:14] | row_address[13:0]
    
    memory_mapped_I/O : bits indicating which peripheral device is going to be used. For DRAM in this simulation, it's value is 10.
    invalid : unused bits, these bits can be used if more elements (chip, bank, row, column) is needed.
    column_address : address of a column in a bank
    bank_selection : index of a bank to read or write
    row_address : address of a row in a bank
    */
    
    output reg [31:0] out_data,     // data output
    output reg        ready,    // flag of whether data is completely processed

    // SDRAM MODEL INTERFACE
    input [31:0] read_data, // DRAM output of read operation
    
    output reg       cs,            // chip select
    output reg       we,            // write enable
    output reg       ras,           // row address strobe
    output reg       cas,           // column address strobe
    output reg [1:0]  bank_select,  // bank selection bits, 2 bits for 4 banks 
    output reg [13:0] dram_addr,    // DRAM address to read or write
    output reg [31:0] write_data    // DRAM input of write operation
);

	reg [31:0] hold_in_data;   // data buffer holding data to write 
	reg [31:0] hold_addr;      // address buffer
	reg [3:0]  state;          // DRAM state registers
	
	localparam
	   IDLE          = 4'b0000,
	   // read operation states
       READ_ACT      = 4'b0001,
       READ_NOP0     = 4'b0010,
	   READ_CAS      = 4'b0011,
	   READ_NOP1     = 4'b0100,
	   READ_NOP2     = 4'b0101,
			
	   // write operation states
	   WRITE_ACT     = 4'b0110,
	   WRITE_NOP0    = 4'b0111,
	   WRITE_CAS     = 4'b1000,
	   WRITE_NOP1    = 4'b1001,
	   WRITE_NOP2    = 4'b1010;
	
	always @(posedge clk, posedge rst) begin
	   if(!rst) begin
	       case(state)
	           IDLE: begin
	               if(sel == 1'b1 && write == 1'b0) begin
	                   state <= READ_ACT;
	                   
	                   ready <= 1'b0;
	                   
	                   hold_addr <= addr;
	               end
	               else if(sel == 1'b1 && write == 1'b1) begin
	                   state <= WRITE_ACT;
	                   
	                   ready <= 1'b0;
	                   
	                   hold_in_data <= in_data;
	                   hold_addr <= addr;
	               end
	           end
	           // read operation
	           READ_ACT: begin
	               state <= READ_NOP0;
	               
	               cs <= 1'b0;
	               we <= 1'b1;
	               ras <= 1'b0;
	               cas <= 1'b1;
	               
	               bank_select <= hold_addr[15:14];
	               dram_addr <= hold_addr[13:0];
	           end
	           READ_NOP0: begin
	               state <= READ_CAS;
	               
	               cs <= 1'b0;
	               we <= 1'b1;
	               ras <= 1'b1;
	               cas <= 1'b1;
	           end
	           READ_CAS: begin
	               state <= READ_NOP1;
	               
	               cs <= 1'b0;
	               we <= 1'b1;
	               ras <= 1'b1;
	               cas <= 1'b0;
	               
	               bank_select <= hold_addr[15:14];
	               dram_addr <= {5'b0, hold_addr[24:16]};
	           end
	           READ_NOP1: begin
	               state <= READ_NOP2;
	               
	               cs <= 1'b0;
	               we <= 1'b1;
	               ras <= 1'b1;
	               cas <= 1'b1;
	           end
	           READ_NOP2: begin
	               state <= IDLE;
	               
	               cs <= 1'b1;
	               we <= 1'b1;
	               ras <= 1'b1;
	               cas <= 1'b1;
	               
	               out_data <= read_data;
	               ready <= 1'b1;
	           end
	           
	           // write operation
	           WRITE_ACT: begin
	               state <= WRITE_NOP0;
	               
	               cs <= 1'b0;
	               we <= 1'b1;
	               ras <= 1'b0;
	               cas <= 1'b1;
	               
	               bank_select <= hold_addr[15:14];
	               dram_addr <= hold_addr[13:0];
	           end
	           WRITE_NOP0: begin
	               state <= WRITE_CAS;
	               
	               cs <= 1'b0;
	               we <= 1'b1;
	               ras <= 1'b1;
	               cas <= 1'b1;
	           end
	           WRITE_CAS: begin
	               state <= WRITE_NOP1;
	               
	               cs <= 1'b0;
	               we <= 1'b0;
	               ras <= 1'b1;
	               cas <= 1'b0;
	               
	               bank_select <= hold_addr[15:14];
	               dram_addr <= {5'b0, hold_addr[24:16]};
	           end
	           WRITE_NOP1: begin
	               state <= WRITE_NOP2;
	               
	               cs <= 1'b0;
	               we <= 1'b1;
	               ras <= 1'b1;
	               cas <= 1'b1;
	               
	               write_data <= hold_in_data;
	           end
	           WRITE_NOP2: begin
	               state <= IDLE;
	           
	               cs <= 1'b1;
	               we <= 1'b1;
	               ras <= 1'b1;
	               cas <= 1'b1;
	               
	               ready <= 1'b1;
	           end
	           default: begin
	               state <= IDLE;
	           
	               cs <= 1'b1;
	               we <= 1'b1;
	               ras <= 1'b1;
	               cas <= 1'b1;
	           end
	       endcase
	   end
	   else begin
	       state <= IDLE;
	       
	       cs <= 1'b1;
	       we <= 1'b1;
	       ras <= 1'b1;
	       cas <= 1'b1;
	       
	       bank_select <= 2'b0;
	       dram_addr <= 14'b0;
	       write_data <= 32'b0;
	       
	       hold_in_data <= 32'b0;
	       hold_addr <= 32'b0;
	       
	       out_data <= 32'b0;
	       ready <= 1'b0;
	   end
	end
endmodule
