/*
 * This file can be included inside any verilog module wanting to simulate
 * a PLL.
 */

module PLL_sim
    #( parameter PLL_NAME="PLL_sim"
     )
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
   /* verilator lint_off width */
   reg [63:0] pll_name = PLL_NAME;
   /* verilator lint_on width */
   reg x,y; // so they don't get optimized out
   reg [31:0] m_s, d_s;
   wire reset = pll_mult != m_s || pll_div != d_s; 
   always @(posedge input_clk) begin
      m_s <= pll_mult;
      d_s <= pll_div;
      x=$c("m_PLL->posedge(", debug, ",", reset, ",", pll_name, ")");
      y=$c("m_PLL->locked()" );
   end
   assign output_clk = $c("m_PLL->clkFX (", input_clk, ",", pll_mult, ",", pll_div, ",", debug, ",", pll_name, ")" );
   assign locked = y; 

`systemc_header
#ifndef __PLL_H__
#define __PLL_H__

#include <vpi_user.h>

extern unsigned int main_time;

#define LOCK_COUNT 5 

class t_PLL
  {

 private:
   int m_posedge2;
   int m_posedge1;        
   bool m_locked;
   int m_T;

   int m_cnt;
   int m_fail;
   int m_delta1;
   int m_dT;

 public:
  // CONSTRUCTORS
   t_PLL()
   {
    //printf ( "PLL %p created\n", this );
    m_posedge2 = m_posedge1 = m_locked = 0;
    m_T = 10;
    m_cnt = m_delta1 = m_fail = 0;

    }
  
  ~t_PLL() {
  }

  inline bool locked() { 
    return m_locked;
  }

  inline bool unlock() {
    m_cnt = 0;
    m_fail = 0;
    m_locked=0;
  }

  inline const char* pll_name (int64_t pn) {
    //vpiHandle h = vpi_handle_by_name((PLI_BYTE8*)"PLL_NAME", NULL);
    //s_vpi_value v;
    //v.format = vpiStringVal;
    //vpi_get_value(h,&v); 
    //return strdup(v.value.str); 
    //printf ( "ull val: %llu\n", pn ); 
    char chars[9];
    chars[8]=0;
    int pos=8;
    while (pn>0 && pos>0) {
       chars[--pos] = pn&0xff; 
       pn >>= 8;
    }
    return strdup(chars+pos);
    //return "test";
  }
  
  inline bool posedge(int32_t debug, bool reset, int64_t pn ) {
    m_posedge1 = m_posedge2;
    m_posedge2 = main_time;
    int delta = m_posedge2-m_posedge1;

    if (reset) {
        unlock();
    }

    if (m_cnt<LOCK_COUNT) {
       if (delta == m_delta1) {
         ++m_cnt;
       } else {
         ++m_fail; 

         if (debug && (m_fail % 100==0))  printf ( "PLL %s fail to lock delta1=%d delta=%d\n", pll_name(pn), m_delta1, delta );
       }
    } else {
       if (m_delta1 != delta) {
          m_locked=false;
          m_cnt=0;
          printf ( "PLL %s clock change detected unlocking.\n", pll_name(pn)); 
       } else {
          m_locked=true;
          m_T=delta;
          m_fail=0;
       }
    }

    m_delta1=delta;

    return true;

  }

  inline bool clkFX(bool x, int32_t m, int32_t d, int32_t debug, int64_t pn) {
    if ( !m || !d || !m_locked || !m_T) { return false; }
    bool clko;
    int dT = round((double)m_T*d / 2 / m);
    if (m_cnt==LOCK_COUNT) {
        int mod = (m_T * d) % (2*m);
        ++m_cnt;
        if ( mod ) {
            printf ( "FAIL PLL %s not integer divisible by m/d m_T=%d div=%d m=%d rounded d_T=%d\n", pll_name(pn), m_T, d, m, dT ); 
        } else {
            printf ( "SUCCESS PLL %s m_T=%d * d=%d / 2 / m=%d = dT=%d\n", pll_name(pn), m_T, d, m, dT );
        }
        m_dT = dT;
    } else if (m_cnt > LOCK_COUNT && m_dT != dT) {
        unlock(); 
    }
    if (!dT) return false;
    clko = ((main_time-1) / dT) % 2 == 0; 
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
