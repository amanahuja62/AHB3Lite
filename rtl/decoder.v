`timescale 1ns / 1ps

module decoder(input[31:0] HADDR,
				      input HCLK,
					    output HSEL_S1,
					    output HSEL_S2,
					    output HSEL_S3,
					    output HSEL_S4,
					    output reg[1:0] addr//guides mux for selecting right slave
					
              );
				  
				  
		always@(posedge HCLK) begin
		  addr<=HADDR[17:16];
      end		
		
		assign HSEL_S1=HADDR[17:16]=='b00;
		assign HSEL_S2=HADDR[17:16]=='b01;
		assign HSEL_S3=HADDR[17:16]=='b10;
		assign HSEL_S4=HADDR[17:16]=='b11;


endmodule
