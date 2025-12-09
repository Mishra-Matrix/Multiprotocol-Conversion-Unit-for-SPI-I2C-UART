`timescale 1ns / 1ps
module uart_to_spi_bridge #(
    parameter CLOCK_FREQ = 1000000,
    parameter BAUDRATE   = 1250
)(
    input  wire clk,
    input  wire usb_rx,
    output wire usb_tx,
    output wire MOSI,
    output wire SCLK,
    output wire CS
);

    wire clk_16x;
    wire rx_rdy;
    reg  rx_rdy_clr = 0;
    wire [7:0] rx_data;
    wire tx_busy;
    reg  tx_start = 0;
    reg [7:0] tx_data = 8'd0;
    wire spi_clk_en;
    reg  spi_start = 0;
    reg [7:0] spi_data_in = 8'd0;
    wire [7:0] spi_data_out;
    wire spi_done;

    reg [7:0] captured;
    reg [2:0] state = 0;

    uart_16x_baud #(.CLOCK_FREQ(CLOCK_FREQ), .BAUDRATE(BAUDRATE)) baudgen (
        .clk(clk),
        .clk_16x(clk_16x)
    );

    uart_rx u_rx (
        .clk(clk),
        .clk_16x(clk_16x),
        .rdy_clr(rx_rdy_clr),
        .rx(usb_rx),
        .rdy(rx_rdy),
        .data(rx_data)
    );

    uart_tx #(.BAUD_TICK_COUNT(16)) u_tx (
        .clk(clk),
        .clk_16x(clk_16x),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(usb_tx),
        .tx_busy(tx_busy)
    );

    spi_clk_divider #(.DIVISOR(4)) clkdiv (.clk(clk), .spi_clk_en(spi_clk_en));

    wire internal_MOSI;
    wire internal_MISO = internal_MOSI;

    spi_master spi (
        .clk(clk),
        .spi_clk_en(spi_clk_en),
        .start(spi_start),
        .data_in(spi_data_in),
        .data_out(spi_data_out),
        .MOSI(internal_MOSI),
        .MISO(internal_MISO),
        .SCLK(SCLK),
        .CS(CS),
        .done(spi_done)
    );

    assign MOSI = internal_MOSI;

    always @(posedge clk) begin
        rx_rdy_clr <= 0;
        tx_start <= 0;
        spi_start <= 0;

        case(state)
            3'd0: begin
                if(rx_rdy) begin
                    captured <= rx_data;
                    rx_rdy_clr <= 1;
                    state <= 3'd1;
                end
            end
            3'd1: begin
                spi_data_in <= captured;
                spi_start <= 1;
                state <= 3'd2;
            end
            3'd2: begin
                if(spi_done) begin
                    tx_data <= spi_data_out;
                    state <= 3'd3;
                end
            end
            3'd3: begin
                if(!tx_busy) begin
                    tx_start <= 1;
                    state <= 3'd4;
                end
            end
            3'd4: begin
                if(!tx_busy) state <= 3'd0;
            end
        endcase
    end
endmodule