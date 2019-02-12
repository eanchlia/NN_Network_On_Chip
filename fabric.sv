// required interfaces for master side -- both nn master and tb master
//interface mAHBIF(reg HCLK,HRESET);
//    logic mHBUSREQ,mHGRANT,mHREADYin;
//    logic [1:0] mHRESP;
//    logic [31:0] mHRDATA,mHWDATA,mHADDR;
//    logic mHLOCK; // not used
//    logic [1:0] mHTRANS;
//    logic mHWRITE;
//    logic [2:0] mHSIZE; // only 32 bits used
//    logic [2:0] mHBURST;
//    logic [3:0] mHPROT; // not used
//    logic [3:0] mHMASTER; // not used
//    logic mHMASTLOCK; // not used
//
//
//
//    modport AHBMfab( input HCLK, input HRESET,
//    input mHGRANT, output mHBUSREQ,
//    input mHREADYin,input mHRESP, output mHPROT,
//    input mHRDATA,output mHTRANS, output mHADDR,
//    output mHWRITE, output mHWDATA, output mHSIZE, output mHBURST);
//    
//    modport AHBMtb(input HCLK, input HRESET,
//    output mHGRANT, input mHBUSREQ,
//    output mHREADYin,output mHRESP, input mHPROT,
//    output mHRDATA,input mHTRANS, input mHADDR,
//    input mHWRITE, input mHWDATA, input mHSIZE, input mHBURST);
//
//endinterface : mAHBIF
//
//// required interfaces for slave side -- both nn slave and tb slave
//interface sAHBIF(reg HCLK,HRESET);
//    logic sHREADYin;
//    logic sHREADY;
//    logic [1:0] sHRESP;
//    logic [31:0] sHRDATA,sHWDATA,sHADDR;
//    logic sHLOCK; // not used
//    logic [1:0] sHTRANS;
//    logic sHWRITE;
//    logic [2:0] sHSIZE; // only 32 bits used
//    logic [2:0] sHBURST;
//    logic [3:0] sHPROT; // not used
//    logic [3:0] sHMASTER; // not used
//    logic sHMASTLOCK; // not used
//    logic mHSEL; //sent by decoder to the slaves
//
//    modport AHBSfab( input HCLK, input HRESET,
//    output sHREADY, input sHREADYin,output sHRESP, input sHPROT,
//    output sHRDATA,input sHTRANS, input sHADDR,
//    input sHWRITE, input sHWDATA, input sHSIZE, input sHBURST);
//
//    modport AHBS_drv(input HCLK, input HRESET,
//    input sHREADYin,output sHRESP, output sHPROT,
//    input sHRDATA,output sHTRANS, output sHADDR,
//    output sHWRITE, output sHWDATA, output sHSIZE, output sHBURST);
//
//endinterface : sAHBIF


//
// The AHB Fabric module
//
module fabric(mAHBIF.AHBMfab m0,mAHBIF.AHBMfab m1,mAHBIF.AHBMfab m2,mAHBIF.AHBMfab m3,mAHBIF.AHBMfab mt,
            sAHBIF.AHBSfab s0,sAHBIF.AHBSfab s1,sAHBIF.AHBSfab s2,sAHBIF.AHBSfab s3,sAHBIF.AHBSfab st);





// declarations for arbitor
integer count, count_d;
integer rotate_amount, rotate_amount_d, rotate_amount_final, rotate_amount_temp;
reg [4:0] req_by_masters_d, grant_given, grant_order, actual_grants;
reg [2:0] selected_master, selected_master_d;


// declarations for muxes
reg [2:0] out_burst;
reg [31:0] out_rdata;
reg out_readyin;
reg [1:0] out_resp;
reg out_rwrite;
reg [1:0] out_trans;
reg [31:0] out_wdata, out_size;

// declarations for decoder
reg [31:0] out_addr;
reg [2:0] select_by_decoder, select_by_decoder1, select_by_decoder1_d;

reg [31:0] mrd0_d,mrd1_d,mrd2_d,mrd3_d,mrdt_d;
reg [31:0] swd0_d,swd1_d,swd2_d,swd3_d,swdt_d;

