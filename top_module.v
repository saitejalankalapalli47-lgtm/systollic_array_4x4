//#############pl_systolic_array##############



module bram_to_buf#(
parameter INT_BITS = 8,
parameter FRAC_BITS = 8,
parameter TOTAL_BITS = INT_BITS + FRAC_BITS,
parameter ACCUM_BITS=2*TOTAL_BITS,

parameter PIXELS_SIZE=6,//IMAGE=6*6
parameter WEIGTHS_SIZE=3,//KERNEL=3*3

parameter BUFFERS_SIZE=(PIXELS_SIZE-(WEIGTHS_SIZE-1)),// NO.OF BUFFERS 6-(3-1) 
parameter ROWS=BUFFERS_SIZE,
parameter COLS=BUFFERS_SIZE,

parameter BUFFER_DEPTH= WEIGTHS_SIZE*PIXELS_SIZE+(BUFFERS_SIZE-1),
parameter PX_ADDR_WIDTH = $clog2(PIXELS_SIZE*PIXELS_SIZE),
parameter WT_ADDR_WIDTH = $clog2(WEIGTHS_SIZE*WEIGTHS_SIZE),
parameter OUT_ADDR_WIDTH = $clog2(BUFFERS_SIZE*BUFFERS_SIZE),
parameter LOAD_ADDR_WIDTH= $clog2(WEIGTHS_SIZE*PIXELS_SIZE+(BUFFERS_SIZE-1))
)(
input clk,rst_n,
input start,

input signed [TOTAL_BITS-1:0] px_bram_data_in,

input signed [TOTAL_BITS-1:0] wt_bram_data_in,

output [2:0]state,
output reg done,

output signed [TOTAL_BITS-1:0] out_bram_data_out

);



localparam  IDLE=3'd0,
          LOAD_WT_TO_BRAM=3'd1,
          LOAD_PX_TO_BRAM=3'd2,
          LOAD=3'd3,       
          READ=3'd4,
          STORE_TO_MEM=3'd5,
          DONE=3'd6;

reg pe_en;
wire signed[ACCUM_BITS-1:0]pe_ar [ROWS-1:0][COLS-1:0];
      
reg [PX_ADDR_WIDTH-1:0] px_bram_ld_ct;  
reg [WT_ADDR_WIDTH-1:0] wt_bram_ld_ct;
      
reg px_bram_ld_en;
reg [PX_ADDR_WIDTH-1:0] px_bram_wr_ad;      
reg wt_bram_ld_en;
reg [WT_ADDR_WIDTH-1:0] wt_bram_wr_ad;
wire signed [TOTAL_BITS-1:0] px_in1,px_in2;  
reg [PX_ADDR_WIDTH-1:0] px1_ad,px2_ad;
reg px_wt_en;

reg [WT_ADDR_WIDTH-1:0] wt_ad;
wire signed [TOTAL_BITS-1:0] wt_in;


reg [LOAD_ADDR_WIDTH-1:0] buf_wr_ad,buf_re_ad; 
reg signed [TOTAL_BITS-1:0] data_in [BUFFERS_SIZE-1:0];
wire signed [TOTAL_BITS-1:0] data_out [BUFFERS_SIZE-1:0];
reg wr_en,re_en;

 
reg signed [TOTAL_BITS-1:0] wt_data_in [BUFFERS_SIZE-1:0];
wire signed [TOTAL_BITS-1:0] wt_data_out [BUFFERS_SIZE-1:0];


reg out_bram_ld_en;
reg out_bram_re_en;
reg [OUT_ADDR_WIDTH-1:0] out_bram_wr_ad;
reg [OUT_ADDR_WIDTH-1:0] out_bram_re_ad;
reg signed [TOTAL_BITS-1:0] out_bram_data_in;
reg [OUT_ADDR_WIDTH-1:0] out_bram_r_ct;
reg [OUT_ADDR_WIDTH-1:0] out_bram_c_ct;

reg [2:0] current_state,next_state;
reg [$clog2(WEIGTHS_SIZE*PIXELS_SIZE+(BUFFERS_SIZE-1))-1:0] load_count; 
reg [$clog2((WEIGTHS_SIZE*WEIGTHS_SIZE)+(BUFFERS_SIZE*BUFFERS_SIZE))-1:0] read_count;/////just to verify
reg [OUT_ADDR_WIDTH-1:0] st_count;

integer k,w;
reg [2:0] m;   //$clog2 (PIXELS_SIZE)
reg [1:0] n;   //$clog2 (WEIGHTS_SIZE)

// 3-cycle pipeline alignment for BRAM + PE latency
reg [4:0] count_d,count_dd,count_ddd;
reg [1:0] n_d,n_dd,n_ddd;

reg  signed [TOTAL_BITS-1:0] px_in1_d,px_in2_d,wt_in_d;

reg signed [TOTAL_BITS-1:0] wt_pp [BUFFERS_SIZE * (BUFFERS_SIZE - 1)-2:0];


 genvar i;
    generate
        for (i=0; i<BUFFERS_SIZE; i=i+1) begin : BUFFERS
            BRAM_Buffer #(.DATA_WIDTH(TOTAL_BITS), .BUFFER_DEPTH(BUFFER_DEPTH),.ADDR_WIDTH(LOAD_ADDR_WIDTH)) 
            lb (.clk(clk), .rst_n(rst_n), .wr_en(wr_en), .re_en(re_en), .wr_addr(buf_wr_ad), .rd_addr(buf_re_ad), .data_in(data_in[i]), .data_out(data_out[i]));
            
            BRAM_Buffer #(.DATA_WIDTH(TOTAL_BITS), .BUFFER_DEPTH(BUFFER_DEPTH),.ADDR_WIDTH(LOAD_ADDR_WIDTH)) 
            wb (.clk(clk), .rst_n(rst_n), .wr_en(wr_en), .re_en(re_en), .wr_addr(buf_wr_ad), .rd_addr(buf_re_ad), .data_in(wt_data_in[i]), .data_out(wt_data_out[i]));
        end
    endgenerate
  

BRAM_2_outdata #(.DATA_WIDTH (TOTAL_BITS),.BUFFER_DEPTH (PIXELS_SIZE*PIXELS_SIZE),.ADDR_WIDTH(PX_ADDR_WIDTH))
ldp( .clk(clk), .rst_n(rst_n), .wr_en(px_bram_ld_en), .re_en(px_wt_en),.wr_addr(px_bram_wr_ad), .rd_addr1(px1_ad), .rd_addr2(px2_ad), .data_in(px_bram_data_in), .data_out1(px_in1), .data_out2(px_in2));

BRAM_Buffer #(.DATA_WIDTH(TOTAL_BITS), .BUFFER_DEPTH(WEIGTHS_SIZE*WEIGTHS_SIZE),.ADDR_WIDTH(WT_ADDR_WIDTH)) 
ldw (.clk(clk), .rst_n(rst_n), .wr_en(wt_bram_ld_en),  .re_en(px_wt_en), .wr_addr(wt_bram_wr_ad), .rd_addr(wt_ad), .data_in(wt_bram_data_in), .data_out(wt_in));

pe_array pe( .clk(clk),.rst_n(rst_n),.enable(pe_en),
.pixel_buf0(data_out[0]),.pixel_buf1(data_out[1]),.pixel_buf2(data_out[2]),.pixel_buf3(data_out[3]),
.weight_buf0(wt_data_out[0]),.weight_buf1(wt_data_out[1]),.weight_buf2(wt_data_out[2]),.weight_buf3(wt_data_out[3]),
.pe_out00( pe_ar[0][0]),.pe_out01( pe_ar[0][1]),.pe_out02( pe_ar[0][2]),.pe_out03( pe_ar[0][3]),
.pe_out10( pe_ar[1][0]),.pe_out11( pe_ar[1][1]),.pe_out12( pe_ar[1][2]),.pe_out13( pe_ar[1][3]),
.pe_out20( pe_ar[2][0]),.pe_out21( pe_ar[2][1]),.pe_out22( pe_ar[2][2]),.pe_out23( pe_ar[2][3]),
.pe_out30( pe_ar[3][0]),.pe_out31( pe_ar[3][1]),.pe_out32( pe_ar[3][2]),.pe_out33( pe_ar[3][3])
);

BRAM_Buffer #(.DATA_WIDTH(TOTAL_BITS), .BUFFER_DEPTH(BUFFERS_SIZE*BUFFERS_SIZE),.ADDR_WIDTH(OUT_ADDR_WIDTH)) 
ldo (.clk(clk), .rst_n(rst_n), .wr_en(out_bram_ld_en),  .re_en(out_bram_re_en), .wr_addr(out_bram_wr_ad), .rd_addr(out_bram_re_ad), .data_in(out_bram_data_in), .data_out(out_bram_data_out));

always@(posedge clk )
begin
if(!rst_n)      current_state<=IDLE;
else            current_state<=next_state;
end

always@(*)
begin 
case(current_state)
    
    IDLE: begin
          if (start)    next_state<=LOAD_WT_TO_BRAM;
          else          next_state<=IDLE;
          end
    LOAD_WT_TO_BRAM: begin
          if (wt_bram_ld_ct == (WEIGTHS_SIZE*WEIGTHS_SIZE)-1 )    next_state<=LOAD_PX_TO_BRAM;
          else          next_state<=LOAD_WT_TO_BRAM;
          end
    LOAD_PX_TO_BRAM: begin
          if (px_bram_ld_ct == (PIXELS_SIZE*PIXELS_SIZE)-1)    next_state<=LOAD;
          else          next_state<=LOAD_PX_TO_BRAM;
          end
    LOAD: begin
          if(load_count==(BUFFER_DEPTH+3)-1)    next_state<=READ;  //If pipeline latency = L cycles--->BUFFER_DEPTH + L
          else                                  next_state<=LOAD;
          end
    READ: begin
          if(read_count == (WEIGTHS_SIZE*WEIGTHS_SIZE)+(BUFFERS_SIZE*BUFFERS_SIZE)+2-1)   next_state<=STORE_TO_MEM;
          else                                                                          next_state<=READ;
          end
    
    STORE_TO_MEM:                             
          begin
          if(st_count == (BUFFERS_SIZE*BUFFERS_SIZE)-1)   next_state<=DONE;
          else                                            next_state<=STORE_TO_MEM;
          end
    DONE:  next_state<=DONE;
    default:    next_state<=IDLE;
endcase
end



always@(posedge clk )
begin
if(!rst_n)
begin
    //pipelines
    count_d <= 0; count_dd <= 0; count_ddd <= 0; 
    n_d <= 0; n_dd <= 0; n_ddd <= 0;
    px_in1_d <= 0; px_in2_d <= 0; wt_in_d <= 0;
    
    m <= 0;
    n <= 0;
    px_wt_en <= 0;
    wt_ad <=0;
    px1_ad <= 0;
    px2_ad <= 0;
    buf_wr_ad <= 0;
    wr_en <= 0;
    load_count <= 0;
    buf_re_ad <= 0;
    re_en <= 0;
    read_count <= 0;
    done <= 0;
    px_bram_ld_ct <= 0;
    wt_bram_ld_ct <= 0;
    px_bram_ld_en <= 0;
    px_bram_wr_ad <= 0; 
    wt_bram_ld_en <= 0;
    wt_bram_wr_ad <= 0; 
    pe_en <= 0;
    out_bram_ld_en <= 0;
    out_bram_wr_ad <= 0 ;      
    out_bram_r_ct <= 0;
    out_bram_c_ct <= 0;
    st_count <=0;
    
    out_bram_re_en <= 0;
    out_bram_re_ad <= 0;
    
        for (w=0; w<(BUFFERS_SIZE * (BUFFERS_SIZE - 1)-1); w=w+1)   
        wt_pp[w] <= 0;
        for (k=0; k<BUFFERS_SIZE; k=k+1) begin
        //data_in[k] <= 0;
            wt_data_in[k] <= 0;
        end 
  /*      //###Later (optimization stage):Remove unnecessary data resets
        for (k=0; k<BUFFERS_SIZE; k=k+1) begin
        data_in[k] <= 0;
        wt_data_in[k] <= 0;
        end
            
        
       
        out_bram_data_in <= 0;*/
