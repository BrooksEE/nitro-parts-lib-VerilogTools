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
   int m_locking;
   int m_T;
 public:
  // CONSTRUCTORS
   t_PLL()
   {
    m_posedge2 = m_posedge1 = m_locked = m_locking = 0;
    m_T = 10;
    }
  
  ~t_PLL() {
  }
  
  inline bool posedge(int32_t debug) {
    m_posedge1 = m_posedge2;
    m_posedge2 = main_time;
    int delta = m_posedge2-m_posedge1;

    if (m_locking < 10) { // 10 in a row
        if (m_T == delta) m_locking++;
        else m_locking=0;
        if (m_locking==10) {
            if (debug) printf ( "LOCKING pll %p at %d\n", this, m_T );
        }
    } else {
        if (m_T == delta) m_locked++;
        else {
            if (debug) printf ( "WARN pll %p new old=%d new=%d\n", this, m_T, delta );
            m_locked=0;
            m_locking=0;
        }
    }

    m_T = delta; 
    return true;

  }

  inline bool clkFX(bool x, int32_t m, int32_t d, int32_t debug) {
    if ( !m || !d || !m_locked || !m_T) { return false; }
    bool clko;
    int dT = (m_T*d) / 2 / m;
    if (!dT) return false;
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
