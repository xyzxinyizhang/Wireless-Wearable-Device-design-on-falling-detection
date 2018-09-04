module sensor (input logic  sys_clk,
                            read_done,  // Set to poll the sensor after reading
                            
                            debug,      // assert to activate debug mode
               inout wire   scl,        // Connect to ball C1
                            sda,        // Connect to ball E2
               output logic data_ready, // Safe to use data when set
                            debug_o//,    // low if I2C is working as expected
               //output logic [15:0] buffer [31:0]
              );
              
    // These will tell the machine when and where to latch the sensor data.
    logic latch_higher, latch_lower, check_flag, new_data = 0, lock_index = 0;
    logic [4:0] index = 5'b11_111;
    
    // Various signals to i2c
    logic busy, /*rw,*/ ena;
    logic [7:0] addr, data_wr, data_rd;
    logic [15:0] buffer [31:0]; //temp
    logic [8:0]poweron_reset_count_i = 9'b0;
    logic sys_rst;
    logic poweron_reset_n_i;

    always @(posedge sys_clk)begin
        if(poweron_reset_count_i == 256)begin
            poweron_reset_count_i <= 256;
        end else begin
            poweron_reset_count_i <= poweron_reset_count_i + 1;
        end
    end

    always @(posedge sys_clk)begin
        if(poweron_reset_count_i == 256)begin
            poweron_reset_n_i <= 1;
        end else begin
            poweron_reset_n_i <= 0;
        end
    end

   assign sys_rst = ~poweron_reset_n_i;
    
   i2c_master i2c_master_inst (
                                .scl     (scl), 
                                .sda     (sda),
                                .reset_n (~sys_rst),
                                .clk     (sys_clk),
                                .rw      (addr[0]),
                                .ena     (ena),
                                .addr    (addr[7:1]),
                                .data_wr (data_wr),
                                .data_rd (data_rd),
                                .busy    (busy)
                             );

    typedef enum logic [4:0] {RESET,
                              // Four steps for enabling the accelerometer
                              START_SEND_ADDRESS,
                              START_WAIT_ACK,
                              START_WRITE_MODE,
                              START_SETUP_DONE,
                              // Four steps for reading known value for debug
                              DEBUG_SEND_ADDRESS,
                              DEBUG_WAIT_ACK,
                              DEBUG_READ_COMMAND,
                              DEBUG_GET_DATA,
                              // Four steps for checking for new sensor data
                              CHECK_SEND_ADDRESS,
                              CHECK_WAIT_ACK,
                              CHECK_READ_COMMAND,
                              CHECK_GET_DATA,
                              // Four steps for getting the low byte from sensor
                              LOW_SEND_ADDRESS,
                              LOW_WAIT_ACK,
                              LOW_READ_COMMAND,
                              LOW_GET_DATA,
                              // Four steps for getting the high byte from sensor
                              HIGH_SEND_ADDRESS,
                              HIGH_WAIT_ACK,
                              HIGH_READ_COMMAND,
                              HIGH_GET_DATA,
                              // Three Steps for the Elven-kings under the sky,
                              // Seven for the Dwarf-lords in halls of stone,
                              // Nine for Mortal Men, doomed to die,
                              // One for the Dark Lord on his dark throne
                              // In the Land of Mordor where the Shadows lie.
                              // One Step to rule them all, One Step to find them,
                              // One Step to bring them all and in the darkness bind them.
                              // In the Land of Mordor where the Shadows lie.
                              BUFFER_FULL // This is that One Step.
                            } statetype;
    
    statetype [4:0] state, nextstate;
    
    // state register
    always_ff @(posedge sys_clk)
        if (sys_rst) state <= RESET;
        else       state <= nextstate;
        
 /*   // debug output
    always_ff @(posedge sys_clk)
        if (sys_rst) debug_o <= 0;
        else if ((state == DEBUG_GET_DATA) & busy)
            debug_o <= ~(data_rd == 8'h74); // We just tried to set this register.
*/

