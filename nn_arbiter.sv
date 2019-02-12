module nn_arbiter(
  output logic grant_rcal, grant_fp,
  input logic req_rcal, req_fp,
  input Caddr [7:0] cmem_addr_rcal,
  input Maddr [7:0] dmem_addr_rcal,
  input Caddr [7:0] cmem_addr_fp,
  input Maddr [7:0] dmem_addr_fp,
  output Caddr [7:0] cmem_addr,
  output Maddr [7:0] dmem_addr
);
always @(*)
begin
  if (req_rcal) begin
    grant_rcal   = 1;
    grant_fp = 0;
    cmem_addr    = cmem_addr_rcal;
    dmem_addr    = dmem_addr_rcal;
  end else begin
    grant_rcal   = 0;
    grant_fp     = 1;
    cmem_addr    = cmem_addr_fp;
    dmem_addr    = dmem_addr_fp;
  end

end
endmodule

//module tb_a();
//
//logic r1,r2,g1,g2;
//nn_arbiter (g1,g2,r1,r2);
//initial begin
//$monitor ("Req_L: %h, Reg_R: %h, Grant_L: %h, Grant_R: %h", r2,r1,g2,g1);
//  #10 r1 = 0; r2 = 0;
//  #10 r1 = 1; r2 = 0;
//  #10 r1 = 1; r2 = 1;
//  #10 r1 = 0; r2 = 1;
//  #10 r1 = 1; r2 = 1;
//  #10 r1 = 0; r2 = 0;
//end
//
//endmodule