end
else
begin
    //pipelines
    count_d <= load_count;
    n_d <= n;
    count_dd <= count_d;
    n_dd <= n_d;
    count_ddd <= count_dd;
    n_ddd <= n_dd;   
    px_in1_d <= px_in1;
    px_in2_d <= px_in2;
    wt_in_d <=  wt_in;
    
    wt_bram_ld_en <= (current_state == LOAD_WT_TO_BRAM);
    px_bram_ld_en <= (current_state == LOAD_PX_TO_BRAM);
    px_wt_en <= (current_state == LOAD && load_count < BUFFER_DEPTH);
    
    wr_en <= (current_state == LOAD && load_count >= 3 && load_count <BUFFER_DEPTH+3);
    done<= (current_state == DONE);
    re_en <= (current_state == READ && read_count < BUFFER_DEPTH); 
    
    pe_en <= (current_state == READ &&read_count>=1 &&read_count< (WEIGTHS_SIZE*WEIGTHS_SIZE)+(BUFFERS_SIZE*BUFFERS_SIZE) );
    out_bram_ld_en <=(read_count>WEIGTHS_SIZE*WEIGTHS_SIZE+1 && read_count<=WEIGTHS_SIZE*WEIGTHS_SIZE+BUFFERS_SIZE*BUFFERS_SIZE+1) ;//&& read_count<=9+16+1+1
    out_bram_re_en <= (current_state == STORE_TO_MEM && st_count < BUFFERS_SIZE*BUFFERS_SIZE); 

case(current_state)
    IDLE:
        begin
        m <= 0;
        n <= 0;
        
        px1_ad <= 0;
        px2_ad <= 0;
        wt_ad <=0;
        buf_wr_ad <= 0;

        load_count <= 0;
        buf_re_ad <= 0;
        re_en <= 0;
        read_count <= 0;

        px_bram_ld_ct <= 0;
        wt_bram_ld_ct <= 0;
    
        px_bram_wr_ad <= 0; 
       
        wt_bram_wr_ad <= 0; 
        

        
        st_count <= 0;
        
        out_bram_re_ad <= 0;
        for (w=0; w<(BUFFERS_SIZE * (BUFFERS_SIZE - 1)-1); w=w+1)   
        wt_pp[w] <= 0;
        for (k=0; k<BUFFERS_SIZE; k=k+1) begin
       // data_in[k] <= 0;
            wt_data_in[k] <= 0;
        end 
  /*      //###Later (optimization stage):Remove unnecessary data resets
              
        out_bram_data_in <= 0;*/
        end
    LOAD_WT_TO_BRAM: 
        begin
          wt_bram_ld_ct <= wt_bram_ld_ct+1;
         
          wt_bram_wr_ad <= wt_bram_ld_ct;
        end
    LOAD_PX_TO_BRAM: 
        begin
          px_bram_ld_ct <= px_bram_ld_ct+1;
          px_bram_ld_en <=1;
          px_bram_wr_ad <= px_bram_ld_ct;
        end
    LOAD:
        begin
        
       
        load_count <= load_count+1;
        
        buf_wr_ad<=count_ddd;// if we do direct increment then we clear the signal in IDLE.
        data_in[0] <=(count_ddd>(3*PIXELS_SIZE)-1)?0:px_in1_d;  //base +: constant_width --->[start_bit + 15 : start_bit]
        data_in[1] <=(count_ddd<1||count_ddd>(3*PIXELS_SIZE))?0:(n_ddd==0)?px_in2_d:px_in1_d ;
        data_in[2] <=(count_ddd<2||count_ddd>(3*PIXELS_SIZE)+1)?0:(n_ddd<2)?px_in2_d:px_in1_d;
        data_in[3] <=(count_ddd<3)?0:px_in2_d ;

        
        // stage 0 input
        wt_data_in[0] <= (count_ddd > (WEIGTHS_SIZE*WEIGTHS_SIZE)-1) ? 0 : wt_in_d;
        
        // shift pipeline
        wt_pp[0] <= wt_data_in[0];
        
        for (k = 1; k < BUFFERS_SIZE * (BUFFERS_SIZE - 1)-1; k = k + 1) begin
            wt_pp[k] <= wt_pp[k-1];
        end 
        
        for (w = 1; w < BUFFERS_SIZE; w = w + 1) begin
            wt_data_in[w] <= wt_pp[w * BUFFERS_SIZE - 2];
        end         

        if(load_count < BUFFER_DEPTH) begin
        px1_ad <= m + (PIXELS_SIZE*n);
        px2_ad <= m + (PIXELS_SIZE*n) + (3*PIXELS_SIZE) - 1;
        wt_ad <= m + (WEIGTHS_SIZE*n);
            if(n >= WEIGTHS_SIZE-1) begin
            n <= 0;
            m <= m + 1;
            end
            else begin
            n <= n + 1;
            end
        end
        else begin
        m <=0; n<=0;
        end
        
        
        end
    READ:
        begin
        read_count<=read_count+1;
        if(read_count < BUFFER_DEPTH) 
        buf_re_ad<=read_count;       
        //load or write to out_bram
        if(read_count>WEIGTHS_SIZE*WEIGTHS_SIZE+1 && read_count<=WEIGTHS_SIZE*WEIGTHS_SIZE+BUFFERS_SIZE*BUFFERS_SIZE+1)
        begin
        out_bram_wr_ad <= (out_bram_r_ct*BUFFERS_SIZE)+out_bram_c_ct ;
        out_bram_data_in <= pe_ar[out_bram_r_ct][out_bram_c_ct];
            if (out_bram_r_ct == BUFFERS_SIZE-1)
            begin
            out_bram_r_ct <= 0;
            out_bram_c_ct <= out_bram_c_ct+1;
            end
            else
            out_bram_r_ct <=out_bram_r_ct+1;
        end
        end
    STORE_TO_MEM:                                         
        begin
        st_count <= st_count+1;                         
        out_bram_re_ad <= st_count; 
        end
    DONE:
        begin
       // just to not skip
        end
    default:
        begin
        // just to not skip
        end