// arbitor starts here
always @ (posedge mt.HCLK or posedge mt.HRESET) begin
    if (mt.HRESET) begin
        req_by_masters_d[4] <= #1 0;
        req_by_masters_d[3] <= #1 0;
        req_by_masters_d[2] <= #1 0;
        req_by_masters_d[1] <= #1 0;
        req_by_masters_d[0] <= #1 0;

        //count_d <= #1 0;
        rotate_amount_d <= #1 0;
        selected_master <= #1 0;

        mt.mHGRANT <= #1 0;
        m0.mHGRANT <= #1 0;
        m1.mHGRANT <= #1 0;
        m2.mHGRANT <= #1 0;
        m3.mHGRANT <= #1 0;

	select_by_decoder1_d <= #1 0;
    end
    else begin
        req_by_masters_d[4] <= #1 mt.mHBUSREQ;
        req_by_masters_d[3] <= #1 m0.mHBUSREQ;
        req_by_masters_d[2] <= #1 m1.mHBUSREQ;
        req_by_masters_d[1] <= #1 m2.mHBUSREQ;
        req_by_masters_d[0] <= #1 m3.mHBUSREQ;

        count_d <= #1 count;
        rotate_amount_d <= #1 rotate_amount;
        selected_master <= #1 selected_master_d;

        mt.mHGRANT <= #1 actual_grants[4];
        m0.mHGRANT <= #1 actual_grants[3];
        m1.mHGRANT <= #1 actual_grants[2];
        m2.mHGRANT <= #1 actual_grants[1];
        m3.mHGRANT <= #1 actual_grants[0];

	select_by_decoder1_d <= #1 select_by_decoder1;

        //st.sHWDATA <= #1 swdt_d;
        //s0.sHWDATA <= #1 swd0_d;
        //s1.sHWDATA <= #1 swd1_d;
        //s2.sHWDATA <= #1 swd2_d;
        //s3.sHWDATA <= #1 swd3_d;

        //mt.mHRDATA <= #1 mrdt_d;
        //m0.mHRDATA <= #1 mrd0_d;
        //m1.mHRDATA <= #1 mrd1_d;
        //m2.mHRDATA <= #1 mrd2_d;
        //m3.mHRDATA <= #1 mrd3_d;
    end
end



