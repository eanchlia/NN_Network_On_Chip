// A simple model for a memory... 
// uses typedefs from mem_intf.sv and should be
// included after mem_intf.sv
`timescale 1ns/10ps

module mem(memIntf.model i);

Mdata m[Maddr];    // the model memory is an associative array
Maddr aw,a0,a1,a2,a3,a4,a5,a6,a7;
Mdata wd;
integer ix;
logic write;
event wc;

function Mdata access(Maddr adr);
    if (m.exists(adr)) return(m[adr]);
    return 32'hxxxxxxxx;
endfunction : access

always @(wc or i.a) begin
    #1;
    for(ix=0; ix < 8; ix += 1) i.d[ix]=access(i.a[ix]);
end

always @(posedge(i.clk)) begin
    chkx1(i.write,"write");
    chkxa(i.aw,"write address");
    if (i.write) begin
        m[i.aw]= i.wd;
        -> wc;
    end
    chkxa(i.a[0],"a0");
    chkxa(i.a[1],"a1");
    chkxa(i.a[2],"a2");
    chkxa(i.a[3],"a3");
    chkxa(i.a[4],"a4");
    chkxa(i.a[5],"a5");
    chkxa(i.a[6],"a6");
    chkxa(i.a[7],"a7");
end

task chkh(input logic[31:0] a,b,input string em);
    if ($realtime > 40ns && a !== b) begin
        $display("No m hold time on %s at %t",em,$realtime);
        #10 $finish;
    end
endtask : chkh

task chkx1(input logic d,input string em);
    if ($realtime > 20ns &&d === 1'bX) begin
        $display("Error %s is 'X'",em);
        #10 $finish;
    end
endtask : chkx1

task chkxa(input Maddr d,input string em);
    if ($realtime > 20ns && ^d === 1'bX) begin
        $display("Error %s is 'X'",em);
        #10 $finish;
    end
endtask : chkxa

task chkxd(input Mdata d,input string em);
    if ($realtime > 20ns && ^d === 1'bX) begin
        $display("Error %s is 'X'",em);
        #10 $finish;
    end
endtask : chkxd

always @(posedge(i.clk)) begin
    aw=i.aw;
    wd=i.wd;
    write=i.write;
    a0=i.a[0];
    a1=i.a[1];
    a2=i.a[2];
    a3=i.a[3];
    a4=i.a[4];
    a5=i.a[5];
    a6=i.a[6];
    a7=i.a[7];
    chkx1(write,"write strobe");
    chkxa(aw,"write address");
    chkxd(wd,"write data");
    chkxa(a0,"read address 0");
    chkxa(a1,"read address 1");
    chkxa(a2,"read address 2");
    chkxa(a3,"read address 3");
    chkxa(a4,"read address 4");
    chkxa(a5,"read address 5");
    chkxa(a6,"read address 6");
    chkxa(a7,"read address 7");
    #0.2;
    chkh(aw,i.aw,"write address");
    chkh(write,i.write,"write strobe");
    chkh(wd,i.wd,"write data");
    chkh(a0,i.a[0],"read address 0");
    chkh(a1,i.a[1],"read address 1");
    chkh(a2,i.a[2],"read address 2");
    chkh(a3,i.a[3],"read address 3");
    chkh(a4,i.a[4],"read address 4");
    chkh(a5,i.a[5],"read address 5");
    chkh(a6,i.a[6],"read address 6");
    chkh(a7,i.a[7],"read address 7");
end

endmodule : mem



module cmem(cmemIntf.model i);

Cdata m[Caddr];    // the model memory is an associative array
Caddr aw,a0,a1,a2,a3,a4,a5,a6,a7;
Cdata wd;
logic write;
event ew;

function Cdata access(Caddr adr);
    if (m.exists(adr)) return(m[adr]);
    return 32'hxxxxxxxx;
endfunction : access


always @(ew or i.a[0] or i.a[1] or i.a[2] or i.a[3] or i.a[4] or i.a[5] or i.a[6]
         or i.a[7]) begin
    #1;
    for(integer ix=0; ix < 8; ix += 1) i.d[ix]=access(i.a[ix]);
end

always @(posedge(i.clk)) begin
    chkx1(i.write,"write");
    chkxa(i.aw,"write address");
    if (i.write) begin
//        $display("Writing %x to %x",i.wd,i.aw);
        m[i.aw]<= i.wd;
        -> ew;
    end
    chkxa(i.a[0],"a0");
    chkxa(i.a[1],"a1");
    chkxa(i.a[2],"a2");
    chkxa(i.a[3],"a3");
    chkxa(i.a[4],"a4");
    chkxa(i.a[5],"a5");
    chkxa(i.a[6],"a6");
    chkxa(i.a[7],"a7");
end

task chkh(input logic[31:0] a,b,input string em);
    if ($realtime > 20.0 && a !== b) begin
        $display("No c hold time on %s at %20f",em,$realtime);
        #10 $finish;
    end
endtask : chkh

task chkx1(input logic d,input string em);
    if ($realtime > 20e-9 && d === 1'bX) begin
        $display("Error %s is 'X'",em);
        #10 $finish;
    end
endtask : chkx1

task chkxa(input Caddr d,input string em);
    if ($realtime > 20e-9 && ^d === 1'bX) begin
        $display("Error %s is 'X'",em);
        #10 $finish;
    end
endtask : chkxa

task chkxd(input Cdata d,input string em);
    if ($realtime > 20e-9 && ^d === 1'bX) begin
        $display("Error %s is 'X'",em);
        #10 $finish;
    end
endtask : chkxd

always @(posedge(i.clk)) begin
    aw=i.aw;
    wd=i.wd;
    write=i.write;
    a0=i.a[0];
    a1=i.a[1];
    a2=i.a[2];
    a3=i.a[3];
    a4=i.a[4];
    a5=i.a[5];
    a6=i.a[6];
    a7=i.a[7];
    chkx1(write,"write strobe");
    chkxa(aw,"write address");
    chkxd(wd,"write data");
    chkxa(a0,"read address 0");
    chkxa(a1,"read address 1");
    chkxa(a2,"read address 2");
    chkxa(a3,"read address 3");
    chkxa(a4,"read address 4");
    chkxa(a5,"read address 5");
    chkxa(a6,"read address 6");
    chkxa(a7,"read address 7");
    #0.2;
    chkh(aw,i.aw,"write address");
    chkh(write,i.write,"write strobe");
    chkh(wd,i.wd,"write data");
    chkh(a0,i.a[0],"read address 0");
    chkh(a1,i.a[1],"read address 1");
    chkh(a2,i.a[2],"read address 2");
    chkh(a3,i.a[3],"read address 3");
    chkh(a4,i.a[4],"read address 4");
    chkh(a5,i.a[5],"read address 5");
    chkh(a6,i.a[6],"read address 6");
    chkh(a7,i.a[7],"read address 7");
end

endmodule : cmem
