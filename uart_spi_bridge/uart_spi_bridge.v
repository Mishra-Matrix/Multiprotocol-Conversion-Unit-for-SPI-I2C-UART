`timescale 1ns / 1ps
module uart_spi_bridge (
    input  wire clk,
    input  wire rst_btn,
    input  wire usb_rx,
    output wire usb_tx,
    output wire MOSI,
    input  wire MISO,
    output wire SCLK,
    output wire CS
);
    wire rst = rst_btn;

    wire tick_16x;
    wire rx_rdy;
    reg  rx_rdy_clr;
    wire [7:0] rx_data;
    reg  [7:0] rx_buf;

    wire spi_clk_en;
    reg  spi_start;
    wire spi_busy;
    wire spi_done;
    wire [7:0] spi_rx_data;

    reg  tx_start;
    wire tx_busy;
    reg  [7:0] tx_data;

    localparam S_IDLE=0, S_SPI=1, S_TX=2;
    reg [1:0] state;

    uart_baud_tick baud_gen (.clk(clk), .rst(rst), .tick_16x(tick_16x));

    uart_rx rx_mod (
        .clk(clk), .rst(rst), .rx(usb_rx),
        .tick_16x(tick_16x), .rdy(rx_rdy),
        .rdy_clr(rx_rdy_clr), .data(rx_data)
    );

    spi_clk_divider spi_div (.clk(clk), .rst(rst), .spi_clk_en(spi_clk_en));

    spi_master1 spi_mod (
        .clk(clk), .rst(rst), .spi_clk_en(spi_clk_en),
        .start(spi_start), .data_in(rx_buf),
        .data_out(spi_rx_data), .MOSI(MOSI),
        .MISO(MISO), .SCLK(SCLK), .CS(CS),
        .busy(spi_busy), .done(spi_done)
    );

    uart_tx tx_mod (
        .clk(clk), .rst(rst), .tick_16x(tick_16x),
        .tx_start(tx_start), .tx_data(tx_data),
        .tx(usb_tx), .tx_busy(tx_busy)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            rx_rdy_clr <= 0;
            spi_start <= 0;
            tx_start <= 0;
            tx_data <= 0;
            rx_buf <= 0;
        end else begin
            rx_rdy_clr <= 0;
            spi_start <= 0;
            tx_start <= 0;

            case (state)
                S_IDLE: begin
                    if (rx_rdy && !spi_busy) begin
                        rx_buf <= rx_data;
                        rx_rdy_clr <= 1;
                        spi_start <= 1;
                        state <= S_SPI;
                    end
                end

                S_SPI: begin
                    if (spi_done) begin
                        tx_data <= spi_rx_data;
                        tx_start <= 1;
                        state <= S_TX;
                    end
                end

                S_TX: begin
                    if (!tx_busy)
                        state <= S_IDLE;
                end
            endcase
        end
    end
endmodule
