`timescale 1ns / 1ps

module spi_master (
    input  wire clk,           // 100 MHz System Clock
    input  wire rst,
    input  wire start,         // Trigger to send data
    input  wire [15:0] data_in,// 16-bit payload for MAX7219
    output reg  mosi,          // Master Out Slave In
    output reg  sck,           // Serial Clock
    output reg  cs,            // Chip Select (Active Low)
    output reg  busy           // High while transmitting
);

    // Clock Divider: 100MHz / 20 = 5MHz SPI Clock
    reg [4:0] clk_div = 0;
    wire spi_tick = (clk_div == 19);

    reg [15:0] shift_reg;
    reg [4:0] bit_cnt;
    reg [1:0] state;

    localparam IDLE  = 2'd0;
    localparam LOW   = 2'd1;
    localparam HIGH  = 2'd2;
    localparam LATCH = 2'd3;

    always @(posedge clk) begin
        if (rst) begin
            mosi <= 1'b0;
            sck  <= 1'b0;
            cs   <= 1'b1;  // CS is Active LOW, so default is HIGH
            busy <= 1'b0;
            state <= IDLE;
            clk_div <= 0;
        end else begin
            case (state)
                IDLE: begin
                    sck <= 1'b0;
                    cs  <= 1'b1;
                    busy <= 1'b0;
                    if (start) begin
                        shift_reg <= data_in;
                        bit_cnt <= 16;
                        busy <= 1'b1;
                        cs   <= 1'b0; // Pull CS low to start transmission
                        clk_div <= 0;
                        state <= LOW;
                    end
                end

                LOW: begin
                    clk_div <= clk_div + 1;
                    if (spi_tick) begin
                        sck  <= 1'b0;
                        mosi <= shift_reg[15]; // Shift out MSB
                        clk_div <= 0;
                        state <= HIGH;
                    end
                end

                HIGH: begin
                    clk_div <= clk_div + 1;
                    if (spi_tick) begin
                        sck <= 1'b1; // Clock goes high (MAX7219 reads data here)
                        shift_reg <= {shift_reg[14:0], 1'b0}; // Shift left
                        clk_div <= 0;
                        bit_cnt <= bit_cnt - 1;
                        if (bit_cnt == 1) state <= LATCH;
                        else state <= LOW;
                    end
                end

                LATCH: begin
                    clk_div <= clk_div + 1;
                    if (spi_tick) begin
                        sck <= 1'b0;
                        cs  <= 1'b1; // Pull CS high to latch the data into MAX7219
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule