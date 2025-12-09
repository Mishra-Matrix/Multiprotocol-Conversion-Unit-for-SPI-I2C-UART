`timescale 1ns / 1ps

module spi_clk_divider #(
    parameter DIVISOR = 50
)(
    input  wire clk,
    output reg  spi_clk_en
);

    reg [15:0] count = 0;

    always @(posedge clk) begin
        if(count == DIVISOR-1) begin
            count <= 0;
            spi_clk_en <= 1;
        end else begin
            count <= count + 1;
            spi_clk_en <= 0;
        end
    end

endmodule