assign debug_o = state != START_SEND_ADDRESS;

    // latch data when needed
    always @(posedge latch_higher) begin
        buffer[index] <= buffer[index] | {data_rd, 8'b0};
        index <= index - 1;
    end

    always @(posedge latch_lower)
        // latch low byte of sensor data
        buffer[index] <= {8'b0, data_rd};

    always @(posedge check_flag)
        // start adding data at the back of the buffer
        new_data <= data_rd[2];
    
    // next state logic
    always_comb
        case (state)
            RESET:                                  nextstate = START_SEND_ADDRESS;

            START_SEND_ADDRESS: if (busy)           nextstate = START_WAIT_ACK;
                                else                nextstate = START_SEND_ADDRESS;

            START_WAIT_ACK:     if (busy)           nextstate = START_WAIT_ACK;
                                else                nextstate = START_WRITE_MODE;

            START_WRITE_MODE:   if (busy)           nextstate = START_SETUP_DONE;
                                else                nextstate = START_WRITE_MODE;

            START_SETUP_DONE:   if (busy)           nextstate = START_SETUP_DONE;
                                else if (debug)     nextstate = DEBUG_SEND_ADDRESS;
                                else                nextstate = CHECK_SEND_ADDRESS;
            
            DEBUG_SEND_ADDRESS: if (busy)           nextstate = DEBUG_WAIT_ACK;
                                else                nextstate = DEBUG_SEND_ADDRESS;
            
            DEBUG_WAIT_ACK:     if (busy)           nextstate = DEBUG_WAIT_ACK;
                                else                nextstate = DEBUG_READ_COMMAND;
            
            DEBUG_READ_COMMAND: if (busy)           nextstate = DEBUG_GET_DATA;
                                else                nextstate = DEBUG_READ_COMMAND;
                                
            DEBUG_GET_DATA:     if (busy)           nextstate = DEBUG_GET_DATA;
                                else                nextstate = CHECK_SEND_ADDRESS;
                                
            CHECK_SEND_ADDRESS: if (busy)           nextstate = CHECK_WAIT_ACK;
                                else                nextstate = CHECK_SEND_ADDRESS;

            CHECK_WAIT_ACK:     if (busy)           nextstate = CHECK_WAIT_ACK;
                                else                nextstate = CHECK_READ_COMMAND;
            
            CHECK_READ_COMMAND: if (busy)           nextstate = CHECK_GET_DATA;
                                else                nextstate = CHECK_READ_COMMAND;
            
            CHECK_GET_DATA:     if (busy)           nextstate = CHECK_GET_DATA;
                                else if (new_data)  nextstate = LOW_SEND_ADDRESS;
                                else                nextstate = CHECK_SEND_ADDRESS;
            
            LOW_SEND_ADDRESS:   if (busy)           nextstate = LOW_WAIT_ACK;
                                else                nextstate = LOW_SEND_ADDRESS;
            
            LOW_WAIT_ACK:       if (busy)           nextstate = LOW_WAIT_ACK;
                                else                nextstate = LOW_READ_COMMAND;
            
            LOW_READ_COMMAND:   if (busy)           nextstate = LOW_GET_DATA;
                                else                nextstate = LOW_READ_COMMAND;
            
            LOW_GET_DATA:       if (busy)           nextstate = LOW_GET_DATA;
                                else                nextstate = HIGH_SEND_ADDRESS;
            
            HIGH_SEND_ADDRESS:  if (busy)           nextstate = HIGH_WAIT_ACK;
                                else                nextstate = HIGH_SEND_ADDRESS;
            
            HIGH_WAIT_ACK:      if (busy)           nextstate = HIGH_WAIT_ACK;
                                else                nextstate = HIGH_READ_COMMAND;
            
            HIGH_READ_COMMAND:  if (busy)           nextstate = HIGH_GET_DATA;
                                else                nextstate = HIGH_READ_COMMAND;
            
            HIGH_GET_DATA:      if (busy)           nextstate = HIGH_GET_DATA;
                                else if (&index)    nextstate = BUFFER_FULL;
                                else                nextstate = CHECK_SEND_ADDRESS;
            
            BUFFER_FULL:        if (read_done)      nextstate = CHECK_SEND_ADDRESS;
                                else                nextstate = BUFFER_FULL;

            default:                                nextstate = RESET;
        endcase
        
    // addr output logic
    always_comb 
        case(state)
/*
            START_SEND_ADDRESS: addr = 8'h32; // accelerometer address, write
            START_WRITE_MODE:   addr = 8'h32; // write
            DEBUG_SEND_ADDRESS: addr = 8'h32; // write
            DEBUG_READ_COMMAND: addr = 8'h33; // accelerometer address, read
            CHECK_SEND_ADDRESS: addr = 8'h32; // write
            CHECK_READ_COMMAND: addr = 8'h33; // read
            LOW_SEND_ADDRESS:   addr = 8'h32; // write
            LOW_READ_COMMAND:   addr = 8'h33; // read
            HIGH_SEND_ADDRESS:  addr = 8'h32; // write
            HIGH_READ_COMMAND:  addr = 8'h33; // read
            default:            addr = 8'h00;
*/
            START_SEND_ADDRESS: addr = 8'h30; // accelerometer address, write
            START_WRITE_MODE:   addr = 8'h30; // write
            DEBUG_SEND_ADDRESS: addr = 8'h30; // write
            DEBUG_READ_COMMAND: addr = 8'h31; // accelerometer address, read
            CHECK_SEND_ADDRESS: addr = 8'h30; // write
            CHECK_READ_COMMAND: addr = 8'h31; // read
            LOW_SEND_ADDRESS:   addr = 8'h30; // write
            LOW_READ_COMMAND:   addr = 8'h31; // read
            HIGH_SEND_ADDRESS:  addr = 8'h30; // write
            HIGH_READ_COMMAND:  addr = 8'h31; // read
            default:            addr = 8'h00;
        endcase
        
    // data_wr output logic
    always_comb   
        case(state)
            START_SEND_ADDRESS: data_wr = 8'h20; // CTRL_REG1_A
            START_WRITE_MODE:   data_wr = 8'h74; // Z enabled, 400KHz
            DEBUG_SEND_ADDRESS: data_wr = 8'h20; // CTRL_REG1_A
            CHECK_SEND_ADDRESS: data_wr = 8'h27; // status_reg_a subaddress
            LOW_SEND_ADDRESS:   data_wr = 8'h2C; // z low byte subaddress
            HIGH_SEND_ADDRESS:  data_wr = 8'h2D; // z high byte subaddress
            default:            data_wr = 8'h00;
        endcase

 /*   // rw and ena output logic
    assign rw = (state != START_SEND_ADDRESS) & (state != START_WRITE_MODE)
              & (state != DEBUG_SEND_ADDRESS) & (state != CHECK_SEND_ADDRESS)
              & (state != LOW_SEND_ADDRESS)   & (state != HIGH_SEND_ADDRESS);*/
                 
    assign ena = (state == START_SEND_ADDRESS) | (state == START_WRITE_MODE)
               | (state == DEBUG_SEND_ADDRESS) | (state == DEBUG_READ_COMMAND)
               | (state == CHECK_SEND_ADDRESS) | (state == CHECK_READ_COMMAND)
               | (state == LOW_SEND_ADDRESS)   | (state == LOW_READ_COMMAND)
               | (state == HIGH_SEND_ADDRESS)  | (state == HIGH_READ_COMMAND);
                  
    assign latch_lower  = (state == LOW_GET_DATA);
    assign latch_higher = (state == HIGH_GET_DATA);
    assign check_flag   = (state == CHECK_GET_DATA);
	assign data_ready   = (state == BUFFER_FULL);
    
endmodule