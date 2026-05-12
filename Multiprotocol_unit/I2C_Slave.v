`timescale 1ns / 1ps
module i2c_slave (
    input  wire clk,
    input  wire rst,
    input  wire scl,
    inout  wire sda,
    output reg  [7:0] rx_data,
    output reg  rx_valid
);

    localparam [6:0] SLAVE_ADDR = 7'h42;

    reg [2:0] scl_sync;
    reg [2:0] sda_sync;

    always @(posedge clk) begin
        scl_sync <= {scl_sync[1:0], scl};
        sda_sync <= {sda_sync[1:0], sda};
    end

    wire scl_r = (scl_sync[2:1] == 2'b01);
    wire scl_f = (scl_sync[2:1] == 2'b10);
    wire start_det = (scl_sync[1] && sda_sync[2:1] == 2'b10);
    wire stop_det  = (scl_sync[1] && sda_sync[2:1] == 2'b01);

    reg [3:0] state;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    reg sda_out;
    reg sda_dir; 

    assign sda = sda_dir ? sda_out : 1'bz;

    localparam IDLE = 0, ADDR = 1, ACK_ADDR = 2, DATA = 3, ACK_DATA = 4;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            sda_dir <= 0;
            rx_valid <= 0;
        end else begin
            rx_valid <= 0; 
            if (start_det) begin
                state <= ADDR;
                bit_cnt <= 7;
                sda_dir <= 0;
            end else if (stop_det) begin
                state <= IDLE;
                sda_dir <= 0;
            end else begin
                case (state)
                    IDLE: sda_dir <= 0;
                    ADDR: begin
                        if (scl_r) begin
                            shift_reg <= {shift_reg[6:0], sda_sync[1]};
                            if (bit_cnt == 0) state <= ACK_ADDR;
                            else bit_cnt <= bit_cnt - 1;
                        end
                    end
                    ACK_ADDR: begin
                        if (scl_f) begin
                            if (shift_reg[7:1] == SLAVE_ADDR) begin
                                sda_dir <= 1; sda_out <= 0; 
                            end else state <= IDLE; 
                        end else if (scl_r) begin
                            state <= DATA; bit_cnt <= 7;
                        end
                    end
                    DATA: begin
                        if (scl_f) sda_dir <= 0; 
                        if (scl_r) begin
                            shift_reg <= {shift_reg[6:0], sda_sync[1]};
                            if (bit_cnt == 0) state <= ACK_DATA;
                            else bit_cnt <= bit_cnt - 1;
                        end
                    end
                    ACK_DATA: begin
                        if (scl_f) begin
                            sda_dir <= 1; sda_out <= 0; 
                            rx_data <= shift_reg; rx_valid <= 1;        
                        end else if (scl_r) state <= IDLE; 
                    end
                endcase
            end
        end
    end
endmodule