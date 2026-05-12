`timescale 1ns / 1ps
module uart_rx #(
    parameter CLKS_PER_BIT = 868 
)(
    input  wire clk,      
    input  wire rst,      
    input  wire rx,       
    input  wire rdy_clr,  
    output reg  rdy,      
    output reg  [7:0] data 
);

    reg rx_sync_1 = 1'b1;
    reg rx_sync_2 = 1'b1;

    always @(posedge clk) begin
        rx_sync_1 <= rx;
        rx_sync_2 <= rx_sync_1; 
    end

    localparam RX_STATE_IDLE  = 2'b00;
    localparam RX_STATE_START = 2'b01;
    localparam RX_STATE_DATA  = 2'b10;
    localparam RX_STATE_STOP  = 2'b11;

    reg [1:0] state = RX_STATE_IDLE;
    reg [15:0] clk_cnt = 0;
    reg [2:0] bit_idx = 0;
    reg [7:0] scratch = 0;

    always @(posedge clk) begin
        if (rst) begin
            state   <= RX_STATE_IDLE;
            rdy     <= 1'b0;
            data    <= 8'd0;
            clk_cnt <= 0;
            bit_idx <= 0;
            scratch <= 8'd0;
        end else begin
            if (rdy_clr) rdy <= 1'b0;

            case (state)
                RX_STATE_IDLE: begin
                    rdy     <= 1'b0;
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (rx_sync_2 == 1'b0) begin
                        state <= RX_STATE_START;
                    end
                end

                RX_STATE_START: begin
                    if (clk_cnt == (CLKS_PER_BIT / 2)) begin
                        if (rx_sync_2 == 1'b0) begin
                            clk_cnt <= 0; 
                            state   <= RX_STATE_DATA;
                        end else begin
                            state   <= RX_STATE_IDLE; 
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                RX_STATE_DATA: begin
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        scratch[bit_idx] <= rx_sync_2; 
                        
                        if (bit_idx < 7) begin
                            bit_idx <= bit_idx + 1;
                        end else begin
                            bit_idx <= 0;
                            state   <= RX_STATE_STOP;
                        end
                    end
                end

                RX_STATE_STOP: begin
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        data    <= scratch;
                        rdy     <= 1'b1; 
                        state   <= RX_STATE_IDLE;
                    end
                end
            endcase
        end
    end
endmodule