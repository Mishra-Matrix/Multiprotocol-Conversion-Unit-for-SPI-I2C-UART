`timescale 1ns / 1ps

module top_spi_loopback(
    input  wire clk,
    input  wire btn,
    input  wire [3:0] sw,
    output wire [3:0] led,

    output wire MOSI,
    output wire SCLK,
    output wire CS
);

    wire spi_clk_en;
    wire done;

    wire MISO;
    assign MISO = MOSI;

    spi_clk_divider clkdiv(
        .clk(clk),
        .spi_clk_en(spi_clk_en)
    );

    spi_master spi(
        .clk(clk),
        .spi_clk_en(spi_clk_en),
        .start(btn),
        .data_in(sw),
        .data_out(led),
        .MOSI(MOSI),
        .MISO(MISO),
        .SCLK(SCLK),
        .CS(CS),
        .done(done)
    );

endmodule