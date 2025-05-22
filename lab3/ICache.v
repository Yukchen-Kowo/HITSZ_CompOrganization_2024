`timescale 1ns / 1ps

// `define BLK_LEN  4
// `define BLK_SIZE (`BLK_LEN*32)

module ICache(
    input  wire         cpu_clk,
    input  wire         cpu_rst,        // high active
    // Interface to CPU
    input  wire         inst_rreq,      // 来自CPU的取指请求
    input  wire [31:0]  inst_addr,      // 来自CPU的取指地址
    output reg          inst_valid,     // 输出给CPU的指令有效信号（读指令命中）
    output reg  [31:0]  inst_out,       // 输出给CPU的指令
    // Interface to Read Bus
    input  wire         mem_rrdy,       // 主存就绪信号（高电平表示主存可接收ICache的读请求）
    output reg  [ 3:0]  mem_ren,        // 输出给主存的读使能信号
    output reg  [31:0]  mem_raddr,      // 输出给主存的读地址
    input  wire         mem_rvalid,     // 来自主存的数据有效信号
    input  wire [`BLK_SIZE-1:0] mem_rdata   // 来自主存的读数据
);



`ifdef ENABLE_ICACHE    /******** 不要修改此行代码 ********/

    wire [4:0] tag_from_cpu   = inst_addr[14:10];    // 主存地址的TAG（主存被分为32个区（主存32KB,cache1KB），2^5=32所以5位）
    wire [1:0] offset         = inst_addr[3:2];      // 32位字偏移量
    wire       valid_bit      = cache_line_r[133];   // Cache行的有效位
    wire [4:0] tag_from_cache = cache_line_r[132:128];  // Cache行的TAG

    // TODO: 定义ICache状态机的状态变量
    localparam IDLE = 2'b00;
    localparam TAG_CHECK = 2'b01;
    localparam REFILL = 2'b10;

    reg [1:0] current_state, next_state;

    wire hit = valid_bit && (tag_from_cpu == tag_from_cache) && (current_state == TAG_CHECK);
 

    wire       cache_we     = mem_rvalid;     // ICache存储体的写使能信号
    wire [5:0] cache_index  = inst_addr[9:4];     // 主存地址的Cache索引 / ICache存储体的地址
    wire [133:0] cache_line_w = {1'b1, tag_from_cpu, mem_rdata};     // 待写入ICache的Cache行
    wire [133:0] cache_line_r;                  // 从ICache读出的Cache行

    
    reg  mem_ren_pulse; //记录是否已发送过读请求信号，避免mem_ren一直处于高电平状态导致超时

    always @(*) begin
        inst_valid = hit;
        /* TODO: 根据字偏移，选择Cache行中的某个32位字输出指令 （inst_out = ?）*/
        assign inst_out = (offset == 2'b00) ? cache_line_r[31:0] :
                           (offset == 2'b01) ? cache_line_r[63:32] :
                           (offset == 2'b10) ? cache_line_r[95:64] :
                                               cache_line_r[127:96];

    end

    // ICache存储体：Block MEM IP核
    blk_mem_gen_1 U_isram (
        .clka   (cpu_clk),
        .wea    (cache_we),
        .addra  (cache_index),
        .dina   (cache_line_w),
        .douta  (cache_line_r)
    );

    // TODO: 编写状态机现态的更新逻辑
    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            current_state = IDLE;
        end else begin
            current_state = next_state;
        end
    end

    // TODO: 编写状态机的状态转移逻辑
    always @(*) begin
         if (cpu_rst) begin
             next_state = IDLE;
         end else begin
             case(current_state)
                 IDLE: begin
                     if (inst_rreq) begin
                         next_state = TAG_CHECK;
                     end else begin
                         next_state = IDLE;
                     end
                 end
                 TAG_CHECK: begin
                     if (hit) begin  
                         next_state = IDLE;
                     end else begin
                         next_state = REFILL;
                     end
                 end
                 REFILL: begin
                     if (mem_rvalid) begin  
                         next_state = TAG_CHECK;
                     end else begin
                         next_state = REFILL;
                     end
                 end
                 default: begin
                     next_state = IDLE;
                 end
             endcase
         end
    end


    // TODO: 生成状态机的输出信号
    always @(posedge cpu_clk) begin
        if (cpu_rst) begin
            mem_raddr = 32'hffffffff;
            mem_ren = 4'b0000;
            mem_ren_pulse = 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    mem_ren = 4'b0000;
                    mem_ren_pulse = 1'b0; 
                end
                TAG_CHECK: begin
                    mem_ren = 4'b0000;
                end
                REFILL: begin
                    if (mem_rrdy && !mem_ren_pulse) begin
                        mem_raddr = {inst_addr[31:4], 4'b0000};   // 将低4位设为0，确保从块的起始地址开始读取数据，避免读取到不完整的块
                        mem_ren = 4'b1111;
                        mem_ren_pulse = 1'b1;
                    end else begin
                        mem_ren = 4'b0000;
                    end
                end
                default: begin
                    mem_ren = 4'b0000;
                end
            endcase
        end
    end




    /******** 不要修改以下代码 ********/
`else

    localparam IDLE  = 2'b00;
    localparam STAT0 = 2'b01;
    localparam STAT1 = 2'b11;
    reg [1:0] state, nstat;

    always @(posedge cpu_clk or posedge cpu_rst) begin
        state <= cpu_rst ? IDLE : nstat;
    end

    always @(*) begin
        case (state)
            IDLE:    nstat = inst_rreq ? (mem_rrdy ? STAT1 : STAT0) : IDLE;
            STAT0:   nstat = mem_rrdy ? STAT1 : STAT0;
            STAT1:   nstat = mem_rvalid ? IDLE : STAT1;
            default: nstat = IDLE;
        endcase
    end

    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            inst_valid <= 1'b0;
            mem_ren    <= 4'h0;
        end else begin
            case (state)
                IDLE: begin
                    inst_valid <= 1'b0;
                    mem_ren    <= (inst_rreq & mem_rrdy) ? 4'hF : 4'h0;
                    mem_raddr  <= inst_rreq ? inst_addr : 32'h0;
                end
                STAT0: begin
                    mem_ren    <= mem_rrdy ? 4'hF : 4'h0;
                end
                STAT1: begin
                    mem_ren    <= 4'h0;
                    inst_valid <= mem_rvalid ? 1'b1 : 1'b0;
                    inst_out   <= mem_rvalid ? mem_rdata[31:0] : 32'h0;
                end
                default: begin
                    inst_valid <= 1'b0;
                    mem_ren    <= 4'h0;
                end
            endcase
        end
    end

`endif

endmodule
