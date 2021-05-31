`timescale 1ns / 1ps

module ahbSlave #(parameter ADDR_WIDTH=32, DATA_WIDTH=32)(
         /*******************************************
                     AHB Slave Interface
            ********************************************/
            input[ADDR_WIDTH-1:0] HADDR, // memory address where data is to be written
            input[DATA_WIDTH-1:0] HWDATA, // the data to be written in the memory
            input[1:0] HTRANS, // tells the transfer mode
            input[2:0] HBURST, //tells the burst mode 
            input HWRITE, //tells read or write
            input[2:0] HSIZE, //tells the size of data of each beat
            input[15:0] parityBits,//input from master for error detection
            
            input HSEL_S1, //select signal from decoder
            
            input HCLK,    // global signals
            input HRESETn, // global signals
            
            input HREADYIN, // input signal from mux
             
            input INTR, //interrupt signal
            
         output reg[DATA_WIDTH-1:0] HRDATA,         
            output reg HREADYOUT, // acknowledgement signals to the master
            output reg HRESP
            
    );
     
     //slave's memory
     reg[7:0] memory[2**16-1:0];   
     
     reg[1:0] trans; // contains the sampled value of HTRANS
     reg ready;
     reg error; //new addition
     reg[15:0] e;
     reg[ADDR_WIDTH-1:0] address; //contains the sampled value of HADDR
     reg[2:0] size; //contains the sampled value of HSIZE
     reg rd,wr; //active low signals which control reading/writing into the memory
     
     always@(posedge HCLK) begin
         trans<=HTRANS;
         
         
         if(HREADYIN) begin
            address<=HADDR; 
            size<=HSIZE;
       end       
         
         ready<=HREADYIN;        
         if(!wr) begin
           if(size=='b000)  
           memory[address[15:0]]<=HWDATA[7:0];
            
            if(size=='b001)
            {memory[address[15:0]+1],memory[address[15:0]]} <=HWDATA[15:0];
            
            if(size=='b010)
            {memory[address[15:0]+3],memory[address[15:0]+2],memory[address[15:0]+1],memory[address[15:0]]}<=HWDATA[31:0];
            
         end
         
     end
     
     
     always@(negedge HCLK) begin
        if(!rd) begin
           if(size=='b000) 
           HRDATA<=memory[address[15:0]];
            
            if(size=='b001)
            HRDATA<={memory[address[15:0]+1],memory[address[15:0]]};
            
            if(size=='b010)
            HRDATA<={memory[address[15:0]+3],memory[address[15:0]+2],memory[address[15:0]+1],memory[address[15:0]]};
            
           
       end       
     end 
     
     //fsm states
     parameter
     s_idle=3'b001,   //idle state --> here slave performs idle transfer
     writeInMem=3'b010, //writeInMem --> here slave writes data into its memory
     readFromMem=3'b100, //readFromMem --> here slave fetches the data from the memory and drives it onto HRDATA bus
     s_error=3'b101;
     parameter okay='b0;
     
     //transfer types --> IDLE, BUSY, SEQ, NONSEQ
     parameter
            IDLE='b00,
            BUSY='b01,
            NONSEQ='b10,
            SEQ='b11;
     
     reg[2:0] c_state,n_state; //currentState and nextState
     
     
     always@(posedge HCLK) begin
        if(!HRESETn)
          c_state<=s_idle;
        else
          c_state<=n_state;
     end
     
     
     
     always@(*) begin
       HRESP=okay; HREADYOUT=1; wr=1; rd=1; n_state=s_idle;
                case(c_state) 
                  s_idle: begin 
                             if(!HREADYIN) 
                                n_state=s_idle;
                                    
                                   else begin
                                     if(!HSEL_S1) 
                                        n_state=s_idle;
                                     else begin
                                       if(HTRANS==IDLE)
                                          n_state=s_idle;
                                       else
                                          n_state=nextState(HWRITE);
                                     end
                                   end
                           end
                  writeInMem: begin 
                               if(INTR) begin
                                  if(!(trans==BUSY&&ready==1))                                  
                                     HREADYOUT=0;  
                                  n_state=writeInMem;
                                                
                                  end
                                         
                                  else begin
                                    if(trans==SEQ || trans==NONSEQ) begin
                                                  
                                       HRESP=error;                                                    
                                       if(error) begin
                                          HREADYOUT=0;
                                          n_state=s_error;
                                       end
                                       else begin
                                         wr=0; 
                                         n_state=state(HSEL_S1,HWRITE,HTRANS);         
                                       end
                                    end
                                                
                                    else begin
                                      if(!ready) 
                                         HREADYOUT=0;   
                                      n_state=state(HSEL_S1,HWRITE,HTRANS);                                               
                                                     
                                    end                                            
                                           
                                  end                               
                                         
                              end
                                  
                  readFromMem: begin                
                                 if(INTR) begin
                                    if(!(trans==BUSY&&ready==1))                                      
                                       HREADYOUT=0;  
                                    n_state=readFromMem;                                                    
                                 end
                                             
                                 else begin
                                   if(trans==SEQ || trans==NONSEQ) 
                                      rd=0;                   
                                                    
                                   else begin
                                     if(!ready) 
                                        HREADYOUT=0;                                               
                                   end    
                                   
                                   n_state=state(HSEL_S1,HWRITE,HTRANS);
                                 end                                      
                                        
                               end
                               
                    s_error: begin
                               HRESP=1;
                               HREADYOUT=1;
                               n_state=s_idle;
                             end
                
                
                endcase
     
     end
   
    function[2:0] nextState;
      input HWRITE;
      
        begin
          if(HWRITE)
             nextState=writeInMem;
          else
            nextState=readFromMem;
        end
         
    endfunction
    
    
        function[2:0] state;
         input HSEL_S1;
         input HWRITE;
         input[1:0] HTRANS;
            begin
                           
              case(HTRANS)
                   IDLE: begin 
                           state=s_idle;
                         end
                   NONSEQ: begin
                             if(~HSEL_S1)
                                state=s_idle;
                             else 
                               state=nextState(HWRITE);
                             end
                     SEQ: begin
                            state=nextState(HWRITE);
                          end
                     BUSY: begin 
                                state=nextState(HWRITE);
                           end
                     default: begin 
					            state=s_idle; 
                              end
                     
                     
              endcase 
                  
            end
        endfunction
    //slave can have an error flag as--->
    always@(*) begin
        
        e[15]=parityBits[15]^HWDATA[31]^HWDATA[30];
        e[14]=parityBits[14]^HWDATA[29]^HWDATA[28];
        e[13]=parityBits[13]^HWDATA[27]^HWDATA[26];
        e[12]=parityBits[12]^HWDATA[25]^HWDATA[24];
        e[11]=parityBits[11]^HWDATA[23]^HWDATA[22];
        e[10]=parityBits[10]^HWDATA[21]^HWDATA[20];
        e[9]=parityBits[9]^HWDATA[19]^HWDATA[18];
        e[8]=parityBits[8]^HWDATA[17]^HWDATA[16];
        e[7]=parityBits[7]^HWDATA[15]^HWDATA[14];
        e[6]=parityBits[6]^HWDATA[13]^HWDATA[12];
        e[5]=parityBits[5]^HWDATA[11]^HWDATA[10];
        e[4]=parityBits[4]^HWDATA[9]^HWDATA[8];
        e[3]=parityBits[3]^HWDATA[7]^HWDATA[6];
        e[2]=parityBits[2]^HWDATA[5]^HWDATA[4];
        e[1]=parityBits[1]^HWDATA[3]^HWDATA[2];
        e[0]=parityBits[0]^HWDATA[1]^HWDATA[0];

    end

    always@(*) begin

      case(size)
        'b000:  begin
                     if(e[3:0]==0)
                      error=0;
                     else
                      error=1;
                  end
        'b001:  begin
                     if(e[7:0]==0)
                      error=0;
                     else
                      error=1;
                  end
        'b010: begin
                     if(e[15:0]==0)
                      error=0;
                     else
                      error=1;
                  end
      endcase

    end

endmodule
