/*===============================================================================================================================
   Module       : Testbench for GCD Calculator

   Description  : Testbench for GCD Calculator.            

   Developer    : Mitu Raj, chip@chipmunklogic.com at Chipmunk Logic ™, https://chipmunklogic.com
   Notes        : -
   License      : Open-source.
   Date         : July-20-2022
===============================================================================================================================*/

/*-------------------------------------------------------------------------------------------------------------------------------
                                                   T B - G C D   C A L C U L A T O R  
-------------------------------------------------------------------------------------------------------------------------------*/
`timescale 1ns/100ps

module tb_gcd () ;

// Internal Registers / Signals
logic         clk, rst             ;
logic [7 : 0] a, b, gcd            ;
logic         dut_valid, dut_ready ;
logic         tb_valid, tb_ready   ;
logic         finish               ;

// DUT instance
gcd gcd_inst (
   
   .clk     (clk)       ,
   .rstn    (rst)       ,
   .i_a     (a)         ,
   .i_b     (b)         , 
   .i_valid (tb_valid)  ,
   .o_ready (dut_ready) ,
   .o_gcd   (gcd)       ,
   .o_valid (dut_valid) ,
   .i_ready (tb_ready)

) ;

// Test stimulus generation
initial begin
   
   // Reset	and initialisation
   rst <= 1'b0 ;
   repeat (10) @(posedge clk);
   rst <= 1'b1 ;
   @(posedge clk);
   tb_ready <= 1'b1 ;

   // Fire stimulus: 25 test vectors
   for (int i = 0 ; i < 25 ; i = i + 1) begin 

      a <= $urandom_range(0, 15);
      b <= $urandom_range(0, 15);     

      // Valid-Ready handshake between TB and DUT
      tb_valid <= 1'b1 ;
      @(posedge clk);
      while(!dut_ready) @(posedge clk);

      $display("Test vector %0d :", i+1);
      $display("a = %0d", a);
      $display("b = %0d", b);

   end
   
   // End of simulation
   tb_valid <= 1'b0 ;
   finish   <= 1'b1 ;

end

// Always block to sample output from DUT
always @(posedge clk) begin
   
   if (tb_ready && dut_valid) begin
      $display("GCD = %0d \n", gcd); 
      if (finish) $finish();  	
   end

end

// Clocking - 100 MHz
initial begin   
   clk = 1'b0 ;
   forever #5 clk = ~clk ;	
end

// Dump
initial begin
   $dumpfile("sim.vcd");
   $dumpvars(0, tb_gcd);
end

endmodule
/*-------------------------------------------------------------------------------------------------------------------------------
                                                   T B - G C D   C A L C U L A T O R  
-------------------------------------------------------------------------------------------------------------------------------*/