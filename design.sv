module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input                   wr_clk,
    input                   rd_clk,
    input                   rst,

    input                   wr_en,
    input                   rd_en,

    input  [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,

    output full,
    output empty
);

localparam DEPTH = 1 << ADDR_WIDTH;

// Memory
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

// Binary pointers
reg [ADDR_WIDTH:0] wr_ptr_bin, rd_ptr_bin;

// Gray pointers
reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;

// Synchronized pointers
reg [ADDR_WIDTH:0] wr_gray_sync1, wr_gray_sync2;
reg [ADDR_WIDTH:0] rd_gray_sync1, rd_gray_sync2;

// Binary → Gray
function [ADDR_WIDTH:0] bin2gray;
    input [ADDR_WIDTH:0] bin;
begin
    bin2gray = (bin >> 1) ^ bin;
end
endfunction


// Write Logic

always @(posedge wr_clk or posedge rst)
begin
    if(rst) begin
        wr_ptr_bin  <= 0;
        wr_ptr_gray <= 0;
    end
    else if(wr_en && !full) begin
        mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= din;
        wr_ptr_bin  <= wr_ptr_bin + 1;
        wr_ptr_gray <= bin2gray(wr_ptr_bin + 1);
    end
end


// Read Logic

always @(posedge rd_clk or posedge rst)
begin
    if(rst) begin
        rd_ptr_bin  <= 0;
        rd_ptr_gray <= 0;
        dout <= 0;
    end
    else if(rd_en && !empty) begin
        dout <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
        rd_ptr_bin  <= rd_ptr_bin + 1;
        rd_ptr_gray <= bin2gray(rd_ptr_bin + 1);
    end
end


// Synchronize Read Pointer into Write Clock Domain

always @(posedge wr_clk or posedge rst)
begin
    if(rst) begin
        rd_gray_sync1 <= 0;
        rd_gray_sync2 <= 0;
    end
    else begin
        rd_gray_sync1 <= rd_ptr_gray;
        rd_gray_sync2 <= rd_gray_sync1;
    end
end


// Synchronize Write Pointer into Read Clock Domain

always @(posedge rd_clk or posedge rst)
begin
    if(rst) begin
        wr_gray_sync1 <= 0;
        wr_gray_sync2 <= 0;
    end
    else begin
        wr_gray_sync1 <= wr_ptr_gray;
        wr_gray_sync2 <= wr_gray_sync1;
    end
end


// Empty Detection

assign empty = (rd_ptr_gray == wr_gray_sync2);


// Full Detection

wire [ADDR_WIDTH:0] wr_gray_next;

assign wr_gray_next = bin2gray(wr_ptr_bin + 1);

assign full =
    (wr_gray_next ==
    {~rd_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
      rd_gray_sync2[ADDR_WIDTH-2:0]});

endmodule