`timescale 1ns / 1ps
module top_uart_spi_bridge(
    input  wire clk,
    input  wire usb_rx,
    output wire usb_tx,
    output wire MOSI,
    output wire SCLK,
    output wire CS
);
    uart_to_spi_bridge #(.CLOCK_FREQ(100000000), .BAUDRATE(625000)) bridge(
        .clk(clk),
        .usb_rx(usb_rx),
        .usb_tx(usb_tx),
        .MOSI(MOSI),
        .SCLK(SCLK),
        .CS(CS)
    );
endmodule