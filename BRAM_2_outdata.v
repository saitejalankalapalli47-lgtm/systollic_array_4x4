
// It is a dual port BRAM in which it outputs only 2 values at a time

module BRAM_2_outdata #(
    parameter DATA_WIDTH = 16,
    parameter BUFFER_DEPTH = 32,
    parameter ADDR_WIDTH = $clog2(BUFFER_DEPTH)
)(
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire re_en,
    input wire [ADDR_WIDTH-1:0] wr_addr,
    input wire [ADDR_WIDTH-1:0] rd_addr1,
    input wire [ADDR_WIDTH-1:0] rd_addr2,
    input wire signed [DATA_WIDTH-1:0] data_in,
    output reg signed [DATA_WIDTH-1:0] data_out1,
    output reg signed [DATA_WIDTH-1:0] data_out2
);

 
    (* ram_style = "block" *) 
    reg signed [DATA_WIDTH-1:0] ram [BUFFER_DEPTH-1:0];

    always @(posedge clk) begin
    if (!rst_n) begin
            data_out1 <= 0;
            data_out2 <= 0;
    end
    else begin
      // Write Operation
        if (wr_en) begin
            ram[wr_addr] <= data_in;
        end

    // Read Operation (Synchronous BRAM)
        if (re_en) begin
            data_out1 <= ram[rd_addr1];
            data_out2 <= ram[rd_addr2];
        end
    end
    end

endmodule
