`timescale 1ns / 1ps


// PE array which has 16 PE blocks as a 4x4 grid in which the pixels move from left to right and the weights move from top to bottom


module pe_array#(
    parameter INT_BITS = 8,
    parameter FRAC_BITS = 8,
    parameter TOTAL_BITS = INT_BITS + FRAC_BITS,
    parameter ACCUM_BITS = 32,
    parameter ROWS=4,
    parameter COLS=4
    )
    (
    input clk,rst_n,
    input enable,
    input signed [TOTAL_BITS-1:0]pixel_buf0,pixel_buf1,pixel_buf2,pixel_buf3,
    input signed [TOTAL_BITS-1:0]weight_buf0,weight_buf1,weight_buf2,weight_buf3,
    output   signed[ACCUM_BITS-1:0]pe_out00,pe_out01,pe_out02,pe_out03,
    output   signed[ACCUM_BITS-1:0]pe_out10,pe_out11,pe_out12,pe_out13,
    output   signed[ACCUM_BITS-1:0]pe_out20,pe_out21,pe_out22,pe_out23,
    output   signed[ACCUM_BITS-1:0]pe_out30,pe_out31,pe_out32,pe_out33
    );
    
    wire signed[TOTAL_BITS-1:0]pixel_h[ROWS-1:0][COLS:0];
    wire signed[TOTAL_BITS-1:0]weight_v[ROWS:0][COLS-1:0];
    
    wire signed[ACCUM_BITS-1:0]pe_accum[ROWS-1:0][COLS-1:0];
    assign pixel_h[0][0]=pixel_buf0;
    assign pixel_h[1][0]=pixel_buf1;
    assign pixel_h[2][0]=pixel_buf2;
    assign pixel_h[3][0]=pixel_buf3;
    assign weight_v[0][0]=weight_buf0;
    assign weight_v[0][1]=weight_buf1;
    assign weight_v[0][2]=weight_buf2;
    assign weight_v[0][3]=weight_buf3;
       
    
    genvar i,j;
    generate
    for(i=0;i< ROWS;i=i+1)
    begin:pe_row
    for(j=0;j<COLS;j=j+1)
    begin:pe_col
    
    PE#(
    .INT_BITS(INT_BITS),
    .FRAC_BITS(FRAC_BITS),
    .TOTAL_BITS(TOTAL_BITS),
    .ACCUM_BITS(ACCUM_BITS)
    )pe_inst
    (
     .clk(clk),
     .rst_n(rst_n),
     .enable(enable),
     .pixel_in(pixel_h[i][j]),
     .weight_in(weight_v[i][j]),
     .pixel_out(pixel_h[i][j+1]),
     .weight_out(weight_v[i+1][j]),
     .accumulator(pe_accum[i][j])

    );
    
                
    end
    end
    endgenerate
    
            
                 assign pe_out00 = pe_accum[0][0];
  
                 assign pe_out01 = pe_accum[0][1];
    
                assign pe_out02 = pe_accum[0][2];
            
                assign pe_out03 = pe_accum[0][3];
                
     
                 assign pe_out10 = pe_accum[1][0];
     
                 assign pe_out11 = pe_accum[1][1];

                 assign pe_out12 = pe_accum[1][2];
      
                 assign pe_out13 = pe_accum[1][3];
                
 
                 assign pe_out20 = pe_accum[2][0];
         
                assign pe_out21 = pe_accum[2][1];
    
                assign pe_out22 = pe_accum[2][2];
           
                 assign pe_out23 = pe_accum[2][3];
                
           
                 assign pe_out30 = pe_accum[3][0];
             
                assign pe_out31 = pe_accum[3][1];
            
                assign pe_out32 = pe_accum[3][2];
          
                assign pe_out33 = pe_accum[3][3];

endmodule
