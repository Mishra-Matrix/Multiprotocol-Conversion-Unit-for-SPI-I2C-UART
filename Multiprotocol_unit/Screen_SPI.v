`timescale 1ns / 1ps

module max7219_controller (
    input  wire clk,
    input  wire rst,
    input  wire draw_trigger,     
    input  wire [7:0] ascii_char, 
    
    output reg  matrix_busy,      
    
    // Connections to the raw SPI Master
    input  wire spi_busy,
    output reg  spi_start,
    output reg  [15:0] spi_data
);

    // Boot-up Configuration sequence for MAX7219
    reg [15:0] init_rom [0:4];
    initial begin
        init_rom[0] = 16'h09_00; // Decode Mode: No decode
        init_rom[1] = 16'h0A_07; // Intensity: Medium (0-15)
        init_rom[2] = 16'h0B_07; // Scan Limit: Display all 8 digits/rows
        init_rom[3] = 16'h0C_01; // Shutdown Reg: Normal Operation
        init_rom[4] = 16'h0F_00; // Display Test: OFF
    end

    wire [63:0] font_pixels;
    font8x8_rom FONT_MEM (
        .ascii_char(ascii_char),
        .pixel_data(font_pixels)
    );

    localparam BOOT       = 3'd0;
    localparam INIT       = 3'd1;
    localparam IDLE       = 3'd2;
    localparam FETCH      = 3'd3;
    localparam DRAW_ROW   = 3'd4;
    localparam WAIT_SPI   = 3'd5;

    reg [2:0] state = BOOT;
    reg [2:0] return_state = IDLE;
    reg [2:0] init_idx = 0;
    reg [3:0] row_idx = 1; // MAX7219 rows are addressed 1 to 8
    reg [63:0] active_pixels;

    always @(posedge clk) begin
        if (rst) begin
            state <= BOOT;
            matrix_busy <= 1'b1;
            spi_start <= 1'b0;
            init_idx <= 0;
            row_idx <= 1;
        end else begin
            spi_start <= 1'b0; // Default trigger to 0

            case (state)
                BOOT: begin
                    if (!spi_busy) state <= INIT;
                end
                
                INIT: begin
                    if (!spi_busy) begin
                        spi_data  <= init_rom[init_idx];
                        spi_start <= 1'b1;
                        return_state <= (init_idx == 4) ? IDLE : INIT;
                        if (init_idx < 4) init_idx <= init_idx + 1;
                        state <= WAIT_SPI;
                    end
                end

                IDLE: begin
                    matrix_busy <= 1'b0;
                    if (draw_trigger) begin
                        matrix_busy <= 1'b1;
                        state <= FETCH;
                    end
                end

                FETCH: begin
                    active_pixels <= font_pixels;
                    row_idx <= 1; // Start at Row 1
                    state <= DRAW_ROW;
                end

                DRAW_ROW: begin
                    if (!spi_busy) begin
                        // MAX7219 Format: [15:8] = Row Address, [7:0] = Pixel Data
                        spi_data[15:8] <= {4'b0000, row_idx}; 
                        
                        // Pick the correct 8 bits based on the row we are drawing
                        case (row_idx)
                            1: spi_data[7:0] <= active_pixels[63:56];
                            2: spi_data[7:0] <= active_pixels[55:48];
                            3: spi_data[7:0] <= active_pixels[47:40];
                            4: spi_data[7:0] <= active_pixels[39:32];
                            5: spi_data[7:0] <= active_pixels[31:24];
                            6: spi_data[7:0] <= active_pixels[23:16];
                            7: spi_data[7:0] <= active_pixels[15:8];
                            8: spi_data[7:0] <= active_pixels[7:0];
                        endcase
                        
                        spi_start <= 1'b1;
                        return_state <= (row_idx == 8) ? IDLE : DRAW_ROW;
                        if (row_idx < 8) row_idx <= row_idx + 1;
                        state <= WAIT_SPI;
                    end
                end

                WAIT_SPI: begin
                    if (spi_busy) begin
                        // Wait while SPI is actively sending
                    end else if (!spi_start) begin 
                        state <= return_state; // Go back to INIT, DRAW, or IDLE
                    end
                end
            endcase
        end
    end
endmodule