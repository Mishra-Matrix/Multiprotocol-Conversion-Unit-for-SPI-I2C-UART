`timescale 1ns / 1ps

module multiprotocol_top (
    input  wire clk,               
    input  wire rst_btn,           // ACTIVE-LOW System Reset
    input  wire tx_btn,            // ACTIVE-LOW Transmit Button
    input  wire [1:0] sw_sel,      
    input  wire uart_rx_pin,       
    output wire uart_tx_pin,       
    
    output reg  led_rx_indicator   
);

    wire [7:0] w_rx_data;
    wire w_rx_rdy;
    wire w_rx_rdy_clr;
    
    wire [7:0] w_tx_data;
    wire w_tx_start;
    wire w_tx_busy;
    wire w_buffer_full;

    // -------------------------------------------------------------------------
    // Latching LED Logic (Invert the Active-Low Reset)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (~rst_btn) begin        // If reset button drops to 0, clear LED
            led_rx_indicator <= 1'b0; 
        end else if (w_rx_rdy) begin
            led_rx_indicator <= 1'b1; 
        end else if (~w_buffer_full) begin
            // Turn off LED when buffer is empty (data was dispatched)
            led_rx_indicator <= 1'b0;
        end
    end

    // -------------------------------------------------------------------------
    // Hardware Modules (Invert the Active-Low Reset)
    // -------------------------------------------------------------------------
    uart_rx #(
        .CLKS_PER_BIT(868) 
    ) RX_MODULE (
        .clk(clk),
        .rst(~rst_btn),            // ~ turns 0 into 1 for the internal logic
        .rx(uart_rx_pin),
        .rdy_clr(w_rx_rdy_clr),
        .rdy(w_rx_rdy),
        .data(w_rx_data)
    );

    protocol_router ROUTER_MODULE (
        .clk(clk),
        .rst(~rst_btn),            // ~ turns 0 into 1 for the internal logic
        .protocol_sel(sw_sel),
        .tx_btn(tx_btn),           // Pass active-low button directly to router
        .rx_rdy(w_rx_rdy),
        .rx_data(w_rx_data),
        .rx_rdy_clr(w_rx_rdy_clr),
        .tx_busy(w_tx_busy),
        .tx_start(w_tx_start),
        .tx_data(w_tx_data),
        .buffer_full(w_buffer_full)
    );

    uart_tx #(
        .CLKS_PER_BIT(868) 
    ) TX_MODULE (
        .clk(clk),
        .rst(~rst_btn),            // ~ turns 0 into 1 for the internal logic
        .tx_start(w_tx_start),
        .tx_data(w_tx_data),
        .tx(uart_tx_pin),
        .tx_busy(w_tx_busy)
    );

endmodule