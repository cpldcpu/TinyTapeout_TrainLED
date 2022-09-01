
`default_nettype none

module user_module_341631485498884690(
  input [7:0] io_in,
  output [7:0] io_out
);

TrainLED LED1 (
    .clk(io_in[0]),
    .rst(io_in[1]),
    .din(io_in[2]),
    .dout(io_out[0]),
    .led1(io_out[1]),
    .led2(io_out[2]),
    .led3(io_out[3])
    );

endmodule


module TrainLED(clk,rst,din,dout,led1,led2,led3);

input clk,rst,din;
output dout;
output led1,led2,led3;

reg [3:0] finecount;
reg outdff;
reg [11:00] shiftregister;
reg [3:0] bitcount;
reg [7:0] resetcount;
reg mode;  // 0=receive, 1=forward
wire dataready;

PWMEngine PWM1 (.clk(clk),.rst(rst),.dataready(dataready),.PW_in(shiftregister[3:0]),.led(led1));
PWMEngine PWM2 (.clk(clk),.rst(rst),.dataready(dataready),.PW_in(shiftregister[7:4]),.led(led2));
PWMEngine PWM3 (.clk(clk),.rst(rst),.dataready(dataready),.PW_in(shiftregister[11:8]),.led(led3));

    always @(posedge clk)
        if (rst) begin
            finecount <= 0;
            outdff <= 0;
            shiftregister <= 0;
            bitcount <= 0;
            mode <= 0;
            resetcount <=0;
        end
        else begin
            
            // state machine for Tranceiver
            if ((finecount < 4'b1011) && (finecount >= 4'b0010))
                    finecount <= finecount + 1'b1;
            else 
                if (din && (finecount < 4'b0010))
                    finecount <= finecount + 1'b1;
                else
                    if (~din)
                        finecount <= 0;

            if (~mode) begin          
                // handle data store (mode=0, receive)
                if (finecount == 4'b0110) begin
                    shiftregister <= {shiftregister[10:0], din};
                    bitcount <= bitcount + 1'b1;
                    if (bitcount == 4'b1011)
                        mode = 1'b1;        
                end
                outdff <= 1'b0;
            end
            else begin    
                // handle data out (forward)        
                case(finecount)
                    4'b0010: outdff <= 1'b1; 
                    4'b0110: outdff <= din;
                    4'b1010: outdff <= 1'b0;
                endcase;
            end

            // Handle reset. 
            // Resetcounter is increased while no bits arrive
            if (finecount <= 4'b0010) begin
                resetcount <= resetcount + 1'b1;
                if (resetcount == 8'd96) begin  // reset after 8 bit times
                    mode <= 1'b0;
                    bitcount <= 0; 
                end
            end 
            else 
                resetcount <= 0;
        end

assign dout = outdff;
assign dataready = (bitcount == 4'b1100);  // Careful! If PWM cycle time exceeds reset time, this will stop working. But it is fine for now

endmodule

module PWMEngine(clk,rst,PW_in,dataready,led);

input [3:0] PW_in;   // 
input clk;
input rst;
input dataready;
output led;

reg [3:0] counter ;
reg [3:0] latcheddata ;
reg LEDdff;

	always @(posedge clk)
		if (rst) begin
			counter <= 0;	
            LEDdff <= 0;
            latcheddata <=1;
		end
		else begin
            counter <= counter + 1;

            if (counter == latcheddata)
                LEDdff <= 1'b0;
            else if (counter == 0)
                LEDdff <= 1'b1;

            if ((~counter == 4'b1111) && dataready)
                latcheddata <= PW_in;
        end

assign led = LEDdff;

endmodule
