/*===============================================================================================================================
   Module       : GCD Calculator

   Description  : Computes the GCD of two 8-bit numbers a and b. Supports simple valid-ready handshaking.             

   Developer    : Mitu Raj, chip@chipmunklogic.com at Chipmunk Logic ™, https://chipmunklogic.com
   Notes        : -
   License      : Open-source.
   Date         : July-20-2022
===============================================================================================================================*/

/*-------------------------------------------------------------------------------------------------------------------------------
                                                   G C D   C A L C U L A T O R  
-------------------------------------------------------------------------------------------------------------------------------*/

module gcd (
   
   // Clock and Reset   
   input  logic         clk     ,        // Clock
   input  logic         rstn    ,        // Active-low synchronous reset
   
   // Input Interface
   input  logic [7 : 0] i_a     ,       // a
   input  logic [7 : 0] i_b     ,       // b
   input  logic         i_valid ,       // Inputs valid
   output logic         o_ready ,       // Ready to accept inputs
   
   // Output Interface
   output logic [7 : 0] o_gcd   ,       // gcd(a, b)
   output logic         o_valid ,       // Output valid
   input  logic         i_ready         // Ready to read output

) ;

// Typedefs
typedef enum logic [1 : 0] {IDLE, ITERATE, READ} state ; 

// Internal Registers / Signals
state         state_rg           ;
logic [7 : 0] a_rg, b_rg, gcd_rg ;
logic         ready_rg           ; 
logic         valid_rg           ;

// Synchronous logic to calculate gcd(a, b)
always @(posedge clk) begin
   
   // Reset  
   if (!rstn) begin
      
      state_rg <= IDLE ;      
      a_rg     <= '0   ;   
      b_rg     <= '0   ; 
      gcd_rg   <= '0   ;
      ready_rg <= 1'b0 ;  
      valid_rg <= 1'b0 ;

   end
   
   // Out of reset
   else begin
      
      case (state_rg)
         
         // Idle state         
         IDLE : begin            
            ready_rg <= 1'b1 ;        // Ready to accept inputs
            
            // Buffer valid inputs
            if (i_valid && ready_rg) begin
               a_rg     <= i_a     ;
               b_rg     <= i_b     ;
               ready_rg <= 1'b0    ;        // Busy from now on
               state_rg <= ITERATE ;
            end
         end
         
         // Iterate the algorithm
         ITERATE : begin            
            if (b_rg == 0) begin
               gcd_rg   <= a_rg ;        // Iteration ends
               valid_rg <= 1'b1 ;        
               state_rg <= READ ;
            end

            else if (a_rg == 0) begin
               gcd_rg   <= b_rg ;        // Iteration ends
               valid_rg <= 1'b1 ;        
               state_rg <= READ ;               
            end

            else if (a_rg > b_rg) begin
               a_rg <= a_rg - b_rg ;
            end

            else begin
               b_rg <= b_rg - a_rg ;
            end
         end   
         
         // Read result
         READ : begin            
            // Read acknowledgement            
            if (i_ready) begin
               valid_rg <= 1'b0 ;
               ready_rg <= 1'b1 ;        
               state_rg <= IDLE ;               
            end
         end      

      endcase 

   end

end

// Continuous Assignments
assign o_gcd   = gcd_rg   ;
assign o_valid = valid_rg ;
assign o_ready = ready_rg ;

endmodule

/*-------------------------------------------------------------------------------------------------------------------------------
                                                   G C D   C A L C U L A T O R  
-------------------------------------------------------------------------------------------------------------------------------*/