endcase
end
end
//always @(posedge clk)
//begin
//$strobe(
//"t=%0t | st=%0d | ld_ct=%0d re_ct=%0d | m=%0d n=%0d k=%0d w=%0d | ld=%0d rd=%0d | px_wt_en=%0d | wt_ad=%0d wt_in=%0h | px1_ad=%0d px2_ad=%0d | px1=%0h px2=%0h | wr_en=%0d  re_en=%0d | wr_ad=%0d  re_ad=%0d | wt_in=[%0h %0h %0h %0h] | wt_out=[%0h %0h %0h %0h]|in=[%0h %0h %0h %0h] | out=[%0h %0h %0h %0h]|",
//$time,
//state,
//load_count,read_count,
//m,n,k,w,
//load_done,read_done,
//px_wt_en,
//wt_ad, wt_in,
//px1_ad,px2_ad,
//px_in1,px_in2,
//wr_en,re_en,
//buf_wr_ad,buf_re_ad,
//wt_data_in[0],wt_data_in[1],wt_data_in[2],wt_data_in[3],
//wt_data_out[0] ,wt_data_out[1] ,wt_data_out[2] ,wt_data_out[3] ,
//data_in[0],data_in[1],data_in[2],data_in[3],
//data_out[0],data_out[1],data_out[2],data_out[3],
//);
//end

//always @(posedge clk)
//begin
//$strobe(
//"t=%0t | st=%0d | ld_ct=%0d re_ct=%0d | k=%0d w=%0d | ld=%0d rd=%0d |  re_en=%0d | re_ad=%0d | pe_en=%0d | wt_out=[%0h %0h %0h %0h]| out=[%0h %0h %0h %0h]| pe_0=[%0h %0h %0h %0h]| pe_1=[%0h %0h %0h %0h]| pe_2=[%0h %0h %0h %0h]| pe_3=[%0h %0h %0h %0h]",
//$time,
//state,
//load_count,read_count,
//k,w,
//load_done,read_done,
//re_en,
//buf_re_ad,
//pe_en,
//wt_data_out[0] ,wt_data_out[1] ,wt_data_out[2] ,wt_data_out[3] ,
//data_out[0],data_out[1],data_out[2],data_out[3],
//pe_ar[0][0],pe_ar[0][1],pe_ar[0][2],pe_ar[0][3],
//pe_ar[1][0],pe_ar[1][1],pe_ar[1][2],pe_ar[1][3],
//pe_ar[2][0],pe_ar[2][1],pe_ar[2][2],pe_ar[2][3],
//pe_ar[3][0],pe_ar[3][1],pe_ar[3][2],pe_ar[3][3]

