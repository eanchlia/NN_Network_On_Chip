// A simple neural network block interface.
// The clock and reset come from outside

interface nnIntf(input reg clk,input reg reset);

logic RW,sel;
logic [19:0] addr;
logic [31:0] din;
logic [31:0] dout;
logic bus_stop;
logic pushout;

modport nn(input clk, input reset, input RW,sel,addr,din,
           output dout,bus_stop,pushout);


modport nn_drv(output RW,sel,addr,din,input dout,bus_stop,pushout);




endinterface : nnIntf
