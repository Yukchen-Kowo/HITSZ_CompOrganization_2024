`timescale 1ns / 1ps

module divider (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] x,
    input  wire [7:0] y,
    input  wire       start,
    output reg  [7:0] z,
    output reg  [7:0] r,
    output reg        busy
);

    // TODO
    // 中间变量
    reg [7:0] abs_x, abs_y, quotient, remainder;
    reg [3:0] count; // 移位位数
    reg sign_x, sign_y, sign_quotient; // 符号

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy <= 0;
            count <= 0;
            quotient <= 0;
            remainder <= 0;
            r <= 0;
            z <= 0;
        end else if (start) begin
            busy <= 1;
            sign_x <= x[7]; // 记录被除数x的符号
            sign_y <= y[7]; // 记录除数y的符号
            sign_quotient <= x[7]^y[7];
            abs_x <= {1'b0,x[6:0]};  //x*的补码
            abs_y <= {1'b0,y[6:0]};  //y*的补码
            quotient <= 0; //商
            remainder <= 0; //余数
            count <= 8; //8位
        end else if (busy) begin
            if (count > 0) begin
                remainder = {remainder[6:0], abs_x[7]}; //被除数最高位移入余数最低位
                abs_x = {abs_x[6:0], 1'b0};  //被除数左移
                if (remainder >= abs_y) begin  //说明余数为正
                    remainder = remainder - abs_y; 
                    quotient = {quotient[6:0], 1'b1}; //上商1
                end else begin
                    quotient = {quotient[6:0], 1'b0}; //上商0
                end
                count = count - 1;
            end else begin
                busy <= 0;
                // 恢复余数的符号
                r <= {sign_x,remainder[6:0]};
                // 恢复商的符号
                z <= {sign_quotient,quotient[6:0]};
            end
        end
    end

	
endmodule
