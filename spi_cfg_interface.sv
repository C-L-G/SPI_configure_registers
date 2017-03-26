/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2017/1/7 下午12:25:21
madified:
***********************************************/
`timescale 1ns/1ps
interface spi_cfg_interface #(
    parameter ASIZE = 15,
    parameter DSIZE = 16
)(
    input   bit     clock,
    input   bit     rst_n
);

logic [DSIZE-1:0]   wdata;
logic [DSIZE-1:0]   rdata;
// logic               wr_en;
// logic               rd_en;
// logic               rd_vld;
logic [ASIZE-1:0]   cfg_addr;
logic [DSIZE-1:0]   default_data;


modport master(
input   clock,
input   rst_n,
output  wdata,
input   rdata,
input   default_data,
// output  rd_en,
// input   rd_vld,
input   cfg_addr
);

modport slaver(
input   clock,
input   rst_n,
input   wdata,
output  rdata,
output  default_data,
// input   rd_en,
// output  rd_vld,
output  cfg_addr
);

endinterface

module spi_general_reg (
    spi_cfg_interface.slaver    cfg_inf,
    input int                   addr,
    output int                  data,
    input  int                  default_data
);

assign cfg_inf.cfg_addr = addr[cfg_inf.ASIZE-1:0];
assign cfg_inf.rdata    = cfg_inf.wdata ;
assign cfg_inf.default_data = default_data;
assign data             = {{(32-cfg_inf.DSIZE){1'b0}},cfg_inf.wdata};

endmodule:spi_general_reg

module spi_read_only_reg (
    spi_cfg_interface.slaver    cfg_inf,
    input int                   addr,
    input int                   rdata
);

assign cfg_inf.cfg_addr = addr[cfg_inf.ASIZE-1:0];
assign cfg_inf.rdata    = rdata[cfg_inf.DSIZE-1:0];

endmodule:spi_read_only_reg
