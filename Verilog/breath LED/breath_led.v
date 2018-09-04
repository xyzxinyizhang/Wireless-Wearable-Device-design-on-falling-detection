module breathe_led
(
input   clk,
output reg  led
);
parameter FREQUENCE=50_000_000; //????????50MHZ????????,?????????????,
         //  ????????????clk???????????(????????????2s),???????????; 
         //  ?????????,?????,??????

parameter  WIDTH=9;
reg [WIDTH:0] state0;
reg [WIDTH-1:0] state1;

//=============================================
//????????????
//=============================================
reg [31:0] cnt0;
always @ (posedge clk)
begin
if(cnt0==(FREQUENCE/(2**WIDTH)))
  begin
   cnt0<=0;
   state0<=state0+1'b1;
  end
else
  begin
   cnt0<=cnt0+1'b1;
  end
end

//=============================================
//??????????
//=============================================
always @ (posedge clk)
begin
if(state0[WIDTH])
  state1<=state0[WIDTH-1:0];
else
  state1<=~state0[WIDTH-1:0]; 
end

//=============================================
//???state1??????????cnt1
//=============================================
wire [WIDTH-1:0] time_over;
assign time_over={WIDTH{1'b1}};
reg [WIDTH-1:0] cnt1;
always @ (posedge clk)
begin 
if(cnt1==time_over)
  begin
   cnt1<=0;
  end
else
  begin
   cnt1<=cnt1+1'b1;
  end
end

//=============================================
//???cnt1?state1??????,??led??????????
//=============================================
always @ (posedge clk)
begin
if((cnt1+time_over/3)<=state1) //????if(cnt1<=state1)????led??????,???????????(??????????),
         //?????time_over/3???,????led????????1/3???????
  led<=0;  //led?; ??led????,????led<=1;
else
  led<=1;  //led?; ??led????,????led<=0;
end
endmodule
