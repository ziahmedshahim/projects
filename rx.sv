module uart_rx#(
    parameter integer WIDTH = 12
)
(
    input PCLK,
    input RESET,
    input RX_I,
    input [11:0] WORK_FR,
    output reg [7:0] DATA_RX_O,
    output reg PARITY_RX,
    output READY
);

    localparam [3:0]
        RX_IDLE         = 4'b0000,
        RX_DETECT_START = 4'b0001,    
        RX_TAKE_DATA    = 4'b0010,
        RX_TAKE_PARITY  = 4'b0100,
        RX_HIGH_DETECT  = 4'b1000;

    reg [3:0] state_rx, next_state_rx;
    reg [WIDTH-1:0] COUNTER;
    reg [3:0] DATA_COUNTER;
    reg AUX;
    reg PARITY_BIT_RXED;

    wire CALCULATED_PARITY;

    assign CALCULATED_PARITY = ^DATA_RX_O;  // XOR all bits of received data
    assign READY = (state_rx == RX_HIGH_DETECT && COUNTER == 12'd2);

    always @(*) begin
        next_state_rx = state_rx;
        case(state_rx)
            RX_IDLE: next_state_rx = RX_I ? RX_IDLE : RX_DETECT_START;
            RX_DETECT_START: next_state_rx = (COUNTER == WORK_FR && AUX == 1'b0) ? RX_TAKE_DATA : RX_DETECT_START;
            RX_TAKE_DATA: begin
                if (COUNTER == WORK_FR && DATA_COUNTER == 4'd8)
                    next_state_rx = RX_TAKE_PARITY;
                else
                    next_state_rx = RX_TAKE_DATA;
            end
            RX_TAKE_PARITY: next_state_rx = (COUNTER == WORK_FR) ? RX_HIGH_DETECT : RX_TAKE_PARITY;
            RX_HIGH_DETECT: next_state_rx = (COUNTER == WORK_FR && AUX == 1'b1) ? RX_IDLE : RX_HIGH_DETECT;
            default: next_state_rx = RX_IDLE;
        endcase
    end

    always @(posedge PCLK) begin
        if (RESET) begin
            state_rx <= RX_IDLE;
            COUNTER <= 0;
            DATA_COUNTER <= 0;
            DATA_RX_O <= 0;
            AUX <= 1'b1;
            PARITY_RX <= 1'b0;
            PARITY_BIT_RXED <= 1'b0;
        end else begin
            state_rx <= next_state_rx;
            case (state_rx)
                RX_IDLE: begin
                    if (!RX_I)
                        COUNTER <= COUNTER + 1;
                    else begin
                        COUNTER <= 0;
                        DATA_COUNTER <= 0;
                    end
                end
                RX_DETECT_START: begin
                    if (COUNTER == WORK_FR / 2)
                        AUX <= RX_I;
                    COUNTER <= (COUNTER < WORK_FR) ? COUNTER + 1 : 0;
                end
                RX_TAKE_DATA: begin
                    if (COUNTER == WORK_FR / 2) begin
                        DATA_RX_O[DATA_COUNTER] <= RX_I;
                        DATA_COUNTER <= DATA_COUNTER + 1;
                    end
                    COUNTER <= (COUNTER < WORK_FR) ? COUNTER + 1 : 0;
                end
                RX_TAKE_PARITY: begin
                    if (COUNTER == WORK_FR / 2)
                        PARITY_BIT_RXED <= RX_I;
                    if (COUNTER == WORK_FR) begin
                        COUNTER <= 0;
                        AUX <= 1'b0;
                        // compare calculated and received parity
                        PARITY_RX <= (CALCULATED_PARITY == PARITY_BIT_RXED);
                    end else
                        COUNTER <= COUNTER + 1;
                end
                RX_HIGH_DETECT: begin
                    if (COUNTER == WORK_FR / 2)
                        AUX <= RX_I;
                    COUNTER <= (COUNTER < WORK_FR) ? COUNTER + 1 : 0;
                    DATA_COUNTER <= 0;
                end
                default: begin
                    COUNTER <= 0;
                    DATA_COUNTER <= 0;
                end
            endcase
        end
    end

endmodule


