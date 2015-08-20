// Dual Clock Fifo. 

module FIFO #(parameter ADDR_WIDTH=4, DATA_WIDTH=8)
   (
    input wclk,
    input rclk, 
    input we,
    input re,
    input resetb,
    input flush,
    output full,
    output empty,
    input  [DATA_WIDTH-1:0] wdata,
    output [DATA_WIDTH-1:0] rdata,
    output [ADDR_WIDTH-1:0] wFreeSpace,
    output [ADDR_WIDTH-1:0] rUsedSpace
    );

   reg 			    wreset, rreset;
   always @(posedge wclk or negedge resetb) begin
      if(!resetb) begin
	 wreset <= 1;
      end else begin
	 wreset <= flush;
      end
   end
   always @(posedge rclk or negedge resetb) begin
      if(!resetb) begin
	 rreset <= 1;
      end else begin
	 rreset <= flush;
      end
   end

   reg [ADDR_WIDTH-1:0]    waddr, raddr, nextWaddr;
   wire [ADDR_WIDTH-1:0]   nextRaddr = raddr + 1;
   wire [ADDR_WIDTH-1:0]   raddr_pre;
   reg [ADDR_WIDTH-1:0]    raddr_ss;

   assign full       = (nextWaddr == raddr_ss);
   assign wFreeSpace = raddr_ss - nextWaddr;

   always @(posedge wclk) begin
      raddr_ss  <= raddr;
   end
      
   always @(posedge wclk or posedge wreset) begin
      if(wreset) begin
	 waddr      <= 0;
	 nextWaddr  <= 1;
      end else begin
	 if(we) begin
`ifdef SIM	    
	    if(full) $display("%m(%t) Writing to fifo when full.",$time);
`endif	    
	    waddr     <= nextWaddr;
	    nextWaddr <= nextWaddr + 1;
	 end
      end
   end
   
   reg [ADDR_WIDTH-1:0] waddr_ss;
    
   assign raddr_pre  = (re) ? nextRaddr : raddr;
   assign empty      = (raddr == waddr_ss);
   assign rUsedSpace = waddr_ss - raddr;
   
   always @(posedge rclk) begin
      waddr_ss  <= waddr;
   end

   always @(posedge rclk or posedge rreset) begin
      if(rreset) begin
	 raddr <= 0;
      end else begin
	 raddr <= raddr_pre;
	 if(re) begin
`ifdef SIM
	    if(empty) $display("%m(%t) Reading from fifo when empty",$time);
`endif	    
	 end
      end
   end

   fifo_ram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))
      RAM(
	  .clka(wclk),
	  .clkb(rclk),
	  .wea(we),
	  .addra(waddr),
	  .addrb(raddr_pre),
	  .dia(wdata),
	  .doa(),
	  .dob(rdata)
	  );
   
endmodule

	    

