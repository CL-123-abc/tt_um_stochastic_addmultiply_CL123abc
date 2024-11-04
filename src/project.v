/*
 * Copyright (c) 2024 CL-123-abc
 * SPDX-License-Identifier: Apache-2.0
 */

/* Module name: tt_um_stochastic_addmultiply_CL123abc
 * Module description: 
 * Stochastic adder, multiplier and self-multiplier that takes in 9-bit (+ 1 bit buffer) inputs and gives 9-bit (+ 1 bit buffer) outputs
 * after 2^17+1 clock cycles. 
 * More details on the submodules are found after this module below.
 * INPUTS: 
 * ui_in[0] for serial input of 9bit (+1 bit buffer) probability.
 * ui_in[1] for serial input of 9bit (+1 bit buffer) probability.
 * The adder and multiplier take input from both inputs but the self-multiplier only takes input from ui_in[0].
 * OUTPUTS:
 * uo_out[0] for serial output of 9bit (+1 bit buffer) probability result of multiplier.
 * uo_out[1] for serial output of 9bit (+1 bit buffer) probability result of adder.
 * uo_out[2] for serial output of 9bit (+1 bit buffer) probability result of self-multiplier.
 * uo_out[3] signals the inner reset of the clk_counter of the module (not rst_n).
 */

