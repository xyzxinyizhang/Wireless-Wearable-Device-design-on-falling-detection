//this algorithm will keep LED off in a steady state, when the number of data(among 32) reach a threshold, it's a free_fall
//the control signal is for LED(active low)
//in steady state, control stays 1, LED off, whenver there is free_fall, conreol=0, LED light
//the only concern now is the "0" period is too short

//in  steady state, value from sensor should be around g.
//if there is a fall, there must be some data that not "around" g

//please change the k in testing

module top_level (flag , clk , data , done , control);
input flag;  //flag signal from I2C, tell algorithm can start
input [0:15] data [0:4]; //this is data array used for algorithm
input clk;
output logic done;   //after 32 cycle, the done will be 1, tell I2c to collect new data
output logic control;  //signal that connected to LED
logic[15:0] lower_limit;  //lower threshold
logic[15:0] upper_limit;  //upper threshold
logic [5:0] counter;  //counter width can be bigger if Nick needs longer "done" signal
integer k;
logic a,b,c;
//output logic alarm;

assign  lower_limit = 16'b 0011001100110011; //means this is 0.8g, maybe lower
assign  upper_limit = 16'b 0011111111111111; //this is 1g, maybe slightly larger than this value

initial begin 
k=1'b0;
counter = 1'b0;
//control=1'b0;
//done = 1'b0;
end

always@(negedge clk) begin  //here k can be a value larger than 32, this goves more time for "done" signal
if (flag==1'b1 & k<10 ) begin  //at 31, the real process finish, the additional k are used for "done" signal
k=k+1;
end
//end
else begin 
k=1'b0;
end
end

always@(posedge clk) begin  //here k should be set as 32, can not be larger than 32! ot it will go xxxx
if (flag==1'b1 & k<5 ) begin
//if (k<5) begin 
a = data[k] <=lower_limit;  //within the range, regard as steady state, out of range there is risk of free_fall
b=  data[k]>=upper_limit;
c=  a | b;                          //if this data is out of range, regarding it a fall_detection
counter = c ? counter+1'b1 : counter ;
//control = (counter>= 6'b000010) ? 1'b0 : 1'b1 ;  //if counter larger than 31, its steady state......not using this line any more
end
//end
else begin
counter = 1'b0;
//control=1'b1;  // off when it's in steady state......not using this line any more
end
end


assign control = (counter>= 6'b000010) ? 1'b0 : 1'b1 ;  //if counter larger than 3, its a free_fall!
                                                        //as LED is active low, when detect a fall, LED should light

assign done = (k==6 |k==7| k==8 |k==9| k==10) ? 1'b1 : 1'b0;

//assign done = (k==32 |k==33| k==34 |k==35| k==36 |k==37|k==38| k==39 |k==40| k==41 |k==42 |
//k==43 |k==44 |k==45 |k==46 |k==47 |k==48 |k==49 | k==50) ? 1'b1 : 1'b0;




endmodule
 
