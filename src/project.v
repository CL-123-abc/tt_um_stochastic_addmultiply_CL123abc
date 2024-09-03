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
// ui_in[0] for serial input of 9bit (+1 bit buffer) probability with 1 bit buffer.
// ui_in[1] for serial input of 9bit (+1 bit buffer) probability with 1 bit buffer.
// The adder and multiplier take input from both inputs but the self-multiplier only takes input from ui_in[0].
// OUTPUTS:
// uo_out[0] for serial output of 9bit (+1 bit buffer) probability result of multiplier.
// uo_out[1] for serial output of 9bit (+1 bit buffer) probability result of adder.
// uo_out[2] for serial output of 9bit (+1 bit buffer) probability result of self-multiplier.
// uo_out[3] signals the reset of the clk_counter of the module.
 
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
	
	wire [8:0] input_precheck_1, input_precheck_2, input_postcheck_1;
	wire [30:0] lfsr;
	wire SN_Bit_1, SN_Bit_2, SN_Bit_smul_in, SN_Bit_sel;
	wire SN_Bit_mul_out, SN_Bit_add_out, SN_Bit_smul_out;
    wire [8:0] mul_avg, add_avg, smul_avg;
    wire mul_bit_out, add_bit_out, smul_bit_out;
    reg [17:0] clk_counter;
    

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
  
    serial_to_value_input global_input(.clk(clk), .clk_counter(clk_counter), .rst_n(rst_n), 
									   .input_bit_1(ui_in[0]), .output_bitseq_1(input_precheck_1), 
									   .input_bit_2(ui_in[1]), .output_bitseq_2(input_precheck_2));
	
	input_checker        smul_incheck(.input_precheck(input_precheck_1), .output_postcheck(input_postcheck_1));
	
	LFSR                 global_lsfr(.clk(clk), .rst_n(rst_n), .lfsr(lfsr));
	
	SN_Generators        global_SN_gen(.lfsr(lfsr), 
	                                   .Input_1(input_precheck_1), .Input_2(input_precheck_2), .Input_3(input_postcheck_1),
	                                   .SN_Bit_1(SN_Bit_1), .SN_Bit_2(SN_Bit_2), .SN_Bit_3(SN_Bit_smul_in),
	                                   .SN_Bit_sel(SN_Bit_sel));
	
	multiplier           mul(.SN_Bit_1(SN_Bit_1), .SN_Bit_2(SN_Bit_2), .SN_Bit_Out(SN_Bit_mul_out));
	adder                add(.SN_Bit_1(SN_Bit_1), .SN_Bit_2(SN_Bit_2), .SN_Bit_sel(SN_Bit_sel), .SN_Bit_Out(SN_Bit_add_out));
	self_multiplier      smul(.clk(clk), .rst_n(rst_n), .SN_Bit_1(SN_Bit_smul_in), .SN_Bit_Out(SN_Bit_smul_out));
	
	up_counter           mul_up_counter(.clk(clk), .rst_n(rst_n), .SN_Bit_Out(SN_Bit_mul_out), 
	                                    .out_set(2'b00), .clk_counter(clk_counter), .average(mul_avg));
    up_counter           add_up_counter(.clk(clk), .rst_n(rst_n), .SN_Bit_Out(SN_Bit_add_out), 
                                        .out_set(2'b01), .clk_counter(clk_counter), .average(add_avg));
    up_counter           smul_up_counter(.clk(clk), .rst_n(rst_n), .SN_Bit_Out(SN_Bit_smul_out), 
                                         .out_set(2'b10), .clk_counter(clk_counter), .average(smul_avg));
                                         
    value_to_serial_output mul_output(.clk(clk), .rst_n(rst_n), .input_bits(mul_avg), .output_bit(mul_bit_out));
    value_to_serial_output add_output(.clk(clk), .rst_n(rst_n), .input_bits(add_avg), .output_bit(add_bit_out));
    value_to_serial_output smul_output(.clk(clk), .rst_n(rst_n), .input_bits(smul_avg), .output_bit(smul_bit_out));
    
	// SEQUENTIAL LOGIC BLOCK:
	//
	//
	
    always @(posedge clk or posedge rst_n) 
		begin
        	if (rst_n) 
				begin
	    			clk_counter <= 0; 
        		end 
			else 
				begin
        		    if(clk_counter == 18'd131072)
        		        clk_counter <= 0;
        		    else
        		      clk_counter <= clk_counter + 18'd1;
    			end 
		end  
  
  // PIN LAYOUT
  // 
  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out[0] = mul_bit_out;
  assign uo_out[1] = add_bit_out; 
  assign uo_out[2] = smul_bit_out;
  assign uo_out[3] = clk_counter[17];
  assign uo_out[7:4] = 4'b0;
  assign uio_out[7:0] = 8'b0;    
  assign uio_oe[7:0]  = 8'b00000000;
  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:2], uio_in, 1'b0}; 
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

module serial_to_value_input(clk, clk_counter, rst_n, input_bit_1, output_bitseq_1, input_bit_2, output_bitseq_2);
input wire [17:0] clk_counter;
input wire clk, rst_n, input_bit_1, input_bit_2;
output reg [8:0] output_bitseq_1, output_bitseq_2; 
reg [8:0] output_bitcounter_1, output_bitcounter_2;
reg loop; 
reg [3:0] output_case;
reg [4:0] adjustment;

always @(posedge clk or posedge rst_n)
	begin
    	if(rst_n) 
			begin 
    			output_bitseq_1 <= 9'b0;
    			output_bitseq_2 <= 9'b0;
    			output_bitcounter_1 <= 9'b0;
    			output_bitcounter_2 <= 9'b0;
    			loop <= 1'b0;
				output_case <= 4'b0;
    			adjustment <= 5'd9;
    		end
    	else 
			begin
				if (loop == 0)
					begin
						if (clk_counter == 0)
							begin
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
								if(output_case == 4'd9)
								    begin
									   output_case <= 4'd0;
									end
								else
								    begin
									   output_case <= output_case + 4'd1;
									end
								loop <= 0;
							end
					end
			end
	end
endmodule

module input_checker(input_precheck, output_postcheck); 
input wire [8:0] input_precheck;
wire over_limit, under_limit, limit;
output wire [8:0] output_postcheck;

assign over_limit = (input_precheck > 9'b100001111);
assign under_limit = (input_precheck < 9'b011110001);
assign limit = (over_limit||under_limit) == 1;
assign output_postcheck = (limit == 1)? ((over_limit == 1)? 9'b100001111 : 9'b011110001) : input_precheck;
endmodule

module value_to_serial_output(clk, rst_n, input_bits, output_bit);
input wire clk, rst_n;
input wire [8:0] input_bits;
reg [8:0] bitseq;
reg [3:0] counter;
output reg output_bit;

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

module LFSR(clk, rst_n, lfsr);
input wire clk, rst_n;
output reg [30:0] lfsr;
initial //ASIC no initial!!
    begin
        lfsr <= 31'd134995;
    end

always@(posedge clk or posedge rst_n)
    begin
        if (rst_n == 1)
            lfsr <= 31'd134995;
        else
            lfsr[0] <= lfsr[27] ^ lfsr[30] ;
            lfsr[30:1] <= lfsr[29:0] ;
    end
endmodule

module SN_Generators(lfsr, Input_1, Input_2, Input_3, SN_Bit_1, SN_Bit_2, SN_Bit_3, SN_Bit_sel);
input wire [30:0] lfsr;
input wire [8:0] Input_1, Input_2, Input_3;
output wire SN_Bit_1, SN_Bit_2, SN_Bit_3, SN_Bit_sel;

assign SN_Bit_1 = (lfsr[8:0] < Input_1[8:0]) ;
assign SN_Bit_2 = ({lfsr[20:12]} < Input_2[8:0]) ;
assign SN_Bit_3 = (lfsr[8:0] < Input_3[8:0]);
assign SN_Bit_sel = ({lfsr[3:1], lfsr[30:26], lfsr[11]} < 9'b100000000);
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

module self_multiplier(clk, rst_n, SN_Bit_1, SN_Bit_Out);
input wire clk, rst_n, SN_Bit_1;
output wire SN_Bit_Out; 
wire SN_Bit_Q;
D_FF delay_SN_Bit(clk, rst_n, SN_Bit_1, SN_Bit_Q);
assign SN_Bit_Out = !(SN_Bit_1 ^ SN_Bit_Q);
endmodule

module D_FF(clk, rst_n, D, Q);
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

module up_counter(clk, rst_n, SN_Bit_Out, out_set, clk_counter, average);
input wire clk, rst_n, SN_Bit_Out;
input wire [1:0] out_set;
input wire [17:0] clk_counter;
output reg [8:0] average;
reg [16:0] prob_counter;
//reg over_flag;

always@(posedge clk or posedge rst_n)
begin
    if (rst_n)
        begin
            average <= 0;
            prob_counter <= 0;
            //over_flag <= 0;
        end 
    else 
        begin
            if (SN_Bit_Out == 1) 
                begin
                    if (prob_counter == 17'd131071) 
                        begin
		                    //over_flag <= 1; 
		                    prob_counter <= 17'b0;
	                    end
	                else 
			            begin
	                        prob_counter <= prob_counter + 17'b1;
	                    end
	            end 
	        if (clk_counter == 18'd131072) 
				begin 
				    case(out_set)
				    2'b00: average <= {prob_counter[16:8]}; //Multiplier
				    2'b01: average <= {prob_counter[16:8]}; //Adder ??
				    2'b10: average <= {prob_counter[8:0]};  // Self-Multiplier
				    default:;
	    		    endcase
	    		    //over_flag <= 0; 
	    		    prob_counter <= 17'b0; 
	    		end
	    end
end
endmodule

