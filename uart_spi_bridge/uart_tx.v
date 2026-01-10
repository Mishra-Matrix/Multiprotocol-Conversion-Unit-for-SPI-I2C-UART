`timescale 1ns / 1ps
module uart_tx (
    input  wire clk,
    input  wire rst,
    input  wire tick_16x,
    input  wire tx_start,
    input  wire [7:0] tx_data,
    output reg  tx,
    output reg  tx_busy
);
    reg [3:0] tick_cnt;
    reg [3:0] bit_idx;
    reg [9:0] shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            tx <= 1;
            tx_busy <= 0;
            tick_cnt <= 0;
            bit_idx <= 0;
            shift_reg <= 10'h3FF;
        end else begin
            if (tx_start && !tx_busy) begin
                shift_reg <= {1'b1, tx_data, 1'b0};
                tx <= 0;
                tx_busy <= 1;
                tick_cnt <= 0;
                bit_idx <= 0;
            end else if (tx_busy && tick_16x) begin
                if (tick_cnt == 15) begin
                    tick_cnt <= 0;
                    bit_idx <= bit_idx + 1;
                    if (bit_idx == 9) begin
                        tx_busy <= 0;
                        tx <= 1;
                    end else begin
                        shift_reg <= {1'b1, shift_reg[9:1]};
                        tx <= shift_reg[1];
                    end
                end else
                    tick_cnt <= tick_cnt + 1;
            end
        end
    end
endmodule
