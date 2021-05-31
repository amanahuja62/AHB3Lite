`timescale 1ns / 1ps

module ahb_master(

            /********************************
                        AHB Interface
            ********************************/
            //input signals
            input HREADY,
            input HRESP,
            input HRESETn,
            input HCLK,
            input[DATA_WIDTH-1:0] HRDATA,
            //output signals
            //output latchEnable, // new addition
            output reg[ADDR_WIDTH-1:0] HADDR,
            output reg HWRITE,
            output reg[2:0] HSIZE,
            output reg[2:0] HBURST, 
            output reg[3:0] HPROT,
            output reg[1:0] HTRANS,
            output reg HMASTLOCK,
            output reg[DATA_WIDTH-1:0] HWDATA,
            output[15:0] parityBits,//new addition
            
            /******************************
                    User Interface
            *******************************/
            //input signals
            input[2:0] iHBURST,
            input[1:0] iHTRANS,
            input[2:0] iHSIZE,
            input[3:0] iHPROT,
            input iHMASTLOCK,
            input[ADDR_WIDTH-1:0] iHADDR,
            input[DATA_WIDTH-1:0] iHWDATA,
            input iHWRITE,                  
            
            //output signals
            output reg[DATA_WIDTH-1:0] dataFetched);
            
            parameter
            s_idle=3'd0,
            s_fbtw=3'd1,//finite burst transfer write
            s_ubtw=3'd2,//undefined burst write transfer
            s_fbtr=3'd3,//finite burst transfer read
            s_ubtr=3'd4;//undefined burst read transfer
           
            parameter
            defaultBurst='b000,
            defaultAddress='h0000_0000,
            defaultTrans='b00,
            defaultSize='b010,
            defaultHprot='h1,
            defaultHMASTLOCK='b0,
            defaultHWDATA='hFFFF_FFFF,
            defaultHWRITE='b1;
            
            parameter ADDR_WIDTH=32;
            parameter DATA_WIDTH=32;
        
            
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
            
            
        reg[3:0] beatCounter, countLimit; //keeps track of the number of beats in a burst
          reg[7:0] driveEnable;
          reg[1:0] htrans;
          reg[2:0] hisReg; //samples HREADY and HTRANS on the next rising edge
          // hisReg[2:1] --> tells HTRANS 
          //hisReg[0]  --> tells HREADY
          
          reg resetBC, incBC, sampleData, error,set3,set7,set15, pre_write; 
          
          //beatCounter
          always@(posedge HCLK) begin
            if(!resetBC)
                beatCounter<=0;
            else if(incBC)
                beatCounter<=beatCounter+1;
          end
          
          //sampling HREADY and HTRANS on the next rising edge
          always@(posedge HCLK)
          hisReg <= {HTRANS,HREADY};
          
          //assign latchEnable = ~( (hisReg[2:1]==BUSY)&(hisReg[0]=='b0) );
          
          
         
       //Data Fetched from slave is driven onto the dataFetched bus if sampleData=1
         always@(posedge HCLK)
          if(sampleData)
          dataFetched<=HRDATA;
          
          //deciding countLimit
          always@(posedge HCLK) begin
            if(set3)
             countLimit<=3;
            if(set7)
             countLimit<=7;
            if(set15)
             countLimit<=15;
          end
          
        
           
            
            //DriveEnable decides which control signals can be driven
            always@(posedge HCLK) begin
                        if(!HRESETn||error) begin                        
                            HBURST<=defaultBurst;
                            HADDR<=defaultAddress;
                            HTRANS<=defaultTrans;
                            HSIZE<=defaultSize;
                            HPROT<=defaultHprot;
                            HMASTLOCK<=defaultHMASTLOCK;
                            HWDATA<=defaultHWDATA;
                            HWRITE<=defaultHWRITE;
                             
                        end
                        
                        
                        
                        else begin
                                
                                case(driveEnable)
                                     
                                    'h84: begin
                                           HTRANS<=iHTRANS;
                                           HADDR<=nextAddress(HSIZE, HBURST, HADDR, HTRANS);
                                          end
                                    'hFE: begin
                                            if(iHTRANS==NONSEQ || iHTRANS==IDLE) begin
                                               HADDR<=iHADDR;
                                               HWRITE<=iHWRITE;
                                               HSIZE<=iHSIZE;
                                               HBURST<=iHBURST;
                                               HPROT<=iHPROT;
                                               HTRANS<=iHTRANS;
                                               HMASTLOCK<=iHMASTLOCK;
                                            end
                                                
                                            else begin 
                                              HTRANS<=iHTRANS;
                                              HADDR<=nextAddress(HSIZE, HBURST, HADDR, HTRANS);
                                            end
                                                                                                
                                          end
                                     'hFF: begin
                                              if(iHTRANS==NONSEQ || iHTRANS==IDLE) begin
                                                 HADDR<=iHADDR;
                                                 HWRITE<=iHWRITE;
                                                 HSIZE<=iHSIZE;
                                                 HBURST<=iHBURST;
                                                 HPROT<=iHPROT;
                                                 HTRANS<=iHTRANS;
                                                 HMASTLOCK<=iHMASTLOCK;
                                                 HWDATA<=iHWDATA;
                                               end
                                                    
                                             else begin                                      
                                               HTRANS<=iHTRANS;
                                               HADDR<=nextAddress(HSIZE, HBURST, HADDR, HTRANS);
                                               HWDATA<=iHWDATA;
                                             end
                                          end
                                      
                                      'h85: begin
                                                 HTRANS<=iHTRANS;
                                                 HADDR<=nextAddress(HSIZE, HBURST, HADDR, HTRANS);
                                                 HWDATA<=iHWDATA;                                        
                                            end
                                     
                                endcase
                            
                        end
        
                    
            end
            
            
            
            
          /// registers which store the current and next state
          reg[2:0] c_state, n_state;
         
          
         
        
          
          //fsm
          always@(posedge HCLK) begin
            if(~HRESETn)
            c_state<=s_idle;
            else
            c_state<=n_state;
          end
          
          always@(posedge HCLK) begin
            pre_write<=HWRITE;
          end
          
          
          always@(*) begin
          
              driveEnable='h00; n_state=s_idle; incBC=0; error=0; resetBC=1;
              set3=0; set7=0; set15=0;        
              if(pre_write=='b1)
              sampleData=0;
              else
              sampleData=1;
          
                case(c_state)   
                        s_idle:begin
                                     if(HREADY) begin
                                         driveEnable='hFF;
                                         nextStateDecider(iHTRANS,iHBURST,iHWRITE,n_state,resetBC,set3,set7,set15);
                                     end
                                     else begin
                                         n_state=s_idle;
                                         driveEnable='h00;
                                     end
                                     
                                 end
                        s_fbtr: begin
                                     if(HREADY) begin
                                            if(beatCounter==countLimit-1) begin
                                               sampleData=1;
                                               driveEnable='hfe;
                                               nextStateDecider(iHTRANS,iHBURST,iHWRITE,n_state,resetBC,set3,set7,set15);
                                                    
                                            end
                                            
                                            
                                            else begin
                                                driveEnable='h84;
                                                sampleData=1;
                                               if(hisReg[2:1]==SEQ || hisReg[2:1]==NONSEQ) 
                                                  incBC=1;                                                            
                                               n_state=s_fbtr;                                       
                                                
                                            end 
                                     
                                     end
                                     
                                     else begin
                                            if(!HRESP) begin
                                                if(HTRANS!=BUSY) begin
                                                    driveEnable='h00;
                                                    n_state=s_fbtr;
                                                end
                                                 
                                                 else begin
                                                    driveEnable='h84;
                                                    n_state=s_fbtr;
                                                 end
                                                    
                                            end
                                            
                                            else begin
                                                    error=1;
                                                    n_state=s_idle;
                                            end
                                            
                                     end
                                  end
                                  
                                  
                        s_ubtw: begin
                                     if(HREADY) begin
                                        if(iHTRANS==IDLE || iHTRANS==NONSEQ)
                                            driveEnable='hff;
                                            
                                        else
                                            driveEnable='h85;
                                    
                                            nextStateDecider(iHTRANS,iHBURST,iHWRITE,n_state,resetBC,set3,set7,set15);
                                     end
                                     
                                     else begin
                                        if(HRESP) begin
                                            error=1;
                                            n_state=s_idle;
                                        end
                                        
                                        else begin
                                            if(HTRANS==BUSY)
                                                begin
                                                    driveEnable='hfe;
                                                    nextStateDecider(iHTRANS,iHBURST,iHWRITE,n_state,resetBC,set3,set7,set15);
                                                end
                                            else begin
                                                    driveEnable='h00;
                                                    n_state=s_ubtw;
                                            end
                                       end
                                     end
                                  end
                                  
                                  
                        s_fbtw: if(HREADY) begin
                                        if(beatCounter==countLimit-1)begin
                                          driveEnable='hff;
                                          $display("At t=%d, I was here",$time);
                                          nextStateDecider(iHTRANS,iHBURST,iHWRITE,n_state,resetBC,set3,set7,set15);
                                          
                                        end
                                        
                                        else begin
                                            driveEnable='h85;
                                            if(hisReg[2:1]==SEQ || hisReg[2:1]==NONSEQ) 
                                                incBC=1;
                                                
                                            n_state=s_fbtw;                                 
                                                                                
                                        
                                        end
                        
                        
                                  end
                                  
                                  else begin
                                        if(HRESP=='b0) begin
                                           if(HTRANS!=BUSY) begin
                                                driveEnable='h00;
                                                n_state=s_fbtw;
                                            end
                                            
                                            else begin
                                                driveEnable='h84;
                                                n_state=s_fbtw;
                                            end
                                            
                                        end
                                        
                                        else begin
                                            error=1;
                                            n_state=s_idle;
                                        end
                                  end
                        
                        
                        
                        s_ubtr: begin
                                        if(HREADY) begin
                                            driveEnable='hfe;
                                            sampleData=1;
                                            nextStateDecider(iHTRANS,iHBURST,iHWRITE,n_state,resetBC,set3,set7,set15);
                                        end
                                        
                                        else begin
                                            if(HRESP) begin
                                                error=1;
                                                n_state=s_idle;
                                            end
                                            
                                            else begin
                                                if(HTRANS==BUSY) begin
                                                    driveEnable='hfe;
                                                    nextStateDecider(iHTRANS,iHBURST,iHWRITE,n_state,resetBC,set3,set7,set15);
                                                end
                                                
                                                else begin
                                                    driveEnable='h00;
                                                    n_state=s_ubtr;
                                                end
                                                
                                            end
                                        end
                                  end
                
                        
                        default: begin 
                                        error=1;
                                        n_state=s_idle;
                                    end
                 endcase
              end
              
              
             
        /////////task which determines the next state//////////////////
            task nextStateDecider;
                  input[1:0] htrans;
                  input[2:0] hburst;
                  input hwrite;
                  output [2:0] n_state; 
                  output  resetBC;
                  output set3;
                  output set7;
                  output set15;
                     begin
                             n_state=s_idle;
                             resetBC=1;
                             set3=0;set7=0;set15=0;
                             if(htrans==NONSEQ) begin       
                                    
                                    if(hburst==INCR) 
                                        if(hwrite=='b1)
                                        n_state=s_ubtw;
                                        else
                                        n_state=s_ubtr;                     
                                            
                                     else begin 
                                        resetBC=0;
                                        case(hburst)
                                            INCR4: set3=1;
                                            INCR8: set7=1;
                                            INCR16: set15=1;
                                            WRAP4: set3=1;
                                            WRAP8: set7=1;
                                            WRAP16: set15=1;
                                            default: set3=1;
                                        endcase
                                        if(hwrite=='b1)
                                          n_state=s_fbtw;
                                        else
                                          n_state=s_fbtr;
                                        
                                     end
                         
                              end
                     
                             if(htrans==SEQ || htrans == BUSY)
                             n_state=c_state;
                             
                             if(htrans==IDLE)
                             n_state=s_idle;         
                      
                     end
            endtask
              
            // function to identify address for next beat in a burst
            function[ADDR_WIDTH-1:0] nextAddress;
                  input[2:0] hsize;
                  input[2:0] hburst; 
                  input[ADDR_WIDTH:0] addr;
                  input[1:0] htrans;
                  reg[12:0] burstBytes;//local variables
                  reg[ADDR_WIDTH:0] wrapBoundary;
                  reg[ADDR_WIDTH:0] wrapStart;
                            
                        begin
                            nextAddress=addr;
                            if(htrans!=BUSY) begin
                                    if(hburst==INCR || hburst==INCR4 || hburst==INCR8 || hburst==INCR16)
                                        nextAddress=addr+2**hsize;                                   
                                         
                                         
                                     else begin
                                            case(hburst)
                                                    WRAP4:burstBytes=4*(2**hsize);
                                                    WRAP8:burstBytes=8*(2**hsize);
                                                    WRAP16:burstBytes=16*(2**hsize);
                                                    default: burstBytes=4;                                  
                                            endcase
                                            
                                            wrapStart=addr-addr%burstBytes;
                                            wrapBoundary=wrapStart+burstBytes;
                                            
                                            if((addr+2**hsize)>=wrapBoundary)
                                                nextAddress=wrapStart;
                                            else 
                                                nextAddress=addr+2**hsize;
                                                
                                     end
                             end
                            
                        end
            endfunction
            
            
            
            assign parityBits[15]=(HWDATA[31]^HWDATA[30]);
            assign parityBits[14]=HWDATA[29]^HWDATA[28];
            assign parityBits[13]=HWDATA[27]^HWDATA[26];
            assign parityBits[12]=HWDATA[25]^HWDATA[24];
            assign parityBits[11]=HWDATA[23]^HWDATA[22];
            assign parityBits[10]=HWDATA[21]^HWDATA[20];
            assign parityBits[9]=HWDATA[19]^HWDATA[18];
            assign parityBits[8]=HWDATA[17]^HWDATA[16];
            assign parityBits[7]=HWDATA[15]^HWDATA[14];
            assign parityBits[6]=HWDATA[13]^HWDATA[12];
            assign parityBits[5]=HWDATA[11]^HWDATA[10];
            assign parityBits[4]=HWDATA[9]^HWDATA[8];
            assign parityBits[3]=HWDATA[7]^HWDATA[6];
            assign parityBits[2]=HWDATA[5]^HWDATA[4];
            assign parityBits[1]=HWDATA[3]^HWDATA[2];
            assign parityBits[0]=HWDATA[1]^HWDATA[0];

              

endmodule
