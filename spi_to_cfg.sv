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
module spi_to_cfg #(
    parameter   NUM = 32
)(
    input                   clock,
    input                   rst_n,
//-->> RX INTERFACE <<---
	input			       rx_stream_sof	,
	input[7:0]		       rx_stream_data	,
	input			       rx_stream_vld	,
	input			       rx_stream_eof	,
	//-->> TX INTERFACE <<---
	input			       tx_send_flag		,
	output logic[23:0]	   tx_send_momment	,
	output logic[7:0]      tx_send_data		,
	output logic           tx_send_valid	,
	input			       tx_empty			,
	//-->> PARSE REQ <<------
    spi_cfg_interface.master        cfg_inf [NUM-1:0]
);
wire rx_stream_vld_lat2;

latency #(
	.LAT		(2		),
	.DSIZE		(1		)
)latency_inst(
	.clk		(clock			),
	.rst_n      (rst_n			),
	.d          (rx_stream_vld			),
	.q          (rx_stream_vld_lat2		)
);

assign tx_send_momment = 24'd1;

genvar KK;
int    II;

typedef enum {IDLE,START,ADDR0,ADDR1,SW_PATH,WDATA0,WDATA1,RD_LAT,RDATA0,RDATA1,WRITE_FLAG,READ_FLAG} STATUS;

STATUS cstate,nstate;

logic           wr_rd;  //0: READ 1:write

always@(posedge clock,negedge rst_n)
    if(~rst_n)  cstate  <= IDLE;
    else        cstate  <= nstate;

always@(*)
    case(cstate)
    IDLE:
        if(rx_stream_sof)
                nstate  = START;
        else    nstate  = IDLE;
    START:
        if(rx_stream_eof)
                nstate  = IDLE;
        else if(rx_stream_vld)
                nstate  = ADDR0;
        else    nstate  = START;
    ADDR0:
        if(rx_stream_eof)
                nstate  = IDLE;
        else if(rx_stream_vld)
                nstate  = ADDR1;
        else    nstate  = ADDR0;
    ADDR1:
        if(wr_rd)begin
            if(rx_stream_vld)
                    nstate  = WDATA0;
            else    nstate  = ADDR1;
        end else begin
            if(rx_stream_vld_lat2)
                    nstate  = RDATA0;
            else    nstate  = ADDR1;
        end
    WDATA0:
        if(rx_stream_eof)
                nstate  = IDLE;
        else if(rx_stream_vld)
                nstate  = WDATA1;
        else    nstate  = WDATA0;
    WDATA1:
        if(rx_stream_eof)
                nstate  = IDLE;
        else    nstate  = WRITE_FLAG;
    WRITE_FLAG: nstate  = IDLE;
    RD_LAT:
        if(rx_stream_eof)
                nstate  = IDLE;
        else if(rx_stream_vld_lat2)
                nstate  = RDATA0;
        else    nstate  = RD_LAT;
    RDATA0:
        if(rx_stream_eof)
                nstate  = IDLE;
        else if(tx_empty)
                nstate  = RDATA1;
        else    nstate  = RDATA0;
    RDATA1:
        if(rx_stream_eof)
                nstate  = IDLE;
        else    nstate  = READ_FLAG;
    READ_FLAG:  nstate  = IDLE;
    default:    nstate  = IDLE;
    endcase

//-->> ADDR <<-------------------------------
logic [cfg_inf[0].ASIZE-1:0]    addr;
logic [cfg_inf[0].DSIZE-1:0]    cfg_wdata,cfg_rdata;
logic                        cfg_wr_en;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  {wr_rd,addr}    <= 16'd0;
    else begin
        case(nstate)
        ADDR0:  if(rx_stream_vld)
                        {wr_rd,addr[14:8]}  <= rx_stream_data;
                else    {wr_rd,addr[14:8]}  <= {wr_rd,addr[14:8]};
        ADDR1:  if(rx_stream_vld)
                        addr[7:0]  <= rx_stream_data;
                else    addr[7:0]  <= addr[7:0];
        default:;
        endcase
    end

always@(posedge clock,negedge rst_n)
    if(~rst_n)  cfg_wdata    <= 16'd0;
    else begin
        case(nstate)
        WDATA0: if(rx_stream_vld)
                        cfg_wdata[15:8]  <= rx_stream_data;
                else    cfg_wdata[15:8]  <= cfg_wdata[15:8];
        WDATA1: if(rx_stream_vld)
                        cfg_wdata[7:0]   <= rx_stream_data;
                else    cfg_wdata[7:0]   <= cfg_wdata[7:0];
        default:;
        endcase
    end

