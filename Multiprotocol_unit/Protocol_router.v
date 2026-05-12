`timescale 1ns / 1ps

module protocol_router (
    input  wire clk,
    input  wire rst,
    input  wire [1:0] sw,

    // The 3 Input Protocols
    input  wire uart_rx_valid, input  wire [7:0] uart_rx_data,
    input  wire i2c_rx_valid,  input  wire [7:0] i2c_rx_data,
    input  wire spi_rx_valid,  input  wire [7:0] spi_rx_data,

    // The 3 Output Triggers
    output reg  uart_tx_start,
    output reg  i2c_draw_pulse,
    output reg  spi_draw_pulse,
    output reg  [7:0] routed_data
);

    // Detect if ANY input protocol received a byte
    wire any_rx_valid = uart_rx_valid | i2c_rx_valid | spi_rx_valid;
    
    // Grab whichever byte just arrived
    wire [7:0] latest_rx_data = uart_rx_valid ? uart_rx_data :
                                i2c_rx_valid  ? i2c_rx_data :
                                                spi_rx_data;

    always @(posedge clk) begin
        if (rst) begin
            uart_tx_start  <= 1'b0;
            i2c_draw_pulse <= 1'b0;
            spi_draw_pulse <= 1'b0;
            routed_data    <= 8'h00;
        end else begin
            // Default all triggers to 0
            uart_tx_start  <= 1'b0;
            i2c_draw_pulse <= 1'b0;
            spi_draw_pulse <= 1'b0;

            if (any_rx_valid) begin
                routed_data <= latest_rx_data; 
                
                // Route the data based on the switches
                case (sw)
                    2'b00: uart_tx_start  <= 1'b1; // To PC (UART)
                    2'b01: i2c_draw_pulse <= 1'b1; // To OLED (I2C)
                    2'b10: spi_draw_pulse <= 1'b1; // To Matrix (SPI)
                    2'b11: begin                   // BROADCAST MODE!
                        uart_tx_start  <= 1'b1;
                        i2c_draw_pulse <= 1'b1;
                        spi_draw_pulse <= 1'b1;
                    end
                endcase
            end
        end
    end
endmodule