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
    // �м����
    reg [7:0] abs_x, abs_y, quotient, remainder;
    reg [3:0] count; // ��λλ��
    reg sign_x, sign_y, sign_quotient; // ����

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
            sign_x <= x[7]; // ��¼������x�ķ���
            sign_y <= y[7]; // ��¼����y�ķ���
            sign_quotient <= x[7]^y[7];
            abs_x <= {1'b0,x[6:0]};  //x*�Ĳ���
            abs_y <= {1'b0,y[6:0]};  //y*�Ĳ���
            quotient <= 0; //��
            remainder <= 0; //����
            count <= 8; //8λ
        end else if (busy) begin
            if (count > 0) begin
                remainder = {remainder[6:0], abs_x[7]}; //���������λ�����������λ
                abs_x = {abs_x[6:0], 1'b0};  //����������
                if (remainder >= abs_y) begin  //˵������Ϊ��
                    remainder = remainder - abs_y; 
                    quotient = {quotient[6:0], 1'b1}; //����1
                end else begin
                    quotient = {quotient[6:0], 1'b0}; //����0
                end
                count = count - 1;
            end else begin
                busy <= 0;
                // �ָ������ķ���
                r <= {sign_x,remainder[6:0]};
                // �ָ��̵ķ���
                z <= {sign_quotient,quotient[6:0]};
            end
        end
    end

	
endmodule
