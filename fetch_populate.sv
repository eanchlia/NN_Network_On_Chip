typedef logic [3:0] state_fetch_populate;
typedef enum state_fetch_populate {NO_CALC, CNFG_FETCH, CNFG_POPULATE, NLT_FETCH, NLT_POPULATE, NT_FETCH,
  NT_POPULATE, NIMAP_ADDR_FETCH, NIMAP_FETCH, WIMAP_POPULATE,	DATA_POPULATE_MEM} state_fp;

`define FOO 
typedef struct packed
{
  logic [10:0] Clayers;
  logic [16:0] Cloc;
  logic [3:0] Res;
} c_table;

typedef struct packed
{
  logic [10:0] Nneurons;
  logic [16:0] NtableLoc;
  logic [3:0] Res;
} n_layer_table;

typedef struct packed
{
  logic [9:0] Ninputs;
  logic [16:0] Lbase;
  logic [16:0] Oloc;
  logic [16:0] Nimap;
  logic [16:0] Wimap;
  logic [16:0] NeuronTable;
  logic [4:0] NeuronShift;
  logic [4:0] PostShift;
  logic [22:0] Flags;

} n_table;
typedef struct packed{
reg [10:0] l; //layers
reg [10:0] n; //neurons
reg [9:0] i; //inputs
}counter_block;

module fetch_populate (
  //Signals to/from nncal
  input clk, reset, 
  input logic start_nncal,
  input logic [16:0] config_reg_addr, 
  input Cdata [7:0] cmem_data_arbiter,
  input Mdata [7:0] dmem_data_arbiter,
  //Signals to.from Mul_Cal
  input logic stop_sending_cal,
  output logic start_mul,
  output Mdata [7:0] input_array,
  output Cdata [3:0] weight_array1,
  output logic recirc_mul,
  output logic done_neuron,
  output logic done_layer,
  output logic [4:0] neuronshift,
  output logic [16:0] neurontable,
  output logic [4:0] postshift,
  output logic [16:0] outputloc,
  //signals to/from Arbiter
  input logic grant_fp,
  output logic memory_rqt_fp,
  output Caddr [7:0] cmem_addr_arbiter,
  output Maddr [7:0] dmem_addr_arbiter
);

logic done_neuron_d;
logic active_fp_d, complete_ncal_d;
reg active_fp, complete_ncal;
logic [4:0] nt_itr_d, nimap_itr_d;
reg [4:0] nt_itr, nimap_itr;
logic start_nimap;
logic [4:0] counter_ntfetch_d, counter_nimap_d;
reg [4:0] counter_ntfetch, counter_nimap;
Caddr [7:0] cmem_addr_arbiter_ff;
Maddr [7:0] dmem_addr_arbiter_ff;
Caddr nimap_a, nimap_a_d;
Caddr wimap_a, wimap_a_d;
Cdata [3:0] weight_array, weight_array_d, weight_array1_d;
Mdata [7:0] input_array_d;
Caddr nimap_reg_0_d,nimap_reg_1_d, nimap_reg_0, nimap_reg_1;
logic [4:0] NShift1, NShift1_d, NShift2, NShift2_d;
logic [4:0] PShift1, PShift1_d, PShift2, PShift2_d;
logic [16:0] NTable1, NTable1_d, NTable2, NTable2_d;
logic [16:0] Oloc1, Oloc1_d, Oloc2, Oloc2_d;
logic [9:0] Ninputs1_d, Ninputs1;
reg [3:0] datac;
logic [3:0] datac_d;
logic [3:0] data_inc;
logic [23:0] i0, i1, i2, i3, i4, i5, i6, i7;
counter_block counter_max, counter_current, counter_current_d;
c_table Config_Block, Config_Block_d;
n_layer_table Neuron_Layer, Neuron_Layer_d;
n_table Neuron_Table, Neuron_Table_d;

state_fetch_populate state_fp, state_fp_d;
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
assign neuronshift = NShift2;
assign neurontable = NTable2;
assign outputloc = Oloc2;
assign postshift = PShift2;
assign counter_max = {Config_Block.Clayers, Neuron_Layer.Nneurons, Neuron_Table.Ninputs};
always @(posedge clk or posedge reset) begin
  if (reset) begin
    state_fp          <= 0;
    active_fp         <= 0;
    complete_ncal     <= 0;
    Config_Block      <= 0;
    Neuron_Layer      <= 0;
    Neuron_Table      <= 0;
    nt_itr            <= 0;
    nimap_itr         <= 0;
    counter_ntfetch   <= 0;
    counter_nimap     <= 0;
    nimap_a           <= 0;
    wimap_a           <= 0;
    nimap_reg_0       <= 0;
    nimap_reg_1       <= 0;
    counter_current   <= 0;
    datac             <= 0;
    cmem_addr_arbiter_ff <= 0;
    dmem_addr_arbiter_ff <= 0;
    input_array          <= 0;
    weight_array        <= 0;
    weight_array1        <= 0;
    NShift1              <= 0;
    NShift2              <= 0;
    NTable1              <= 0;
    NTable2              <= 0;
    Oloc1                <= 0;
    Oloc2                <= 0;
    Ninputs1		 <= 0;
    done_neuron		 <= 0;

  end else begin
    state_fp          <= #0.2 state_fp_d;
    active_fp         <= #0.2 active_fp_d;
    complete_ncal     <= #0.2 complete_ncal_d;
    Config_Block      <= #0.2 Config_Block_d;
    Neuron_Layer      <= #0.2 Neuron_Layer_d;
    Neuron_Table      <= #0.2 Neuron_Table_d;
    nt_itr            <= #0.2 nt_itr_d;
    nimap_itr         <= #0.2 nimap_itr_d;
    counter_ntfetch   <= #0.2 counter_ntfetch_d;
    counter_nimap     <= #0.2 counter_nimap_d;
    nimap_a           <= #0.2 nimap_a_d;
    wimap_a           <= #0.2 wimap_a_d;
    nimap_reg_0       <= #0.2 nimap_reg_0_d;
    nimap_reg_1       <= #0.2 nimap_reg_1_d;
    counter_current   <= #0.2 counter_current_d;
    datac             <= #0.2 datac_d;
    cmem_addr_arbiter_ff <= #0.2 cmem_addr_arbiter;
    dmem_addr_arbiter_ff <= #0.2 dmem_addr_arbiter;
    input_array          <= #0.2 input_array_d;
    weight_array         <= #0.2 weight_array_d;
    weight_array1         <= #0.2 weight_array1_d;
    NShift1              <= #0.2 NShift1_d;
    NShift2              <= #0.2 NShift2_d;
    NTable1              <= #0.2 NTable1_d;
    NTable2              <= #0.2 NTable2_d;
    Oloc1                <= #0.2 Oloc1_d;
    Oloc2                <= #0.2 Oloc2_d;
    PShift1              <= #0.2 PShift1_d;
    PShift2              <= #0.2 PShift2_d;
    Ninputs1		 <= #0.2 Ninputs1_d;
    done_neuron		 <= #0.2 done_neuron_d;

  end
end

always @(*) begin
  complete_ncal_d = complete_ncal;
	datac_d = datac;
	data_inc = (datac == 2) ? 2 : 3;
  memory_rqt_fp = 1; 
  cmem_addr_arbiter = cmem_addr_arbiter_ff;
  dmem_addr_arbiter = dmem_addr_arbiter_ff;
  nt_itr_d = nt_itr;
  counter_nimap_d   = counter_nimap;
  counter_ntfetch_d  = counter_ntfetch;
  counter_current_d = counter_current;
  nimap_a_d = nimap_a;
  recirc_mul = ((state_fp == 8) && !grant_fp); 

  i7 = (Ninputs1 >= 8) ? fetch_data_dm(dmem_data_arbiter[7]) : 0;
  i6 = (Ninputs1 >= 7) ? fetch_data_dm(dmem_data_arbiter[6]) : 0;
  i5 = (Ninputs1 >= 6) ? fetch_data_dm(dmem_data_arbiter[5]) : 0;
  i4 = (Ninputs1 >= 5) ? fetch_data_dm(dmem_data_arbiter[4]) : 0;
  i3 = (Ninputs1 >= 4) ? fetch_data_dm(dmem_data_arbiter[3]) : 0;
  i2 = (Ninputs1 >= 3) ? fetch_data_dm(dmem_data_arbiter[2]) : 0;
  i1 = (Ninputs1 >= 2) ? fetch_data_dm(dmem_data_arbiter[1]) : 0;
  i0 = fetch_data_dm(dmem_data_arbiter[0]);
//		 i7=    fetch_data_dm(dmem_data_arbiter[7]);
//                 i6=    fetch_data_dm(dmem_data_arbiter[6]);
//                 i5=    fetch_data_dm(dmem_data_arbiter[5]);
//                 i4=    fetch_data_dm(dmem_data_arbiter[4]);
//                 i3=    fetch_data_dm(dmem_data_arbiter[3]);
//                 i2=    fetch_data_dm(dmem_data_arbiter[2]);
//                 i1=    fetch_data_dm(dmem_data_arbiter[1]);
//                 i0=    fetch_data_dm(dmem_data_arbiter[0]);
  input_array_d =  {i7, i6, i5, i4, i3, i2, i1, i0};
  weight_array_d = {fetch_data_cm(cmem_data_arbiter[6]),
                         fetch_data_cm(cmem_data_arbiter[5]),
                         fetch_data_cm(cmem_data_arbiter[4]),
                         fetch_data_cm(cmem_data_arbiter[3])};
    weight_array1_d = weight_array; 
    done_neuron_d = 0;
    NShift2_d = NShift1;
    NTable2_d = NTable1;
    Oloc2_d = Oloc1;
    PShift2_d = PShift1;
    case(state_fp)
    NO_CALC: begin
      //STATE 0
      start_mul = 0;
      done_neuron_d = 0;
       done_layer =0;
      if (start_nncal && !complete_ncal) begin
        state_fp_d = CNFG_FETCH;
      end else begin
        state_fp_d = NO_CALC;
      end
    end
    CNFG_FETCH: begin
      //STATE 1
      active_fp_d = 1;
      complete_ncal_d = 0;
      read_add_cm(config_reg_addr,0);
      if (grant_fp) begin
        state_fp_d = CNFG_POPULATE;
      end else begin
        state_fp_d = CNFG_FETCH;
      end
    end
    CNFG_POPULATE: begin
      //STATE 2
      Config_Block_d = cmem_data_arbiter[0];
      state_fp_d = NLT_FETCH;
    end
    NLT_FETCH: begin
      //STATE 3
     //$display ("DE:%d: CNFG_FETCH: %h", $time, Config_Block);
      read_add_cm(Config_Block.Cloc,0);
      if (grant_fp) begin
        state_fp_d = NLT_POPULATE;
      end else begin
        state_fp_d = NLT_FETCH;
      end
    end
    NLT_POPULATE: begin
      //STATE 4
      Neuron_Layer_d = cmem_data_arbiter[0];
      state_fp_d = NT_FETCH;
    end
    NT_FETCH: begin
      //STATE 5
        //$display("DE:%d: NLT_FETCH: %h", $time,Neuron_Layer);

      read_add_cm(Neuron_Layer.NtableLoc+ nt_itr + 0, 0);
      read_add_cm(Neuron_Layer.NtableLoc+ nt_itr + 1, 1);
      read_add_cm(Neuron_Layer.NtableLoc+ nt_itr + 2, 2);
      read_add_cm(Neuron_Layer.NtableLoc+ nt_itr + 3, 3);
      //counter_ntfetch_d = 0;
      start_nimap = 0;
      start_mul = 0;
      done_neuron_d = 0;
       done_layer =0;
      if (grant_fp) begin
        state_fp_d = NT_POPULATE;
      end else begin
        state_fp_d = NT_FETCH;
      end
    end
    NT_POPULATE: begin
      //STATE 6
      nt_itr_d = nt_itr + 4;
      Neuron_Table_d = {(fetch_data_cm(cmem_data_arbiter[3])),
                        (fetch_data_cm(cmem_data_arbiter[2])), 
                        (fetch_data_cm(cmem_data_arbiter[1])), 
                        (fetch_data_cm(cmem_data_arbiter[0]))};
      state_fp_d = NIMAP_ADDR_FETCH;
      Ninputs1_d = fetch_data_cm(cmem_data_arbiter[3][31:22]);
    end
    NIMAP_ADDR_FETCH: begin
      //STATE 7
      wimap_a_d =(counter_ntfetch == 0 && start_nimap == 0) ? Neuron_Table.Wimap : (wimap_a+4);
      nimap_a_d =(counter_ntfetch == 0 && start_nimap == 0) ? Neuron_Table.Nimap : (nimap_a+nimap_itr);
      //TODO : check cmem_data_arbiter with Neuron_Table.Nimap and Wimap
      state_fp_d = NIMAP_FETCH; 
       start_mul = 0;
       done_neuron_d = 0;
       done_layer =0;
    end
    NIMAP_FETCH: begin
      //STATE 8
      start_nimap = 1;
      counter_ntfetch_d = (counter_ntfetch < 2)? counter_ntfetch + 1:0;
       // $display("DE:%d: NIMAP_FETCH: %h", $time,nimap_a);
       // $display("DE:%d: NIMAP_FETCH: %h", $time,wimap_a);
      nimap_itr_d = (counter_ntfetch == 2 )? 2 :3;
      NShift1_d = Neuron_Table.NeuronShift;
      PShift1_d = Neuron_Table.PostShift;
      NTable1_d = Neuron_Table.NeuronTable;
      Oloc1_d   = Neuron_Table.Oloc;
      //Send Nimap address to Config_Mem
      //if(Neuron_Table.Ninputs > 6) begin 
        read_add_cm(nimap_a + 0,0);
        read_add_cm(nimap_a + 1,1);
        read_add_cm(nimap_a + 2,2);
      //end else if(Neuron_Table.Ninputs > 3) begin 
      //  read_add_cm(nimap_a + 0,0);
      //  read_add_cm(nimap_a + 1,1);
      //end else begin
      //  read_add_cm((nimap_a + 0),0);
      //end
      
      //Send Wimap address to Config_Mem
      read_add_cm(wimap_a + 0,3);
      read_add_cm(wimap_a + 1,4);
      read_add_cm(wimap_a + 2,5);
      read_add_cm(wimap_a + 3,6);
      if (grant_fp) begin
        state_fp_d = WIMAP_POPULATE;
      end else begin
        state_fp_d = NIMAP_FETCH;
      end
    end
    WIMAP_POPULATE: begin
      //STATE 9: Populate Wimap array
      //Send Nimap address to Data_Mem
      Ninputs1_d = Ninputs1 - 8;
      if(counter_nimap == 0) begin
        read_add_dm(cmem_data_arbiter[0][9:0]  + Neuron_Table.Lbase,0);
        read_add_dm(cmem_data_arbiter[0][19:10]+ Neuron_Table.Lbase,1);
        read_add_dm(cmem_data_arbiter[0][29:20]+ Neuron_Table.Lbase,2);
        read_add_dm(cmem_data_arbiter[1][9:0]  + Neuron_Table.Lbase,3);
        read_add_dm(cmem_data_arbiter[1][19:10]+ Neuron_Table.Lbase,4);
        read_add_dm(cmem_data_arbiter[1][29:20]+ Neuron_Table.Lbase,5);
        read_add_dm(cmem_data_arbiter[2][9:0]  + Neuron_Table.Lbase,6);
        read_add_dm(cmem_data_arbiter[2][19:10]+ Neuron_Table.Lbase,7);
        nimap_reg_0_d = cmem_data_arbiter[2][29:20]; 
      end else if(counter_nimap == 1) begin
        read_add_dm(nimap_reg_0 + Neuron_Table.Lbase ,0);
        read_add_dm(cmem_data_arbiter[0][9:0] + Neuron_Table.Lbase ,1);
        read_add_dm(cmem_data_arbiter[0][19:10]+ Neuron_Table.Lbase,2);
        read_add_dm(cmem_data_arbiter[0][29:20]+ Neuron_Table.Lbase,3);
        read_add_dm(cmem_data_arbiter[1][9:0] + Neuron_Table.Lbase ,4);
        read_add_dm(cmem_data_arbiter[1][19:10]+ Neuron_Table.Lbase,5);
        read_add_dm(cmem_data_arbiter[1][29:20]+ Neuron_Table.Lbase,6);
        read_add_dm(cmem_data_arbiter[2][9:0] + Neuron_Table.Lbase ,7);
        nimap_reg_0_d =cmem_data_arbiter[2][19:10];
        nimap_reg_1_d =cmem_data_arbiter[2][29:20];
      end else begin
        read_add_dm(nimap_reg_0 + Neuron_Table.Lbase  ,0);
        read_add_dm(nimap_reg_1 + Neuron_Table.Lbase  ,1);
        read_add_dm(cmem_data_arbiter[0][9:0] + Neuron_Table.Lbase  ,2);
        read_add_dm(cmem_data_arbiter[0][19:10]+ Neuron_Table.Lbase ,3);
        read_add_dm(cmem_data_arbiter[0][29:20]+ Neuron_Table.Lbase ,4);
        read_add_dm(cmem_data_arbiter[1][9:0]+ Neuron_Table.Lbase   ,5);
        read_add_dm(cmem_data_arbiter[1][19:10]+ Neuron_Table.Lbase ,6);
        read_add_dm(cmem_data_arbiter[1][29:20]+ Neuron_Table.Lbase ,7);
      end
      if (grant_fp) begin
        if (stop_sending_cal) begin
          state_fp_d = WIMAP_POPULATE;
        end else begin
          state_fp_d = DATA_POPULATE_MEM; 
        end
      end else begin
        state_fp_d = WIMAP_POPULATE;
      end
    end
    DATA_POPULATE_MEM: begin
      //STATE A: Populate input array from Data_Mem
      start_mul = 1;
//      state_fp_d = NIMAP_ADDR_FETCH;
      datac_d = (datac == 2) ? 0 : (datac + 1);
      counter_current_d.i = counter_current.i + data_inc;
      /* after reading all inputs, move to next neuron */
  	if (((counter_current.i + data_inc)*3) >= counter_max.i) begin
		state_fp_d = NT_FETCH;
		counter_current_d.i = 0;
		counter_current_d.n = counter_current.n + 1;
		done_neuron_d = 1;
		datac_d = 0;
		counter_ntfetch_d = 0;
		counter_nimap_d = 0;
        	`ifdef FOO
        	/* after reading all neurons, move to next layer */
		if ((counter_current.n + 1) >= counter_max.n) begin
          		state_fp_d = NLT_FETCH;
          		counter_current_d.n = 0;
          		counter_current_d.l = counter_current.l + 1;
          		/* after reading all the layers, end calculation */
          		if ((counter_current.l + 1) >= counter_max.l) begin
          			state_fp_d = NO_CALC;
          			done_layer =1;
          			complete_ncal_d = 1;
        		end
        	end
        	`endif
	end else begin
		state_fp_d = NIMAP_ADDR_FETCH;
		counter_nimap_d = (counter_nimap<2) ? counter_nimap+ 1: 0; //TODO: test counter 
      end
    end
    default: begin
      
    end
  endcase
end

endmodule

