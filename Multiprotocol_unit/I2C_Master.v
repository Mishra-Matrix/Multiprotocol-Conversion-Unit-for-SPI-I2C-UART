`timescale 1ns / 1ps
module i2c_master (
    input  wire clk,           
    input  wire rst,           
    input  wire i2c_start,     
    input  wire [7:0] i2c_ctrl, 
    input  wire [7:0] i2c_data, 
    output reg  i2c_busy,      
    output reg  i2c_scl,       
    inout  wire i2c_sda        
);

    localparam CLK_DIV = 250; 
    localparam TARGET_ADDR = 8'h78; 

    localparam IDLE       = 4'd0;
    localparam START      = 4'd1;
    localparam SEND_ADDR  = 4'd2;
    localparam ACK_ADDR   = 4'd3;
    localparam SEND_CTRL  = 4'd4;
    localparam ACK_CTRL   = 4'd5;
    localparam SEND_DATA  = 4'd6;
    localparam ACK_DATA   = 4'd7;
    localparam STOP       = 4'd8;

    reg [3:0] state = IDLE;
    reg [15:0] clk_cnt = 0;
    reg [2:0] bit_cnt = 0;
    
    reg sda_out = 1'b1;
    reg sda_en  = 1'b1; 
    
    assign i2c_sda = (sda_en) ? sda_out : 1'bz;

    always @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            i2c_busy <= 1'b0;
            i2c_scl  <= 1'b1;
            sda_out  <= 1'b1;
            sda_en   <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    i2c_scl  <= 1'b1; sda_out <= 1'b1; sda_en <= 1'b1; i2c_busy <= 1'b0;
                    if (i2c_start) begin
                        i2c_busy <= 1'b1; state <= START; clk_cnt <= 0;
                    end
                end
                START: begin
                    clk_cnt <= clk_cnt + 1;
                    if (clk_cnt == CLK_DIV) sda_out <= 1'b0; 
                    else if (clk_cnt == CLK_DIV * 2) begin
                        i2c_scl <= 1'b0; bit_cnt <= 7; state <= SEND_ADDR; clk_cnt <= 0;
                    end
                end
                SEND_ADDR: begin
                    clk_cnt <= clk_cnt + 1;
                    if (clk_cnt == 1) sda_out <= TARGET_ADDR[bit_cnt];
                    else if (clk_cnt == CLK_DIV) i2c_scl <= 1'b1; 
                    else if (clk_cnt == CLK_DIV * 3) begin
                        i2c_scl <= 1'b0; clk_cnt <= 0;
                        if (bit_cnt == 0) state <= ACK_ADDR;
                        else bit_cnt <= bit_cnt - 1;
                    end
                end
                ACK_ADDR: begin
                    clk_cnt <= clk_cnt + 1;
                    if (clk_cnt == 1) sda_en <= 1'b0;  
                    else if (clk_cnt == CLK_DIV) i2c_scl <= 1'b1; 
                    else if (clk_cnt == CLK_DIV * 3) begin
                        i2c_scl <= 1'b0; sda_en <= 1'b1; bit_cnt <= 7; state <= SEND_CTRL; clk_cnt <= 0;
                    end
                end
                SEND_CTRL: begin
                    clk_cnt <= clk_cnt + 1;
                    if (clk_cnt == 1) sda_out <= i2c_ctrl[bit_cnt];
                    else if (clk_cnt == CLK_DIV) i2c_scl <= 1'b1; 
                    else if (clk_cnt == CLK_DIV * 3) begin
                        i2c_scl <= 1'b0; clk_cnt <= 0;
                        if (bit_cnt == 0) state <= ACK_CTRL;
                        else bit_cnt <= bit_cnt - 1;
                    end
                end
                ACK_CTRL: begin
                    clk_cnt <= clk_cnt + 1;
                    if (clk_cnt == 1) sda_en <= 1'b0;  
                    else if (clk_cnt == CLK_DIV) i2c_scl <= 1'b1; 
                    else if (clk_cnt == CLK_DIV * 3) begin
                        i2c_scl <= 1'b0; sda_en <= 1'b1; bit_cnt <= 7; state <= SEND_DATA; clk_cnt <= 0;
                    end
                end
                SEND_DATA: begin
                    clk_cnt <= clk_cnt + 1;
                    if (clk_cnt == 1) sda_out <= i2c_data[bit_cnt]; 
                    else if (clk_cnt == CLK_DIV) i2c_scl <= 1'b1; 
                    else if (clk_cnt == CLK_DIV * 3) begin
                        i2c_scl <= 1'b0; clk_cnt <= 0;
                        if (bit_cnt == 0) state <= ACK_DATA;
                        else bit_cnt <= bit_cnt - 1;
                    end
                end
                ACK_DATA: begin
                    clk_cnt <= clk_cnt + 1;
                    if (clk_cnt == 1) sda_en <= 1'b0;  
                    else if (clk_cnt == CLK_DIV) i2c_scl <= 1'b1; 
                    else if (clk_cnt == CLK_DIV * 3) begin
                        i2c_scl <= 1'b0; sda_en <= 1'b1; state <= STOP; clk_cnt <= 0;
                    end
                end
                STOP: begin
                    clk_cnt <= clk_cnt + 1;
                    if (clk_cnt == 1) sda_out <= 1'b0; 
                    else if (clk_cnt == CLK_DIV) i2c_scl <= 1'b1; 
                    else if (clk_cnt == CLK_DIV * 2) begin sda_out <= 1'b1; state <= IDLE; end
                end
            endcase
        end
    end
endmodule