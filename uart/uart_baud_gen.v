`timescale 1ns / 1ps
module uart_16x_baud #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUDRATE   = 625000
)(
    input  wire clk,
    output reg  clk_16x
);

    localparam integer DIVIDER = CLOCK_FREQ / (BAUDRATE * 16);
    integer counter = 0;

    always @(posedge clk) begin
        if (counter == DIVIDER - 1) begin
            counter <= 0;
            clk_16x <= 1;
        end else begin
            counter <= counter + 1;
            clk_16x <= 0;
        end
    end
endmodule