always @ (*) begin
    if (mt.HRESET) begin
        rotate_amount_temp = 0;
        rotate_amount_final = 0;
        grant_order = 0;
        grant_given = 0;
        actual_grants = 0;
        count = 0;
        rotate_amount = 0;
        selected_master_d = 0;
    end
    else begin
        if (count_d == 4'b0111) rotate_amount_temp = rotate_amount_d + 1;   
        else rotate_amount_temp = rotate_amount_d;

        if (rotate_amount_temp > 4) rotate_amount_final = (rotate_amount_temp % 5);
        else rotate_amount_final = rotate_amount_temp;

        grant_order = (req_by_masters_d << rotate_amount_final) | (req_by_masters_d >> (5-rotate_amount_final)); // circular rotation

        if (grant_order[4] == 1) begin
            grant_given = 5'b10000;
            if (count_d == 4'b0111) count = 0;
            else count = count_d + 1;  
            rotate_amount = rotate_amount_final; 
        end
        else if (grant_order[3] == 1) begin
            grant_given = 5'b01000;
            rotate_amount = rotate_amount_final + 1;
            count = 1;
        end
        else if (grant_order[2] == 1) begin
            grant_given = 5'b00100;
            rotate_amount = rotate_amount_final + 2;
            count = 1;
        end
        else if (grant_order[1] == 1) begin
            grant_given = 5'b00010;
            rotate_amount = rotate_amount_final + 3;
            count = 1;
        end
        else if (grant_order[0] == 1) begin
            grant_given = 5'b00001;
            rotate_amount = rotate_amount_final + 4;
            count = 1;
        end
        else begin
            grant_given = 0;
            count = 1;
	    rotate_amount = rotate_amount_d;
        end
        actual_grants = (grant_given << (5-rotate_amount_final)) | (grant_given >> rotate_amount_final); // reverse circular rotation
        case (actual_grants) 
            5'b10000 : selected_master_d = 3'd5;
            5'b01000 : selected_master_d = 3'd4;
            5'b00100 : selected_master_d = 3'd3;
            5'b00010 : selected_master_d = 3'd2;
            5'b00001 : selected_master_d = 3'd1;
	    default : selected_master_d = 0;
        endcase
    end
end
// arbitor ends here

// decoder starts here
always @ (*) begin
//    case (out_addr) inside
if (out_trans != 0)
    case (1)
        (out_addr == 32'hfffeff00) : begin
            st.sHSEL = 1'b0;    // 1 is tb, from 2 its nn1 to nn4
            s0.sHSEL = 1'b1;
            s1.sHSEL = 1'b0;
            s2.sHSEL = 1'b0;
            s3.sHSEL = 1'b0;
        end 
        (out_addr == 32'hfffeff04) : begin
            st.sHSEL = 1'b0;    // 1 is tb, from 2 its nn1 to nn4
            s0.sHSEL = 1'b0;
            s1.sHSEL = 1'b1;
            s2.sHSEL = 1'b0;
            s3.sHSEL = 1'b0; 
        end 
        (out_addr == 32'hfffeff08) : begin
            st.sHSEL = 1'b0;    // 1 is tb, from 2 its nn1 to nn4
            s0.sHSEL = 1'b0;
            s1.sHSEL = 1'b0;
            s2.sHSEL = 1'b1;
            s3.sHSEL = 1'b0; 
        end 
        (out_addr == 32'hfffeff0c) : begin
            st.sHSEL = 1'b0;    // 1 is tb, from 2 its nn1 to nn4
            s0.sHSEL = 1'b0;
            s1.sHSEL = 1'b0;
            s2.sHSEL = 1'b0;
            s3.sHSEL = 1'b1; 
        end 
//        [32'h10000000 : 32'h3fffffff] : begin
	((out_addr >= 32'h10000000) && (out_addr <= 32'h3fffffff)): begin
            st.sHSEL = 1'b1;    // 1 is tb, from 2 its nn1 to nn4
            s0.sHSEL = 1'b0;
            s1.sHSEL = 1'b0;
            s2.sHSEL = 1'b0;
            s3.sHSEL = 1'b0; 
        end 
        default : begin
            st.sHSEL = 1'b0;    // 1 is tb, from 2 its nn1 to nn4
            s0.sHSEL = 1'b0;
            s1.sHSEL = 1'b0;
            s2.sHSEL = 1'b0;
            s3.sHSEL = 1'b0; 
        end
    endcase 
else begin
            st.sHSEL = 1'b0;    // 1 is tb, from 2 its nn1 to nn4
            s0.sHSEL = 1'b0;
            s1.sHSEL = 1'b0;
            s2.sHSEL = 1'b0;
            s3.sHSEL = 1'b0; 
end

	case (1)
		(out_addr == 32'hfffeff00) : begin
		    select_by_decoder = 3'd2; 
		    select_by_decoder1 = 3'd2;  
		end 
		(out_addr == 32'hfffeff04) : begin
	 
		    select_by_decoder = 3'd3; 
		    select_by_decoder1 = 3'd3;  
		end 
		(out_addr == 32'hfffeff08) : begin

		    select_by_decoder = 3'd4;
		    select_by_decoder1 = 3'd4;   
		end 
		(out_addr == 32'hfffeff0c) : begin
		    select_by_decoder = 3'd5; 
		    select_by_decoder1 = 3'd5;  
		end 
		((out_addr >= 32'h10000000) && (out_addr <= 32'h3fffffff)): begin
		    select_by_decoder = 3'd1;
		    select_by_decoder1 = 3'd1;   
		end 
		default : begin
		    select_by_decoder = 3'd0; 
		    select_by_decoder1 = 3'd0;  
		end
	endcase
end
//decoder ends here

//mux for haddr starts here
always @ (*) begin
    case (selected_master) 
        3'd1 : out_addr = m3.mHADDR;
        3'd2 : out_addr = m2.mHADDR;
        3'd3 : out_addr = m1.mHADDR;
        3'd4 : out_addr = m0.mHADDR;
        3'd5 : out_addr = mt.mHADDR;
        default : out_addr = 0;
    endcase 
    st.sHADDR = out_addr;
    s0.sHADDR = out_addr;
    s1.sHADDR = out_addr;
    s2.sHADDR = out_addr;
    s3.sHADDR = out_addr;
end
//mux for haddr ends here
//mux for hsize starts here
always @ (*) begin
    case (selected_master) 
        3'd1 : out_size = m3.mHSIZE;
        3'd2 : out_size = m2.mHSIZE;
        3'd3 : out_size = m1.mHSIZE;
        3'd4 : out_size = m0.mHSIZE;
        3'd5 : out_size = mt.mHSIZE;
        default : out_size = 0;
    endcase 
    st.sHSIZE = out_size;
    s0.sHSIZE = out_size;
    s1.sHSIZE = out_size;
    s2.sHSIZE = out_size;
    s3.sHSIZE = out_size;
end
//mux for hsize ends here



//mux for hburst starts here
always @ (*) begin
    case (selected_master) 
        3'd1 : out_burst = m3.mHBURST;
        3'd2 : out_burst = m2.mHBURST;
        3'd3 : out_burst = m1.mHBURST;
        3'd4 : out_burst = m0.mHBURST;
        3'd5 : out_burst = mt.mHBURST;
        default : out_burst = 0;
    endcase 
    st.sHBURST = out_burst;
    s0.sHBURST = out_burst;
    s1.sHBURST = out_burst;
    s2.sHBURST = out_burst;
    s3.sHBURST = out_burst;
end
//mux for hburst ends here

//mux for hrwrite starts here
always @ (*) begin
    case (selected_master) 
        3'd1 : out_rwrite = m3.mHWRITE;
        3'd2 : out_rwrite = m2.mHWRITE;
        3'd3 : out_rwrite = m1.mHWRITE;
        3'd4 : out_rwrite = m0.mHWRITE;
        3'd5 : out_rwrite = mt.mHWRITE;
        default : out_rwrite = 1;
    endcase 
    st.sHWRITE = out_rwrite;
    s0.sHWRITE = out_rwrite;
    s1.sHWRITE = out_rwrite;
    s2.sHWRITE = out_rwrite;
    s3.sHWRITE = out_rwrite;
end
//mux for hrwrite ends here

//mux for htrans starts here
always @ (*) begin
    case (selected_master) 
        3'd1 : out_trans = m3.mHTRANS;
        3'd2 : out_trans = m2.mHTRANS;
        3'd3 : out_trans = m1.mHTRANS;
        3'd4 : out_trans = m0.mHTRANS;
        3'd5 : out_trans = mt.mHTRANS;
        default : out_trans = 0;
    endcase 
    st.sHTRANS = out_trans;
    s0.sHTRANS = out_trans;
    s1.sHTRANS = out_trans;
    s2.sHTRANS = out_trans;
    s3.sHTRANS = out_trans;
end
//mux for htrans ends here

//mux for hwdata starts here
always @ (*) begin
    case (selected_master) 
        3'd1 : out_wdata = m3.mHWDATA;
        3'd2 : out_wdata = m2.mHWDATA;
        3'd3 : out_wdata = m1.mHWDATA;
        3'd4 : out_wdata = m0.mHWDATA;
        3'd5 : out_wdata = mt.mHWDATA;
        default : out_wdata = 0;
    endcase 
    st.sHWDATA = out_wdata;
    s0.sHWDATA = out_wdata;
    s1.sHWDATA = out_wdata;
    s2.sHWDATA = out_wdata;
    s3.sHWDATA = out_wdata;
end
//mux for hwdata ends here

//mux for hrdata starts here
always @ (*) begin
    case (select_by_decoder1_d) 
        3'd1 : out_rdata = st.sHRDATA; // tb
        3'd2 : out_rdata = s0.sHRDATA; // nn1
        3'd3 : out_rdata = s1.sHRDATA; // nn2
        3'd4 : out_rdata = s2.sHRDATA; // nn3
        3'd5 : out_rdata = s3.sHRDATA; // nn4
        default : out_rdata = 0;
    endcase 
    mt.mHRDATA = out_rdata;
    m0.mHRDATA = out_rdata;
    m1.mHRDATA = out_rdata;
    m2.mHRDATA = out_rdata;
    m3.mHRDATA = out_rdata;
end
//mux for hrdata ends here

//mux for hreadyin starts here
always @ (*) begin
    case (select_by_decoder1_d) 
        3'd1 : out_readyin = st.sHREADY;
        3'd2 : out_readyin = s0.sHREADY;
        3'd3 : out_readyin = s1.sHREADY;
        3'd4 : out_readyin = s2.sHREADY;
        3'd5 : out_readyin = s3.sHREADY;
        default : out_readyin = 1;
    endcase
    mt.mHREADYin = out_readyin;
    m0.mHREADYin = out_readyin;
    m1.mHREADYin = out_readyin;
    m2.mHREADYin = out_readyin;
    m3.mHREADYin = out_readyin; 
    st.sHREADYin = out_readyin;
    s0.sHREADYin = out_readyin;
    s1.sHREADYin = out_readyin;
    s2.sHREADYin = out_readyin;
    s3.sHREADYin = out_readyin; 
end
//mux for hreadyin ends here

//mux for hresp starts here
always @ (*) begin
    case (select_by_decoder) 
        3'd1 : out_resp = st.sHRESP;
        3'd2 : out_resp = s0.sHRESP;
        3'd3 : out_resp = s1.sHRESP;
        3'd4 : out_resp = s2.sHRESP;
        3'd5 : out_resp = s3.sHRESP;
        default : out_resp = 0;
    endcase 
    mt.mHRESP = out_resp;
    m0.mHRESP = out_resp;
    m1.mHRESP = out_resp;
    m2.mHRESP = out_resp;
    m3.mHRESP = out_resp;
end
//mux for hresp ends here

endmodule : fabric
