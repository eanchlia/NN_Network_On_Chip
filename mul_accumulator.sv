typedef logic [3:0] state_mul_accumulator;
typedef enum state_mul_accumulator {WAIT_NN, START_CAL, MUL_1, MUL_2, MUL_3, MUL_4, 
  ACCUMULATE, SHIFT, SATURATE, F_W, START_RCAL } state_mul;
//TODO: check how to use stop

module mul (output logic signed [39:0] out, input Mdata a, input Maddr b, input clk);
DW02_mult_3_stage #(24,16) M0 (.A(a), .B(b), .TC(1'b1), .CLK(clk), .PRODUCT(out));
//assign out=a*b;
endmodule

module mul_accumulator(
  //signals to/from nn
  input clk,reset,
  input logic  grant,
  //signals to/from fetch_populate
  input Mdata [7:0] i,
  input Cdata [3:0] w,
  input logic start_mul_acc_d,
  input logic done_neuron,
  input logic done_layer_from_fp,
  input logic [4:0] neuronshift,
  input logic [16:0] neurontable,
  input logic [4:0] postshift,
  input logic [16:0] outputloc,
  output logic stop_sending_i_w,
  //signal to/from rcal
  output logic start_rcal,
  output logic signed [31:0] W_to_rcal, F_to_rcal,
  output logic [16:0] outputloc_to_rcal,
  output logic [4:0] postshift_to_rcal,
  output logic done_layer_to_rcal
);

state_mul_accumulator state_ma, state_ma_d;
Mdata [7:0] mul_input_i, mul_input_i_d, mul_input_i_1, mul_input_i_1_d;
Cdata [3:0] mul_input_w, mul_input_w_d, mul_input_w_1,mul_input_w_1_d;
logic signed [7:0][39:0] mul_r;
logic signed [7:0][39:0] mul_r, muls1, muls1_d;
reg signed [47:0] sum1, sum2, sum3, sum4, sum5, sum6, sum_acc;
logic signed [47:0] sum1_d, sum2_d, sum3_d, sum4_d, sum5_d, sum6_d, sum_acc_d;
reg [4:0] shift1, shift2, shift3, shift4;
logic [4:0] shift1_d, shift2_d, shift3_d, shift4_d;
reg [16:0] ntable1, ntable2, ntable3, ntable4, ntable5, ntable6;
logic [16:0] ntable1_d, ntable2_d, ntable3_d, ntable4_d, ntable5_d, ntable6_d;
logic signed [47:0] shifted_result;
reg signed [31:0] value_for_loop, saturated_result;
logic signed [31:0] value_for_loop_d, saturated_result_d;
logic signed [31:0] W, F;
reg valid_1, valid_2, valid_3, valid_4, valid_5, valid_6, valid_7, valid_8, valid_9, valid_10_d ;
logic valid_1_d, valid_2_d, valid_3_d, valid_4_d, valid_5_d, valid_6_d, valid_7_d, valid_8_d, valid_9_d;
reg done_n_1, done_n_2, done_n_3, done_n_4, done_n_5, done_n_6;
logic done_n_1_d, done_n_2_d, done_n_3_d, done_n_4_d, done_n_5_d, done_n_6_d;
reg done_l_1, done_l_2, done_l_3, done_l_4, done_l_5, done_l_6, done_l_7, done_l_8, done_l_9, done_l_10;
logic done_l_1_d, done_l_2_d, done_l_3_d, done_l_4_d, done_l_5_d, done_l_6_d, done_l_7_d, done_l_8_d, done_l_9_d, done_l_10_d;
reg [4:0] pshift_1, pshift_2, pshift_3, pshift_4, pshift_5, pshift_6, pshift_7, pshift_8, pshift_9, pshift_10;
logic [4:0] pshift_1_d, pshift_2_d, pshift_3_d, pshift_4_d, pshift_5_d, pshift_6_d, pshift_7_d, pshift_8_d, pshift_9_d, pshift_10_d;
reg [16:0] oloc1, oloc2, oloc3, oloc4, oloc5, oloc6, oloc7, oloc8, oloc9, oloc10;
logic [16:0] oloc1_d, oloc2_d, oloc3_d, oloc4_d, oloc5_d, oloc6_d, oloc7_d, oloc8_d, oloc9_d, oloc10_d;
logic start_mul_acc;
mul m0(mul_r[0],mul_input_i[0], mul_input_w[0][15:0],clk);
mul m1(mul_r[1],mul_input_i[1], mul_input_w[0][31:16],clk);
mul m2(mul_r[2],mul_input_i[2], mul_input_w[1][15:0],clk);
mul m3(mul_r[3],mul_input_i[3], mul_input_w[1][31:16],clk);
mul m4(mul_r[4],mul_input_i[4], mul_input_w[2][15:0],clk);
mul m5(mul_r[5],mul_input_i[5], mul_input_w[2][31:16],clk);
mul m6(mul_r[6],mul_input_i[6], mul_input_w[3][15:0],clk);
mul m7(mul_r[7],mul_input_i[7], mul_input_w[3][31:16],clk);
assign outputloc_to_rcal = oloc10;
assign postshift_to_rcal = pshift_10;
assign done_layer_to_rcal = done_l_10;

