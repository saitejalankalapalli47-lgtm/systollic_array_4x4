`timescale 1ns / 1ps

// It is a buffer in which we can write values through write address and read values through read address
// ================= BRAM BUFFER =================
module BRAM_Buffer #(
    parameter DATA_WIDTH = 16,
    parameter BUFFER_DEPTH = 32,
    parameter ADDR_WIDTH = $clog2(BUFFER_DEPTH)
)(
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire re_en,
    input wire [ADDR_WIDTH-1:0] wr_addr,
    input wire [ADDR_WIDTH-1:0] rd_addr,
    input wire signed [DATA_WIDTH-1:0] data_in,
    output reg signed [DATA_WIDTH-1:0] data_out
);

 
    (* ram_style = "block" *) 
    reg signed [DATA_WIDTH-1:0] ram [BUFFER_DEPTH-1:0];

    always @(posedge clk) begin
    if (!rst_n)
            data_out <= 0;
    else begin
        if (wr_en)
            ram[wr_addr] <= data_in;
        
        if (re_en) begin
            if (rd_addr < BUFFER_DEPTH)
                data_out <= ram[rd_addr];
            else
                data_out <= 0;
        end
        else
            data_out <= data_out;
    end

                
    end
endmodule
