`timescale 1ns / 1ps

module font8x8_rom (
    input  wire [7:0] ascii_char,
    output reg  [63:0] pixel_data  // 8 rows of 8 pixels = 64 bits
);

    always @(*) begin
        case (ascii_char)
            // 8 rows top-to-bottom. 1 = LED ON, 0 = LED OFF
            8'h41: pixel_data = 64'h18_3C_66_66_7E_66_66_00; // 'A'
            8'h42: pixel_data = 64'h7C_66_66_7C_66_66_7C_00; // 'B'
            8'h43: pixel_data = 64'h3C_66_60_60_60_66_3C_00; // 'C'
            8'h44: pixel_data = 64'h78_6C_66_66_66_6C_78_00; // 'D'
            8'h45: pixel_data = 64'h7E_60_60_7C_60_60_7E_00; // 'E'
            8'h46: pixel_data = 64'h7E_60_60_7C_60_60_60_00; // 'F'
            8'h5A: pixel_data = 64'h7E_06_0C_18_30_60_7E_00; // 'Z'
            default: pixel_data = 64'h00_00_00_00_00_00_00_00; // Blank
        endcase
    end
endmodule