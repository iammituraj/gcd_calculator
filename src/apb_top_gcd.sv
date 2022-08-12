/*===============================================================================================================================
   Module       : APB Slave Wrapper on GCD Calculator

   Description  : APB Slave Interface provides a memory mapped interface for all peripheral registers of GCD calculator core.
                  - Default configuration of register space = 32-bit addressing space(DATA_W)
                  - Register space is byte-addressable.
                  - Register space supports 2^(ADDR_W-2) registers.
                  - Supports run-time configurable interrupt: level/edge-triggered.
                  
   Developer    : Mitu Raj, chip@chipmunklogic.com at Chipmunk Logic ™, https://chipmunklogic.com
   Notes        : -
   License      : Open-source.
   Date         : Aug-05-2022
===============================================================================================================================*/

/*-------------------------------------------------------------------------------------------------------------------------------
                                       A P B   W R A P P E R  -   G C D   C A L C U L A T O R  
-------------------------------------------------------------------------------------------------------------------------------*/

module apb_top_gcd #(

   // Global Parameters
   parameter ADDR_W = 8  ,        // Address width        
   parameter DATA_W = 32          // Data width

)

(   
   // Clock and Reset
   input  logic                clk       ,        // Clock
   input  logic                rstn      ,        // Active-low synchronous reset	

   // APB Slave Interface
   input  logic [ADDR_W-1 : 0] i_paddr   ,        // Address
   input  logic                i_pwrite  ,        // Write signal
   input  logic                i_psel    ,        // Select
   input  logic                i_penable ,
   input  logic [DATA_W-1 : 0] i_pwdata  ,        // Write-data
   output logic [DATA_W-1 : 0] o_prdata  ,        // Read-data
   output logic                o_pready  ,        // Ready

   // Interrupt Interface
   output logic                o_intr             // Interrupt

) ;

// Typedefs
typedef enum logic [1 : 0] {IDLE, W_ACCESS, R_ACCESS, FINISH} apb_state ;

// Internal Registers / Signals
apb_state            state_rg                            ;
logic                gcd_rst                             ;
logic                intr_en, intr_type                  ;
logic [7 : 0]        a, b, gcd                           ;
logic                data_in_valid, data_in_ready        ;
logic                data_out_valid, data_out_ready      ;
logic                data_in_valid_rg, data_out_ready_rg ;
logic                data_out_valid_rg                   ;
logic [DATA_W-1 : 0] prdata_rg                           ;
logic                pready_rg                           ;

/*------------------------------------------------------------------------------------
   Register Space (supports up to 64 registers by default configuration)
   -----------------------------------------------------------------------------------
   1) 0x00 : apb_reg [0] - control  (RW) = {Interrupt Type, Interrupt Enable, Enable}
   2) 0x04 : apb_reg [1] - status   (RO) = {data_in_ready, data_out_valid}
   3) 0x08 : apb_reg [2] - data_in  (RW) = {a , b}
   4) 0x0C : apb_reg [3] - data_out (RO) = {gcd(a, b)}
------------------------------------------------------------------------------------*/
logic [DATA_W-1 : 0] apb_reg [4] ; 

/* Peripheral instance (in bare RTL) to be memory-mapped */
gcd gcd_inst (
   
   .clk     (clk)            ,
   .rstn    (gcd_rst)        ,
   .i_a     (a)              ,
   .i_b     (b)              , 
   .i_valid (data_in_valid)  ,
   .o_ready (data_in_ready)  ,
   .o_gcd   (gcd)            ,
   .o_valid (data_out_valid) ,
   .i_ready (data_out_ready)

) ;

