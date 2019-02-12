//`define FOO

`ifdef FOO
`include "nnintf.svh"
`include "ahbif.svh"
`endif

`define ADDR_OFFSET 4
`define NN_ADDR_OFFSET 1
`define KBOUNDARY (1024 - `ADDR_OFFSET)

typedef reg [31:0] system_addr;
typedef reg [31:0] Word;

typedef enum logic [7:0] {LoadMem=1, SaveMem=2, StartNN=3, WaitNN=4, SetMem=5, EndBM=15} cmd;
typedef enum reg [4:0] {SLAVE_SEL, SLAVE_READ, SLAVE_WRITE, REQ, ADDR, ADDR2, ADDR3, CMD1, CMD2, CMD3, LOAD_ADDR, LOAD_READ, LOAD, SAVE_ADDR, SAVE, SET_ADDR,
			SET, START, START2, WAIT, WAIT_REQ, WAIT_GRANT, END} state_enum;

typedef enum logic [1:0] {IDLE,BUSY,NONSEQ,SEQ} transfermode;
typedef enum logic [2:0] {SINGLE,INCR,WRAP4,INCR4,WRAP8,INCR8,WRAP16,INCR16} burstmode;

//module NNTop (mAHBIF.AHBM master, sAHBIF.AHBS slave, nnIntf nn,input clk,reset);

//
// interface to student bus master to nn block
//

module bmnn(mAHBIF.AHBM m,sAHBIF.AHBS slv,nnIntf.nn_drv n);

	struct packed{
		system_addr PC;
		struct packed{
			reg [7:0] opcode;
			reg [23:0] length;
		} w1,w2,w3;
		state_enum state, next_state;
		system_addr addr, prev_addr, next_addr;
		reg busreq;
		Word loadword;
		reg waiting;
		Word ndout;
	} vals, vals_d;
	
	logic cont;
	logic store; // store=1 means the value at nextread is written
	logic advance_pc; // advance_pc=1 means the PC will increment

	state_enum state, next_state;
	reg [7:0] opcode;
	system_addr pc,next_addr;
	reg [23:0] length;
	assign opcode = vals.w1.opcode;
	assign state = vals.state;
	assign next_state = vals.next_state;
	assign pc = vals.PC;
	assign next_addr = vals.next_addr;
	assign length = vals.w3.length;

	always @(*) begin

		/* hold state by default */
		vals_d = vals;

		/* usually, I don't talk to the NN */
		n.addr = 0;
		n.RW = 0;
		n.sel = 0;
		n.din = 0;

		/* if this gets set to 0, data will not be stored into buffer */
		store = 1;
		
		/* continue once we get valid data from the bus */
		cont = m.mHREADYin;

		/* send addr to the master interface */
		m.mHADDR = vals.addr;

		/* if this gets set to 0, the PC will not increment */
		advance_pc = 1;

		/* send busreq to the master interface */
		vals_d.busreq = vals.busreq;
		m.mHBUSREQ = vals.busreq;

		/* we are always ready, always OKAY */
		slv.sHREADY = 1; slv.sHRESP = 0;

		/* as a slave, we always give PC as read data */
		slv.sHRDATA = vals.PC;

		/* size is always 32 bits */
		m.mHSIZE = 2;

		/* some AHB defaults */
		m.mHWDATA = 0;
		m.mHTRANS = 0;
		m.mHBURST = 0;
		m.mHWRITE = 0;

		/* these aren't used */
		m.mHPROT = 0;

		/**** CASE STATEMENT ****/
		case (vals.state)
		/** SLAVE STATES HERE **/
		SLAVE_SEL: begin /* patiently wait for my hsel signal */
			store = 0; advance_pc = 0;
			if (slv.sHSEL && slv.sHREADYin) begin
				if (slv.sHTRANS == 2'd1 || slv.sHTRANS == 2'd0) /* busy or idle */
					vals_d.state = SLAVE_SEL;
				else if (slv.sHWRITE) begin
					vals_d.state = SLAVE_READ;
				end else begin
					vals_d.state = SLAVE_WRITE;
				end
			end else begin
				vals_d.state = SLAVE_SEL;
			end
		end
		SLAVE_READ: begin /* receive data as a slave */
			store = 0; advance_pc = 0;

			vals_d.PC = slv.sHWDATA;
			vals_d.addr = slv.sHWDATA;

			if (slv.sHSEL) begin
				vals_d.state = REQ;
				vals_d.busreq = 1;
			end else begin
				vals_d.state = (vals.busreq) ? SLAVE_SEL : REQ;
			end
			vals_d.busreq = 1;
		end
		SLAVE_WRITE: begin /* send data as a slave */
			store = 0; advance_pc = 0;
			if (slv.sHSEL) begin
				//slv.sHRDATA = vals.PC;
				vals_d.busreq = 1;
			end
			vals_d.state = (vals.busreq) ? SLAVE_SEL : REQ;
		end

		/** MASTER STATES HERE **/
		/* 3 */
		REQ: begin /* during this phase, assert busreq */

			store = 0; //advance_pc = 0;

			/* we can still be addressed as a slave here */
			if (slv.sHSEL) begin
				if (slv.sHWRITE) begin
					vals_d.state = SLAVE_READ;
				end else begin
					vals_d.state = SLAVE_WRITE;
				end
			end
