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
    //�м����
    reg [31:0] abs_x, abs_y, quotient, remainder;
    reg [5:0] count; //��λλ��
    reg sign_x, sign_y, sign_quotient; //����

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
            sign_x <= x[31]; // ��¼������x�ķ���
            sign_y <= y[31]; // ��¼����y�ķ���
            sign_quotient <= x[31]^y[31];
            abs_x <= {1'b0,x[30:0]};  //x*�Ĳ���
            abs_y <= {1'b0,y[30:0]};  //y*�Ĳ���
            quotient <= 0; //��
            remainder <= 0; //����
            count <= 32; //32λ
        end else if (busy) begin
            if (count > 0) begin
                remainder = {remainder[30:0], abs_x[31]}; //���������λ�����������λ
                abs_x = {abs_x[30:0], 1'b0};  //����������
                if (remainder >= abs_y) begin  //˵������Ϊ��
                    remainder = remainder - abs_y; 
                    quotient = {quotient[30:0], 1'b1}; //����1
                end else begin
                    quotient = {quotient[30:0], 1'b0}; //����0
                end
                count = count - 1;
            end else begin
                busy <= 0;
               
                // �ָ������ķ���
                r <= {sign_x,remainder[30:0]};
                // �ָ��̵ķ���
                z <= {sign_quotient,quotient[30:0]};
            end
        end
    end
    

endmodule
