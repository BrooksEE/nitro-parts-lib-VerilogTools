/*
 * This file can be included inside any verilog module wanting to simulate
 * a PLL.
 */

module PLL_sim
 (input      input_clk,
  output     output_clk,
  input int  pll_mult,
  input int  pll_div,
  input int debug);


`ifdef verilator

   reg x;
   always @(posedge input_clk) begin
      x=$c("m_PLL->posedge(", debug, ")");
   end
   assign output_clk = $c("m_PLL->clkFX (", input_clk, ",", pll_mult, ",", pll_div, ",", debug, ")" );

`systemc_header
#ifndef __PLL_H__
#define __PLL_H__
extern unsigned int main_time;

class t_PLL
  {

 private:
   int m_posedge2;
   int m_posedge1;        
   int m_locked;
   int m_T;
 public:
  // CONSTRUCTORS
   t_PLL()
   {
    m_posedge2 = m_posedge1 = m_locked = 0;            
    m_T = 10;
    }
  
  ~t_PLL() {
  }
  
  inline bool posedge(int32_t debug) {
    if(!m_locked < 10) {
      m_locked++;
    

      m_posedge1 = m_posedge2;
      m_posedge2 = main_time;
      m_T = m_posedge2 - m_posedge1;
      if(m_T == 0) m_T = 10;
    }
    return true;
  }

  inline bool clkFX(bool x, int32_t m, int32_t d, int32_t debug) {
    if ( !m || !d || !m_locked) { return false; }
    bool clko;
    int dT = (m_T*d) / 2 / m;
    clko = (main_time / dT) % 2; 
    return clko;
  }

};
#endif

`systemc_interface
   t_PLL* m_PLL;        // Pointer to object we are embedding
`systemc_ctor
   m_PLL = new t_PLL(); // Construct contained object
`systemc_dtor
   delete m_PLL;    // Destruct contained object
`verilog
`endif
   
endmodule
