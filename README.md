## SPI 配置寄存器
**通过spi的slaver口配置FPGA内部逻辑寄存器**
---
 **文件说明：**
 1. spi_ctrl_master 控制器顶层，里面包含一个完整的spi slaver模块和spi数据解析成控制信号的模块（spi_to_cfg)
 2. spi_to_cfg 把SPI数据解析成配置寄存器的控制信号
 3. spi_cfg_interface 定义配置的接口和，读写寄存器


 **读写协议定义：**
SPI每次交互4个Bytes，前两个Bytes合成16位，为地址（高位先），后两个Bytes合成16位数据。
16位地址的最高位标志“读写”，‘1’为写，‘0’为读，所以实际地址位宽为15
```
--READ--
-->>--{WR_RD_FLAG[0],ADDR[14:8]},{ADDR[7:0]},{WDATA[15:8]},{WDATA[7:0]}-->>--
-->>--.......................................{RDATA[15:8]},{RDATA[7:0]}-->>--
```

 **代码例子**

 ```systemverilog
 localparam CFG_NUM = 12;       //寄存器数量

 spi_cfg_interface #(           // 例化寄存器接口
    .ASIZE      (15),           // 寄存器地址宽   MAX 15
    .DSIZE      (16)            // 寄存器数据宽   MAX 16
)cfg_inf [CFG_NUM-1:0] (
/*    input   bit   */  .clock      (clk_100M      ),
/*    input   bit   */  .rst_n      (rst_n         )
);

 spi_ctrl_master #(
    .CFG_NUM            (CFG_NUM),
    .PHASE              (1),
    .ACTIVE             (1)
)spi_ctrl_master(
/*    input         */  .clock                  (clk_100M       ),
/*    input         */  .rst_n                  (rst_n          ),
//-->> SPI INTERFACE <<---
/*    input         */  .sck                    (mcu_spi_clk    ),
/*    input         */  .cs_n                   (mcu_spi_cs     ),
/*    output        */  .miso                   (mcu_spi_do     ),
/*    input         */  .mosi                   (mcu_spi_di     ),
/*    spi_cfg_interface.master  */  .cfg_inf    (cfg_inf        )//[CFG_NUM-1:0] 这行关键
);

logic [15:0]        reg0;
logic [15:0]        reg1;

//--下面为例化不同寄存器--
//------------------------------------------------
//                         使用哪个接口   || 寄存器地址  ||  寄存器数据  
//                         哪个并不重要， ||            ||                  
//                         单必须是独占的 ||            ||                                 
spi_read_only_reg year_reg (cfg_inf[0],         0,        16'h2017); //只读寄存器 标识年
spi_read_only_reg date_reg (cfg_inf[1],         1,        16'h0326); //只读寄存器 标识日期
// 下面为读写寄存器                                                 || 寄存器默认值
spi_general_reg rd_wr_reg0 (cfg_inf[2],         2,        reg0,       32'h0000_0000);
spi_general_reg rd_wr_reg1 (cfg_inf[3],         3,        reg1,       32'h0000_0000);

/*
例化寄存器的数量可以小于CFG_NUM
*/
 ```

 **--@--Young--@--**