`default_nettype none

module tt_um_stochastic_addmultiply_CL123abc(
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
	
	wire [8:0] input_1, input_2;
	wire [30:0] lfsr;
	wire SN_Bit_1, SN_Bit_1_Input2, SN_Bit_2, SN_Bit_sel;
	wire SN_Bit_mul_out, SN_Bit_add_out, SN_Bit_smul_out;
    wire [8:0] mul_avg, add_avg, smul_avg;
    wire mul_bit_out, add_bit_out, smul_bit_out;
    reg [17:0] clk_counter;
    
    serial_to_value_input global_input(.clk(clk), .clk_counter(clk_counter), .rst_n(rst_n), 
									   .input_bit_1(ui_in[0]), .output_bitseq_1(input_1), 
									   .input_bit_2(ui_in[1]), .output_bitseq_2(input_2));
	
	LFSR                 global_lsfr(.clk(clk), .rst_n(rst_n), .lfsr(lfsr));
	
	SN_Generators        global_SN_gen(.lfsr(lfsr), .Input_1(input_1), .Input_2(input_2), 
	                                   .SN_Bit_1(SN_Bit_1), .SN_Bit_1_Input2(SN_Bit_1_Input2), .SN_Bit_2(SN_Bit_2), 
	                                   .SN_Bit_sel(SN_Bit_sel));
	
	multiplier           mul(.SN_Bit_1(SN_Bit_1), .SN_Bit_2(SN_Bit_2), .SN_Bit_Out(SN_Bit_mul_out));
	adder                add(.SN_Bit_1(SN_Bit_1), .SN_Bit_2(SN_Bit_2), .SN_Bit_sel(SN_Bit_sel), .SN_Bit_Out(SN_Bit_add_out));
	self_multiplier      smul(.clk(clk), .SN_Bit_Input1(SN_Bit_1),.SN_Bit_Input2(SN_Bit_1_Input2), .SN_Bit_Out(SN_Bit_smul_out));
	
	up_counter           mul_up_counter(.clk(clk), .rst_n(rst_n), .SN_Bit_Out(SN_Bit_mul_out), 
	                                    .out_set(2'b00), .clk_counter(clk_counter), .average(mul_avg));
    up_counter           add_up_counter(.clk(clk), .rst_n(rst_n), .SN_Bit_Out(SN_Bit_add_out), 
                                        .out_set(2'b01), .clk_counter(clk_counter), .average(add_avg));
    up_counter           smul_up_counter(.clk(clk), .rst_n(rst_n), .SN_Bit_Out(SN_Bit_smul_out), 
                                         .out_set(2'b10), .clk_counter(clk_counter), .average(smul_avg));
                                         
    value_to_serial_output mul_output(.clk(clk), .rst_n(rst_n), .input_bits(mul_avg), .output_bit(mul_bit_out));
    value_to_serial_output add_output(.clk(clk), .rst_n(rst_n), .input_bits(add_avg), .output_bit(add_bit_out));
    value_to_serial_output smul_output(.clk(clk), .rst_n(rst_n), .input_bits(smul_avg), .output_bit(smul_bit_out));
  
	/* SEQUENTIAL LOGIC BLOCK:
	   The main code only controls the global clock counter and 
	   resets after 131072+1 or (2^17)+1 clk cycles counting 0th cycle.
	*/
	
    always @(posedge clk or posedge rst_n) begin
        	if (rst_n) begin
	    			clk_counter <= 0; 
        	end 
			else begin
        		if(clk_counter == 18'd131072)
        		    clk_counter <= 0;
        		else
        		    clk_counter <= clk_counter + 18'd1;
    		end 
	end  
  
  // PIN LAYOUT
  // All output pins must be assigned. If not used, assign to 0.
  /*
  assign uo_out[7:0] = mul_avg[8:1];
  assign uio_out[0] = mul_avg[0];
  assign uio_out[7:1] = 7'b0;
  assign uio_oe[7:0] = 8'b1;
  */
  
  assign uo_out[0] = mul_bit_out;
  assign uo_out[1] = add_bit_out; 
  assign uo_out[2] = smul_bit_out;
  assign uo_out[3] = clk_counter[17];
  assign uo_out[7:4] = 4'b0;
  assign uio_out[7:0] = 8'b0;    
  assign uio_oe[7:0]  = 8'b0;
  
  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:2], uio_in, 1'b0}; 
endmodule

/* SUBMODULES:
     *
     * /////////////////////////////////////////////////////////////////////////////
	 * SUBMODULE NAME:
	   serial_to_value_input (.clk(), .clk_counter(), .rst_n(), 
	    					  .input_bit_1(), .output_bitseq_1(), 
	    					  .input_bit_2(), .output_bitseq_2());
     * SUBMODULE DESCRIPTION: 
     * Takes in serial input (10bit) carrying the 9bit probability in bipolar representation 
	 * and gives the 9bit value as output. The last bit in the 10 is the dummy bit.
     * INPUTS:
     * .clk() takes in the clk of the whole circuit.
	 * .clk_counter() takes in the global clock counter that is controlled by the main code.
     * .rst_n() takes in the reset of the whole circuit.
	 * .input_bit_1() takes in the serial bitstream of input 1, 1 bit per clk cycle. 
     * .input_bit_2() takes in the serial bitstream of input 2, 1 bit per clk cycle. 
     * OUTPUTS:
     * .output_bitseq_1() outputs the 9bit value of input 1.
	 * .output_bitseq_2() outputs the 9bit value of input 1.
     * \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	 *
     * /////////////////////////////////////////////////////////////////////////////
	 * (UNUSED) SUBMODULE NAME:
	   input_checker (.input_precheck(), .output_postcheck());
     * SUBMODULE DESCRIPTION:
	 * Checks the input to see if it is within the desired limits. 
     * In this code it is only used for the self-multiplier, because the self-multiplier is scaled. 
	 * It cannot show result values if the input exceeds the limits. 
     * Currently, the limits are set to [9'b011110001 < input < 9'b100001111].
     * INPUTS:
     * .input_precheck() takes in a 9bit value to compare with the limit.
     * OUTPUTS:
	 * .output_postcheck() outputs a 9bit value that has already been cut to the limit.
     * \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	 *
	 * /////////////////////////////////////////////////////////////////////////////
	 * SUBMODULE NAME:
       LFSR (.clk(), .rst_n(), .lfsr());
     * SUBMODULE DESCRIPTION:
	 * Generates and runs the LFSR, which is 31 bits long and has a seed of 31'd134995 in this code.
     * INPUTS:
     * .clk() takes in the clk of the whole circuit.
	 * .rst_n() takes in the reset of the whole circuit.
     * OUTPUTS:
	 * .lfsr() outputs the entire LFSR contents in 31-bit.
     * \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	 *
	 * /////////////////////////////////////////////////////////////////////////////
	 * SUBMODULE NAME:
  	   SN_Generators (.lfsr(), .Input_1(), .Input_2(), 
	                  .SN_Bit_1(), .SN_Bit_1_Input2(), .SN_Bit_2(), 
	                  .SN_Bit_sel());
     * SUBMODULE DESCRIPTION:
	 * Generates stochastic bits by comparing the value from the input to the random number and generates a 1 if the input is larger.
     * The whole LFSR values is inputted so that different arrangements of its bits can result in more decorrelated random numbers.
     * INPUTS:
     * .lfsr() takes in the 31 bit LFSR values so that the random numbers can be extracted.
	 * .Input_1() takes in the 9bit bipolar probability value of input 1.
     * .Input_2() takes in the 9bit bipolar probability value of input 2.
     * OUTPUTS:
	 * .SN_Bit_1() outputs the generated SN bit from input 1, using its own lfsr value arrangement.
	 * .SN_Bit_1_Input2() outputs the generated SN bit from input 1, using the same lfsr value arrangement as SN_Bit_2.
     * .SN_Bit_2() outputs the generated SN bit from input 2, using the same lfsr value arrangement as SN_Bit_1_Input2.
	 * .SN_Bit_sel() outputs the generated SN bit from a unipolar probability value of 0.5, meant for use as the sel in the adder.
	 *               Uses its own lfsr value arrangement.
     * \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	 *
     * /////////////////////////////////////////////////////////////////////////////
	 * SUBMODULE NAME:
  	   multiplier (.SN_Bit_1(), .SN_Bit_2(), .SN_Bit_Out());
     * SUBMODULE DESCRIPTION:
	 * Implements SN bipolar multiplication through a XNOR gate.
     * INPUTS:
     * .SN_Bit_1() takes in a SN bit with bipolar probability.
	 * .SN_Bit_2() takes in a SN bit with bipolar probability.
     * OUTPUTS:
	 * .SN_Bit_Out() outputs a SN bit with bipolar probability.
     * \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	 *
     * /////////////////////////////////////////////////////////////////////////////
	 * SUBMODULE NAME:
  	   adder (.SN_Bit_1(), .SN_Bit_2(), .SN_Bit_sel(), .SN_Bit_Out());
     * SUBMODULE DESCRIPTION:
	 * Implements SN bipolar weighted averaging/addition through a MUX with SN_Bit_sel determining the weight of the inputs.
     * If SN_Bit_sel has a probability of 0.5, the result is averaging with equal weight between both inputs, 
	 * so it acts as an adder.
     * INPUTS:
     * .SN_Bit_1() takes in a SN bit with bipolar probability.
	 * .SN_Bit_2() takes in a SN bit with bipolar probability.
     * .SN_Bit_sel() takes in a SN bit with unipolar probability to determine the weight of the inputs.
     * OUTPUTS:
	 * .SN_Bit_Out() outputs a SN bit with bipolar probability.
     * \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	 *
	 * /////////////////////////////////////////////////////////////////////////////
	 * (UNUSED) SUBMODULE NAME:
       absolute_value (.clk(), .SN_Bit_1(), .SN_Bit_Out());
     * SUBMODULE DESCRIPTION:
	 * This function was supposed to be the self-multiplier, but testing shows that it implements the 
	 * absolute function. 
	 * It takes in 1 input SN bitstream and uses a D-FF to generate what should be a 2nd decorrelated
	 * bitstream with the same probability, then passes them through XNOR gate for multiplication.
	 * Since it actually implements the absolute function, it seems that
	 * the decorrelation did not work here as intended. 
	 * Further testing should be done to figure out the correlation;
	 * this same function may also be able to be implemented without the D-FF.
     * INPUTS:
     * .clk() takes in the clk of the whole circuit.
	 * .SN_Bit_1() takes in a SN bit with bipolar probability.
     * OUTPUTS:
	 * .SN_Bit_Out() outputs a SN bit with bipolar probability.
     * \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
     * /////////////////////////////////////////////////////////////////////////////
	 * SUBMODULE NAME:
       self_multiplier (.clk(), .SN_Bit_Input1(),.SN_Bit_Input2(), .SN_Bit_Out());
     * SUBMODULE DESCRIPTION:
	 * This is the actual self_multiplier and it functions like the multiplier but the D-FF has been left in the bitstream.
	 * The 2 inputs are meant to take in the SN bits generated from the same input. SN_Bit_Input1 goes through the D-FF,
	 * but SN_Bit_Input2 does not. The 2 bits are then passed through an XNOR gate for multiplication.
	 * THe D-FF does not need to be included for multiplication, which can be seen in multiplier.
     * INPUTS:
     * .clk()takes in the clk of the whole circuit.
     * .SN_Bit_Input1()takes in a SN bit with bipolar probability, meant to be from the same input value.
     * .SN_Bit_Input2()takes in a SN bit with bipolar probability, meant to be from the same input value.
     * OUTPUTS:
	 * .SN_Bit_Out() outputs a SN bit with bipolar probability.
     * \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	 *
     * /////////////////////////////////////////////////////////////////////////////
	 * SUBMODULE NAME:
       D_FF(.clk(), .D(), .Q());
     * SUBMODULE DESCRIPTION:
	 * D-flip flop. Takes D value and outputs it as Q every clk cycle.
     * INPUTS:
     * .clk() takes in the clk of the whole circuit.
	 * .D() takes in 1 bit.
     * OUTPUTS:
	 * .Q() takes in 1 bit.
     * \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	 *
     * /////////////////////////////////////////////////////////////////////////////
	 * SUBMODULE NAME:
       up_counter (.clk(), .rst_n(), .SN_Bit_Out(), 
	               .out_set(), .clk_counter(), .average());
     * SUBMODULE DESCRIPTION:
	 * Counts the number of bits in a certain number of clk cycles and outputs the 9 MSB as the bipolar probability of 1s in the SN bitstream.
     * This code counts up to 2^17 + 1 clk cycles before outputting.
	 * out_set was meant to control scaling, but doesn't do anything currently.
     * INPUTS:
     * .clk() takes in the clk of the whole circuit.
	 * .rst_n() takes in the rst_n of the whole circuit.
     * .SN_Bit_Out() takes in the SN bitstream to be counted.
	 * .out_set() takes in a 2bit value to determine the case for the set of bits from the counter to be output.
     * 			  Currently, all options (2'b00, 2'b01, 2'b10) set the 9 MSB for output.
     * .clk_counter() takes in the global clock counter that is controlled by the main code.
     * OUTPUTS:
	 * .average() outputs a 9bit value, here that is the bipolar probability of 1s in the SN bitstream.
     * \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	 *
     * /////////////////////////////////////////////////////////////////////////////
	 * SUBMODULE NAME:
       value_to_serial_output mul_output(.clk(), .rst_n(), .input_bits(), .output_bit());
     * SUBMODULE DESCRIPTION:
	 * Outputs each bit in the 9bit input as a serial bitstream with an added 10th bit as 0 as a dummy bit.
     * INPUTS:
     * .clk() takes in the clk of the whole circuit.
     * .rst_n() takes in the rst_n of the whole circuit.
	 * .input_bits() takes in a 9bit value, here that is the bipolar probability of 1s in the SN bitstream.
     * OUTPUTS:
	 * .output_bit() outputs each bit in the 9bit value and then outputs 0 for the 10th bit.
     * \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	 *
 
*/

module serial_to_value_input(clk, clk_counter, rst_n, input_bit_1, output_bitseq_1, input_bit_2, output_bitseq_2);
input wire [17:0] clk_counter;
input wire clk, rst_n, input_bit_1, input_bit_2;
output reg [8:0] output_bitseq_1, output_bitseq_2; 
reg [8:0] output_bitcounter_1, output_bitcounter_2;
reg loop; 
reg [3:0] output_case;
reg [4:0] adjustment;

	always @(posedge clk or posedge rst_n) begin
    	if(rst_n) begin 
    		output_bitseq_1 <= 9'b0;
    		output_bitseq_2 <= 9'b0;
    		output_bitcounter_1 <= 9'b0;
    		output_bitcounter_2 <= 9'b0;
    		loop <= 1'b0;
			output_case <= 4'b0;
    		adjustment <= 5'd9;
    	end
    	else begin
			if (loop == 0) begin
				if (clk_counter == 0) begin
					case (output_case)
                    4'd0: adjustment <= 5'd9;
                    4'd1: adjustment <= 5'd16;
                    4'd2: adjustment <= 5'd13;
                    4'd3: adjustment <= 5'd10; 
                    4'd4: adjustment <= 5'd17; 
                    4'd5: adjustment <= 5'd14;
                    4'd6: adjustment <= 5'd11;   
                    4'd7: adjustment <= 5'd18;   
                    4'd8: adjustment <= 5'd17; 
                    4'd9: adjustment <= 5'd12;   
                    default:;
					endcase
				end
				output_bitcounter_1 <= (output_bitcounter_1 >> 1);
				output_bitcounter_1[8] <= input_bit_1;
				output_bitcounter_2 <= (output_bitcounter_2 >> 1);
				output_bitcounter_2[8] <= input_bit_2;
				if(clk_counter[4:0] == adjustment) begin
					output_bitseq_1 <= output_bitcounter_1;
					output_bitseq_2 <= output_bitcounter_2;
					loop <= 1;
				end
			end
			else if (loop == 1) begin
				if (clk_counter == 18'd131072) begin
					if(output_case == 4'd9)
						output_case <= 4'd0;
					else 
						output_case <= output_case + 4'd1;
				loop <= 0;
				end
			end
		end
	end
endmodule

/* UNUSED
module input_checker(input_precheck, output_postcheck); 
input wire [8:0] input_precheck;
wire over_limit, under_limit, limit;
output wire [8:0] output_postcheck;

assign over_limit = (input_precheck > 9'b100001111);
assign under_limit = (input_precheck < 9'b011110001);
assign limit = (over_limit||under_limit) == 1;
assign output_postcheck = (limit == 1)? ((over_limit == 1)? 9'b100001111 : 9'b011110001) : input_precheck;
endmodule
*/

module LFSR(clk, rst_n, lfsr);
input wire clk, rst_n;
output reg [30:0] lfsr;
	always@(posedge clk or posedge rst_n) begin
        if (rst_n == 1)
            lfsr <= 31'd134995; // LFSR SEED AFFECTS ACCURACY A LOT
        else begin
            lfsr[0] <= lfsr[27] ^ lfsr[30] ;
            lfsr[30:1] <= lfsr[29:0] ;
		end
    end
endmodule

module SN_Generators(lfsr, Input_1, Input_2, SN_Bit_1, SN_Bit_1_Input2, SN_Bit_2, SN_Bit_sel);
input wire [30:0] lfsr;
input wire [8:0] Input_1, Input_2;
output wire SN_Bit_1, SN_Bit_1_Input2, SN_Bit_2, SN_Bit_sel;

assign SN_Bit_1 = (lfsr[8:0] < Input_1[8:0]) ;
assign SN_Bit_1_Input2 = (lfsr[20:12] < Input_1[8:0]);
assign SN_Bit_2 = (lfsr[20:12] < Input_2[8:0]) ;
assign SN_Bit_sel = ({lfsr[3:1], lfsr[30:26], lfsr[11]} < 9'b100000000);
wire unused = &{1'b0, lfsr[25:21], lfsr[10:9], 1'b0};
endmodule

module multiplier(SN_Bit_1, SN_Bit_2, SN_Bit_Out);
input wire SN_Bit_1, SN_Bit_2;
output wire SN_Bit_Out;
	
assign SN_Bit_Out = !(SN_Bit_1 ^ SN_Bit_2);
endmodule

module adder(SN_Bit_1, SN_Bit_2, SN_Bit_sel, SN_Bit_Out);
input wire SN_Bit_1, SN_Bit_2, SN_Bit_sel;
output wire SN_Bit_Out;
	
assign SN_Bit_Out = (SN_Bit_sel == 0) ? SN_Bit_1 : SN_Bit_2;
endmodule

/*UNUSED
module absolute_value(clk, SN_Bit_1, SN_Bit_Out);
input wire clk, SN_Bit_1;
output wire SN_Bit_Out; 
wire SN_Bit_Q;
D_FF delay_1_SN_Bit(clk, SN_Bit_1, SN_Bit_Q);

assign SN_Bit_Out = !(SN_Bit_1 ^ SN_Bit_Q);
endmodule
*/

module self_multiplier(clk, SN_Bit_Input1, SN_Bit_Input2, SN_Bit_Out);
input wire clk, SN_Bit_Input1, SN_Bit_Input2;
output wire SN_Bit_Out; 
wire SN_Bit_Q;
D_FF delay_1_SN_Bit(clk, SN_Bit_Input1, SN_Bit_Q);

assign SN_Bit_Out = !(SN_Bit_Q ^ SN_Bit_Input2);
endmodule

module D_FF(clk, D, Q);
input wire clk, D;
output reg Q;
	
	always@(posedge clk)begin
	       Q <= D;
	end
endmodule

module up_counter(clk, rst_n, SN_Bit_Out, out_set, clk_counter, average);
input wire clk, rst_n, SN_Bit_Out;
input wire [1:0] out_set;
input wire [17:0] clk_counter;
output reg [8:0] average;
reg [16:0] prob_counter;
//reg over_flag;

	always@(posedge clk or posedge rst_n) begin
		if (rst_n) begin
            average <= 0;
            prob_counter <= 0;
            //over_flag <= 0;
        end 
    	else begin
        	if (SN_Bit_Out == 1) begin
				if (prob_counter == 17'd131071) begin
		            //over_flag <= 1; 
		            prob_counter <= 17'b0;
	            end
	            else 
					prob_counter <= prob_counter + 17'b1;
	        end 
	        if (clk_counter == 18'd131072) begin 
				case(out_set)                           //For scaling, if needed.
			    2'b00: average <= {prob_counter[16:8]}; //Multiplier
			    2'b01: average <= {prob_counter[16:8]}; //Adder 
			    2'b10: average <= {prob_counter[16:8]}; //Self-Multiplier
			    default:;
	    		endcase
	    		//over_flag <= 0; 
	    		prob_counter <= 17'b0; 
	    	end
	    end
	end
endmodule

module value_to_serial_output(clk, rst_n, input_bits, output_bit);
input wire clk, rst_n;
input wire [8:0] input_bits;
reg [8:0] bitseq;
reg [3:0] counter;
output reg output_bit;

	always@(posedge clk or posedge rst_n) begin
		if(rst_n) begin
            bitseq <= 9'b0;
            counter <= 4'b0;
            output_bit <= 1'b0;
        end
        else begin
			if (counter == 0) begin
            	output_bit <= input_bits[0];
                bitseq <= input_bits >> 1;
                counter <= counter + 4'b1;
            end
			if (counter == 4'd9) begin
                output_bit <= 0;
                counter <= 4'b0;
            end
			else if (counter != 0 && counter != 4'd9) begin
                bitseq <= bitseq >> 1;
                output_bit <= bitseq[0];
                counter <= counter + 4'b1;
            end
         end
    end
endmodule
