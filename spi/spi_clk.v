`timescale 1ns / 1ps
module spi_clk_divider #(
    parameter DIVISOR = 50
)(
    input  wire clk,
    input  wire rst,
    output reg  spi_clk_en
);
    reg [$clog2(DIVISOR)-1:0] count;

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            spi_clk_en <= 0;
        end else if (count == DIVISOR-1) begin
            count <= 0;
            spi_clk_en <= 1;
        end else begin
            count <= count + 1;
            spi_clk_en <= 0;
        end
    end
endmodule
