`timescale 1ns / 1ps
module uart_baud_tick (
    input  wire clk,
    input  wire rst,
    output reg  tick_16x
);
    localparam integer MAX_COUNT = 10;
    reg [3:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            tick_16x <= 0;
        end else if (counter == MAX_COUNT - 1) begin
            counter <= 0;
            tick_16x <= 1;
        end else begin
            counter <= counter + 1;
            tick_16x <= 0;
        end
    end
endmodule
