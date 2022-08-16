/*===============================================================================================================================
   Module       : Test Environment for GCD IP (GCD Calculator with APB wrapper)

   Description  : This test Environment created for GCD IP:  
                  - Assumes GCD IP is slave to a APB bus master running firmware.                
                  - Emulates firmware sending inputs to IP and reading output using IP Driver APIs.                  
                  - Emulates GCD IP driver APIs using tasks.                          

   Developer    : Mitu Raj, chip@chipmunklogic.com at Chipmunk Logic ™, https://chipmunklogic.com
   Notes        : -
   License      : Open-source.
   Date         : July-20-2022
===============================================================================================================================*/
/*-------------------------------------------------------------------------------------------------------------------------------
                                             T E S T   E N V   -   G C D  IP 
-------------------------------------------------------------------------------------------------------------------------------*/
`timescale 1ns/100ps

module tb_apb_top_gcd () ;

// Local Parameters - GCD IP register addresses in system memory space
localparam GCD_IP_CTRL_REG = 32'h00 ;
localparam GCD_IP_STS_REG  = 32'h04 ;
localparam GCD_IP_DIN_REG  = 32'h08 ;
localparam GCD_IP_DOUT_REG = 32'h0C ;

// Internal Registers / Signals 
logic          clk, rst                      ;
logic [31 : 0] paddr, pwdata, prdata         ;
logic          psel, penable, pwrite, pready ;
logic          intr                          ;
logic [7  : 0] a, b, gcd                     ;

// DUT instance
apb_top_gcd apb_top_gcd_inst (   
   
   .clk       (clk)     ,
   .rstn 	  (rst)     ,
   .i_paddr   (paddr)   ,
   .i_pwrite  (pwrite)  ,
   .i_psel    (psel)    ,
   .i_penable (penable) ,
   .i_pwdata  (pwdata)  ,
   .o_prdata  (prdata)  ,        
   .o_pready  (pready)  ,       
   .o_intr    (intr)         

) ;

// This block emulates power-on reset and firmware execution
initial begin
   
   // System reset
   rst <= 1'b0 ;
   repeat (10) @(posedge clk);
   rst <= 1'b1 ;
   @(posedge clk);   
   
   // Emulates typical main() loop in firmware
   main: begin
      
      // Configuring GCD IP       
      gcdIP_cfg({1'b0, 1'b0, 1'b1});
      $display("Configured GCD IP ...@%0t", $time); 
      
      // Test 10 inputs      
      repeat (10) begin
         
         // Generate random inputs (a, b)           
         a = $urandom_range(0, 15);
         b = $urandom_range(0, 15);    
         
         // Write inputs (a, b) to GCD IP
         gcdIP_write(a, b);
         $display("Written inputs a = %0d, b = %0d to GCD IP @%0t", a, b, $time);  

         // Read output from GCD IP: gcd(a, b) to variable gcd
         gcdIP_read(gcd);
         $display("Read output gcd (%0d, %0d) = %0d from GCD IP @%0t", a, b, gcd, $time);

      end      

      $finish;

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
   $dumpvars(0, tb_apb_top_gcd);
end

/*===============================================================================================================================
   Following tasks emulate GCD IP driver APIs
===============================================================================================================================*/

// Task to configure GCD IP: 
task automatic gcdIP_cfg (bit [2 : 0] ctrl);
    write_data (GCD_IP_CTRL_REG, ctrl);    // Write to control register 
endtask

// Task to send input to GCD IP
task automatic gcdIP_write (bit [7 : 0] a, bit [7 : 0] b);
   
   // Local vars	
   bit [1 : 0] sts = 2'h0 ;
   
   // Write to data_in register only when IP is ready to accept data
   while (!sts [1]) read_data (GCD_IP_STS_REG, sts);     // Poll status register continuously   
   write_data (GCD_IP_DIN_REG, {a, b});                  // Write to data_in register

endtask

// Task to read status of GCD IP 
task automatic gcdIP_read_sts (output bit [1 : 0] sts); 
   read_data (GCD_IP_STS_REG, sts);    // Read status register 
endtask

// Task to read output of GCD IP 
task automatic gcdIP_read (output bit [7 : 0] dout);
   
   // Local vars	
   bit [1 : 0] sts = 2'h0 ;

   // Read data_out register only when valid data is available from IP   
   while (!sts [0]) read_data (GCD_IP_STS_REG, sts);     // Poll status register continuously
   read_data (GCD_IP_DOUT_REG, dout);                    // Read data_out register

endtask

/*===============================================================================================================================
   Following tasks emulate low-level system tasks which are typically at OS / baremetal hierarchy
===============================================================================================================================*/

// Task to write 32-bit data to a 32-bit address in the memory space
task write_data (int addr, int wdata);   
   
   // APB write transaction   
   paddr   <= addr  ;
   pwdata  <= wdata ;
   pwrite  <= 1'b1  ;
   psel    <= 1'b1  ;
   @(posedge clk);
   penable <= 1'b1  ;
   while (!pready) @(posedge clk);
   penable <= 1'b0  ;
   psel    <= 1'b0  ;
   pwrite  <= 1'b0  ;

endtask

// Task to read 32-bit data from a 32-bit address in the memory space
task read_data (int addr, output int rdata);
   
   // APB read transaction   
   paddr    <= addr   ;   
   pwrite   <= 1'b0   ;
   psel     <= 1'b1   ;
   @(posedge clk);
   penable  <= 1'b1   ;
   while (!pready) @(posedge clk);
   rdata     = prdata ;
   penable  <= 1'b0   ;
   psel     <= 1'b0   ;
   pwrite   <= 1'b0   ;

endtask 

endmodule

/*-------------------------------------------------------------------------------------------------------------------------------
                                             A P B   T B   -   G C D   C A L C U L A T O R  
-------------------------------------------------------------------------------------------------------------------------------*/