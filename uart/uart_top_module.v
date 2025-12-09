`timescale 1ns / 1ps
module uart_loopback_top (
    input  wire clk,        // 100 MHz system clock
    input  wire usb_rx,     // FTDI RX (PC -> FPGA)
    output wire usb_tx      // FTDI TX (FPGA -> PC)
);

    wire clk_16x;
    wire rdy;
    reg  rdy_clr = 0;
    wire [7:0] rx_data;

    reg tx_start = 0;
    wire tx_busy;
    reg [7:0] tx_data = 0;

    // Generate 16x clock for 625000 baud
    uart_16x_baud #(
        .CLOCK_FREQ(100_000_000),
        .BAUDRATE(625000)
    ) baud_gen (
        .clk(clk),
        .clk_16x(clk_16x)
    );

    // UART Receiver
    uart_rx rx_core (
        .rx(usb_rx),
        .clk_16x_bps(clk_16x),
        .rdy(rdy),
        .rdy_clr(rdy_clr),
        .data(rx_data)
    );

    // UART Transmitter
    uart_tx tx_core (
        .clk_16x(clk_16x),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(usb_tx),
        .tx_busy(tx_busy)
    );

    // Loopback logic
    always @(posedge clk) begin
        tx_start <= 0;

        if (rdy) begin
            if (!tx_busy) begin
                tx_data <= rx_data;  
                tx_start <= 1;       
            end
            rdy_clr <= 1;
        end else begin
            rdy_clr <= 0;
        end
    end

endmodule