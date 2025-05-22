`timescale 1ns / 1ps

module divider (
    input  wire         clk,
    input  wire         rst,        // high active
    input  wire [31:0]  x,          // dividend
    input  wire [31:0]  y,          // divisor
    input  wire         start,      // 1 - division should begin
    output reg  [31:0]  z,          // quotient
    output reg  [31:0]  r,          // remainder
    output reg          busy        // 1 - performing division; 0 - division ends
);

    // TODO
    //中间变量
    reg [31:0] abs_x, abs_y, quotient, remainder;
    reg [5:0] count; //移位位数
    reg sign_x, sign_y, sign_quotient; //符号

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
            sign_x <= x[31]; // 记录被除数x的符号
            sign_y <= y[31]; // 记录除数y的符号
            sign_quotient <= x[31]^y[31];
            abs_x <= {1'b0,x[30:0]};  //x*的补码
            abs_y <= {1'b0,y[30:0]};  //y*的补码
            quotient <= 0; //商
            remainder <= 0; //余数
            count <= 32; //32位
        end else if (busy) begin
            if (count > 0) begin
                remainder = {remainder[30:0], abs_x[31]}; //被除数最高位移入余数最低位
                abs_x = {abs_x[30:0], 1'b0};  //被除数左移
                if (remainder >= abs_y) begin  //说明余数为正
                    remainder = remainder - abs_y; 
                    quotient = {quotient[30:0], 1'b1}; //上商1
                end else begin
                    quotient = {quotient[30:0], 1'b0}; //上商0
                end
                count = count - 1;
            end else begin
                busy <= 0;
               
                // 恢复余数的符号
                r <= {sign_x,remainder[30:0]};
                // 恢复商的符号
                z <= {sign_quotient,quotient[30:0]};
            end
        end
    end
    

endmodule
