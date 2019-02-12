`timescale 1ns/10ps
typedef reg [2:0] state_ncal;
typedef enum state_ncal {IDLE_NN,START_NN, PUSHOUT,BUSTOP} state_n;

//`define SYN
`ifdef SYN
`include "mem_intf.svh"
`include "nnintf.svh"
`else
`include "DW02_mult_3_stage.v"
`endif

`include "fetch_populate.sv"
`include "nn_arbiter.sv"
`include "mul_accumulator.sv"
`include "rcal.sv"
`include "r_calc3.sv"

module nn (nnIntf.nn ncal,memIntf.mem d_mem, cmemIntf.mem c_mem);

state_ncal state_ncal, state_ncal_d;
reg [31:0] config_reg, cal_time_reg, start_reg;
logic [31:0] config_reg_d, cal_time_reg_d, start_reg_d;
logic [16:0] config_reg_to_fp;
logic bus_stop_d, pushout_d;
Caddr [7:0] cmem_a_c, cmem_addr_engine;
Maddr [7:0] dmem_a_c, dmem_addr_engine;
Cdata [7:0] cmem_data_engine;
Mdata [7:0] dmem_data_engine;

// MUL Signals
logic start_nncal, done_neuron_cal, done_layer_cal, done_layer_cal_m, done_layer_cal_final;
logic stop_sending_cal, start_mul;
Cdata [3:0] weights_array_fp;
Mdata [7:0] input_array_fp;
logic signed [47:0] sum_cal; 
logic [4:0] NShift, PShift, PShift_m_r;
logic [16:0] NTable;
logic [16:0] Oloc, Oloc_m_r; 
//Arbiter Signals
logic grant_from_arbiter_fp, req_to_arbiter_fp;
logic grant_from_arbiter_rcal, req_to_arbiter_rcal;
Caddr [7:0] cmem_addr_to_arbiter_rcal, cmem_addr_to_arbiter_fp;
Maddr [7:0] dmem_addr_to_arbiter_rcal, dmem_addr_to_arbiter_fp;
logic  start_rcal;
logic signed [31:0] W_m_r, F_m_r; 
logic write_rcal_to_dem;
logic [63:0] neuron_result;
logic [16:0] neuron_oloc;
logic bus_stop_d, pushout_d;
logic recirc_mul;

fetch_populate fp( ncal.clk, ncal.reset, start_nncal_dummy, config_reg_to_fp, 
  cmem_data_engine, dmem_data_engine,
  stop_sending_cal, start_mul, input_array_fp, weights_array_fp, recirc_mul,
  done_neuron_cal, done_layer_cal,
  NShift, NTable, PShift, Oloc,
  grant_from_arbiter_fp, req_to_arbiter_fp,
  cmem_addr_to_arbiter_fp, dmem_addr_to_arbiter_fp);

nn_arbiter nn_arb ( grant_from_arbiter_rcal, grant_from_arbiter_fp, req_to_arbiter_rcal, req_to_arbiter_fp,
cmem_addr_to_arbiter_rcal, dmem_addr_to_arbiter_rcal,cmem_addr_to_arbiter_fp, dmem_addr_to_arbiter_fp,
cmem_addr_engine, dmem_addr_engine);

mul_accumulator mul_acc( ncal.clk, ncal.reset, recirc_mul,
  input_array_fp, weights_array_fp, 
  start_mul, done_neuron_cal, done_layer_cal, NShift, NTable, PShift, Oloc,
  stop_sending_cal,
  start_rcal, W_m_r, F_m_r, Oloc_m_r, PShift_m_r, done_layer_cal_m
);

rcal rc( ncal.clk, ncal.reset, cmem_data_engine, dmem_data_engine,
  write_rcal_to_dem, neuron_result, neuron_oloc, done_layer_cal_final,
  start_rcal, W_m_r, F_m_r, PShift_m_r, Oloc_m_r, done_layer_cal_m,
  grant_from_arbiter_rcal, req_to_arbiter_rcal,
  cmem_addr_to_arbiter_rcal, dmem_addr_to_arbiter_rcal 
);

//Sending address to Config Mem
task read_add_cm(input Caddr addres, logic [3:0] i);
//  cmem_a_s[i] = addres;
//  $display("DE: read_add_cm Address: %h, Position %h", addres, i);
endtask

//Sending address to Data Mem
task read_add_dm(input Maddr addres, logic [3:0] i);
//  dmem_a_s[i] = addres;
//  $display("DE: read_add_cm Address: %h, Position %h", addres, i);
endtask
//Returning Config Mem Data
function Cdata fetch_data_cm(input Cdata data);
  if(data) return data;
    else return 32'h00000000;
endfunction

//Returning Data Mem Data
function Mdata fetch_data_dm(input Mdata data);
  if(data) return data;
    else return 32'h00000000;
endfunction

assign c_mem.a = (ncal.sel) ? cmem_a_c : cmem_addr_engine;
assign d_mem.a = (ncal.sel) ? dmem_a_c : dmem_addr_engine;
assign config_reg_to_fp = config_reg[16:0];
assign start_nncal_dummy = start_nncal;
always @(posedge(ncal.clk) or posedge(ncal.reset)) begin
  if (ncal.reset) begin
    config_reg          <= 0;
    cal_time_reg        <= 0;
    start_reg           <= 0;
    ncal.bus_stop       <= 0;
    ncal.pushout        <= 0;
    state_ncal          <= IDLE_NN;

  end else begin
    config_reg          <= #0.2 config_reg_d;
    cal_time_reg        <= #0.2 cal_time_reg_d;
    start_reg           <= #0.2 start_reg_d;
    ncal.bus_stop       <= #0.2 bus_stop_d;
    ncal.pushout        <= #0.2 pushout_d;
    state_ncal          <= #0.2 state_ncal_d;
  end
  
end
always @(*) begin
  bus_stop_d = 0;
  pushout_d = 0;
  ncal.dout = 0;
  cmem_a_c = 0;
  dmem_a_c = 0;
  state_ncal_d = state_ncal;
	c_mem.aw = 0;
	c_mem.wd = 0;
	d_mem.aw = 0;
	d_mem.wd = 0;


 case (state_ncal)
   IDLE_NN: begin
     if (ncal.reset) begin //If Reset
       c_mem.write = 0;
       c_mem.aw    = 0;
       c_mem.wd    = 0;
       //c_mem.a    = 0;
       cmem_a_c    = 0;
       d_mem.write = 0;
       d_mem.aw    = 0;
       d_mem.wd    = 0;
       dmem_a_c    = 0;
       start_nncal = 0;
       cmem_data_engine =0;
       dmem_data_engine =0;
     end else if (ncal.sel) begin //When testbench/AHB master is in control
       case (1) 
        (ncal.addr == 'h0): begin //Config reg pointer
           config_reg_d =  (ncal.RW) ? ncal.din : config_reg;
           ncal.dout = (ncal.RW) ? 0 : config_reg ;
          end
        (ncal.addr == 'h1): begin //Calculation
          cal_time_reg_d =  (ncal.RW) ? ncal.din : cal_time_reg;
          ncal.dout = (ncal.RW) ? 0 : cal_time_reg;
        end
        (ncal.addr == 'h2): begin //Start
          start_reg_d =  (ncal.RW) ? ncal.din : start_reg;
          if ((ncal.RW) && (ncal.din == 32'h0000_0ACE)) begin
            state_ncal_d = START_NN;
            end else state_ncal_d= IDLE_NN;
         //   halt = 1;
         //   active_d = 1;
 
          if (!ncal.RW)  //Write to Dout when WRITE is enabled
  				ncal.dout = (start_reg) ? {32{1}} : 0;
        end
        (ncal.addr >= 'h20000 & ncal.addr < 'h40000): begin //Config Memory
          c_mem.write = ncal.RW;
          if (ncal.RW) begin
            c_mem.aw    = ncal.addr - 'h20000;
            c_mem.wd    = ncal.din;
          end else begin
            cmem_a_c     = ncal.addr - 'h20000;
            //c_mem.a     = ncal.addr - 'h20000;
            ncal.dout  = c_mem.d[0]; //c_mem.d[0]
            //ncal.dout  = c_mem.d[0]; //c_mem.d[0]
          end
        end
        (ncal.addr >= 'h40000): begin //Data Memory
          d_mem.write = ncal.RW;
          if (ncal.RW) begin
            d_mem.aw    = ncal.addr - 'h40000;
            d_mem.wd    = ncal.din;
          end else begin
            //d_mem.a   = ncal.addr - 'h40000;
            dmem_a_c   = ncal.addr - 'h40000;
            ncal.dout  = d_mem.d[0]; //c_mem.d[0]
          end
        end
        default: begin
          c_mem.write = 0;
          c_mem.aw    = 0;
          c_mem.wd    = 0;
          //c_mem.a    = 0;
          cmem_a_c    = 0;
          d_mem.write = 0;
          d_mem.aw    = 0;
          d_mem.wd    = 0;
          dmem_a_c    = 0;
          //d_mem.a    = 0;
        end
      endcase
    end
   end
   START_NN: begin //When ACE starts the state machine
   if (ncal.reset) begin
     start_nncal = 0;
     cmem_data_engine = 0;
     dmem_data_engine = 0;
   end else begin
     start_nncal = 1;
     cmem_data_engine[0] = fetch_data_cm(c_mem.d[0]);;
     cmem_data_engine[1] = fetch_data_cm(c_mem.d[1]);;
     cmem_data_engine[2] = fetch_data_cm(c_mem.d[2]);;
     cmem_data_engine[3] = fetch_data_cm(c_mem.d[3]);;
     cmem_data_engine[4] = fetch_data_cm(c_mem.d[4]);;
     cmem_data_engine[5] = fetch_data_cm(c_mem.d[5]);;
     cmem_data_engine[6] = fetch_data_cm(c_mem.d[6]);;
     cmem_data_engine[7] = fetch_data_cm(c_mem.d[7]);;
     dmem_data_engine = d_mem.d;
     if (write_rcal_to_dem) begin
      
       d_mem.write = 1;
       d_mem.aw    = neuron_oloc;
       d_mem.wd    = neuron_result[55:32];
     end
     if (done_layer_cal_final) begin
       //Pushout
       ////Piepline done_laye in rcal
       state_ncal_d = PUSHOUT;
     end
   end
   end
   PUSHOUT: begin
     pushout_d = 1;
     bus_stop_d = 1;
     state_ncal_d = BUSTOP;
   end
   BUSTOP: begin
     pushout_d = 0;
     bus_stop_d = 0;
     state_ncal_d = IDLE_NN;
   end
   default: begin
   end
 endcase
end

endmodule

