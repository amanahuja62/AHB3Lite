`timescale 1ns / 1ps



module ahb_testbench;


/*****************************************************
                    AHB MASTER
******************************************************/
	// Inputs
	// these three signals will come from mux
	//reg HREADY;
	//reg HRESP;
	//reg [31:0] HRDATA;
	reg HRESETn; // global signals
	reg HCLK;    // glocal signal	
	reg [2:0] iHBURST;
	reg [1:0] iHTRANS;
	reg [2:0] iHSIZE;
	reg [3:0] iHPROT;
	reg iHMASTLOCK;
	reg [31:0] iHADDR;
	reg[31:0] iHWDATA; 
	reg iHWRITE;

	// Outputs
	wire [31:0] HADDR;
	wire HWRITE;
	wire [2:0] HSIZE;
	wire [2:0] HBURST;
	wire [3:0] HPROT;
	wire [1:0] HTRANS;
	wire HMASTLOCK;
	wire [31:0] HWDATA;
	wire[31:0] dataFetched;
	wire[15:0] parityBits;
	
	
	// Instantiate the Unit Under Test (UUT)
	ahb_master uut (
		.HREADY(HREADY), 
		.HRESP(HRESP), 
		.HRESETn(HRESETn), 
		.HCLK(HCLK), 
		.HRDATA(HRDATA), 
		.HADDR(HADDR), 
		.HWRITE(HWRITE), 
		.HSIZE(HSIZE), 
		.HBURST(HBURST), 
		.HPROT(HPROT), 
		.HTRANS(HTRANS), 
		.HMASTLOCK(HMASTLOCK), 
		.HWDATA(HWDATA), 
		.iHBURST(iHBURST), 
		.iHTRANS(iHTRANS), 
		.iHSIZE(iHSIZE), 
		.iHPROT(iHPROT), 
		.iHMASTLOCK(iHMASTLOCK), 
		.iHADDR(iHADDR), 
		.iHWDATA(iHWDATA), 
		.iHWRITE(iHWRITE), 
		.dataFetched(dataFetched),
		.parityBits(parityBits)
		
	);
	
	
	/****************************************************************
	                       AHB Slave
	****************************************************************/	
	wire[31:0] HRDATA1,HRDATA2,HRDATA3,HRDATA4;
	reg INTR;
	wire HRESP1,HRESP2,HRESP3,HRESP4,HREADY1,HREADY2,HREADY3,HREADY4;
	ahbSlave sl (
	  .HADDR(HADDR),
	  .HWDATA(HWDATA),
	  .HTRANS(HTRANS),
	  .HBURST(HBURST),
	  .HWRITE(HWRITE),
	  .HSIZE(HSIZE),
	  .HCLK(HCLK),
	  .HRESETn(HRESETn),
	  .HREADYOUT(HREADY1),
	  .HRESP(HRESP1),
	  .HRDATA(HRDATA1),
	  .INTR(INTR),
	  .HREADYIN(HREADY),
	  .HSEL_S1(HSEL_S1),
	  .parityBits(parityBits)
	);
	ahbSlave s2(
	  .HADDR(HADDR),
	  .HWDATA(HWDATA),
	  .HTRANS(HTRANS),
	  .HBURST(HBURST),
	  .HWRITE(HWRITE),
	  .HSIZE(HSIZE),
	  .HCLK(HCLK),
	  .HRESETn(HRESETn),	
     .HREADYOUT(HREADY2),
	  .HRESP(HRESP2),
	  .HRDATA(HRDATA2),
     .INTR(INTR),
	  .HREADYIN(HREADY),
	  .HSEL_S1(HSEL_S2),
	  .parityBits(parityBits)
	);
	ahbSlave s3(
	  .HADDR(HADDR),
	  .HWDATA(HWDATA),
	  .HTRANS(HTRANS),
	  .HBURST(HBURST),
	  .HWRITE(HWRITE),
	  .HSIZE(HSIZE),
	  .HCLK(HCLK),
	  .HRESETn(HRESETn),	
     .HREADYOUT(HREADY3),
	  .HRESP(HRESP3),
	  .HRDATA(HRDATA3),
     .INTR(INTR),
	  .HREADYIN(HREADY),
	  .HSEL_S1(HSEL_S3),
	  .parityBits(parityBits)
	);
	ahbSlave s4(
	  .HADDR(HADDR),
	  .HWDATA(HWDATA),
	  .HTRANS(HTRANS),
	  .HBURST(HBURST),
	  .HWRITE(HWRITE),
	  .HSIZE(HSIZE),
	  .HCLK(HCLK), 
	  .HRESETn(HRESETn),	
     .HREADYOUT(HREADY4),
	  .HRESP(HRESP4),
	  .HRDATA(HRDATA4),	  
	  .INTR(INTR),
	  .HREADYIN(HREADY),
	  .HSEL_S1(HSEL_S4),
	  .parityBits(parityBits)
	);
	/****************************************************************
	                MULTIPLEXER
	****************************************************************/
	//outputs
	wire HRESP,HREADY;
	wire[31:0] HRDATA;
	
	mux m( .HRDATA1(HRDATA1),
			 .HRESP1(HRESP1),
			 .HREADY1(HREADY1),
			 
			 .HRDATA2(HRDATA2),
			 .HRESP2(HRESP2),
			 .HREADY2(HREADY2),
			 
			 .HRDATA3(HRDATA3),
			 .HRESP3(HRESP3),
			 .HREADY3(HREADY3),
			 
			 .HRDATA4(HRDATA4),
			 .HRESP4(HRESP4),
			 .HREADY4(HREADY4),
			 
			 .addr(addr),
			 .HRESP(HRESP),
			 .HRDATA(HRDATA),
			 .HREADY(HREADY)
	  
	);
	
	/*********************************************************************
	                            DECODER
	********************************************************************/
	//outputs
	wire HSEL_S1,HSEL_S2,HSEL_S3,HSEL_S4;
	wire[1:0] addr;
	
	decoder d(
	  .HCLK(HCLK),
	  .HADDR(HADDR),
	  .HSEL_S1(HSEL_S1),
	  .HSEL_S2(HSEL_S2),
	  .HSEL_S3(HSEL_S3),
	  .HSEL_S4(HSEL_S4),  
	  .addr(addr)
	
	);
	

	
	parameter
			SINGLE='b000,
			INCR='b001,
			WRAP4='b010,
			INCR4='b011,
			WRAP8='b100,
			INCR8='b101,
			WRAP16='b110,
			INCR16='b111;
			
	parameter
			IDLE='b00,
			BUSY='b01,
			NONSEQ='b10,
			SEQ='b11;
			
	initial begin 
		// Initialize Inputs
		{s4.memory[35],s4.memory[34],s4.memory[33],s4.memory[32]}= 'h6723_3422;
		{s4.memory[39],s4.memory[38],s4.memory[37],s4.memory[36]}= 'hffaa_3253;
		{s4.memory[43],s4.memory[42],s4.memory[41],s4.memory[40]}= 'hff11_3233;
		{s4.memory[47],s4.memory[46],s4.memory[45],s4.memory[44]}= 'haaef_3422;
		
		{s2.memory[71],s2.memory[70],s2.memory[69],s2.memory[68]}= 'h6723_3422;
		{s2.memory[75],s2.memory[74],s2.memory[73],s2.memory[72]}= 'hffaa_3253;
		
		{s2.memory['h23],s2.memory['h22],s2.memory['h21],s2.memory['h20]}= $random;
		{s2.memory['h27],s2.memory['h26],s2.memory['h25],s2.memory['h24]}= $random;
		{s2.memory['h2b],s2.memory['h2a],s2.memory['h29],s2.memory['h28]}= $random;
		{s2.memory['h2f],s2.memory['h2e],s2.memory['h2d],s2.memory['h2c]}= $random;
		{s2.memory['h33],s2.memory['h32],s2.memory['h31],s2.memory['h30]}= $random;
		
	
		
		HRESETn = 0;
		HCLK = 0;
		INTR=0;
		iHBURST = 0;
		iHTRANS = 0;
		iHSIZE = 0;
		iHPROT = 0;
		iHMASTLOCK = 0;
		iHADDR = 0;
		iHWRITE = 0;
		
		#2 HRESETn=1; iHTRANS=NONSEQ; iHBURST=INCR4; iHSIZE='b010; iHADDR='h7efa_1234; iHWRITE=1;
		#2 iHTRANS=SEQ; iHWDATA='h3424_2343;
		#2 iHTRANS=NONSEQ;
		
		//WRAP4 BURST Transfer
		#2 HRESETn=1; iHTRANS=NONSEQ; iHBURST=WRAP4; iHSIZE='b010; iHADDR='h7efa_1234; iHWRITE=1; 
		#2 iHTRANS=SEQ; iHWDATA='h7654_5576;
		#2 iHTRANS=SEQ; iHWDATA='h5345_1234;
		#2 iHTRANS=SEQ; iHWDATA='h2242_1733;
		#2 iHTRANS=SEQ; iHWDATA='h6672_7782; 
		
		//10ns time spent 
		//starting a new burst
		 iHTRANS=NONSEQ; iHADDR='h7efa_1230; iHBURST=INCR; iHSIZE='b010; iHWRITE=0;
      #2 iHTRANS=BUSY;
      #2 iHTRANS=SEQ;
      #2 iHTRANS=SEQ;
      #2 iHTRANS=SEQ;
      #1.1 INTR=1;
      #2 INTR=0;

      //21.1ns time spent
		//starting a new burst
		iHTRANS=NONSEQ;  iHWRITE=1; iHADDR='h0000_0038; iHBURST=WRAP4; iHSIZE='b010;
		#2 iHTRANS=SEQ; iHWDATA='h7697_27fe;
		#2 INTR=1;
		#2 INTR=0; iHTRANS=SEQ;  iHWDATA='h5768_1263; 
		#2 iHTRANS=SEQ; iHWDATA='h6682_7723;
		#2  iHWDATA='h9977_7723;
      		
		//31.1ns time spent
      //starting new burst
		iHTRANS=NONSEQ; iHADDR='h0001_0034; iHWRITE=1; iHSIZE='h001; iHBURST=INCR8;
		#2 iHTRANS=SEQ; iHWDATA='h8732;
		#2 iHTRANS=SEQ; iHWDATA='h6743;
		#2 iHTRANS=SEQ; iHWDATA='haf31;
		#2 iHTRANS=SEQ; iHWDATA='h9563;
		#2 iHTRANS=SEQ; iHWDATA='h27a3;
		#2 iHTRANS=SEQ; iHWDATA='ha233;
		#2 iHTRANS=SEQ; iHWDATA='h822a;
		#2 iHWDATA='h5578;
		
		//47.1ns time spent
		//starting new burst
		iHTRANS=NONSEQ; iHADDR='h0003_0020; iHSIZE='b010; iHWRITE=0; iHBURST=INCR4;
		#2 iHTRANS=SEQ; 
		#2 iHTRANS=BUSY;
		#2 iHTRANS=BUSY; INTR=1;
		#2 iHTRANS=SEQ;
		#2 iHTRANS=SEQ; INTR=0;
			
		
		//57.1ns time spent
		//starting new burst
		#4 iHTRANS= NONSEQ;	iHADDR='h0001_0034; iHWRITE=0; iHBURST=WRAP8; iHSIZE='b010;
      #2 iHTRANS=SEQ;	
      #2 iHTRANS=SEQ;
		#2 iHTRANS=SEQ;
		#2 iHTRANS=SEQ;
		#2 iHTRANS=SEQ;
		#2 iHTRANS=SEQ;
		#2 iHTRANS=SEQ;
		#2 iHTRANS=IDLE;
		
 
	end 
	
	always #1 HCLK=~HCLK;
      
endmodule

