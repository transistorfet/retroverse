module systemboard(
    input clock,
    input [3:0] br,
    output reg [3:0] bgout,
    output reg bclr,


    input [5:0] vme_address_mod,
    input [7:0] vme_data,
    input [23:0] vme_address,
);

    localparam IDLE = 2'b00;
    localparam BUS_ACQUIRED = 2'b01;
    localparam BUS_CLEAR = 2'b10;

    reg [1:0] state;
    reg [1:0] current;

    always @(posedge clock) begin
        case (state)
            IDLE: begin
                bclr <= INACTIVE;
                bgout <= 4'h0;

                if (br[0] == ACTIVE) begin
                    state <= BUS_ACQUIRED;
                    bgout[0] <= ACTIVE;
                    current <= 2'b00;
                end else if (br[1] == ACTIVE) begin
                    state <= BUS_ACQUIRED;
                    bgout[1] <= ACTIVE;
                    current <= 2'b01;
                end
            end
            BUS_ACQUIRED: begin
                if (br[current] == INACTIVE) begin
                    state <= IDLE;
                    bgout[current] <= INACTIVE;
                end else if (br >> (current + 2'b01) != 4'h0) begin
                    state <= BUS_CLEAR;
                    bclr <= ACTIVE;
                end
            end
            BUS_CLEAR: begin

                state <= IDLE;
            end 
            default:
                state <= IDLE;
        endcase
    end

endmodule
// Pin assignment for the experimental Yosys FLoow
//
//PIN: CHIP "counter" ASSIGNED TO AN PLCC84
//PIN: clock      : 54
//PIN: counter_0  : 69
//PIN: counter_1  : 67
