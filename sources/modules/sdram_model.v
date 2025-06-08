`timescale 1ns / 1ps

module sdram_model(
    input        clk,           // clock
    input        cs,            // chip select
    input        we,            // write enable
    input        ras,           // row address strobe
    input        cas,           // column address strobe
    input [1:0]  bank_select,   // bank selection bits, 2 bits for 4 banks 
    input [13:0] dram_addr,     // DRAM address to read or write
    input [31:0] write_data,    // DRAM input of write operation

    output reg [31:0] read_data // DRAM output of read operation
);

	localparam
	   DATA   = 32,    // == 2^5
	   ROW    = 16384, // == 2^14
	   COLUMN = 512,   // == 2^9
	   
	   BANK0 = 2'b00,
	   BANK1 = 2'b01,
	   BANK2 = 2'b10,
	   BANK3 = 2'b11;
			
	wire act;           // flag signal of activation state
	wire read_cas;      // flag signal of CAS state during read operation
    wire write_cas;     // flag signal of CAS state during write operation
    wire nop;           // flag signal of no-operation state
	
	reg [13:0] hold_row_address    = 14'b0;    //row address buffer
	reg [8:0] hold_column_address  = 9'b0;     //column address buffer
	reg [1:0] hold_bank_sel        = 2'b0;     // bank selection buffer
	reg [1:0] nop_counter	       = 2'b0;     // no-operation counter
	reg       hold_write_cas       = 1'b0;     // flag signal indicating DRAM module is ready to write a data
	reg       hold_read_cas        = 1'b0;     // flag signal indicating DRAM module is ready to read a data
	
	// DRAM banks
	reg [DATA-1:0] bank0 [0:ROW-1][0:COLUMN-1];
	reg [DATA-1:0] bank1 [0:ROW-1][0:COLUMN-1];
	reg [DATA-1:0] bank2 [0:ROW-1][0:COLUMN-1];
	reg [DATA-1:0] bank3 [0:ROW-1][0:COLUMN-1];
		
	assign act         = ~cs && ~ras && cas && we;
	assign read_cas    = ~cs && ras && ~cas && we;
	assign write_cas   = ~cs && ras && ~cas && ~we;
	assign nop         = ~cs && ras && cas && we;
	
	always @(posedge clk)begin
		if(!cs)begin
			if(act) begin
				hold_row_address[13:0] <= dram_addr[13:0];
				hold_bank_sel[1:0]     <= bank_select[1:0];
				hold_read_cas          <= 1'b0;
				hold_write_cas         <= 1'b0;
			end
			else if (read_cas || write_cas)begin
				hold_column_address[8:0] <= dram_addr[8:0];
				hold_bank_sel[1:0]       <= bank_select[1:0];
				hold_read_cas            <= read_cas;
				hold_write_cas           <= write_cas;
			end
			else begin
			   hold_read_cas   <= read_cas;
	           hold_write_cas  <= write_cas;
			end

            if(nop_counter == 'd2)begin
                nop_counter <= 2'b0;
            end
            else if(nop)begin
                nop_counter <= nop_counter + 'd1;    
            end	
		end
	end

    always @(*) begin
		if(hold_write_cas)begin
			case(hold_bank_sel)
				BANK0: bank0[hold_row_address][hold_column_address] = write_data;
				BANK1: bank1[hold_row_address][hold_column_address] = write_data;
				BANK2: bank2[hold_row_address][hold_column_address] = write_data;
				BANK3: bank3[hold_row_address][hold_column_address] = write_data;
			endcase	
		end
		else if(hold_read_cas)begin
			case(hold_bank_sel)
				BANK0: read_data = bank0[hold_row_address][hold_column_address];
		        BANK1: read_data = bank1[hold_row_address][hold_column_address];
		        BANK2: read_data = bank2[hold_row_address][hold_column_address];
		        BANK3: read_data = bank3[hold_row_address][hold_column_address];
			endcase
		end	
	end
endmodule