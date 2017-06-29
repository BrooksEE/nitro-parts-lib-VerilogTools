/*
 * This file can be included inside any verilog module wanting to simulate
 * a PLL.
 */

`timescale 1ps/1ps

module PLL_sim
    #( parameter PLL_NAME="PLL_sim",
       parameter MAX_NAME_LEN=256 // must be more than 8 or class won't compile
     )
 (input      input_clk,
  output     output_clk,
  input [31:0] pll_mult,
  input [31:0] pll_div,
  output     locked,
  input debug);


`ifndef verilator

 reg output_clkr;
 initial output_clkr=0;
 assign output_clk=output_clkr;

 integer in_period0=1;
 integer in_period1=2;
 integer in_period2=3;
 integer cur_p, last_time=0, out_period=100000;
 assign locked = in_period2 == in_period1 &&
                 in_period1 == in_period0;
 always @(posedge input_clk) begin
    cur_p = $time - last_time;
    in_period2 = in_period1;
    in_period1 = in_period0;
    in_period0 = cur_p;
    last_time=$time;
    out_period = locked ? cur_p / pll_mult * pll_div / 2 : out_period;
 end  
 

   always #out_period output_clkr = ~output_clkr;

`else
   /* verilator lint_off width */
   // in case len is less than 8 this ensures that 
   // the pll_name type will be resolved to WData * and not uint64_t
   reg [MAX_NAME_LEN*8:0] pll_concat = PLL_NAME;
   /* verilator lint_on width */
   reg [(MAX_NAME_LEN+1)*8:0] pll_name = { 8'b0, pll_concat }; // ensure we have a zero byte at the top
   reg x,y; // so they don't get optimized out
   reg [31:0] m_s, d_s;
   wire reset = pll_mult != m_s || pll_div != d_s; 
   always @(posedge input_clk) begin
      m_s <= pll_mult;
      d_s <= pll_div;
      x=$c("m_PLL->posedge(", debug, ",", reset, ",", pll_name, ")");
      y=$c("m_PLL->locked()" );
   end
   reg oclk /*verilator public_flat_rw @(posedge input_clk) */;
   assign oclk = $c("m_PLL->clkFX (", input_clk, ",", pll_mult, ",", pll_div, ",", debug, ",", pll_name, ")" );
   assign output_clk = oclk;
   assign locked = y; 

`systemc_header
#ifndef __PLL_H__
#define __PLL_H__


#include <memory>

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

  inline std::auto_ptr<char> pll_name (unsigned int *pn) {
    
    // 4 chars per int 
    // 0 byte is at the beginning of the string not the end
    int chars = 0;
    int pos=0;
    while (pn[pos++]) ++chars;
    char* str = new char[chars*4+1];
    str[chars*4]=0;
    int c=chars*4;
    for (pos=0;pos<=chars;++pos) {
        int word=pn[pos];
        while (word & 0xff) {
           str[--c] = word&0xff; 
           word >>= 8;
        }
    }
    std::auto_ptr<char> ret = auto_ptr<char>(strdup ( str+c ));
    delete [] str;
    return ret;

  }
  
  inline bool posedge(int32_t debug, bool reset, unsigned int *pn ) {
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

         if (debug && (m_fail % 100==0))  printf ( "PLL %s fail to lock delta1=%d delta=%d\n", pll_name(pn).get(), m_delta1, delta );
       }
    } else {
       if (m_delta1 != delta) {
          m_locked=false;
          m_cnt=0;
          printf ( "PLL %s clock change detected unlocking.\n", pll_name(pn).get()); 
       } else {
          m_locked=true;
          m_T=delta;
          m_fail=0;
       }
    }

    m_delta1=delta;

    return true;

  }

  inline bool clkFX(bool x, int32_t m, int32_t d, int32_t debug, unsigned int *pn) {
    if ( !m || !d || !m_locked || !m_T) { return false; }
    bool clko;
    int dT = round((double)m_T*d / 2 / m);
    if (m_cnt==LOCK_COUNT) {
        int mod = (m_T * d) % (2*m);
        ++m_cnt;
        if ( mod ) {
            printf ( "FAIL PLL %s not integer divisible by m/d m_T=%d div=%d m=%d rounded d_T=%d\n", pll_name(pn).get(), m_T, d, m, dT ); 
        } else {
           if(debug)
            printf ( "SUCCESS PLL %s m_T=%d * d=%d / 2 / m=%d = dT=%d\n", pll_name(pn).get(), m_T, d, m, dT );
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
