module i2c_master (
    input clk,
    input rst,
    input start,
    input [6:0] slave_addr,
    input [7:0] data,
    output reg scl,
    output reg sda,
    output reg done
);

reg [3:0] state;
reg [3:0] bit_cnt;
reg [7:0] shift_reg;

parameter IDLE  = 0,
          START = 1,
          ADDR  = 2,
          DATA  = 3,
          STOP  = 4,
          DONE  = 5;

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        state <= IDLE;
        scl <= 1;
        sda <= 1;
        done <= 0;
        bit_cnt <= 0;
    end

    else
    begin
        case(state)

        IDLE:
        begin
            scl <= 1;
            sda <= 1;
            done <= 0;

            if(start)
                state <= START;
        end

        START:
        begin
            sda <= 0;
            scl <= 1;

            shift_reg <= {slave_addr,1'b0}; // write bit
            bit_cnt <= 7;

            state <= ADDR;
        end

        ADDR:
        begin
            scl <= 0;
            sda <= shift_reg[bit_cnt];
            scl <= 1;

            if(bit_cnt == 0)
            begin
                shift_reg <= data;
                bit_cnt <= 7;
                state <= DATA;
            end
            else
                bit_cnt <= bit_cnt - 1;
        end

        DATA:
        begin
            scl <= 0;
            sda <= shift_reg[bit_cnt];
            scl <= 1;

            if(bit_cnt == 0)
                state <= STOP;
            else
                bit_cnt <= bit_cnt - 1;
        end

        STOP:
        begin
            scl <= 1;
            sda <= 0;
            sda <= 1;

            state <= DONE;
        end

        DONE:
        begin
            done <= 1;
            state <= IDLE;
        end

        endcase
    end
end

endmodule