//			else if (m.mHGRANT) begin
//				vals_d.state = ADDR;
//			end
//			else begin
//				vals_d.state = REQ;
//			end
			else begin
				//vals_d.state = ADDR;
				vals_d.state = CMD1;
				vals_d.addr = vals.PC;
			end
		end
		/* 4 */
		ADDR: begin /* during this phase, the first master addr is being sent */
			vals_d.state = CMD1;
			store = 0;
			m.mHTRANS = NONSEQ; m.mHBURST = SINGLE;
		end
		/* 5 */
		ADDR2: begin /* same as addr, but return to next_state (follows loss of grant) */
			vals_d.state = vals.next_state;
			vals_d.addr = vals.next_addr;

			cont = 1;

			store = 0; //advance_pc = 0;
			m.mHTRANS = NONSEQ; m.mHBURST = SINGLE;
		end
		/* 6 */
		ADDR3: begin /* same as addr, but skip CMD1 (use after 1-word command) */
			vals_d.state = CMD2;
			store = 0;
			m.mHTRANS = NONSEQ; m.mHBURST = SINGLE;
		end
		/* 7 */
		CMD1: begin /* data is read and the next addr is sent during this phase */
			vals_d.state = CMD2;
			if (m.mHRDATA[31:24] == EndBM) begin
				m.mHWRITE = 1;
				m.mHTRANS = IDLE; m.mHBURST = SINGLE;
			end else begin
				m.mHWRITE = 0;
				m.mHTRANS = NONSEQ; m.mHBURST = SINGLE;
			end
		end
		/* 8 */
		CMD2: begin /* data retrieved in CMD1 can be interpreted here */
			case (vals.w1.opcode)
				LoadMem: begin
					vals_d.state = CMD3;
				end
				SaveMem: begin
					vals_d.state = CMD3;
				end
				StartNN: begin
					vals_d.state = START;
					advance_pc = 0;
				end
				WaitNN: begin
					vals_d.state = WAIT;
					vals_d.busreq = 0;
					vals_d.waiting = 1;
					advance_pc = 0;
				end
				SetMem: begin
					vals_d.state = CMD3;
				end
				EndBM: begin
					vals_d.waiting = 0;
					vals_d.state = END;
					m.mHWRITE = 1;vals_d.PC = 0; advance_pc = 0;
					vals_d.busreq = 0;
				end
				default: begin
					vals_d.state = CMD2;
				end
			endcase
			if (vals.w1.opcode == EndBM) begin
				m.mHTRANS = IDLE; m.mHBURST = SINGLE;
			end else begin
				m.mHTRANS = NONSEQ; m.mHBURST = SINGLE;
			end
		end
		/* 9 */
		CMD3: begin /* if the command has 3 words, this state is used for the 3rd */
		
			vals_d.addr = 0;
		
			advance_pc = 0;

			case (vals.w2.opcode) //check opcode
				LoadMem: begin
					vals_d.addr = vals.w1;
					vals_d.state = LOAD_ADDR;
				end
				SaveMem: begin
					vals_d.addr = m.mHRDATA;
					vals_d.state = SAVE_ADDR;
				end
				SetMem: begin
					vals_d.addr = vals.w1;
					vals_d.state = SET_ADDR;
				end
				default: begin
					vals_d.addr = vals.PC;
					vals_d.state = CMD1;
				end
			endcase
			m.mHTRANS = IDLE; m.mHBURST = SINGLE;
		end
		/* 10 */
		LOAD_ADDR: begin
			vals_d.w2 = vals.w2 + `ADDR_OFFSET;
			vals_d.addr = vals_d.w2;
			vals_d.state = LOAD_READ;
			store = 0; advance_pc = 0;
			m.mHTRANS = NONSEQ; m.mHBURST = INCR;
		end
		/* 11 */
		LOAD_READ: begin /* LoadMem: copy data from main memory to NN memory */
			/* word2 is the main memory addr, CMD3 is the NN memory addr */
			//m.mHADDR = vals.w2;
			m.mHWRITE = 0;
			
			
			/* increment address and decrement length */
			//vals_d.w1 = vals.w1 + `ADDR_OFFSET;
			vals_d.w2 = vals.w2 + `ADDR_OFFSET;
			vals_d.addr = vals_d.w2;
			//vals_d.w3.length = vals.w3.length - 1;

			store = 0;

			advance_pc = 0;

			vals_d.loadword = m.mHRDATA;

			if (vals.addr[9:0] == `KBOUNDARY) begin
				m.mHTRANS = NONSEQ; m.mHBURST = INCR;
			end else begin
				m.mHTRANS = SEQ; m.mHBURST = INCR;
			end

			vals_d.state = LOAD;
		end
		/* 12 */
		LOAD: begin /* LoadMem: copy data from main memory to NN memory */
			/* word2 is the main memory addr, CMD3 is the NN memory addr */
			//m.mHADDR = vals.w2;
			m.mHWRITE = 0;
			
			//n.addr = vals.w1;
			n.addr = (vals.w1[31]) ? (vals.w1[19:0] + 20'h20000) :
					(vals.w1[19:0] + 20'h40000);
			n.RW = 1;
			n.sel = 1;
			n.din = vals.loadword;

			vals_d.loadword = m.mHRDATA;
			
			/* increment address and decrement length */
			vals_d.w1 = vals.w1 + `NN_ADDR_OFFSET;
			vals_d.w2 = vals.w2 + `ADDR_OFFSET;
			vals_d.w3.length = vals.w3.length - 1;

			store = 0;

			advance_pc = 0;

			if (vals.w3.length>1) begin
				vals_d.state = LOAD;
				vals_d.PC = vals.PC;
				vals_d.addr = vals_d.w2;

				if (vals.addr[9:0] == `KBOUNDARY) begin
					m.mHTRANS = NONSEQ; m.mHBURST = INCR;
				end else begin
					m.mHTRANS = SEQ; m.mHBURST = INCR;
				end
			end else begin
				vals_d.state = ADDR;
				vals_d.addr = vals_d.PC;
				m.mHTRANS = IDLE; m.mHBURST = SINGLE;
			end
		end
		/* 13 */
		SAVE_ADDR: begin
			vals_d.w1 = vals.w1 + `ADDR_OFFSET;
			vals_d.w2 = vals.w2 + `NN_ADDR_OFFSET;
			
			vals_d.addr = vals_d.w1;
			vals_d.state = SAVE;
			
			//n.addr = vals_d.w2;
			n.addr = (vals.w2[31]) ? (vals.w2[19:0] + 20'h20000) :
					(vals.w2[19:0] + 20'h40000);
			n.RW = 0;
			n.sel = 1;

			vals_d.ndout = n.dout;

			m.mHWRITE = 1;

			store = 0; advance_pc = 0;
			m.mHTRANS = NONSEQ; m.mHBURST = INCR;
		end
		/* 14 */
		SAVE: begin /* SaveMem: copy data from NN memory to main memory */
			/* word2 is the NN memory addr, CMD3 is the main memory addr */
			//n.addr = vals.w2;
			n.addr = (vals.w2[31]) ? (vals.w2[19:0] + 20'h20000) :
					(vals.w2[19:0] + 20'h40000);
			n.RW = 0;
			n.sel = 1;

			vals_d.ndout = n.dout;
			
			//m.mHADDR = vals.w1;
			m.mHWRITE = 1;
			m.mHWDATA = vals.ndout;
			
			/* increment address and decrement length */
			vals_d.w1 = vals.w1 + `ADDR_OFFSET;
			vals_d.w2 = vals.w2 + `NN_ADDR_OFFSET;
			vals_d.w3.length = vals.w3.length - 1;

			store = 0;

			advance_pc = 0;

			if (vals.w3.length>1) begin
				vals_d.state = SAVE;
				vals_d.PC = vals.PC;
				vals_d.addr = vals_d.w1;

				if (vals.addr[9:0] == `KBOUNDARY) begin
					m.mHTRANS = NONSEQ; m.mHBURST = INCR;
				end else begin
					m.mHTRANS = SEQ; m.mHBURST = INCR;
				end
			end else begin
				vals_d.state = ADDR;
				vals_d.addr = vals_d.PC;
				m.mHTRANS = IDLE; m.mHBURST = SINGLE;
			end
		end
		/* 15 */
		SET_ADDR: begin
			vals_d.addr = vals.w2;
			vals_d.state = SET;
			store = 0; advance_pc = 0;
			m.mHWRITE = 1;
			m.mHTRANS = NONSEQ; m.mHBURST = SINGLE;
		end
		/* 16 */
		SET: begin /* SetMem: place an immediate value into main memory */
			/* word2 is the main memory addr, CMD3 is the value to write */
			//m.mHADDR = vals.w2;
			m.mHWRITE = 1;
			m.mHWDATA = vals.w1;
			
			vals_d.state = ADDR;
			vals_d.addr = vals_d.PC;

			store = 0; advance_pc = 0;
			m.mHTRANS = IDLE; m.mHBURST = SINGLE;
		end
		/* 17 */
		START: begin
			store = 0; advance_pc = 0;

			n.RW = 1; n.sel = 1; n.addr = 0;
			n.din = 32'h20010;

			vals_d.addr = vals_d.PC;

			vals_d.state = START2;
			m.mHTRANS = IDLE; m.mHBURST = SINGLE;
		end
		/* 18 */
		START2: begin
			store = 0; advance_pc = 0;

			n.RW = 1; n.sel = 1; n.addr = 2;
			n.din = 32'h0000_0ACE;

			vals_d.addr = vals_d.PC;

			vals_d.state = ADDR3;
			m.mHTRANS = IDLE; m.mHBURST = SINGLE;
		end
		/* 19 */
		WAIT: begin
			//if (n.pushout) begin
			//	vals_d.state = ADDR3;
			//	vals_d.busreq = 1;
			//end else begin
			//	vals_d.state = WAIT;
			//end
			vals_d.state = CMD2;
			store = 0; advance_pc = 0;
		end
		/* 20 */
		WAIT_REQ: begin
			vals_d.state = WAIT_GRANT;
			store = 0; advance_pc = 0;
		end
		/* 21 */
		WAIT_GRANT: begin
			if (m.mHGRANT)
				vals_d.state = ADDR3;
			else
				vals_d.state = WAIT_GRANT;
			store = 0; advance_pc = 0;
		end
		/* 22 */
		END: begin
			vals_d.state = SLAVE_SEL;
			vals_d.busreq = 0;
			store = 0; advance_pc = 0;
			m.mHWRITE = 1;
		end
		endcase
		/**** END CASE STATEMENT ****/


		/* increment the PC */
		if (advance_pc) begin
			vals_d.PC = vals.PC + `ADDR_OFFSET;
			vals_d.addr = vals_d.PC;
		end

		/* if lose grant, keep busreq high, so no need to return to REQ */
		if ((!m.mHGRANT && vals.busreq) || vals.waiting ) begin

			vals_d.next_state = vals_d.state;
			vals_d.next_addr = vals_d.addr;

			vals_d.state = ADDR2;
			//vals_d.addr = vals.prev_addr;
			vals_d.addr = vals.addr;

			//store = 0;

			if (advance_pc) vals_d.PC = vals.PC; // don't advance PC
		end
		else begin
			vals_d.next_state = vals_d.state;
			vals_d.prev_addr = vals.addr;
			vals_d.next_addr = vals_d.addr;
		end

		/* store read data into shift buffer */
		if (store) begin
			vals_d.w1 = m.mHRDATA;
			vals_d.w2 = vals.w1;
			vals_d.w3 = vals.w2;
		end

		if (vals.waiting) begin
			if (n.pushout) begin
				vals_d.busreq = 1;
				vals_d.waiting = 0;
			end
			else vals_d.busreq = 0;
		end

		if (!cont && m.mHGRANT) /* if slave isn't ready, hold everything */
			vals_d = vals;

	end
	
	always @(posedge(m.HCLK) or posedge(m.HRESET)) begin
		if (m.HRESET) begin
			vals <= 0;
		end else begin
			vals <= #0.2 vals_d;
`ifdef FOO
			#1 $display("Addr: %d, State: %s, Reads: %0h,%0h,%0h", m.mHADDR, 					vals.state.name, vals.w1,vals.w2,vals.w3); // DEBUG
`endif
		end
	end
	
endmodule : bmnn

`ifdef FOO
module tb();

	reg clk, reset;
	mAHBIF m(clk,reset);
	sAHBIF s(clk,reset);
	nnIntf n(clk,reset);

	int clks;

	logic g;

	bmnn topmod(m.AHBM, s.AHBS, n.nn_drv);

	initial begin
		clk = 0;
		clks = 0;
		#5;
		repeat (100) begin
			clk = ~clk;
			if (clk) clks += 1;
			if (clk) $write("%d  ", clks);
			if (!clk) if (clks == 11 || clks == 17) g = ~g;
			if (!clk) if (clks == 35) n.pushout = 1;
			#5;
		end
		$finish;
	end

	Word arr [] = {0,1,2,3,4,5,{8'h01,24'h1},7,8,{8'h02,24'h1},10,11,{8'h03,24'h0},
			{8'h04,24'h0},{8'h05,24'h1},15,16,{8'hf,24'h0}};
	system_addr addr;

	initial begin
		$display("10bit boundary: %d",`KBOUNDARY);
		s.sHWRITE = 0;
		s.sHSEL = 0;
		s.sHWDATA = 0;
		s.sHREADYin = 1;
		s.sHTRANS = 2;

		m.mHREADYin = 0;
		m.mHRDATA = 0;

		g = 1;

		n.pushout = 1;

		reset = 1;
		#2 reset = 0;
		$monitor("Data out: %d",m.mHWDATA);

		@(posedge(clk)) #1;
		s.sHWRITE = 1;
		s.sHSEL = 1;
		@(posedge(clk)) #1;
		s.sHWDATA = 6;

		@(posedge(clk)) #1;
		s.sHSEL = 0;

		m.mHREADYin = 1;
		m.mHGRANT = 0;
		@(posedge(clk)) #1;@(posedge(clk)) #1;
		forever begin
			m.mHGRANT = m.mHBUSREQ && g;
			addr = (m.mHGRANT) ? m.mHADDR : 0;
			@(posedge(clk));
			#1;
			m.mHRDATA = arr[addr];
		end

	end

endmodule
`endif
