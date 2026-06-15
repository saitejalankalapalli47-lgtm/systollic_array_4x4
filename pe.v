`timescale 1ns / 1ps


module PE #(
    parameter INT_BITS = 8,
    parameter FRAC_BITS = 8,
    parameter TOTAL_BITS = INT_BITS + FRAC_BITS,
    parameter ACCUM_BITS = 32
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire signed [TOTAL_BITS-1:0] pixel_in,
    input wire signed [TOTAL_BITS-1:0] weight_in,
    output reg signed [TOTAL_BITS-1:0] pixel_out,
    output reg signed [TOTAL_BITS-1:0] weight_out,
    output reg signed [ACCUM_BITS-1:0] accumulator
);

    wire signed [2*TOTAL_BITS-1:0] mult_result_raw;
    wire signed [ACCUM_BITS-1:0] mult_result;
    
    assign mult_result_raw = pixel_in * weight_in;
 
    assign mult_result = mult_result_raw >>> FRAC_BITS;
    
    always @(posedge clk ) begin
        if (!rst_n) begin
            pixel_out <= {TOTAL_BITS{1'b0}};
            weight_out <= {TOTAL_BITS{1'b0}};
            accumulator <= {ACCUM_BITS{1'b0}};
        end else if (enable) begin
            pixel_out <= pixel_in;
            weight_out <= weight_in;
            accumulator <= accumulator + mult_result;
        end
    end

endmodule
