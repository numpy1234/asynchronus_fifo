`timescale 1ns/1ps

module tb_async_fifo;

parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 4;

reg wr_clk;
reg rd_clk;
reg rst;
reg wr_en;
reg rd_en;
reg [DATA_WIDTH-1:0] din;

wire [DATA_WIDTH-1:0] dout;
wire full;
wire empty;

async_fifo #(
.DATA_WIDTH(DATA_WIDTH),
.ADDR_WIDTH(ADDR_WIDTH)
)dut(
.wr_clk(wr_clk),
.rd_clk(rd_clk),
.rst(rst),
.wr_en(wr_en),
.rd_en(rd_en),
.din(din),
.dout(dout),
.full(full),
.empty(empty)
);

// Write clock =100MHz
always #5 wr_clk = ~wr_clk;

// Read clock =71MHz
always #7 rd_clk = ~rd_clk;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb_async_fifo);

    wr_clk=0;
    rd_clk=0;
    rst=1;
    wr_en=0;
    rd_en=0;
    din=0;

    #20;
    rst=0;

    
    // Write 10 values
    
    repeat(10)
    begin
        @(posedge wr_clk);
        wr_en=1;
        din=din+1;
    end

    @(posedge wr_clk);
    wr_en=0;

    #30;

  
    // Read 10 values
   
    repeat(10)
    begin
        @(posedge rd_clk);
        rd_en=1;
    end

    @(posedge rd_clk);
    rd_en=0;

    #100;

    $finish;
end

initial begin
    $monitor("T=%0t WR=%b RD=%b DIN=%h DOUT=%h FULL=%b EMPTY=%b",
    $time,wr_en,rd_en,din,dout,full,empty);
end

endmodule