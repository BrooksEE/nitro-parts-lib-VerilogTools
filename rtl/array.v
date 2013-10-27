`define PACK_1DARRAY(PK_WIDTH,PK_LEN,PK_SRC,PK_DEST)    genvar pk_idx; generate for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) begin; assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; end; endgenerate

`define UNPACK_1DARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC)  genvar unpk_idx; generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) begin; assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; end; endgenerate

`define PACK_2DARRAY(PK_WIDTH, PK_DIM0, PK_DIM1, PK_SRC,PK_DEST)    genvar pk_idx0, pk_idx1; generate for (pk_idx0=0; pk_idx0<(PK_DIM0); pk_idx0=pk_idx0+1) begin; for (pk_idx1=0; pk_idx1<(PK_DIM1); pk_idx1=pk_idx1+1) begin; assign PK_DEST[(pk_idx0*(PK_DIM1) + pk_idx1 + 1)*PK_WIDTH-1:(pk_idx0*(PK_DIM1) + pk_idx1)*PK_WIDTH ] = PK_SRC[pk_idx0][pk_idx1][((PK_WIDTH)-1):0]; end; end; endgenerate

`define UNPACK_2DARRAY(PK_WIDTH,PK_DIM0,PK_DIM1,PK_DEST,PK_SRC)  genvar unpk_idx0,unpk_idx1; generate for (unpk_idx0=0; unpk_idx0<(PK_DIM0); unpk_idx0=unpk_idx0+1) begin; for (unpk_idx1=0; unpk_idx1<(PK_DIM1); unpk_idx1=unpk_idx1+1) begin; assign PK_DEST[unpk_idx0][unpk_idx1][((PK_WIDTH)-1):0] = PK_SRC[(unpk_idx0*(PK_DIM1) + unpk_idx1 + 1)*PK_WIDTH-1:(unpk_idx0*(PK_DIM1) + unpk_idx1)*PK_WIDTH]; end;end;endgenerate