always@(posedge clock,negedge rst_n)
    if(~rst_n)  cfg_wr_en   <= 1'b0;
    else begin
        case(nstate)
        WRITE_FLAG:
                cfg_wr_en   <= 1'b1;
        default:cfg_wr_en   <= 1'b0;
        endcase
    end

always@(posedge clock,negedge rst_n)
    if(~rst_n)  tx_send_data    <= 8'd0;
    else begin
        case(nstate)
        // RDATA0: tx_send_data    <= cfg_rdata[14:7];
        // RDATA1: tx_send_data    <= {cfg_rdata[6:0],1'b0};

        RDATA0: tx_send_data    <= cfg_rdata[15:8];
        RDATA1: tx_send_data    <= cfg_rdata[7:0];

        default:;
        endcase
    end

always@(posedge clock,negedge rst_n)
    if(~rst_n)  tx_send_valid    <= 1'b0;
    else begin
        case(nstate)
        RDATA0,RDATA1: if(tx_empty)
                        tx_send_valid  <= 1'b1;
                else    tx_send_valid  <= 1'b0;
        default:        tx_send_valid  <= 1'b0;
        endcase
    end


//--<< ADDR >>-------------------------------
//-->> channals <<---------------------------
localparam NSIZE    =   NUM<= 2 ? 1:
                        NUM<= 4 ? 2:
                        NUM<= 8 ? 3:
                        NUM<= 16? 4:
                        NUM<= 32? 5:
                        NUM<= 64? 6:
                        NUM<= 128? 7:
                        NUM<= 256? 8:
                        NUM<= 512? 9: 16;

logic [NUM-1:0]         channal_mask;
logic [NSIZE-1:0]       channal_index;
logic [NSIZE-1:0]       channal_index_wire=0;

generate
for(KK=0;KK<NUM;KK++)begin
always@(posedge clock,negedge rst_n)
    if(~rst_n)  channal_mask[KK]    <= 1'b0;
    else        channal_mask[KK]    <= addr == cfg_inf[KK].cfg_addr;

end
endgenerate

always@(*)begin
    channal_index_wire  = {NSIZE{1'b0}};
    for(II=1;II<NUM;II++)
        channal_index_wire = channal_mask[II]? II : channal_index_wire;
end

always@(posedge clock,negedge rst_n)
    if(~rst_n)  channal_index   <= {NSIZE{1'b0}};
    else        channal_index   <= channal_index_wire;

//--<< channals >>---------------------------
//--->> WRITE DATA <<------------------------
generate
for(KK=0;KK<NUM;KK++)begin

// assign cfg_inf[KK].wdata    = cfg_wdata;

// always@(posedge clock,negedge rst_n)
//     if(~rst_n)   cfg_inf[KK].wr_en  <= 1'b0;
//     else         cfg_inf[KK].wr_en  <= channal_mask[KK] && cfg_wr_en;
// end

always@(posedge clock,negedge rst_n)
    if(~rst_n)   cfg_inf[KK].wdata  <= cfg_inf[KK].default_data;
    else         cfg_inf[KK].wdata  <= (channal_mask[KK] && cfg_wr_en)? cfg_wdata : cfg_inf[KK].wdata;
end

endgenerate
//---<< WRITE DATA >>------------------------
//--->> READ DATA <<-------------------------
logic[cfg_inf[0].DSIZE-1:0]    cfg_inf_rdata [NUM-1:0];
generate
    for(KK=0;KK<NUM;KK++)
        assign cfg_inf_rdata[KK]    = cfg_inf[KK].rdata;
endgenerate

always@(*)begin
    cfg_rdata   = cfg_inf_rdata[0];
    for(II=1;II<NUM;II++)
        cfg_rdata   = channal_mask[II]? cfg_inf_rdata[II] : cfg_rdata;
end

//---<< READ DATA >>-------------------------
`ifdef SIM

logic[cfg_inf[0].DSIZE-1:0]     chk_addr_queue [$];
logic[cfg_inf[0].ASIZE-1:0]     default_cfg_addr    [NUM-1:0];
generate
    for(KK=0;KK<NUM;KK++)
        assign default_cfg_addr[KK] = cfg_inf[KK].cfg_addr;
endgenerate

initial begin
    #100;
    $display("CHECK SPI CFG ADDR");
    foreach(default_cfg_addr[j])begin
        foreach(chk_addr_queue[i])begin
            if(chk_addr_queue[i]==default_cfg_addr[j])
                $error("SPI ADDR CON'T BE SAME :: QUEUE[%d],ADDR=[%h]",i,default_cfg_addr[j]);
        end
        chk_addr_queue.push_back(default_cfg_addr[j]);
    end
    chk_addr_queue.delete;
end
`endif
endmodule
