module clk_divn #(
parameter WIDTH = 30,  //this is the counter reg 's width，
parameter N = 2000001)// if N is 2, then the source clk f is divided by 2
 
(clk, clk_out);
 
input clk;
//input reset;
output clk_out;
reg [WIDTH-1:0] pos_count, neg_count;
wire [WIDTH-1:0] r_nxt;

initial begin
 pos_count =0;
 neg_count =0;
end
 
 always @(posedge clk)
 begin 
if (pos_count ==N-1) 
 pos_count <= 0;
 else 
 pos_count<= pos_count +1;
end
 
 always @(negedge clk)
 begin
  if (neg_count ==N-1) 
  neg_count <= 0;
  else 
  neg_count<= neg_count +1; 
  end
 
assign clk_out = ((pos_count > (N>>1)) | (neg_count > (N>>1))); 
endmodule