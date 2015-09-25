/*
 * This file can be included inside any verilog module wanting to simulate
 * a PLL.
 */

module PLL_sim
 (input      input_clk,
  output     output_clk,
  input [31:0] pll_mult,
  input [31:0] pll_div,
  output     locked,
  input debug);


`ifndef verilator

 reg output_clkr; // driven in testbench for now.
 assign output_clk=output_clkr;

`else

   reg x;
   always @(posedge input_clk) begin
      x=$c("m_PLL->posedge(", debug, ")");
   end
   assign output_clk = $c("m_PLL->clkFX (", input_clk, ",", pll_mult, ",", pll_div, ",", debug, ")" );
   assign locked = $c("m_PLL->locked()" );

`systemc_header
#ifndef __PLL_H__
#define __PLL_H__
extern unsigned int main_time;

class t_PLL
  {

 private:
   int m_posedge2;
   int m_posedge1;        
   bool m_locked;
   double m_T;

   double m_accum;
   int m_cnt;
   int m_delta1;

 public:
  // CONSTRUCTORS
   t_PLL()
   {
    printf ( "PLL %p created\n", this );
    m_posedge2 = m_posedge1 = m_locked = 0;
    m_T = 10;

    m_accum = m_cnt = m_delta1 = 0;
    }
  
  ~t_PLL() {
  }

  inline bool locked() { return m_locked; }
  
  inline bool posedge(int32_t debug) {
    m_posedge1 = m_posedge2;
    m_posedge2 = main_time;
    int delta = m_posedge2-m_posedge1;

    #define LOCK_COUNT 100
    #define SKIP 10


    if (m_cnt<LOCK_COUNT+SKIP) {
        ++m_cnt;
        // ignore first 10
        if (m_cnt > SKIP ) m_accum+=delta;
    }

    double expected = m_cnt > SKIP ? m_accum/(m_cnt-SKIP) : 0;
    double measured = ((double)delta+m_delta1)/2; 
    double jitter = abs(expected-measured);

    if (!m_locked) {
        if (debug) {
            printf ( "PLL %p locking cnt=%d delta=%d expected=%0.3f measured=%0.3f\n", this, m_cnt, delta, expected, measured);
        }
        if (m_cnt>=LOCK_COUNT+SKIP && jitter <.5) {
                m_locked=true;       
                m_T=expected;
                if (debug) printf ( "PLL %p lock with m_T=%0.3f\n", this, m_T );
        } else if (m_cnt>=LOCK_COUNT+SKIP) {
            m_cnt=0;
            m_accum=0;
            if (debug) printf ( "PLL %p lock fail try again\n", this );
        }
   } else if (jitter > .5) {
        printf ( "WARN PLL %p too much jitter. expected=%0.3f measured=%0.3f\n", this, expected, measured );
        m_locked=false;
        m_cnt=0;
        m_accum=0;
    }

    m_delta1=delta;

    return true;

  }

  inline bool clkFX(bool x, int32_t m, int32_t d, int32_t debug) {
    if ( !m || !d || !m_locked || !m_T) { return false; }
    bool clko;
    double dT = (double)m_T*d / 2 / m;
    if (!dT) return false;
    clko = (int)(round(((double)main_time-1)) / dT) % 2 == 0; 
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
