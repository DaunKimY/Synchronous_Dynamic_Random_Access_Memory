# Synchronous_Dynamic_Random_Access_Memory

![image.png](attachment:10dcc693-d799-4b45-b939-1eb53c93327d:image.png)

# Project purpose

- Understand how a SDRAM chip read/write data.
- For developing further memory designs with RTL tools, implement SDRAM module and write a testbench with verilog.

# Signal specification

## Input/Output

### Inputs

| Signal | Description |
| --- | --- |
| clk | 1bit, clock pulse |
| rst | 1bit, reset flag, initialize the controller’s controll signals at a positive edge of this input. |
| write | 1bit, flag signal of write operation. If it’s 1, the type of an operation is writing. If not, reading. |
| sel | 1bit, chip selection signal, enabling read/write operation for a DRAM chip. |
| in_data | 32bits, data given to write on a DRAM bank. |
| addr | 32bits, address of data to read or write. |
- [31:0] addr signal bits mapping

| Items | memory mapped I/O [31:30] | invalid bits [29:25] | column address [24:16] | bank selelction [15:14] | row address [13:0] |
| --- | --- | --- | --- | --- | --- |
| Description | the value of these bits is 10 in here simulation. See further details about MMIO at [Appendix A. MMIO](https://www.notion.so/SDRAM-Synchronous-DRAM-19ba04706db480f9aac5dc5d00c3d17d?pvs=21). | unused bits, these bits can be used if more elements (chip, bank, row, column) is needed. | address of a column in a bank | index of a bank to read or write | address of a row in a bank |

### Outputs

| Signal | Description |
| --- | --- |
| out_ready | 1bit, a indicator that read data is ready for sending as an output. |
| out_data | 32bits, data read from a DRAM bank. |

## Control signals

| Signal | Description |
| --- | --- |
| clk | 1bit, clock pulse |
| cs | 1bit, chip selection signal, enabling read/write operation for a DRAM chip. |
| we | 1bit, flag signal of write operation. If it’s 1, the type of an operation is writing. If not, reading. |
| ras | 1bit, row address strobe, It’s 1 at row activation state. If not, 0. |
| cas | 1bit, column address strobe, It’s 1 at array selection state (sending column address). If not, 0. |
| bank_select | 2bits for 4 banks, bank selection bits |
| dram_addr | 13bits, DRAM address to read or write, If it’s column address only the 9 less significant bits will be used, else 13 bits. |
| read_data | 32bits, DRAM input of write operation |
| write_data | 32bits, DRAM output of read operation |

# SDRAM operation

## DRAM logic

![image.png](attachment:421b519a-7e29-443e-9869-abe70ae15902:image.png)

## State diagram

![image.png](attachment:ca4f43ac-e54e-498c-983e-431cc174a957:image.png)

## Read operation

- States

| State | Description |
| --- | --- |
| READ_ACT | Activate rows in a bank about given row address and charge bit lines and sense amplifiers.  |
| READ_NOP0 | Wait a single cycle to amplify charges by sense amplifiers |
| READ_CAS | Send column address to sense amplifier MUX to store the output to the data buffer. |
| READ_NOP1 | Wait a single cycle to amplify charges in bit lines and cells by sense amplifiers |
| READ_NOP2 | Send the output and ready signal outside of the DRAM chip. |
- State table

$$
\begin{tabular}[h]{c:cc:c:ccccccc}Current State & sel & write & Next State & cs & we & ras & cas & bank\_select & dram\_addr & ready \\ \hline IDLE & 1 & 1 & READ\_ACT & x & x & x & x & x & x & 0 \\ READ\_ACT & x & x & READ\_NOP0 & 0 & 1 & 0 & 1 & bank\# & row\_address & 0 \\ READ\_NOP0 & x & x & READ\_CAS & 0 & 1 & 1 & 1 & 'd0 & 'd0 & 0 \\ READ\_CAS & x & x & READ\_NOP1 & 0 & 1 & 1 & 0 & bank\# & column\_address & 0 \\ READ\_NOP1 & x & x & READ\_NOP2 & 0 & 1 & 1 & 1 & 'd0 & 'd0 & 0 \\ READ\_NOP2 & x & x & IDLE & 1 & 1 & 1 & 1 & 'd0 & 'd0 & 1 \\ \end{tabular}
$$

## Write Operation

| State | Description |
| --- | --- |
| WRITE_ACT | Activate rows in a bank about given row address, to precharge cells, bitlines and sense amplifiers at 1/2 V_{dd}. |
| WRITE_NOP0 | Wait a single cycle for precharging by sense amplifiers |
| WRITE_CAS | Send column address to sense amplifier DeMUX and load input from the data buffer. |
| WRITE_NOP1 | Wait a single cycle to amplify charges in bit lines and cells by sense amplifiers |
| WRITE_NOP2 | Send ready signal outside of the DRAM chip, and close row and bit lines. |

$$
\begin{tabular}[h]{c:cc:c:ccccccc}Current State & sel & write & Next State & cs & we & ras & cas & bank\_select & dram\_addr & ready \\ \hline IDLE & 1 & 0 & WRITE\_ACT & x & x & x & x & x & x & 0 \\ WRITE\_ACT & x & x & WRITE\_NOP0 & 0 & 1 & 0 & 1 & bank\# & row\_address & 0 \\ WRITE\_NOP0 & x & x & WRITE\_CAS & 0 & 1 & 1 & 1 & 'd0 & 'd0 & 0 \\ WRITE\_CAS & x & x & WRITE\_NOP1 & 0 & 0 & 1 & 0 & bank\# & column\_address & 0 \\ WRITE\_NOP1 & x & x & WRITE\_NOP2 & 0 & 1 & 1 & 1 & 'd0 & 'd0 & 0 \\ WRITE\_NOP2 & x & x & IDLE & 1 & 1 & 1 & 1 & 'd0 & 'd0 & 1 \\ \end{tabular}
$$

# Testbench result screenshot

![image.png](attachment:ce354e6e-3183-41af-9a47-9c6c61a68e56:image.png)

# Appendix

## Appendix A. Memory Mapped I/O (MMIO)
