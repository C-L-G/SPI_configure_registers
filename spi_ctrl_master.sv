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
module spi_ctrl_master #(
    parameter   CFG_NUM = 16,
    parameter	PHASE	= 0,
	parameter	ACTIVE	= 0
)(
    input                       clock,
    input                       rst_n,
    //-->> SPI INTERFACE <<---
    input                       sck	    ,
    input                       cs_n    ,
    output                      miso    ,
    input                       mosi    ,
    spi_cfg_interface.master    cfg_inf [CFG_NUM-1:0]
);

//-->> RX INTERFACE <<---
logic 			rx_stream_sof	;
logic [7:0]		rx_stream_data	;
logic 			rx_stream_vld	;
logic 			rx_stream_eof	;
//-->> TX INTERFACE <<---
logic			tx_send_flag			;
logic[23:0]	    tx_send_momment			;
logic[7:0]		tx_send_data			;
logic			tx_send_valid			;
logic			tx_empty                ;

spi_phy_verb #(
	.PHASE	       (PHASE	   ),
	.ACTIVE	       (ACTIVE	   )
)spi_phy_verb_inst(
	//-->> SPI INTERFACE <<---
/*    input	        */  .sck					(sck	            ),
/*    input	        */  .cs_n        			(cs_n               ),
/*    output        */  .miso        			(miso               ),
/*    input	        */  .mosi					(mosi               ),
	//-->> system <<---------
/*    input			*/  .clock					(clock              ),
/*    input			*/  .rst_n					(rst_n              ),
	//-->> RX INTERFACE <<---
/*    output        */  .rx_stream_sof          (rx_stream_sof      ),
/*    output[7:0]   */  .rx_stream_data         (rx_stream_data     ),
/*    output        */  .rx_stream_vld          (rx_stream_vld      ),
/*    output        */  .rx_stream_eof          (rx_stream_eof      ),
	//-->> TX INTERFACE <<---
/*  output          */  .tx_send_flag           (tx_send_flag	    ),
/*  input [23:0]    */  .tx_send_momment        (tx_send_momment	),
/*  input [7:0]     */  .tx_send_data           (tx_send_data	    ),
/*  input           */  .tx_send_valid		    (tx_send_valid	    ),
/*  output          */  .tx_empty               (tx_empty           )
);


spi_to_cfg #(
    .NUM        (CFG_NUM)
)spi_to_cfg_inst(
/*    input			*/  .clock					(clock			    ),
/*    input			*/  .rst_n					(rst_n			    ),
//-->> RX INTERFACE <<---
/*    input         */  .rx_stream_sof          (rx_stream_sof      ),
/*    input [7:0]   */  .rx_stream_data         (rx_stream_data     ),
/*    input         */  .rx_stream_vld          (rx_stream_vld      ),
/*    input         */  .rx_stream_eof          (rx_stream_eof      ),
//-->> TX INTERFACE <<---
/*  input           */  .tx_send_flag           (tx_send_flag	    ),
/*  output[23:0]    */  .tx_send_momment        (tx_send_momment	),
/*  output[7:0]     */  .tx_send_data           (tx_send_data	    ),
/*  output          */  .tx_send_valid		    (tx_send_valid	    ),
/*  input           */  .tx_empty               (tx_empty           ),
//-->> PARSE REQ <<------
/*    spi_cfg_interface.master */   .cfg_inf    (cfg_inf            )//[NUM-1:0]
);

endmodule