always @(posedge clk or posedge reset) begin
  if (reset) begin
    mul_input_i     <= 0;
    mul_input_i_1   <= 0;
    mul_input_w     <= 0;
    mul_input_w_1   <= 0;
    muls1           <= 0;
	  shift3          <= 0;
	  sum1            <= 0;
	  sum2            <= 0;
	  sum3            <= 0;
	  sum4            <= 0;
	  shift1          <= 0;
	  sum5            <= 0;
	  sum6            <= 0;
	  shift2          <= 0;
    sum_acc         <= 0;
    value_for_loop  <= 0;
    saturated_result<= 0;
    W_to_rcal       <= 0;
    F_to_rcal       <= 0;
    ntable1         <= 0;
    ntable2         <= 0;
    ntable3         <= 0;
    ntable4         <= 0;
    ntable5         <= 0;
    ntable6         <= 0;
    state_ma        <= 0;
    valid_1         <= 0;
    valid_2         <= 0;
    valid_3         <= 0;
    valid_4         <= 0;
    valid_5         <= 0;
    valid_6         <= 0;
    valid_7         <= 0;
    valid_8         <= 0;
    valid_9         <= 0;
    start_rcal      <= 0;
    done_n_1        <= 0;
    done_n_2        <= 0;
    done_n_3        <= 0;
    done_n_4        <= 0;
    done_n_5        <= 0;
    done_n_6        <= 0;
    pshift_1        <= 0;
    pshift_2        <= 0;
    pshift_3        <= 0;
    pshift_4        <= 0;
    pshift_5        <= 0;
    pshift_6        <= 0;
    pshift_7        <= 0;
    pshift_8        <= 0;
    pshift_9        <= 0;
    pshift_10       <= 0;
    oloc1           <= 0;
    oloc2           <= 0;
    oloc3           <= 0;
    oloc4           <= 0;
    oloc5           <= 0;
    oloc6           <= 0;
    oloc7           <= 0;
    oloc8           <= 0;
    oloc9           <= 0;
    oloc10           <= 0;
    done_l_1        <= 0;
    done_l_2        <= 0;
    done_l_3        <= 0;
    done_l_4        <= 0;
    done_l_5        <= 0;
    done_l_6        <= 0;
    done_l_7        <= 0;
    done_l_8        <= 0;
    done_l_9        <= 0;
    done_l_10        <= 0;
    start_mul_acc    <= 0;
  end else begin
    mul_input_i     <= #0.2 i;
//    mul_input_i     <= #0.2 mul_input_i_1_d;
//    mul_input_i_1   <= #0.2 i;
    mul_input_w     <= #0.2 w;
