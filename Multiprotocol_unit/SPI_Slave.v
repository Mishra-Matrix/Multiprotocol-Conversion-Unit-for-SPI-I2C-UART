`timescale 1ns / 1ps

module spi_slave (
    input  wire clk,         // FPGA 100MHz Clock
    input  wire rst,
    
    // Asynchronous inputs from Arduino SPI Master
    input  wire sck_in,
    input  wire mosi_in,
    input  wire cs_in,
    
    // Synchronous outputs to your Router
    output reg  rx_valid,
    output reg  [7:0] rx_data
);

    // --- 1. CROSS-CLOCK DOMAIN SYNCHRONIZERS ---
    reg [2:0] sck_sync;
    reg [2:0] cs_sync;
    reg [1:0] mosi_sync;

    always @(posedge clk) begin
        sck_sync  <= {sck_sync[1:0], sck_in};
        cs_sync   <= {cs_sync[1:0], cs_in};
        mosi_sync <= {mosi_sync[0], mosi_in};
    end

    // Detect the exact nanosecond the Arduino SCK rises
    wire sck_rising = (sck_sync[2:1] == 2'b01);
    
    // CS is active low
    wire cs_active  = ~cs_sync[1]; 

    // --- 2. THE RECEIVER LOGIC ---
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            bit_cnt  <= 0;
            rx_valid <= 0;
            rx_data  <= 0;
        end else begin
            rx_valid <= 1'b0; // Default pulse low

            if (cs_active) begin
                if (sck_rising) begin
                    // Shift the new bit in from the right
                    shift_reg <= {shift_reg[6:0], mosi_sync[1]};
                    bit_cnt <= bit_cnt + 1;
                    
                    // If we just received the 8th bit, package it up!
                    if (bit_cnt == 7) begin
                        rx_data  <= {shift_reg[6:0], mosi_sync[1]};
                        rx_valid <= 1'b1;
                    end
                end
            end else begin
                // If Chip Select is pulled high, reset the counter
                bit_cnt <= 0;
            end
        end
    end
endmodule