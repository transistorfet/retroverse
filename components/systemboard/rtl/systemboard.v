module systemboard(
    input clock,
    input reset,
    output reg status_led,

    output vme_sysclk,
    inout vme_sysreset,

    input vme_address_strobe,
    input [1:0] vme_data_strobe,
    input vme_lword,
    input vme_write,
    //inout vme_dtack,
    //inout vme_berr,
    input [5:0] vme_address_mod,
    input [23:0] vme_address,
    //inout [7:0] vme_data,

    //inout vme_bbsy,
    //inout vme_bclr,
    output reg [3:0] vme_bgout,
    input [3:0] vme_br

    //inout vme_acfail,
    //input [3:0] vme_bgin,
    //inout vme_sysfail,
    //input vme_iackin,
    //output vme_iackout,
    //inout vme_iack,
    //inout [7:0] vme_irq
);

    assign vme_sysclk = clock;
    //assign vme_iackout = vme_iackin;

    //assign vme_bgout = vme_bgin;
    //assign vme_irq = 7'bZZZZZZZ;
    //assign vme_sysfail = 1'bZ;
    //assign vme_address_mod = 7'bZZZZZ;

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
    reg vme_sysreset_out;

    //assign vme_address = vme_dtb_output_enable == 1'b1 ? vme_address_out : 24'hZZZZZZ;

    //assign status_led = (vme_address == 24'hffffff && vme_data == 8'h00);
    //assign status_led = 1'b0;

    //assign vme_address_strobe = (vme_address_1 == 1'b1) ? 1'b0 : 1'bZ;
    assign vme_sysreset = (vme_sysreset_out == ACTIVE) ? 1'b0 : 1'bZ;

    reg [9:0] counter;
    always @(posedge clock) begin
        if (reset == ACTIVE) begin
            vme_sysreset_out <= ACTIVE;
            counter <= 10'b0;
        end else begin
            if (vme_sysreset_out == ACTIVE) begin
                counter <= counter + 10'b1;
                if (counter == 10'h3ff) begin
                    vme_sysreset_out <= INACTIVE;
                end
            end
        end
    end

    ///
    /// Bus Arbitrator Logic
    ///
    always @(posedge clock) begin
        if (reset == ACTIVE) begin
            state <= IDLE;
            //vme_bclr <= INACTIVE;
            vme_bgout <= 4'b1111;
            status_led <= 1'b1;
        end else begin
            status_led <= 1'b0;

            case (state)
                IDLE: begin
                    //vme_dtb_output_enable <= 1'b0;
                    //vme_bclr <= INACTIVE;
                    vme_bgout <= 4'b1111;

                    if (vme_br != 4'b1111) begin
                        state <= BUS_ACQUIRED;
                        //vme_bbsy <= ACTIVE;

                        if (vme_br[0] == ACTIVE) begin
                            vme_bgout[0] <= ACTIVE;
                            current <= 2'h0;
                            request_mask <= 4'b0000;
                        end else if (vme_br[1] == ACTIVE) begin
                            vme_bgout[1] <= ACTIVE;
                            current <= 2'h1;
                            request_mask <= 4'b0001;
                        end else if (vme_br[2] == ACTIVE) begin
                            vme_bgout[2] <= ACTIVE;
                            current <= 2'h2;
                            request_mask <= 4'b0011;
                        end else if (vme_br[3] == ACTIVE) begin
                            vme_bgout[3] <= ACTIVE;
                            current <= 2'h3;
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
                        //state <= BUS_CLEAR;
                        //vme_bclr <= ACTIVE;
                    end
                end
                //BUS_CLEAR: begin
                //    //vme_bbsy <= INACTIVE;
                //    //vme_address_out <= 24'hFF00000;
                //    //vme_dtb_output_enable <= 1'b1;
                //    if (vme_br[current] == INACTIVE) begin
                //        state <= IDLE;
                //    end
                //end 
                default:
                    state <= IDLE;
            endcase
        end
    end

    ////////////////////////////
    /// Dummy Peripheral Logic
    ////////////////////////////

    /*
    localparam DEVICE_IDLE = 2'h0;
    localparam DEVICE_RESPOND = 2'h1;
    localparam DEVICE_END = 2'h2;

    reg [1:0] device_state;

    wire requested_self;
    reg vme_dtack_out;
    reg vme_data_bus_out_enabled;
    reg [7:0] vme_data_out;

    assign requested_self = vme_address_strobe == ACTIVE && vme_address[23:20] == 4'h5;
    assign vme_dtack = (requested_self && !(vme_data_strobe[0] == INACTIVE && vme_data_strobe[1] == INACTIVE)) ? ACTIVE : 1'bZ;
    assign vme_data = (requested_self && !(vme_data_strobe[0] == INACTIVE && vme_data_strobe[1] == INACTIVE) && vme_write == INACTIVE) ? 8'h37 : 8'bZZZZZZZZ;
    assign status_led = 1'b0;

    always @(posedge clock) begin
        case (device_state)
            DEVICE_IDLE: begin
                vme_data_bus_out_enabled <= INACTIVE;
                vme_dtack_out <= INACTIVE;

                if (requested_self) begin
                    device_state <= DEVICE_RESPOND;
                end
            end

            DEVICE_RESPOND: begin
                if (vme_data_strobe != { INACTIVE, INACTIVE }) begin
                    device_state <= DEVICE_END;
                    vme_dtack_out <= ACTIVE;

                    if (vme_write == ACTIVE) begin
                        vme_data_out <= 8'h37;
                        vme_data_bus_out_enabled <= ACTIVE;
                    end else begin
                        status_led <= vme_data == 8'hAA;
                    end
                end
            end

            DEVICE_END: begin
                vme_dtack_out <= ACTIVE;

                if (vme_data_strobe == { INACTIVE, INACTIVE }) begin
                    device_state <= DEVICE_IDLE;
                    vme_dtack_out <= INACTIVE;
                end
            end

            default: begin
                device_state <= DEVICE_IDLE;
            end
        endcase
    end
    */

endmodule
// Pin assignment for the experimental Yosys Flow
//
//PIN: CHIP "systemboard" ASSIGNED TO AN TQFP100
//PIN: clock                    : 87
//PIN: reset                    : 89
//PIN: status_led               : 2
//PIN: vme_sysreset             : 1
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
//PIN: vme_data_strobe_1        : 5
//PIN: vme_data_strobe_0        : 6
//PIN: vme_write                : 7
//PIN: vme_address_strobe       : 9
//PIN: vme_address_mod_0        : 10
//PIN: vme_address_mod_1        : 12
//PIN: vme_address_mod_2        : 13
//PIN: vme_address_mod_3        : 14
//PIN: vme_address_mod_4        : 16
//PIN: vme_address_mod_5        : 17
//PIN: vme_berr                 : 19
//PIN: vme_lword                : 20
//PIN: vme_address_1            : 23
//PIN: vme_address_2            : 24
//PIN: vme_address_3            : 25
//PIN: vme_address_4            : 27
//PIN: vme_address_5            : 28
//PIN: vme_address_6            : 29
//PIN: vme_address_7            : 30
//PIN: vme_address_8            : 31
//PIN: vme_address_9            : 32
//PIN: vme_address_10           : 33
//PIN: vme_address_11           : 35
//PIN: vme_address_12           : 36
//PIN: vme_address_13           : 37
//PIN: vme_address_14           : 40
//PIN: vme_address_15           : 41
//PIN: vme_address_16           : 42
//PIN: vme_address_17           : 44
//PIN: vme_address_18           : 45
//PIN: vme_address_19           : 46
//PIN: vme_address_20           : 47
//PIN: vme_address_21           : 48
//PIN: vme_address_22           : 49
//PIN: vme_address_23           : 50
//PIN: vme_data_0               : 100
//PIN: vme_data_1               : 99
//PIN: vme_data_2               : 98
//PIN: vme_data_3               : 97
//PIN: vme_data_4               : 96
//PIN: vme_data_5               : 94
//PIN: vme_data_6               : 93
//PIN: vme_data_7               : 92

//P IN: vme_serclk               : 21
//P IN: vme_serdat               : 22
//P IN: vme_bgin_0               : 80
//P IN: vme_bgin_1               : 78
//P IN: vme_bgin_2               : 76
//P IN: vme_bgin_3               : 72
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
