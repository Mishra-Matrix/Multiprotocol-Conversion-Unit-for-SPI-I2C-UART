`timescale 1ns / 1ps
module uart_16x_baud #(
    parameter CLOCK_FREQ = 1000000,
    parameter BAUDRATE   = 1250
)(
    input  wire clk,
    output reg  clk_16x = 0
);

    localparam integer DIVIDER = CLOCK_FREQ / (BAUDRATE * 16);
    integer counter = 0;

    always @(posedge clk) begin
        if (counter == DIVIDER/2 - 1) begin
            clk_16x <= ~clk_16x;
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule