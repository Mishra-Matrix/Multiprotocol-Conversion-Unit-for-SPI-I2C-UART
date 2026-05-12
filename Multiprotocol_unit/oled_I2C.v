`timescale 1ns / 1ps
module oled_controller (
    input  wire clk,
    input  wire rst,
    input  wire draw_trigger,
    input  wire [7:0] ascii_char,
    output reg  oled_busy,
    input  wire i2c_busy,
    output reg  i2c_start,
    output reg  [7:0] i2c_ctrl,
    output reg  [7:0] i2c_data
);

    reg [7:0] init_rom [0:14];
    initial begin
        init_rom[0]  = 8'hAE; init_rom[1]  = 8'hD5; init_rom[2]  = 8'h80;
        init_rom[3]  = 8'hA8; init_rom[4]  = 8'h3F; init_rom[5]  = 8'hD3;
        init_rom[6]  = 8'h00; init_rom[7]  = 8'h40; init_rom[8]  = 8'h8D;
        init_rom[9]  = 8'h14; init_rom[10] = 8'h20; init_rom[11] = 8'h00;
        init_rom[12] = 8'hA1; init_rom[13] = 8'hC8; init_rom[14] = 8'hAF;
    end

    wire [39:0] font_pixels;
    font_rom FONT_MEM (
        .ascii_char(ascii_char),
        .pixel_data(font_pixels)
    );

    localparam STATE_BOOT     = 3'd0;
    localparam STATE_INIT     = 3'd1;
    localparam STATE_IDLE     = 3'd2;
    localparam STATE_FETCH    = 3'd3;
    localparam STATE_DRAW     = 3'd4;
    localparam STATE_WAIT_I2C = 3'd5;

    reg [2:0] state = STATE_BOOT;
    reg [2:0] return_state = STATE_IDLE;
    
    reg [3:0] init_idx = 0;
    reg [2:0] col_idx = 0;
    reg [39:0] active_pixels = 0;

    always @(posedge clk) begin
        if (rst) begin
            state     <= STATE_BOOT;
            oled_busy <= 1'b1; 
            i2c_start <= 1'b0;
            init_idx  <= 0;
            col_idx   <= 0;
        end else begin
            i2c_start <= 1'b0; 

            case (state)
                STATE_BOOT: begin
                    if (!i2c_busy) state <= STATE_INIT;
                end
                STATE_INIT: begin
                    if (!i2c_busy) begin
                        i2c_ctrl  <= 8'h00; 
                        i2c_data  <= init_rom[init_idx];
                        i2c_start <= 1'b1;
                        return_state <= (init_idx == 14) ? STATE_IDLE : STATE_INIT;
                        if (init_idx < 14) init_idx <= init_idx + 1;
                        state <= STATE_WAIT_I2C;
                    end
                end
                STATE_IDLE: begin
                    oled_busy <= 1'b0;
                    if (draw_trigger) begin
                        oled_busy <= 1'b1;
                        state     <= STATE_FETCH;
                    end
                end
                STATE_FETCH: begin
                    active_pixels <= font_pixels;
                    col_idx       <= 0;
                    state         <= STATE_DRAW;
                end
                STATE_DRAW: begin
                    if (!i2c_busy) begin
                        i2c_ctrl  <= 8'h40; 
                        case (col_idx)
                            0: i2c_data <= active_pixels[39:32];
                            1: i2c_data <= active_pixels[31:24];
                            2: i2c_data <= active_pixels[23:16];
                            3: i2c_data <= active_pixels[15:8];
                            4: i2c_data <= active_pixels[7:0];
                        endcase
                        i2c_start <= 1'b1;
                        return_state <= (col_idx == 4) ? STATE_IDLE : STATE_DRAW;
                        if (col_idx < 4) col_idx <= col_idx + 1;
                        state <= STATE_WAIT_I2C;
                    end
                end
                STATE_WAIT_I2C: begin
                    if (i2c_busy) begin
                    end else if (!i2c_start) begin 
                        state <= return_state;
                    end
                end
            endcase
        end
    end
endmodule