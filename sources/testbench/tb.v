`timescale 1ns / 1ps

module tb();
    localparam
        READ_ITER   = 'd8,
        WRITE_ITER  = 'd8;

    reg        clk;
    reg        rst;
    reg        write;
    reg        sel;
    reg [31:0] in_data;
    reg [31:0] addr;
    
    reg  [4:0]  iter;
    reg  [31:0] data_mem[0:WRITE_ITER-'d1];
    reg  [31:0] addr_mem[0:WRITE_ITER+WRITE_ITER-'d1];

    wire [31:0] out_data;
    wire        ready;

    initial begin
        clk <= 1;
        rst <= 1;
        write <= 0;
        sel <= 0;
        
        iter <= 0;
        $readmemb("addr.txt", addr_mem);
        $readmemb("data.txt", data_mem);
        
        repeat(10)
            @(negedge clk);
        rst <= 0;
        
        repeat(10)
            @(negedge clk);
        
        write <= 1'b1;
        repeat(WRITE_ITER) begin
            @(negedge clk) begin
                in_data <= data_mem[iter];
                addr <= addr_mem[iter];
                iter <= iter + 'd1;
                sel <= 1'b1;
            end
            @(negedge clk) begin
                sel <= 1'b0;
            wait(ready);
            $display("#%d / Write operation / Bank#: %d / Row: %d / Column: %d", iter-1, addr[15:14], addr[13:0], addr[24:16]);
            end
        end
       
        write <= 1'b0;
        repeat(READ_ITER) begin
            @(negedge clk) begin
                in_data <= 32'b0;
                addr <= addr_mem[iter];
                iter <= iter + 'd1;
                sel <= 1'b1;
            end
            @(negedge clk) begin
                sel <= 1'b0;
            wait(ready);
            $display("#%d / Read operation / Bank#: %d / Row: %d / Column: %d", iter-1, addr[15:14], addr[13:0], addr[24:16]);
            end
        end
        
        repeat(6)
            @(posedge clk);
        $finish;
    end
    
    always #10 clk <= ~clk;
    
    sdram_top sdram_top(
        .clk(clk),
        .rst(rst),
        .write(write),
        .sel(sel),
        .in_data(in_data),
        .addr(addr),
        
        .out_data(out_data),
        .ready(ready)
    );
endmodule
