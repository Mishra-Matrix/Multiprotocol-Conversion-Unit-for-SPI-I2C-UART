`timescale 1ns / 1ps
module spi_master1 #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire spi_clk_en,
    input  wire start,
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out,
    output reg  MOSI,
    input  wire MISO,
    output reg  SCLK,
    output reg  CS,
    output reg  busy,
    output reg  done
);
    localparam IDLE=0, TRANS=1, END=2;

    reg [1:0] state;
    reg [WIDTH-1:0] shreg_tx, shreg_rx;
    reg [$clog2(WIDTH+1)-1:0] bit_cnt;
    reg miso_sync1, miso_sync2;

    always @(posedge clk) begin
        miso_sync1 <= MISO;
        miso_sync2 <= miso_sync1;
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            CS <= 1; SCLK <= 0; MOSI <= 0;
            busy <= 0; done <= 0; data_out <= 0;
            shreg_tx <= 0; shreg_rx <= 0; bit_cnt <= 0;
        end else begin
            done <= 0;
            case (state)
                IDLE: begin
                    CS <= 1; SCLK <= 0; busy <= 0;
                    if (start && !busy) begin
                        shreg_tx <= data_in;
                        shreg_rx <= 0;
                        bit_cnt <= WIDTH;
                        MOSI <= data_in[WIDTH-1];
                        CS <= 0;
                        busy <= 1;
                        state <= TRANS;
                    end
                end

                TRANS: begin
                    if (spi_clk_en) begin
                        SCLK <= ~SCLK;
                        if (SCLK == 0)
                            shreg_rx <= {shreg_rx[WIDTH-2:0], miso_sync2};
                        else begin
                            shreg_tx <= {shreg_tx[WIDTH-2:0], 1'b0};
                            MOSI <= shreg_tx[WIDTH-2];
                            bit_cnt <= bit_cnt - 1;
                            if (bit_cnt == 1)
                                state <= END;
                        end
                    end
                end

                END: begin
                    CS <= 1;
                    SCLK <= 0;
                    busy <= 0;
                    done <= 1;
                    data_out <= shreg_rx;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
