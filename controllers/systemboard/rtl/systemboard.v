module systemboard(
    //inout vme_sysreset,
    output reg statusled,
    inout vme_address_strobe,
    input vme_address_1,
    //inout [1:0] vme_data_strobe,
    //inout vme_write,
    //inout vme_dtack,
    //inout vme_address_strobe,
    //inout [5:0] vme_address_mod,
    //inout vme_berr,
    //inout vme_lword,
    //inout vme_serclk,
    //inout vme_serdat,
    //inout [23:1] vme_address,
    //inout [7:0] vme_data,
    //input reset,
    input clock,
    output vme_sysclk,
    //inout vme_bbsy,
    inout vme_bclr,
    //inout vme_acfail,
    //input [3:0] vme_bgin,
    output reg [3:0] vme_bgout,
    input [3:0] vme_br,
    //inout vme_sysfail,
    //input vme_iackin,
    //output vme_iackout,
    //inout vme_iack,
    //inout [7:0] vme_irq
);

    //assign vme_sysreset = 1'bZ;
    //assign statusled = 1'b0;
    //assign vme_data_strobe = 2'bZZ;
    assign vme_sysclk = clock;
    //assign vme_iackout = vme_iackin;

    //assign vme_bgout = vme_bgin;
    //assign vme_irq = 7'bZZZZZZZ;
    //assign vme_sysfail = 1'bZ;
    //assign vme_address_mod = 7'bZZZZZ;
