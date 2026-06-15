//######## tb_pl_sys#########

module tb_bram_to_buf();
parameter INT_BITS = 8;
parameter FRAC_BITS = 8;
parameter TOTAL_BITS = INT_BITS + FRAC_BITS;
parameter BUFFERS_SIZE=4;// NO.OF BUFFERS 
parameter PIXELS_SIZE=6;//IMAGE=6*6
parameter WEIGTHS_SIZE=3;//KERNEL=3*3
parameter BUFFER_DEPTH= WEIGTHS_SIZE*PIXELS_SIZE+(BUFFERS_SIZE-1);
parameter ADDR_WIDTH =6;
parameter ACCUM_BITS = 32;
parameter DATA_WIDTH=16;

reg clk,rst_n;
reg start;
reg signed [TOTAL_BITS-1:0] px_bram_data_in;
reg signed [TOTAL_BITS-1:0] wt_bram_data_in;
wire [2:0]state;
wire done;
wire signed [TOTAL_BITS-1:0] out_bram_data_out;


bram_to_buf uut(
.clk(clk),
.rst_n(rst_n),
.start(start),

.px_bram_data_in(px_bram_data_in),

.wt_bram_data_in(wt_bram_data_in),

.state(state),
.done(done),

.out_bram_data_out(out_bram_data_out)

);

initial
begin
clk = 1;
forever #1 clk=~clk;
end

// =================  MEMORY =================
reg signed [TOTAL_BITS-1:0] tb_px_mem [PIXELS_SIZE*PIXELS_SIZE-1:0];
reg signed [TOTAL_BITS-1:0] tb_wt_mem [WEIGTHS_SIZE*WEIGTHS_SIZE-1:0];


integer i;

// Load MEM file
initial begin
    $readmemh("wt.mem", tb_wt_mem); 
    $readmemh("px.mem", tb_px_mem);   // your pixel mem file
end

// ================= BRAM WRITE LOGIC =================
initial begin
    rst_n=0;
    start=0;
    
    @(posedge clk);
    rst_n=1;
    @(posedge clk);
    @(posedge clk);
    
    start=1;
    wait(state == bram_to_buf.LOAD_WT_TO_BRAM);
    @(posedge clk);
    for (i = 0; i < WEIGTHS_SIZE*WEIGTHS_SIZE; i = i + 1) begin
        
        @(posedge clk);
        wt_bram_data_in = tb_wt_mem[i];   // pixel value
        
    end
    
    wait(state == bram_to_buf.LOAD_PX_TO_BRAM);// NO USE OF THIS AS IT ALREADY GOES TO LOAD_PX_TO_BRAM BEFORE THIS COMMAND.
   
    for (i = 0; i < PIXELS_SIZE*PIXELS_SIZE; i = i + 1) begin
        @(posedge clk);
        px_bram_data_in = tb_px_mem[i];   // pixel value
        
    end
    
    $display("All pixels loaded into BRAM");
    
    wait(done == 1); 
    @(posedge clk);
    @(posedge clk);
    
    $finish;
 
   

    
end


initial
begin
    wait(start == 1);
    @(posedge clk);  // as our wish
    start=0;
end

integer f;
integer j;

initial begin
    wait(bram_to_buf.out_bram_re_en == 1);   // wait until outputs are ready
    
    @(posedge clk);
    f = $fopen("output3.mem", "w");

    for (j = 0; j < 16; j = j + 1) begin
        @(posedge clk);
        $fwrite(f, "%08h\n", out_bram_data_out);  // 32-bit hex
    end

    $fclose(f);

    $display("Output written to output3.mem");
end
endmodule
