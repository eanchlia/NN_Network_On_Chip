// This is an interface module for the AHB master in 
// the 272 problem.  All master names begin with m to keep them simple
//

interface mAHBIF(input reg HCLK,HRESET);
    logic mHBUSREQ,mHGRANT,mHREADYin;
    logic [1:0] mHRESP;
    logic [31:0] mHRDATA,mHWDATA,mHADDR;
    logic mHLOCK;    // not used
    logic [1:0] mHTRANS;
    logic mHWRITE;
    logic [2:0] mHSIZE; // only 32 bits used
    logic [2:0] mHBURST;
    logic [3:0] mHPROT;     // not used
    logic [3:0] mHMASTER;   // not used
    logic mHMASTLOCK;       // not used

    modport AHBM( input HCLK, input HRESET,
        input mHGRANT, output mHBUSREQ, 
        input mHREADYin,input mHRESP, output mHPROT,
        input mHRDATA,output mHTRANS, output mHADDR,
        output mHWRITE, output mHWDATA, output mHSIZE, output mHBURST);

    modport AHBMfab(input HCLK, input HRESET,
        output mHGRANT, input mHBUSREQ, 
        output mHREADYin,output mHRESP, input mHPROT,
        output mHRDATA,input mHTRANS, input mHADDR,
        input mHWRITE, input mHWDATA, input mHSIZE, input mHBURST);

endinterface : mAHBIF

interface sAHBIF(input reg HCLK,HRESET);
    logic sHREADYin;
    logic sHREADY;
    logic sHSEL;
    logic [1:0] sHRESP;
    logic [31:0] sHRDATA,sHWDATA,sHADDR;
    logic sHLOCK;    // not used
    logic [1:0] sHTRANS;
    logic sHWRITE;
    logic [2:0] sHSIZE; // only 32 bits used
    logic [2:0] sHBURST;
    logic [3:0] sHPROT;     // not used
    logic [3:0] sHMASTER;   // not used
    logic sHMASTLOCK;       // not used

    modport AHBS( input HCLK, input HRESET,
        output sHREADY, input sHREADYin,input sHSEL, 
        output sHRESP, input sHPROT,
        output sHRDATA,input sHTRANS, input sHADDR,
        input sHWRITE, input sHWDATA, input sHSIZE, input sHBURST);

    modport AHBSfab(input HCLK, input HRESET,
        input sHREADY, output sHREADYin,output sHRESP, output sHSEL, 
        output sHPROT,
        input sHRDATA,output sHTRANS, output sHADDR,
        output sHWRITE, output sHWDATA, output sHSIZE, output sHBURST);

endinterface : sAHBIF