/*
    inout vme_write,
    inout vme_dtack,
    inout vme_address_strobe,
    inout vme_berr,
    inout vme_lword,
    inout vme_serclk,
    inout vme_serdat,
    input reset,
    inout vme_bbsy,
    inout vme_bclr,
    inout vme_acfail,
    inout [3:0] vme_br,
    inout vme_sysfail,
    inout vme_iack,
*/

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    localparam IDLE = 2'b00;
    localparam BUS_ACQUIRED = 2'b01;
    localparam BUS_CLEAR = 2'b10;

    reg vme_dtb_output_enable;
    reg [1:0] state;
    reg [1:0] current;
    reg [3:0] request_mask;
    //reg [23:0] vme_address_out;

    //assign vme_address = vme_dtb_output_enable == 1'b1 ? vme_address_out : 24'hZZZZZZ;

    //assign statusled = (vme_address == 24'hffffff && vme_data == 8'h00);
    assign statusled = 1'b1;

    assign vme_address_strobe = (vme_address_1 == 1'b1) ? 1'b0 : 1'bZ;

    always @(posedge clock) begin

        case (state)
            IDLE: begin
                vme_dtb_output_enable <= 1'b0;
                vme_bclr <= INACTIVE;
                vme_bgout <= 4'b1111;

                if (vme_br != 4'b1111) begin
                    state <= BUS_ACQUIRED;
                    //vme_bbsy <= ACTIVE;

                    if (vme_br[0] == ACTIVE) begin
                        vme_bgout[0] <= ACTIVE;
                        current <= 2'b00;
                        request_mask <= 4'b0000;
                    end else if (vme_br[1] == ACTIVE) begin
                        vme_bgout[1] <= ACTIVE;
                        current <= 2'b01;
                        request_mask <= 4'b0001;
                    end else if (vme_br[2] == ACTIVE) begin
                        vme_bgout[2] <= ACTIVE;
                        current <= 2'b10;
                        request_mask <= 4'b0011;
                    end else if (vme_br[3] == ACTIVE) begin
                        vme_bgout[3] <= ACTIVE;
                        current <= 2'b11;
                        request_mask <= 4'b0111;
                    end
                end
            end
            BUS_ACQUIRED: begin
                if (vme_br[current] == INACTIVE) begin
                    state <= IDLE;
                    //vme_bbsy <= INACTIVE;
                    vme_bgout[current] <= INACTIVE;
                end else if ((vme_br & request_mask) != request_mask) begin
                    state <= BUS_CLEAR;
                    vme_bclr <= ACTIVE;
                end
            end
            BUS_CLEAR: begin
                //vme_bbsy <= INACTIVE;
                //vme_address_out <= 24'hFF00000;
                //vme_dtb_output_enable <= 1'b1;
                if (vme_br[current] == INACTIVE) begin
                    state <= IDLE;
                end
            end 
            default:
                state <= IDLE;
        endcase
    end

endmodule
// Pin assignment for the experimental Yosys FLoow
//
//PIN: CHIP "systemboard" ASSIGNED TO AN TQFP100
//PIN: clock                    : 87
//PIN: statusled                : 2
//PIN: vme_sysclk               : 85
//PIN: vme_bbsy                 : 84
//PIN: vme_bclr                 : 83
//PIN: vme_acfail               : 81
//PIN: vme_bgout_0              : 79
//PIN: vme_bgout_1              : 77
//PIN: vme_bgout_2              : 75
//PIN: vme_bgout_3              : 71
//PIN: vme_br_0                 : 70
//PIN: vme_br_1                 : 69
//PIN: vme_br_2                 : 68
//PIN: vme_br_3                 : 67
//PIN: vme_address_strobe       : 9
//PIN: vme_address_1            : 23

// Pin assignment for the experimental Yosys FLoow
//
//P IN: CHIP "systemboard" ASSIGNED TO AN TQFP100
//P IN: vme_sysreset             : 1
//P IN: vme_data_strobe_1        : 5
//P IN: vme_data_strobe_0        : 6
//P IN: vme_write                : 7
//P IN: vme_dtack                : 8
//P IN: vme_address_strobe       : 9
//P IN: vme_address_mod_0        : 10
//P IN: vme_address_mod_1        : 12
//P IN: vme_address_mod_2        : 13
//P IN: vme_address_mod_3        : 14
//P IN: vme_address_mod_4        : 16
//P IN: vme_address_mod_5        : 17
//P IN: vme_berr                 : 19
//P IN: vme_lword                : 20
//P IN: vme_serclk               : 21
//P IN: vme_serdat               : 22
//P IN: vme_address_1            : 23
//P IN: vme_address_2            : 24
//P IN: vme_address_3            : 25
//P IN: vme_address_4            : 27
//P IN: vme_address_5            : 28
//P IN: vme_address_6            : 29
//P IN: vme_address_7            : 30
//P IN: vme_address_8            : 31
//P IN: vme_address_9            : 32
//P IN: vme_address_10           : 33
//P IN: vme_address_11           : 35
//P IN: vme_address_12           : 36
//P IN: vme_address_13           : 37
//P IN: vme_address_14           : 40
//P IN: vme_address_15           : 41
//P IN: vme_address_16           : 42
//P IN: vme_address_17           : 44
//P IN: vme_address_18           : 45
//P IN: vme_address_19           : 46
//P IN: vme_address_20           : 47
//P IN: vme_address_21           : 48
//P IN: vme_address_22           : 49
//P IN: vme_address_23           : 50
//P IN: vme_data_0               : 100
//P IN: vme_data_1               : 99
//P IN: vme_data_2               : 98
//P IN: vme_data_3               : 97
//P IN: vme_data_4               : 96
//P IN: vme_data_5               : 94
//P IN: vme_data_6               : 93
//P IN: vme_data_7               : 92
//P IN: reset                    : 89
//P IN: clock                    : 87
//P IN: vme_sysclk               : 85
//P IN: vme_bbsy                 : 84
//P IN: vme_bclr                 : 83
//P IN: vme_acfail               : 81
//P IN: vme_bgin_0               : 80
//P IN: vme_bgout_0              : 79
//P IN: vme_bgin_1               : 78
//P IN: vme_bgout_1              : 77
//P IN: vme_bgin_2               : 76
//P IN: vme_bgout_2              : 75
//P IN: vme_bgin_3               : 72
//P IN: vme_bgout_3              : 71
//P IN: vme_br_0                 : 70
//P IN: vme_br_1                 : 69
//P IN: vme_br_2                 : 68
//P IN: vme_br_3                 : 67
//P IN: vme_sysfail              : 65
//P IN: vme_iackin               : 64
//P IN: vme_iackout              : 63
//P IN: vme_iack                 : 61
//P IN: vme_irq_7                : 60
//P IN: vme_irq_6                : 58
//P IN: vme_irq_5                : 57
//P IN: vme_irq_4                : 56
//P IN: vme_irq_3                : 55
//P IN: vme_irq_2                : 54
//P IN: vme_irq_1                : 53
