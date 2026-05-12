`timescale 1ns / 1ps
module font_rom (
    input  wire [7:0] ascii_char,
    output reg  [39:0] pixel_data 
);
    always @(*) begin
        case (ascii_char)
            8'h41: pixel_data = 40'h7E_11_11_11_7E; // 'A'
            8'h42: pixel_data = 40'h7F_49_49_49_36; // 'B'
            8'h43: pixel_data = 40'h3E_41_41_41_22; // 'C'
            8'h44: pixel_data = 40'h7F_41_41_22_1C; // 'D'
            8'h45: pixel_data = 40'h7F_49_49_49_41; // 'E'
            default: pixel_data = 40'h00_00_00_00_00; 
        endcase
    end
endmodule