typedef logic [2:0] state_rcal;
typedef enum state_rcal {WAIT_RCAL, FETCH_W, RCAL_CAL, WRITE_RESULT_TO_MEM} state_ra;

module rcal(
  //signals to/from nncal
  input clk, reset,
  input Cdata [7:0] cmem_data_arbiter,
  input Mdata [7:0] dmem_data_arbiter,
  output logic write_to_oloc,
  output logic [63:0] rcal_result,
  output logic [16:0] outputloc_to_nn,
  output logic done_layer_to_nn,
  //signals to from MUL_Cal
  input logic start_rcal,
  input logic signed [31:0] W_from_mul, F_from_mul,
  input logic [4:0] postshift_from_m,
  input logic [16:0] outputloc_from_mul,
  input logic done_layer_from_mul,
  //signals to/from Arbiter
  input logic grant_rcal,
  output logic memory_rqt_rcal,
  output Caddr [7:0] cmem_addr_arbiter,
  output Maddr [7:0] dmem_addr_arbiter
);
state_rcal state_ra, state_ra_d;
reg start_rcal_engine;
logic start_rcal_engine_d;
reg [95:0] Weight_array;
logic signed [95:0] Weight_array_d;
logic [63:0] W0, W2;
logic [31:0] W1;
logic [95:0] W3;
reg signed [31:0] F_from_mul_1, F_from_mul_2, W_from_mul_1;
logic signed [31:0] F_from_mul_1_d, F_from_mul_2_d, W_from_mul_1_d;
reg [16:0] oloc_1, oloc_2, oloc_3, oloc_4, oloc_5, oloc_6, oloc_7, oloc_8, oloc_9;
logic [16:0] oloc_1_d, oloc_2_d, oloc_3_d, oloc_4_d, oloc_5_d, oloc_6_d, oloc_7_d, oloc_8_d, oloc_9_d;
reg [4:0] pshift_1, pshift_2, pshift_3, pshift_4, pshift_5, pshift_6, pshift_7, pshift_8, pshift_9, pshift_10;
logic [4:0] pshift_1_d, pshift_2_d, pshift_3_d, pshift_4_d, pshift_5_d, pshift_6_d, pshift_7_d, pshift_8_d,  pshift_9_d, pshift_10_d;
logic [63:0] rcal_result_d, rcal_result_shifted;
reg finish_rcal;
logic finish_rcal_d;
reg  done_l_1, done_l_2, done_l_3, done_l_4, done_l_5, done_l_6, done_l_7, done_l_8, done_l_9, done_l_10;
logic done_l_1_d, done_l_2_d, done_l_3_d, done_l_4_d, done_l_5_d, done_l_6_d, done_l_7_d, done_l_8_d, done_l_9_d, done_l_10_d;
r_calc R(clk, reset, start_rcal_engine, F_from_mul_2, W0, W1, W2, W3 ,rcal_result_d, finish_rcal_d);

//Sending address to Config Mem
task read_add_cm(input Caddr address, logic [3:0] i);
  cmem_addr_arbiter[i] = address;
//  $display("DE: read_add_cm Address: %h, Position %h", address, i);
endtask

//Sending address to Data Mem
task read_add_dm(input Maddr address, logic [3:0] i);
  dmem_addr_arbiter[i] = address;
//  $display("DE: read_add_cm Address: %h, Position %h", address, i);
endtask

