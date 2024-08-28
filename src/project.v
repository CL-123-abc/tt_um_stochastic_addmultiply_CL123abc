/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */


/*
 * Copyright (c) 2024 David Parent
 * SPDX-License-Identifier: Apache-2.0
 * tt_um_davidparent_prbs31
 */
 
`default_nettype none

module tt_um_stochastic_multiplier_CL123abc(
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n    // reset_n - low to reset
);
    wire [8:0] input_bitseq_1, input_bitseq_2; // Input sequence that determines the probabilities to be multiplied, 9 bits but in 10 bit intervals (10th for reset)
    wire [8:0] input_bout1, input_bout2; //Wire to connect the input checker to the main code, input checker limits the input values
	reg [30:0] lfsr_1, lfsr_2; // LFSR to generate psuedorandom numbers
    reg SN_Bit_1, SN_Bit_2, SN_Bit_Out; // SN bits
    reg [17:0] clk_counter; // Used mainly to count how many cycles before output.
    reg [16:0] prob_counter;// Used as part of upcounter to count number of 1s
    reg over_flag; // Used as part of the upcounter to determine if overflow has happened
    reg [9:0] average; 
  
    bitstream_to_9bit_input SN_Bit_1_Input(.clk(clk), .rst_n(rst_n), .input_bit(ui_in[0]), .output_bitseq(input_bitseq_1));
    bitstream_to_9bit_input SN_Bit_2_Input(.clk(clk), .rst_n(rst_n), .input_bit(ui_in[1]), .output_bitseq(input_bitseq_2));
    input_checker incheck_1(.input_bitseq(input_bitseq_1), .output_bitseq(input_bout1));
    input_checker incheck_2(.input_bitseq(input_bitseq_2), .output_bitseq(input_bout2));
    
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
        lfsr_1 <= 31'd17301504; // Reset 1st counter
	    lfsr_2 <= 31'd268435584; // Reset 2nd counter to different value
	    SN_Bit_1 <= 1'b0; // Reset SN bits
	    SN_Bit_2 <= 1'b0; 
        SN_Bit_Out <= 1'b0; 
	    clk_counter <= 18'b0; // Reset clk counter
	    prob_counter <= 17'b0; // Reset output counter
	    over_flag <= 0; // Reset overflag
        average <= 0;
        end else begin
        
        // Increment counter on each clock cycle
        lfsr_1[0] <= lfsr_1[27] ^ lfsr_1[30] ;
        lfsr_1[30:1] <= lfsr_1[29:0] ;
        
	    lfsr_2[0] <= lfsr_2[27] ^ lfsr_2[30] ; 
        lfsr_2[30:1] <= lfsr_2[29:0] ;
        
	    // Comparator used to generate Bipolar Stochastic Number from 4-bit probability.
	    // Compare RN from LFSR with probability wanted in BN and generate 1 when RN < BN
	    SN_Bit_1 <= (lfsr_1[8:0] < input_bout1[8:0]) ;
	    SN_Bit_2 <= (lfsr_2[8:0] < input_bout2[8:0]) ;
	    
	    // Stochastic Multiplier for Bipolar SN uses XNOR gate
	    SN_Bit_Out <= !(SN_Bit_1 ^ SN_Bit_2) ;
	    
	    // To convert back to binary probability, use an up-counter, outputting the number of 1s in every 2^17 bits
	    if (SN_Bit_Out == 1) begin
	        if (prob_counter == 17'd131071) begin
		    over_flag <= 1; // if the number of bits is 2^17, overflow
		    prob_counter <= 17'b0;
	        end
	        else begin
	        prob_counter <= prob_counter + 17'b1;
	        end
	    end 
	    if (clk_counter == 18'd131072) begin // output only when clk_counter has counted 2^17 cycles. Skip bit 2^17 + 1 to output and go back to reset.
	    average <= {over_flag,prob_counter[16:8]}; // Currently taking value per 2^17 clk cycles for 9 bit.
	    over_flag <= 0; //Reset over_flag
	    prob_counter <= 17'b0; // Reset prob_counter
	    clk_counter <= 18'b0; //Reset clock counter
	    end
	    else begin
	    clk_counter <= clk_counter + 18'b1;
	    end
    end 
end  
  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out[7:0] = average[7:0]; //average [7:0] are the 8th to 1st bits of the 9bit probability.
  assign uio_out[1:0] = average[9:8]; // average[9] is the over_flag and if it is 1 something's wrong since we are multiplying fraction.
  assign uio_out[7:2] = 6'b000000;    // average[8] is the MSB of the 9bit probability, being positive if 1 and negative if 0
  assign uio_oe[7:0]  = 8'b11111111;
  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:2], uio_in, 1'b0}; 
endmodule

module bitstream_to_9bit_input(clk, rst_n, input_bit, output_bitseq);
input wire clk, rst_n, input_bit;
output reg [8:0] output_bitseq; // At this point, the value here is in Px probability for bipolar representation
reg [8:0] output_bitcounter;
reg [16:0] clk_bitcounter;
reg enable; // Only takes input when enable is 1


always @(posedge clk or posedge rst_n)begin
    if(rst_n) begin // Reset everything
    output_bitseq <= 9'b0;
    output_bitcounter <= 9'b0;
    clk_bitcounter <= 17'b0;
    enable <= 1'b1;
    end
    else if(enable == 1 && rst_n == 0)begin
        output_bitcounter <= (output_bitcounter >> 1); // Shift bits in
        output_bitcounter[8] <= input_bit; //input bit
        
        if(clk_bitcounter == 17'd10) begin //Will output 9bit sequences but ignore the 10th bit to reset clk_bitcounter.
        output_bitseq <= output_bitcounter;
        enable <= 0;
        end
        else begin
        clk_bitcounter <= clk_bitcounter + 17'd1;
        end
    end
    else if(enable == 0 && rst_n == 0) begin
        if(clk_bitcounter == 17'd131068) begin //Will allow input after 131068 clk, 131068 + 10 + 
        clk_bitcounter <= 0;
        enable <= 1;
        end
        else begin
        clk_bitcounter <= clk_bitcounter + 17'd1;
        end
    end
end
endmodule

module input_checker(input_bitseq, output_bitseq); // Will only be used for the self multiplier
input wire [8:0] input_bitseq;
output reg [8:0] output_bitseq;
assign output_bitseq = input_bitseq;
//always@* begin
    //if(input_bitseq > 9'b100001111) 
        //output_bitseq <= 9'b100001111;
    //else if (input_bitseq < 9'b011110001)
        //output_bitseq <= 9'b011110001;
    //else
        //output_bitseq <= input_bitseq;
//end
endmodule
