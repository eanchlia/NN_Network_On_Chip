// A memory interface for the NN project
// The memory is multiported, and has one write port,
// and 8 read ports.
//
// Copyright Morris Jones 2018
//
typedef logic [15:0] Maddr;  // a type for memory addresses
typedef logic [23:0] Mdata;  // a type for memory data
typedef logic [16:0] Caddr;  // configuration memory for each level
typedef logic [31:0] Cdata;  // configuration data for the levels


// These blocks hold the configuration memory interfaces
interface cmemIntf(input logic clk);
    Caddr   aw;     // write address
    logic   write;  // write to configuration memory
    Cdata   wd;     // the write data for configuration memory
    Caddr [7:0]  a;
    Cdata  [7:0] d;

    // mem modport is for a design to connect to a memory block
    modport mem(input clk, output aw, output write, output wd,
                output a,
                input  d);
    
    // model modport connects to a memory model
    modport model(input clk, input aw,write,wd,
                  input a,
                  output d);

endinterface : cmemIntf

interface memIntf(input logic clk);
    Maddr aw;       // The write address
    logic write;    // a write strobe (It's clocked)
    Mdata wd;       // The write data
    Maddr [7:0] a;  // Read addresses
    Mdata [7:0] d;  // Read data back
    
    // mem modport is for a design to connect to a memory block
    modport mem(input clk, output aw, output write, output wd,
                output a,
                input  d);
    
    // model modport connects to a memory model
    modport model(input clk, input aw,write,wd,
                  input a,
                  output d);
    
    
endinterface : memIntf
