`timescale 1ns / 1ps
module uart_rx (
    input  wire clk,
    input  wire rst,
    input  wire rx,
    input  wire tick_16x,
    input  wire rdy_clr,
    output reg  rdy,
    output reg  [7:0] data
);
    localparam IDLE=0, START=1, DATA=2, STOP=3;

    reg [1:0] state;
    reg [3:0] sample_cnt;
    reg [2:0] bit_idx;
    reg [7:0] scratch;
    reg rx_sync1, rx_sync2;

    always @(posedge clk) begin
        rx_sync1 <= rx;
        rx_sync2 <= rx_sync1;
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            rdy <= 0;
            sample_cnt <= 0;
            bit_idx <= 0;
            data <= 0;
            scratch <= 0;
        end else begin
            if (rdy_clr)
                rdy <= 0;

            if (tick_16x) begin
                case (state)
                    IDLE: begin
                        if (rx_sync2 == 0) begin
                            state <= START;
                            sample_cnt <= 0;
                        end
                    end

                    START: begin
                        if (sample_cnt == 7) begin
                            state <= DATA;
                            sample_cnt <= 0;
                            bit_idx <= 0;
                        end else
                            sample_cnt <= sample_cnt + 1;
                    end

                    DATA: begin
                        if (sample_cnt == 15) begin
                            sample_cnt <= 0;
                            scratch[bit_idx] <= rx_sync2;
                            if (bit_idx == 7)
                                state <= STOP;
                            else
                                bit_idx <= bit_idx + 1;
                        end else
                            sample_cnt <= sample_cnt + 1;
                    end

                    STOP: begin
                        if (sample_cnt == 15) begin
                            if (rx_sync2 == 1) begin
                                data <= scratch;
                                rdy <= 1;
                            end
                            state <= IDLE;
                            sample_cnt <= 0;
                        end else
                            sample_cnt <= sample_cnt + 1;
                    end
                endcase
            end
        end
    end
endmodule
