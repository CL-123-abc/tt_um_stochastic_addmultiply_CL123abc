/*
 * Copyright (c) 2024 Ciecen Lestari
 * SPDX-License-Identifier: Apache-2.0
 */

// Module name: tt_um_stochastic_addmultiply_CL123abc
// Module description: 
// Stochastic adder, multiplier and self-multiplier that takes in 9-bit inputs and gives 9-bit outputs
// after 2^17+1 clock cycles. 
// 
// INPUTS: 
// ui_in[0] for serial input of 9bit probability with 1 bit buffer.
// ui_in[1] for serial input of 9bit probability with 1 bit buffer.
// The adder and multiplier take input from both inputs but 
// the self-multiplier only takes input from ui_in[0].
// OUTPUTS:
// uo_out[0] for serial output of 9bit probability result of multiplier.
// uo_out[1] for serial output of 9bit probability result of adder.
// uo_out[2] for serial output of 9bit probability result of self-multiplier.
 
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
	
	// WIRES and REGS:
	// 
	//
	
	wire [8:0] input_precheck_1, input_precheck_2, input_postcheck_1, input_postcheck_2;
	wire SN_Bit_1, SN_Bit_2, SN_Bit_sel;
	reg [30:0] lfsr; 
    reg SN_Bit_Out, over_flag, mode; 
    reg [17:0] clk_counter;
    reg [16:0] prob_counter;
    reg [9:0] average; 

	// SUBMODULES USED:
	// 
	//
  
    serial_to_9bit_input SN_Input(.clk(clk), .clk_counter(clk_counter), .rst_n(rst_n), 
									 .input_bit_1(ui_in[0]), .output_bitseq_1(input_precheck_1), 
									 .input_bit_2(ui_in[1]), .output_bitseq_2(input_precheck_2));
	
	//input_checker incheck_1(.input_bitseq(input_precheck_1), .output_bitseq(input_postcheck_1));
	//input_checker incheck_2(.input_bitseq(input_precheck_2), .output_bitseq(input_postcheck_2));
	assign input_postcheck_1 = input_precheck_1;
	assign input_postcheck_2 = input_precheck_2;

	// COMBINATORIAL LOGIC BLOCK:
	// 
	//
    
	assign SN_Bit_1 = (lfsr[8:0] < input_postcheck_1[8:0]) ;
	assign SN_Bit_2 = ({lfsr[14:10], lfsr[23:20]} < input_postcheck_2[8:0]) ;
	assign SN_Bit_sel = ({lfsr[3:1], lfsr[30:26], lfsr[16]} < 9'b100000000);

	// SEQUENTIAL LOGIC BLOCK:
	//
	//
	
    always @(posedge clk or posedge rst_n) 
		begin
        	if (rst_n) 
				begin
        			lfsr <= 31'd134995; 
        			SN_Bit_Out <= 1'b0; 
	    			clk_counter <= 18'b0; 
	    			prob_counter <= 17'b0; 
	    			over_flag <= 0; 
        			average <= 0;
        		end 
			else 
				begin
        		
        			lfsr[0] <= lfsr[27] ^ lfsr[30] ;
        			lfsr[30:1] <= lfsr[29:0] ;
					
        			
	    			if (SN_Bit_Out == 1) 
						begin
	        				if (prob_counter == 17'd131071) 
								begin
		    						over_flag <= 1; 
		    						prob_counter <= 17'b0;
	        					end
	        				else 
								begin
	        						prob_counter <= prob_counter + 17'b1;
	        					end
	    				end 
	    			if (clk_counter == 18'd131072) 
						begin 
	    					average <= {over_flag,prob_counter[16:8]}; 
	    					over_flag <= 0; 
	    					prob_counter <= 17'b0; 
	    					clk_counter <= 18'b0; 
	    				end
	    			else 
						begin
	    					clk_counter <= clk_counter + 18'b1;
	    				end
    			end 
		end  
  
  // PIN LAYOUT
  // 
  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out[7:0] = average[7:0]; 
  assign uio_out[1:0] = average[9:8]; 
  assign uio_out[7:2] = 6'b0;    
  assign uio_oe[7:0]  = 8'b11111111;
  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:3], uio_in, 1'b0}; 
endmodule

// SUBMODULES:
// Submodule name:
// Submodule description:
// INPUTS:
//
// OUTPUTS:
//
// Submodule name:
// Submodule description:
// INPUTS:
//
// OUTPUTS:
//

module serial_to_9bit_input(clk, clk_counter, rst_n, input_bit_1, output_bitseq_1, input_bit_2, output_bitseq_2);
// WIRES and REGS:
// 
//
input wire [17:0] clk_counter;
input wire clk, rst_n, input_bit_1, input_bit_2;
output reg [8:0] output_bitseq_1, output_bitseq_2; 
reg [8:0] output_bitcounter_1, output_bitcounter_2;
reg loop; 
reg [2:0] output_case;
reg [4:0] adjustment;

// SEQUENTIAL LOGIC BLOCK:
//
//

always @(posedge clk or posedge rst_n)
	begin
    	if(rst_n) 
			begin 
    			output_bitseq_1 <= 9'b0;
    			output_bitseq_2 <= 9'b0;
    			output_bitcounter_1 <= 9'b0;
    			output_bitcounter_2 <= 9'b0;
    			loop <= 1'b0;
				output_case <= 2'b0;
    			adjustment <= 5'b0;
    		end
    	else 
			begin
				if (loop == 0)
					begin
						if (clk_counter == 0)
							begin
								case (output_case)
                                3'd000: adjustment <= 5'd10;
                                3'b001: adjustment <= 5'd16;
                                3'b010: adjustment <= 5'd12;
                                3'b011: adjustment <= 5'd18;
                                3'b100: adjustment <= 5'd14;
								endcase
							end
						output_bitcounter_1 <= (output_bitcounter_1 >> 1);
						output_bitcounter_1[8] <= input_bit_1;
						output_bitcounter_2 <= (output_bitcounter_2 >> 1);
						output_bitcounter_2[8] <= input_bit_2;
						if(clk_counter == adjustment)
							begin
								output_bitseq_1 <= output_bitcounter_1;
								output_bitseq_2 <= output_bitcounter_2;
								loop <= 1;
							end
					end
				else if (loop == 1)
					begin
						if (clk_counter == 18'd131072)
							begin
								loop <= 0;
								if(output_case == 3'b100)
									output_case <= 3'b000;
								else
									output_case <= output_case +3'b001;
							end
					end
			end
	end
endmodule

module input_checker(input_precheck, output_postcheck); 
input wire [8:0] input_precheck;
output reg [8:0] output_postcheck;

//SEQUENTIAL LOGIC BLOCK:
//
//

always@(input_precheck) 
	begin
		if(input_precheck > 9'b100001111) 
    	    output_postcheck <= 9'b100001111;
		else if (input_precheck < 9'b011110001)
     	   output_postcheck <= 9'b011110001;
    	else
    	   output_postcheck <= input_precheck;
	end
endmodule

module serial_output(clk, rst_n, input_bits, output_bit);
//WIRES and REG
//
//

input wire clk, rst_n;
input wire [8:0] input_bits;
reg [8:0] bitseq;
reg [3:0] counter;
output reg output_bit;

//SEQUENTIAL LOGIC BLOCK
//
//

always@(posedge clk or posedge rst_n)
    begin
        if(rst_n) 
            begin
                bitseq <= 8'b0;
                counter <= 4'b0;
                output_bit <= 1'b0;
            end
        else 
            begin
                if (counter == 0)
                    begin
                        output_bit <= input_bits[0];
                        bitseq <= input_bits >> 1;
                        counter <= counter + 4'b1;
                    end
                if (counter == 4'd9)
                    begin
                        output_bit <= 0;
                        counter <= 4'b0;
                    end
                else if (counter != 0 && counter != 4'd9)
                    begin
                        bitseq <= bitseq >> 1;
                        output_bit <= bitseq[0];
                        counter <= counter + 4'b1;
                    end
            end
    end
endmodule

module multiplier(SN_Bit_1, SN_Bit_2, SN_Bit_Out)
input wire SN_Bit_1, SN_Bit_2;
output wire SN_Bit_Out;
assign SN_Bit_Out = !(SN_Bit_1 ^ SN_Bit_2);
endmodule

module adder(SN_Bit_1, SN_Bit_2, SN_Bit_sel, SN_Bit_Out)
input wire SN_Bit_1, SN_Bit_2, SN_Bit_sel;
output wire SN_Bit_Out;
always@(SN_Bit_1 or SN_Bit_2)
	begin
		if(SN_Bit_sel == 0)
			SN_Bit_Out <= SN_Bit_1;
		else if (SN_Bit_sel == 1)
			SN_Bit_Out <= SN_Bit_2;
	end
endmodule

module self_multiplier(clk, rst_n, SN_Bit_1, SN_Bit_Out)
input wire clk, rst_n, SN_Bit_1;
output wire SN_Bit_Q, SN_Bit_Out;
D_FF delay_SN_Bit(clk, rst_n, SN_Bit_1, SN_Bit_Q)
assign SN_Bit_Out = !(SN_Bit_1 ^ SN_Bit_Q);
endmodule

module D_FF(clk, rst_n, D, Q)
input wire clk, rst_n, D;
output reg Q;
always@(posedge clk or posedge rst_n)
	begin
		if(rst_n)
			Q <= 0;
		else
			Q <= D;
	end
endmodule

