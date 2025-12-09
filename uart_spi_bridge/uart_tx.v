`timescale 1ns / 1ps
module uart_tx #(
    parameter BAUD_TICK_COUNT = 16
)(
    input  wire clk,
    input  wire clk_16x,
    input  wire tx_start,
    input  wire [7:0] tx_data,
    output reg  tx,
    output reg  tx_busy
);

    reg [3:0] bit_idx = 0;
    reg [3:0] tick_cnt = 0;
    reg [9:0] shift_reg = 10'b1111111111;
    reg clk16_d = 0;
    wire clk16_tick = (clk_16x & ~clk16_d);

    initial begin
        tx = 1;
        tx_busy = 0;
    end

    always @(posedge clk) begin
        clk16_d <= clk_16x;

        if (!tx_busy) begin
            if (tx_start) begin
                shift_reg <= {1'b1, tx_data, 1'b0};
                tx_busy <= 1;
                bit_idx <= 0;
                tick_cnt <= 0;
            end
        end else begin
            if (clk16_tick) begin
                tick_cnt <= tick_cnt + 1;
                if (tick_cnt == BAUD_TICK_COUNT - 1) begin
                    tick_cnt <= 0;
                    tx <= shift_reg[0];
                    shift_reg <= {1'b1, shift_reg[9:1]};
                    bit_idx <= bit_idx + 1;
                    if (bit_idx == 9) begin
                        tx_busy <= 0;
                        tx <= 1;
                    end
                end
            end
        end
    end
endmodule