//    mul_input_w     <= #0.2 mul_input_w_1_d;
//    mul_input_w_1   <= #0.2 w;
    muls1           <= #0.2 muls1_d;
	  sum1            <= #0.2 sum1_d;
	  sum2            <= #0.2 sum2_d;
	  sum3            <= #0.2 sum3_d;
	  sum4            <= #0.2 sum4_d;
	  sum5            <= #0.2 sum5_d;
	  sum6            <= #0.2 sum6_d;
	  shift1          <= #0.2 shift1_d;
	  shift2          <= #0.2 shift2_d;
	  shift3          <= #0.2 shift3_d;
	  shift4          <= #0.2 shift4_d;
    sum_acc         <= #0.2 sum_acc_d;
    value_for_loop  <= #0.2 value_for_loop_d;
    saturated_result<= #0.2 saturated_result_d;
    W_to_rcal       <= #0.2 W;
    F_to_rcal       <= #0.2 F;
    ntable1         <= #0.2 ntable1_d;
    ntable2         <= #0.2 ntable2_d;
    ntable3         <= #0.2 ntable3_d;
    ntable4         <= #0.2 ntable4_d;
    ntable5         <= #0.2 ntable5_d;
    ntable6         <= #0.2 ntable6_d;
    valid_1         <= #0.2 valid_1_d;
    valid_2         <= #0.2 valid_2_d;
    valid_3         <= #0.2 valid_3_d;
    valid_4         <= #0.2 valid_4_d;
    valid_5         <= #0.2 valid_5_d;
    valid_6         <= #0.2 valid_6_d;
    valid_7         <= #0.2 valid_7_d;
    valid_8         <= #0.2 valid_8_d;
    valid_9         <= #0.2 valid_9_d;
    start_rcal      <= #0.2 valid_10_d;
    done_n_1        <= #0.2 done_n_1_d;
    done_n_2        <= #0.2 done_n_2_d;
    done_n_3        <= #0.2 done_n_3_d;
    done_n_4        <= #0.2 done_n_4_d;
    done_n_5        <= #0.2 done_n_5_d;
    done_n_6        <= #0.2 done_n_6_d;
    pshift_1        <= #0.2 pshift_1_d;
    pshift_2        <= #0.2 pshift_2_d;
    pshift_3        <= #0.2 pshift_3_d;
    pshift_4        <= #0.2 pshift_4_d;
    pshift_5        <= #0.2 pshift_5_d;
    pshift_6        <= #0.2 pshift_6_d;
    pshift_7        <= #0.2 pshift_7_d;
    pshift_8        <= #0.2 pshift_8_d;
    pshift_9        <= #0.2 pshift_9_d;
    pshift_10       <= #0.2 pshift_10_d;
    oloc1           <= #0.2 oloc1_d;
    oloc2           <= #0.2 oloc2_d;
    oloc3           <= #0.2 oloc3_d;
    oloc4           <= #0.2 oloc4_d;
    oloc5           <= #0.2 oloc5_d;
    oloc6           <= #0.2 oloc6_d;
    oloc7           <= #0.2 oloc7_d;
    oloc8           <= #0.2 oloc8_d;
    oloc9           <= #0.2 oloc9_d;
    oloc10          <= #0.2 oloc10_d;
    done_l_1        <= #0.2 done_l_1_d;
    done_l_2        <= #0.2 done_l_2_d;
    done_l_3        <= #0.2 done_l_3_d;
    done_l_4        <= #0.2 done_l_4_d;
    done_l_5        <= #0.2 done_l_5_d;
    done_l_6        <= #0.2 done_l_6_d;
    done_l_7        <= #0.2 done_l_7_d;
    done_l_8        <= #0.2 done_l_8_d;
    done_l_9        <= #0.2 done_l_9_d;
    done_l_10        <= #0.2 done_l_10_d;
    start_mul_acc    <= #0.2 start_mul_acc_d;
  end
