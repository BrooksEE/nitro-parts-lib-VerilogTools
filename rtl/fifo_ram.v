// simple ram structure to 
// allocate memory and control read/write access
// to that memory.

module fifo_ram 
   #(parameter ADDR_WIDTH = 4, DATA_WIDTH=8)
   (
    input  clka,
    input  clkb,
    input  wea,
    input  [ADDR_WIDTH-1:0] addra,
    input  [ADDR_WIDTH-1:0] addrb,
    input  [DATA_WIDTH-1:0] dia,
    output [DATA_WIDTH-1:0] doa,
    output [DATA_WIDTH-1:0] dob
    );

   reg [DATA_WIDTH-1:0]     RAM [(1<<ADDR_WIDTH)-1:0];
   reg [ADDR_WIDTH-1:0]     read_addra;
   reg [ADDR_WIDTH-1:0]     read_addrb;
   always @(posedge clka) begin
      if (wea == 1'b1) RAM[addra] <= dia;
      read_addra <= addra;
   end
   always @(posedge clkb) begin
      read_addrb <= addrb;
   end
   assign doa = RAM[read_addra];
   assign dob = RAM[read_addrb];
endmodule

