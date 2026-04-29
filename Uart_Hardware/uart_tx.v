`timescale 1ns / 1ps

module uart_tx #(
    parameter CLKS_PER_BIT = 868 
)(
    input  wire clk,         
    input  wire rst,         
    input  wire tx_start,    
    input  wire [7:0] tx_data, 
    output reg  tx,          
    output reg  tx_busy      
);

    localparam IDLE  = 1'b0;
    localparam TXING = 1'b1;

    reg state = IDLE;
    reg [9:0] shift_reg = 10'b1111111111;
    reg [3:0] bit_idx = 0;
    reg [15:0] clk_cnt = 0; 

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            tx        <= 1'b1;     
            tx_busy   <= 1'b0;
            clk_cnt   <= 0;
            bit_idx   <= 0;
            shift_reg <= 10'b1111111111;
        end else begin
            case (state)
                IDLE: begin
                    tx      <= 1'b1;
                    tx_busy <= 1'b0;
                    clk_cnt <= 0;
                    bit_idx <= 0;

                    if (tx_start) begin
                        shift_reg <= {1'b1, tx_data, 1'b0};
                        tx        <= 1'b0; 
                        tx_busy   <= 1'b1;
                        state     <= TXING;
                    end
                end

                TXING: begin
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        shift_reg <= {1'b1, shift_reg[9:1]};
                        tx <= shift_reg[1]; 
                        bit_idx <= bit_idx + 1;

                        if (bit_idx == 9) begin
                            state   <= IDLE;
                            tx_busy <= 1'b0;
                        end
                    end
                end
            endcase
        end
    end
endmodule