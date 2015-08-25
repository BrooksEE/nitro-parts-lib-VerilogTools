// Single Clock Fifo. 

module fifo_singleclk #(parameter ADDR_WIDTH=4, DATA_WIDTH=8)
   (
    input clk,
    input we,
    input re,
    input resetb,
    input flush,
    output full,
    output empty,
    input  [DATA_WIDTH-1:0] wdata,
    output [DATA_WIDTH-1:0] rdata,
    output [ADDR_WIDTH-1:0] freeSpace,
    output [ADDR_WIDTH-1:0] usedSpace
    );

   reg [ADDR_WIDTH-1:0]    waddr, raddr;
   wire [ADDR_WIDTH-1:0]   nextRaddr = raddr + 1;
   wire [ADDR_WIDTH-1:0]   nextWaddr = waddr + 1;
   wire [ADDR_WIDTH-1:0]   raddr_pre, waddr_pre;

   assign full       = (nextWaddr == raddr);
   assign freeSpace = raddr - nextWaddr;

   assign raddr_pre  = flush ? 0 :
                       re ? nextRaddr : 
                       raddr;
   assign waddr_pre  = flush ? 0 :
                       we ? nextWaddr :
                       waddr;
   assign empty      = raddr == waddr;
   assign usedSpace = waddr - raddr;
 
   always @(posedge clk or negedge resetb) begin
      if(!resetb) begin
	 waddr      <= 0;
         raddr      <= 0;
      end else begin
	 raddr <= raddr_pre;
         waddr <= waddr_pre;
	 if(we && full) begin
	    $display("%m(%t) Writing to fifo when full.",$time);
	 end
	 if(re && empty) begin
	    $display("%m(%t) Reading from fifo when empty",$time);
	 end
      end
   end
   
  
   fifo_ram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))
      RAM(
	  .clka(clk),
	  .clkb(clk),
	  .wea(we),
	  .addra(waddr),
	  .addrb(raddr_pre),
	  .dia(wdata),
	  .doa(),
	  .dob(rdata)
	  );
   
endmodule

	    

