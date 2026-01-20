`timescale 1ns / 1ps
module spi_loopback_top (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [3:0] data_in,   // switches
    input  wire MISO,            // from PMOD (loopback)
    output wire MOSI,
    output wire SCLK,
    output wire CS,
    output wire [3:0] LED        // LEDs show received data
);

    wire spi_clk_en;
    wire [3:0] data_out;

    // SPI clock divider
    spi_clk_divider #(
        .DIVISOR(50)
    ) u_div (
        .clk(clk),
        .rst(rst),
        .spi_clk_en(spi_clk_en)
    );

    // SPI master
    spi_master1 #(
        .WIDTH(4)
    ) u_spi (
        .clk(clk),
        .rst(rst),
        .spi_clk_en(spi_clk_en),
        .start(start),
        .data_in(data_in),
        .data_out(data_out),
        .MOSI(MOSI),
        .MISO(MISO),
        .SCLK(SCLK),
        .CS(CS),
        .busy(),
        .done()   // not used
    );

    // 🔹 Show received SPI data on LEDs
    assign LED = data_out;

endmodule
