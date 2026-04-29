`timescale 1ns / 1ps

module protocol_router (
    input wire clk,              
    input wire rst,              
    input wire [1:0] protocol_sel, 
    input wire tx_btn,           // ACTIVE-LOW Transmit button
    
    input wire rx_rdy,           
    input wire [7:0] rx_data,    
    output reg rx_rdy_clr,       
    
    input wire tx_busy,          
    output reg tx_start,         
    output reg [7:0] tx_data,    
    
    output reg buffer_full       
);

    localparam STATE_IDLE      = 3'd0;
    localparam STATE_WAIT_TRIG = 3'd1; 
    localparam STATE_DISPATCH  = 3'd2;
    localparam STATE_ACK       = 3'd3;

    reg [2:0] state = STATE_IDLE;
    reg [7:0] data_buffer = 8'd0; 

    // -------------------------------------------------------------------------
    // Button Edge Detector (Configured for ACTIVE-LOW)
    // -------------------------------------------------------------------------
    // Idle state for active-low is HIGH (1'b1)
    reg btn_sync1 = 1'b1;
    reg btn_sync2 = 1'b1;
    reg btn_last  = 1'b1;
    
    // Falling Edge Detector: Triggers ONLY when signal drops from 1 to 0
    wire trigger_pulse = (~btn_sync2 && btn_last); 

    always @(posedge clk) begin
        if (rst) begin
            state       <= STATE_IDLE;
            rx_rdy_clr  <= 1'b0;
            tx_start    <= 1'b0;
            tx_data     <= 8'd0;
            data_buffer <= 8'd0;
            buffer_full <= 1'b0;
            
            // Reset synchronizers to idle high
            btn_sync1   <= 1'b1;
            btn_sync2   <= 1'b1;
            btn_last    <= 1'b1;
        end else begin
            // Synchronize the active-low button input
            btn_sync1 <= tx_btn;
            btn_sync2 <= btn_sync1;
            btn_last  <= btn_sync2;

            rx_rdy_clr <= 1'b0;
            tx_start   <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    if (rx_rdy) begin
                        data_buffer <= rx_data;  
                        buffer_full <= 1'b1;     
                        state       <= STATE_WAIT_TRIG;
                    end
                end

                STATE_WAIT_TRIG: begin
                    if (trigger_pulse) begin
                        state <= STATE_DISPATCH;
                    end
                end

                STATE_DISPATCH: begin
                    case (protocol_sel)
                        2'b00: begin // UART TX
                            if (!tx_busy) begin      
                                tx_data     <= data_buffer; 
                                tx_start    <= 1'b1;        
                                buffer_full <= 1'b0; 
                                state       <= STATE_ACK;
                            end
                        end

                        2'b01: begin // SPI 
                            buffer_full <= 1'b0;
                            state <= STATE_ACK; 
                        end

                        2'b10: begin // I2C 
                            buffer_full <= 1'b0;
                            state <= STATE_ACK; 
                        end
                        
                        default: begin
                            buffer_full <= 1'b0;
                            state <= STATE_ACK; 
                        end
                    endcase
                end

                STATE_ACK: begin
                    rx_rdy_clr <= 1'b1; 
                    if (!rx_rdy) begin 
                        state <= STATE_IDLE;
                    end
                end
            endcase
        end
    end
endmodule