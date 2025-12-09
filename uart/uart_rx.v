`timescale 1ns / 1ps
module uart_rx (
    input wire rx,
    input wire clk_16x_bps,
    input wire rdy_clr,
    output reg rdy,
    output reg [7:0] data
);
    parameter RX_STATE_IDLE  = 2'b00;
    parameter RX_STATE_START = 2'b01;
    parameter RX_STATE_DATA  = 2'b10;
    parameter RX_STATE_STOP  = 2'b11;

    reg [1:0] state = RX_STATE_IDLE;
    reg [3:0] sample = 0;
    reg [2:0] bitpos = 0;
    reg [7:0] scratch = 0;

    initial begin
        rdy = 0;
        data = 0;
    end

    always @(posedge clk_16x_bps) begin
        if (rdy_clr)
            rdy <= 0;

        case (state)
            RX_STATE_IDLE: begin
                if (rx == 1'b0) begin
                    state <= RX_STATE_START;
                    sample <= 0;
                end
            end

            RX_STATE_START: begin
                sample <= sample + 1;
                if (sample == 4'd7) begin
                    state <= RX_STATE_DATA;
                    sample <= 0;
                    bitpos <= 0;
                end
            end

            RX_STATE_DATA: begin
                sample <= sample + 1;
                if (sample == 4'd8) begin
                    scratch[bitpos] <= rx;
                end
                if (sample == 4'd15) begin
                    sample <= 0;
                    if (bitpos == 3'd7)
                        state <= RX_STATE_STOP;
                    else
                        bitpos <= bitpos + 1;
                end
            end

            RX_STATE_STOP: begin
                sample <= sample + 1;
                if (sample == 4'd15) begin
                    data <= scratch;
                    rdy <= 1;
                    state <= RX_STATE_IDLE;
                    sample <= 0;
                end
            end
        endcase
    end
endmodule