// APB Slave - Synchronous logic to read/write RW and RO registers
always @(posedge clk) begin
   
   // Reset  
   if (!rstn) begin
      
      state_rg <= IDLE ;

      // RW registers      
      apb_reg [0] <= '0 ;
      apb_reg [2] <= '0 ;
      
      // APB registers
      prdata_rg <= '0   ;
      pready_rg <= 1'b0 ;

   end
   
   // Out of reset
   else begin      
      
      // APB control FSM
      case (state_rg)
         
         // Idle State : waits for psel signal and decodes access type         
         IDLE : begin
            
            if      (i_psel && i_pwrite) state_rg <= W_ACCESS ;        // Write access required
            else if (i_psel)             state_rg <= R_ACCESS ;        // Read access required

         end
         
         // Write Access State : waits for penable signal and writes addressed-register
         W_ACCESS : begin
            
            if (i_penable) begin 
               
               // psel and pwrite expected to be stable for successful write               
               if (i_psel && i_pwrite) begin 

                  // Address decoding - two LSbs masked because 32-bit byte-addressable
                  case (i_paddr [ADDR_W-1 : 2])
                     0       : apb_reg [0] <= i_pwdata ;
                     2       : apb_reg [2] <= i_pwdata ;
                     default : ;                 
                  endcase                  
                        
               end    

               pready_rg <= 1'b1   ;        // Induces one wait state
               state_rg  <= FINISH ;           

            end

         end
         
         // Write Access State : waits for penable signal and reads addressed-register
         R_ACCESS : begin
            
            if (i_penable) begin 
               
               // psel and pwrite expected to be stable for successful read               
               if (i_psel && !i_pwrite) begin 

                  // Address decoding - two LSbs masked because 32-bit byte-addressable
                  case (i_paddr [ADDR_W-1 : 2])
                     0       : prdata_rg <= apb_reg [0] ;
                     1       : prdata_rg <= apb_reg [1] ;
                     2       : prdata_rg <= apb_reg [2] ;
                     3       : prdata_rg <= apb_reg [3] ;
                     default : ;                 
                  endcase                           
 
               end 

               pready_rg <= 1'b1   ;        // Induces one wait state
               state_rg  <= FINISH ;              

            end

         end
         
         // Finish state : All read/write access finishes here          
         FINISH : begin
            
            pready_rg <= 1'b0 ;
            state_rg  <= IDLE ;

         end

         default : ;         

      endcase 

   end

end

// APB Slave - Synchronous logic to update all RO registers
always @(posedge clk) begin
   
   // Reset  
   if (!rstn) begin
      
      apb_reg [1] <= '0 ;
      apb_reg [3] <= '0 ;

   end
   
   // Out of reset
   else begin

      apb_reg [1] <= {data_in_ready, data_out_valid} ;
      apb_reg [3] <= gcd ;

   end

end

// Synchronous logic to generate pulses at data_in_valid, data_out_ready
always @(posedge clk) begin
   
   // Reset  
   if (!rstn) begin      
      data_in_valid_rg  <= 1'b0 ;
      data_out_ready_rg <= 1'b0 ;
   end
   
   // Out of reset
   else begin 
      
      // Valid logic      
      if (state_rg == W_ACCESS) begin
         
         if (i_penable) begin 
               
            // Successful write              
            if (i_psel && i_pwrite) begin 

               // Writing data_in register should assert valid
               case (i_paddr [ADDR_W-1 : 2])                     
                  2       : data_in_valid_rg <= 1'b1 ;                     
                  default : data_in_valid_rg <= 1'b0 ;                 
               endcase                           
 
            end 
            
         end

      end

      else begin
         data_in_valid_rg <= 1'b0 ;         
      end
      
      // Ready logic
      if (state_rg == R_ACCESS) begin
         
         if (i_penable) begin 
               
            // Successful read            
            if (i_psel && !i_pwrite) begin 

               // Reading data_out register should assert ready
               case (i_paddr [ADDR_W-1 : 2])                     
                  3       : data_out_ready_rg <= 1'b1 ;                     
                  default : data_out_ready_rg <= 1'b0 ;                
               endcase                           
 
            end 
            
         end

      end

      else begin
         data_out_ready_rg <= 1'b0 ;         
      end

   end

end

// Synchronous logic to register data_out_valid
always @(posedge clk) begin
   
   // Reset  
   if (!rstn) begin      
      data_out_valid_rg <= 1'b0 ;
   end   
   // Out of reset
   else begin      
      data_out_valid_rg <= data_out_valid ;
   end

end

// Mapping between register space and Peripheral input ports
assign gcd_rst    = rstn & apb_reg [0] [0] ;
assign intr_en    = apb_reg [0] [1]        ;
assign intr_type  = apb_reg [0] [2]        ;
assign a          = apb_reg [2] [15 : 8]   ;
assign b          = apb_reg [2] [7  : 0]   ;

// Valid and Ready with Peripheral
assign data_in_valid  = data_in_valid_rg  ;
assign data_out_ready = data_out_ready_rg ;

// APB output signals
assign o_prdata = prdata_rg ;
assign o_pready = pready_rg ;

// Interrupt
assign intr_lvl  = data_out_valid ;                                               // Level-triggered interrupt
assign intr_edge = data_out_valid & ~data_out_valid_rg ;                          // Edge-triggered interrupt
assign o_intr    = (intr_en)? ((intr_type)? intr_edge : intr_lvl) : 1'b0 ;        // Interrupt driven out

endmodule 

/*-------------------------------------------------------------------------------------------------------------------------------
                                       A P B   W R A P P E R  -   G C D   C A L C U L A T O R  
-------------------------------------------------------------------------------------------------------------------------------*/