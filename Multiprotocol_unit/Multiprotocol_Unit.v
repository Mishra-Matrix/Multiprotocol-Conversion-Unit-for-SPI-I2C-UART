`timescale 1ns / 1ps

module multiprotocol_top (
    input  wire clk,
    input  wire rst_btn,      
    input  wire [1:0] sw,     

    // UART Only
    input  wire uart_rxd,     
    output wire uart_txd,     
    
    // PMOD JB: OLED Video Card (I2C)
    output wire oled_scl,     
    inout  wire oled_sda,

    // PMOD JC: Matrix Video Card (SPI)
    output wire matrix_mosi,
    output wire matrix_sck,
    output wire matrix_cs,

    output wire activity_led  
);

    wire rst = ~rst_btn;

    // --- 1. THE 3 RECEIVERS (INPUTS) ---
    wire w_uart_rx_valid; wire [7:0] w_uart_rx_data;
    uart_rx #(.CLKS_PER_BIT(10416)) UART_IN ( 
        .clk(clk), .rst(rst), .rx(uart_rxd),
        .rdy_clr(1'b0), .rdy(w_uart_rx_valid), .data(w_uart_rx_data)
    );

    wire w_i2c_rx_valid; wire [7:0] w_i2c_rx_data;
    i2c_slave I2C_IN (
        .clk(clk), .rst(rst), 
        .scl(arduino_scl), .sda(arduino_sda),
        .rx_valid(w_i2c_rx_valid), .rx_data(w_i2c_rx_data)
    );

    wire w_spi_rx_valid; wire [7:0] w_spi_rx_data;
    spi_slave SPI_IN (
        .clk(clk), .rst(rst),
        .sck_in(arduino_spi_sck), .mosi_in(arduino_spi_mosi), .cs_in(arduino_spi_cs),
        .rx_valid(w_spi_rx_valid), .rx_data(w_spi_rx_data)
    );

    // --- 2. THE 3x3 OMNI-ROUTER ---
    wire w_uart_tx_start, w_i2c_draw_pulse, w_spi_draw_pulse;
    wire [7:0] w_routed_data;
    
    protocol_router ROUTER (
        .clk(clk), .rst(rst), .sw(sw),
        .uart_rx_valid(w_uart_rx_valid), .uart_rx_data(w_uart_rx_data),
        .i2c_rx_valid(w_i2c_rx_valid),   .i2c_rx_data(w_i2c_rx_data),
        .spi_rx_valid(w_spi_rx_valid),   .spi_rx_data(w_spi_rx_data),
        .uart_tx_start(w_uart_tx_start), 
        .i2c_draw_pulse(w_i2c_draw_pulse),
        .spi_draw_pulse(w_spi_draw_pulse), 
        .routed_data(w_routed_data)
    );

    // --- 3. THE 3 TRANSMITTERS (OUTPUTS) ---
    wire w_uart_tx_busy; 
    uart_tx #(.CLKS_PER_BIT(10416)) UART_OUT ( 
        .clk(clk), .rst(rst),
        .tx_start(w_uart_tx_start), .tx_data(w_routed_data),
        .tx(uart_txd), .tx_busy(w_uart_tx_busy) 
    );

    wire w_i2c_busy, w_i2c_start; wire [7:0] w_i2c_ctrl, w_i2c_data; wire w_oled_busy;
    i2c_master I2C_OUT_CORE (
        .clk(clk), .rst(rst),
        .i2c_start(w_i2c_start), .i2c_ctrl(w_i2c_ctrl), .i2c_data(w_i2c_data),
        .i2c_busy(w_i2c_busy), .i2c_scl(oled_scl), .i2c_sda(oled_sda)
    );
    oled_controller OLED_CORE (
        .clk(clk), .rst(rst),
        .draw_trigger(w_i2c_draw_pulse), .ascii_char(w_routed_data),
        .oled_busy(w_oled_busy), .i2c_busy(w_i2c_busy),
        .i2c_start(w_i2c_start), .i2c_ctrl(w_i2c_ctrl), .i2c_data(w_i2c_data)
    );

    wire w_spi_busy, w_spi_start; wire [15:0] w_spi_data; wire w_matrix_busy;
    spi_master SPI_OUT_CORE (
        .clk(clk), .rst(rst),
        .start(w_spi_start), .data_in(w_spi_data),
        .mosi(matrix_mosi), .sck(matrix_sck), .cs(matrix_cs),
        .busy(w_spi_busy)
    );
    max7219_controller MATRIX_CORE (
        .clk(clk), .rst(rst),
        .draw_trigger(w_spi_draw_pulse), .ascii_char(w_routed_data),
        .matrix_busy(w_matrix_busy),
        .spi_busy(w_spi_busy), .spi_start(w_spi_start), .spi_data(w_spi_data)
    );

    // --- 4. ACTIVITY LED ---
    reg r_led_state = 1'b0;
    reg r_uart_busy_prev = 1'b0, r_oled_busy_prev = 1'b0, r_matrix_busy_prev = 1'b0;

    always @(posedge clk) begin
        r_uart_busy_prev   <= w_uart_tx_busy;
        r_oled_busy_prev   <= w_oled_busy;
        r_matrix_busy_prev <= w_matrix_busy;

        if (rst) r_led_state <= 1'b0;
        else if (w_uart_rx_valid | w_i2c_rx_valid | w_spi_rx_valid) r_led_state <= 1'b1; 
        else if ((r_uart_busy_prev && !w_uart_tx_busy) || 
                 (r_oled_busy_prev && !w_oled_busy) ||
                 (r_matrix_busy_prev && !w_matrix_busy)) r_led_state <= 1'b0; 
    end
    assign activity_led = r_led_state;
endmodule