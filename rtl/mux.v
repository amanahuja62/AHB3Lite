`timescale 1ns / 1ps
module mux #(parameter dataWidth=32)(input[dataWidth-1:0] HRDATA1,
				 input[dataWidth-1:0] HRDATA2,
				 input[dataWidth-1:0] HRDATA3,
				 input[dataWidth-1:0] HRDATA4,
				 input HRESP1,
				 input HRESP2,
				 input HRESP3,
				 input HRESP4,
				 input HREADY1,
				 input HREADY2,
				 input HREADY3,
				 input HREADY4,
				 input[1:0] addr,
				 output reg[dataWidth-1:0] HRDATA,
				 output reg HREADY,
				 output reg HRESP

           );
			  
			  always@(*) begin
				  HRDATA=HRDATA1;
				  HRESP=HRESP1;
				  HREADY=HREADY1;
					 case(addr)
					 'b00: begin
					          HRDATA=HRDATA1;
								 HRESP=HRESP1;
								 HREADY=HREADY1;
					       end
					 'b01: begin
					          HRDATA=HRDATA2;
								 HRESP=HRESP2;
								 HREADY=HREADY2;
					       end
					 'b10: begin
					          HRDATA=HRDATA3;
								 HRESP=HRESP3;
								 HREADY=HREADY3;
					       end
					 'b11: begin
					          HRDATA=HRDATA4;
								 HRESP=HRESP4;
								 HREADY=HREADY4;
					       end
					 endcase
			  end


endmodule