assign W0 = {12'b0,Weight_array[23:0],28'b0};
assign W1 = {Weight_array[47:24],8'b0};
assign W2 = {4'b0,Weight_array[71:48],36'b0};
assign W3 = {8'b0,Weight_array[95:72],64'b0};
assign outputloc_to_nn = oloc_8;
assign done_layer_to_nn = done_l_9;
assign rcal_result_shifted = rcal_result_d <<< pshift_8;

always @(posedge clk or posedge reset) begin
  if (reset) begin
    state_ra           <= 0;
    start_rcal_engine  <= 0;
    Weight_array       <= 0;
    F_from_mul_1       <= 0;
    F_from_mul_2       <= 0;
    W_from_mul_1       <= 0;
    oloc_1             <= 0;
    oloc_2             <= 0;
    oloc_3             <= 0;
    oloc_4             <= 0;
    oloc_5             <= 0;
    oloc_6             <= 0;
    oloc_7             <= 0;
    oloc_8             <= 0;
    oloc_9             <= 0;
    pshift_1           <= 0;
    pshift_2           <= 0;
    pshift_3           <= 0;
    pshift_4           <= 0;
    pshift_5           <= 0;
    pshift_6           <= 0;
    pshift_7           <= 0;
    pshift_8           <= 0;
    pshift_9           <= 0;
    pshift_10           <= 0;
    done_l_1           <= 0;
    done_l_2           <= 0;
    done_l_3           <= 0;
    done_l_4           <= 0;
    done_l_5           <= 0;
    done_l_6           <= 0;
    done_l_7           <= 0;
    done_l_8           <= 0;
    done_l_9           <= 0;
    done_l_10           <= 0;
    rcal_result        <= 0;
    write_to_oloc      <= 0;
  end else begin
    state_ra           <= #0.2 state_ra_d;
    start_rcal_engine  <= #0.2 start_rcal_engine_d;
    Weight_array       <= #0.2 Weight_array_d;
    F_from_mul_1       <= #0.2 F_from_mul_1_d;
    F_from_mul_2       <= #0.2 F_from_mul_2_d;
    W_from_mul_1       <= #0.2 W_from_mul_1_d;
    oloc_1             <= #0.2 oloc_1_d;
    oloc_2             <= #0.2 oloc_2_d;
    oloc_3             <= #0.2 oloc_3_d;
    oloc_4             <= #0.2 oloc_4_d;
    oloc_5             <= #0.2 oloc_5_d;
    oloc_6             <= #0.2 oloc_6_d;
    oloc_7             <= #0.2 oloc_7_d;
    oloc_8             <= #0.2 oloc_8_d;
    oloc_9             <= #0.2 oloc_9_d;
    pshift_1           <= #0.2 pshift_1_d;
    pshift_2           <= #0.2 pshift_2_d;
    pshift_3           <= #0.2 pshift_3_d;
    pshift_4           <= #0.2 pshift_4_d;
    pshift_5           <= #0.2 pshift_5_d;
    pshift_6           <= #0.2 pshift_6_d;
    pshift_7           <= #0.2 pshift_7_d;
    pshift_8           <= #0.2 pshift_8_d;
    pshift_9           <= #0.2 pshift_9_d;
    pshift_10           <= #0.2 pshift_10_d;
    done_l_1           <= #0.2 done_l_1_d;
    done_l_2           <= #0.2 done_l_2_d;
    done_l_3           <= #0.2 done_l_3_d;
    done_l_4           <= #0.2 done_l_4_d;
    done_l_5           <= #0.2 done_l_5_d;
    done_l_6           <= #0.2 done_l_6_d;
    done_l_7           <= #0.2 done_l_7_d;
    done_l_8           <= #0.2 done_l_8_d;
    done_l_9           <= #0.2 done_l_9_d;
    done_l_10           <= #0.2 done_l_10_d;
    rcal_result        <= #0.2 rcal_result_shifted;
    write_to_oloc      <= #0.2 finish_rcal_d;
  end
end

always @(*) begin
  start_rcal_engine_d = start_rcal_engine;
  F_from_mul_1_d = F_from_mul;
  F_from_mul_2_d = F_from_mul_1;
  W_from_mul_1_d = W_from_mul;
  oloc_1_d = outputloc_from_mul;
  oloc_2_d = oloc_1;
  oloc_3_d = oloc_2;
  oloc_4_d = oloc_3;
  oloc_5_d = oloc_4;
  oloc_6_d = oloc_5;
  oloc_7_d = oloc_6;
  oloc_8_d = oloc_7;
  oloc_9_d = oloc_8;
  pshift_1_d = postshift_from_m;
  pshift_2_d = pshift_1;
  pshift_3_d = pshift_2;
  pshift_4_d = pshift_3;
  pshift_5_d = pshift_4;
  pshift_6_d = pshift_5;
  pshift_7_d = pshift_6;
  pshift_8_d = pshift_7;
  pshift_9_d = pshift_8;
  pshift_10_d = pshift_9;
  
  done_l_1_d = done_layer_from_mul;
  done_l_2_d = done_l_1;
  done_l_3_d = done_l_2;
  done_l_4_d = done_l_3;
  done_l_5_d = done_l_4;
  done_l_6_d = done_l_5;
  done_l_7_d = done_l_6;
  done_l_8_d = done_l_7;
  done_l_9_d = done_l_8;
  done_l_10_d = done_l_9;
  Weight_array_d = { (cmem_data_arbiter[2]),
                   (cmem_data_arbiter[1]), 
                   (cmem_data_arbiter[0])};
  if (reset) begin
    cmem_addr_arbiter = 0;
    dmem_addr_arbiter = 0;
    start_rcal_engine_d =  0;
    Weight_array_d = 0;
    oloc_1_d = 0;
    oloc_2_d = 0;
    oloc_3_d = 0;
    //write_to_oloc = 0;
  end else begin
  case (state_ra)
    WAIT_RCAL: begin
      //STATE 0
      start_rcal_engine_d = 0;
      //write_to_oloc = 0;
      cmem_addr_arbiter = 0;
      dmem_addr_arbiter = 0;
      if (start_rcal) begin
        memory_rqt_rcal = 1; 
        state_ra_d = FETCH_W;
      end else begin
        memory_rqt_rcal = 0; 
        state_ra_d = WAIT_RCAL;
      end
    end
    FETCH_W: begin
      //STATE 1
      read_add_cm(W_from_mul_1 + 0, 0);
      read_add_cm(W_from_mul_1 + 1, 1);
      read_add_cm(W_from_mul_1 + 2, 2);
      start_rcal_engine_d = 1;
      state_ra_d = WAIT_RCAL;
    end
    default: begin
    end
  endcase
  end
end
endmodule