end
always @(*) begin
  if (reset) begin
  end else begin
  valid_1_d = start_mul_acc_d;
  valid_2_d = valid_1;
  valid_3_d = valid_2;
  done_n_1_d = done_neuron;
  done_n_2_d = done_n_1;
  done_n_3_d = done_n_2;
  done_l_1_d = done_layer_from_fp;
  done_l_2_d = done_l_1;
  done_l_3_d = done_l_2;
  pshift_1_d = postshift;
  pshift_2_d = pshift_1;
  pshift_3_d = pshift_2;
  oloc1_d = outputloc;
  oloc2_d = oloc1;
  oloc3_d = oloc2;
//  mul_input_i_1_d = mul_input_i_1;
//  mul_input_w_1_d = mul_input_w_1;
      
  //STATE 0
  muls1_d = mul_r;
  shift1_d = neuronshift;
  ntable1_d = neurontable;
  valid_4_d = valid_3;
  done_n_4_d = done_n_3;
  done_l_4_d = done_l_3;
  pshift_4_d = pshift_3;
  oloc4_d = oloc3;
  //STATE 1
  sum1_d = muls1[0] + muls1[1];
  sum2_d = muls1[2] + muls1[3];
  sum3_d = muls1[4] + muls1[5];
  sum4_d = muls1[6] + muls1[7];
  shift2_d = shift1;
  ntable2_d = ntable1;
  valid_5_d = valid_4;
  done_n_5_d = done_n_4;
  done_l_5_d = done_l_4;
  pshift_5_d = pshift_4;
  oloc5_d = oloc4;
  //STATE 2
  sum5_d = sum1 + sum2;
  sum6_d = sum3 + sum4;
  shift3_d = shift2;
  ntable3_d = ntable2;
  valid_6_d = valid_5;
  done_n_6_d = done_n_5;
  done_l_6_d = done_l_5;
  pshift_6_d = pshift_5;
  oloc6_d = oloc5;
  //STATE 3
  if (!done_n_6) begin
	  sum_acc_d = (valid_6) ? sum_acc + sum5 + sum6: sum_acc;  
  end else begin
	  sum_acc_d = 0;
  end
  shift4_d = shift3;
  ntable4_d = ntable3;
  valid_7_d = valid_6;
  pshift_7_d = pshift_6;
  oloc7_d = oloc6;
  done_l_7_d = done_l_6;
  //STATE 4
  ntable5_d = ntable4;
  valid_8_d = valid_7;
  pshift_8_d = pshift_7;
  done_l_8_d = done_l_7;
  shifted_result = sum_acc >>> shift4;
  value_for_loop_d = {sum_acc [47], shifted_result[30:0]}; 
  oloc8_d = oloc7;
  //STATE 5
  ntable6_d = ntable5;
  valid_9_d = valid_8;
  pshift_9_d = pshift_8;
  oloc9_d = oloc8;
  done_l_9_d = done_l_8;

  if (value_for_loop > 32'h7fffffe) begin
    saturated_result_d = 32'h7fffffe;
  end if (value_for_loop < -32'h7fffffe) begin
    saturated_result_d  = -32'h7fffffe;
  end begin
    saturated_result_d  = value_for_loop;
  end
  //STATE 6
  valid_10_d = valid_9;
  pshift_10_d = pshift_9;
  oloc10_d = oloc9;
  done_l_10_d = done_l_9;
  W = ((saturated_result[31:24])*3 +ntable6);
  F = {{8{0}},saturated_result[23:0]};

  if (!grant) begin
	valid_1_d = valid_1;
	valid_2_d = valid_2;
	valid_3_d = valid_3;
	valid_4_d = valid_4;
	valid_5_d = valid_5;
	valid_6_d = 0;
	//valid_7_d = valid_7;
	//valid_8_d = valid_8;
	//valid_9_d = valid_9;
	//valid_10_d = start_rcal;
	
	done_n_1_d = done_n_1;
	done_n_2_d = done_n_2;
	done_n_3_d = done_n_3;
	done_n_4_d = done_n_4;
	done_n_5_d = done_n_5;
	//done_n_6_d = done_n_6;
	done_n_6_d = 0;

  end

end
  
end

endmodule