//);
//end

//always @(posedge clk)
//begin
//$strobe(
//"t=%0t | st=%0d | re_ct=%0d rd=%0d | pe_0=[%0h %0h %0h %0h]| pe_1=[%0h %0h %0h %0h]| pe_2=[%0h %0h %0h %0h]| pe_3=[%0h %0h %0h %0h] | st_ct=%0d  r_ct=%0d c_ct=%0d | ld_en=%0d wr_ad=%0d in=%0h | re_en=%0d re_ad=%0d out=%0h | ",
//$time,
//state,
//read_count,done,
//pe_ar[0][0],pe_ar[0][1],pe_ar[0][2],pe_ar[0][3],
//pe_ar[1][0],pe_ar[1][1],pe_ar[1][2],pe_ar[1][3],
//pe_ar[2][0],pe_ar[2][1],pe_ar[2][2],pe_ar[2][3],
//pe_ar[3][0],pe_ar[3][1],pe_ar[3][2],pe_ar[3][3],
//st_count,
//out_bram_r_ct , out_bram_c_ct,
//out_bram_ld_en , out_bram_wr_ad,
//out_bram_data_in , out_bram_re_en , 
//out_bram_re_ad , out_bram_data_out
//);
//end
/*
always @(posedge clk)
begin
$strobe(
"t=%0t | st=%0d | w_l_ct=%0d w_l_e=%0d  w_wr_ad=%0d w_data_in=%0h | p_l_ct=%0d p_l_e=%0d  p_wr_ad=%0d p_data_in=%0h| \
ld_ct=%0d re_ct=%0d | m=%0d n=%0d k=%0d w=%0d | done=%0d | \
px_wt_en=%0d | wt_ad=%0d wt_in=%0h | px1_ad=%0d px2_ad=%0d | px1=%0h px2=%0h | \
wr_en=%0d re_en=%0d | wr_ad=%0d re_ad=%0d | \
wt_in_buf=[%0h %0h %0h %0h] | wt_out_buf=[%0h %0h %0h %0h] | \
px_in_buf=[%0h %0h %0h %0h] | px_out_buf=[%0h %0h %0h %0h] | \
pe_en=%0d | \
pe_0=[%0h %0h %0h %0h] | pe_1=[%0h %0h %0h %0h] | pe_2=[%0h %0h %0h %0h] | pe_3=[%0h %0h %0h %0h] | \
st_ct=%0d r_ct=%0d c_ct=%0d | \
out_ld_en=%0d out_wr_ad=%0d out_in=%0h | \
out_re_en=%0d out_re_ad=%0d out=%0h",
$time,
state,
wt_bram_ld_ct,wt_bram_ld_en,wt_bram_wr_ad,wt_bram_data_in,px_bram_ld_ct,px_bram_ld_en,px_bram_wr_ad,px_bram_data_in,
load_count,read_count,
m,n,k,w,
done,

px_wt_en,

wt_ad, wt_in,

px1_ad, px2_ad,
px_in1, px_in2,

wr_en, re_en,
buf_wr_ad, buf_re_ad,

wt_data_in[0],wt_data_in[1],wt_data_in[2],wt_data_in[3],
wt_data_out[0],wt_data_out[1],wt_data_out[2],wt_data_out[3],

data_in[0],data_in[1],data_in[2],data_in[3],
data_out[0],data_out[1],data_out[2],data_out[3],

pe_en,

pe_ar[0][0],pe_ar[0][1],pe_ar[0][2],pe_ar[0][3],
pe_ar[1][0],pe_ar[1][1],pe_ar[1][2],pe_ar[1][3],
pe_ar[2][0],pe_ar[2][1],pe_ar[2][2],pe_ar[2][3],
pe_ar[3][0],pe_ar[3][1],pe_ar[3][2],pe_ar[3][3],

st_count,
out_bram_r_ct, out_bram_c_ct,

out_bram_ld_en, out_bram_wr_ad, out_bram_data_in,
out_bram_re_en, out_bram_re_ad, out_bram_data_out
);
end
*/
assign state=current_state ;  
endmodule
