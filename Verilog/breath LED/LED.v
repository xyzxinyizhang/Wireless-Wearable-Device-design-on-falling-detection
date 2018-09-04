module led (clk, toggle, led);
input clk;
input toggle;
output led;
reg flag;
reg cnt_0;
reg [30:0]cnt_1;

parameter FREQUENCE=27_000_000;
parameter  WIDTH=1;

always @ (posedge toggle or flag )
if (flag)
begin
cnt_0<=0;
end 
else 
begin
cnt_0<=cnt_0+1;
end






always @ (posedge clk) //counter to counter the clk. lighting time
begin
if (cnt_0==1)
begin
   if(cnt_1==(FREQUENCE/(WIDTH)))
      begin
      cnt_1<=0;
     end
     else begin
     cnt_1<=cnt_1+1'b1;
     end
end
end

assign led = (cnt_1!=0) ? 0:1;

endmodule





