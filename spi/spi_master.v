`timescale 1ns / 1ps

module spi_master(
    input  wire clk,
    input  wire spi_clk_en,
    input  wire start,
    input  wire [3:0] data_in,

    output reg  [3:0] data_out,
    output reg MOSI,
    input  wire MISO,
    output reg SCLK,
    output reg CS,
    output reg done
);

    localparam IDLE = 0,
               LOAD = 1,
               SHIFT = 2,
               END_STATE = 3;

    reg [1:0] state = IDLE;
    reg [3:0] shift_reg;
    reg [2:0] bit_count = 0;

    always @(posedge clk) begin
        done <= 0;

        case(state)

            IDLE: begin
                CS <= 1;
                SCLK <= 0;
                if(start) begin
                    shift_reg <= data_in;
                    bit_count <= 3;
                    state <= LOAD;
                end
            end

            LOAD: begin
                CS <= 0;
                MOSI <= shift_reg[3];
                state <= SHIFT;
            end

            SHIFT: begin
                if(spi_clk_en) begin
                    SCLK <= ~SCLK;
                    if(SCLK == 1) begin
                        shift_reg[bit_count] <= MISO;
                        if(bit_count == 0) begin
                            data_out <= shift_reg;
                            state <= END_STATE;
                        end else begin
                            bit_count <= bit_count - 1;
                        end
                    end else begin
                        MOSI <= shift_reg[bit_count];
                    end
                end
            end

            END_STATE: begin
                CS <= 1;
                SCLK <= 0;
                done <= 1;
                state <= IDLE;
            end

        endcase
    end

endmodule