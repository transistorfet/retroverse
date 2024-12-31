
module vme_bus_arbitration(
    input clock,

    input request_vme,
    output reg bus_acquired,

    output reg vme_bus_request,
    input vme_bus_grant_in,
    output reg vme_bus_grant_out
);

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    always @(posedge clock) begin
        /*
        // TODO these will bypassed bus arbitration for testing
        bus_acquired <= ACTIVE;
        vme_bus_request <= ACTIVE;
        vme_bus_grant_out <= vme_bus_grant_in;
        */

        if (request_vme == ACTIVE) begin
            vme_bus_request <= ACTIVE;
            vme_bus_grant_out <= INACTIVE;

            bus_acquired <= vme_bus_grant_in;
        end else begin
            vme_bus_request <= INACTIVE;
            bus_acquired <= INACTIVE;
            vme_bus_grant_out <= vme_bus_grant_in;
        end
    end

endmodule


module vme_data_transfer(
    input clock,
    input reset,
    output reg status_led,
    input slow_clock,

    input request_vme,
    input request_vme_a16,
    input request_vme_a24,
    input request_vme_a40,
    input bus_acquired,

    input cpu_as,
    input cpu_ds,
    input cpu_write,
    input [1:0] cpu_siz,
    input [1:0] cpu_address,
    input [2:0] cpu_fc,
    output reg [1:0] cpu_dsack,

    output reg vme_as,
    output reg [1:0] vme_ds,
    output reg vme_lword,
    output reg vme_write,
    output reg [5:0] vme_address_mod,
    input vme_dtack,
    input vme_berr,

    output reg addr_low_oe,
    output reg a40_cross_oe,
    output reg data_low_oe,
    output reg data_low_dir,
    output reg d16_cross_oe,
    output reg d16_cross_dir,
    output reg md32_cross_oe,
    output reg md32_cross_dir
);

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    localparam DIR_IN = 1'b1;
    localparam DIR_OUT = 1'b0;

    localparam IDLE = 3'h0;
    localparam ADDRESS = 3'h1;
    localparam DATA = 3'h2;
    localparam ADDRESS40 = 3'h3;
    localparam DATA40 = 3'h4;
    localparam END = 3'h5;

    reg [2:0] state;

    initial begin
        state <= IDLE;
    end

    reg slow_div_2;
    always @(posedge slow_clock) begin
        slow_div_2 <= !slow_div_2;
    end

    always @(posedge clock) begin
        if (reset == ACTIVE) begin
            state <= IDLE;
            status_led <= 1'b1;

            addr_low_oe <= INACTIVE;
            a40_cross_oe <= INACTIVE;
            data_low_oe <= INACTIVE;
            d16_cross_oe <= INACTIVE;
            md32_cross_oe <= INACTIVE;
            data_low_dir <= DIR_OUT;
            d16_cross_dir <= DIR_OUT;
            md32_cross_dir <= DIR_OUT;

            vme_as <= INACTIVE;
            vme_ds <= { INACTIVE, INACTIVE };
        end else begin
            case (state)
                IDLE: begin
                    status_led <= 1'b0;

                    addr_low_oe <= INACTIVE;
                    a40_cross_oe <= INACTIVE;
                    data_low_oe <= INACTIVE;
                    d16_cross_oe <= INACTIVE;
                    md32_cross_oe <= INACTIVE;
                    data_low_dir <= DIR_OUT;
                    d16_cross_dir <= DIR_OUT;
                    md32_cross_dir <= DIR_OUT;

                    vme_as <= INACTIVE;
                    vme_ds <= { INACTIVE, INACTIVE };
                    vme_lword <= INACTIVE;
                    vme_write <= INACTIVE;
                    cpu_dsack <= { INACTIVE, INACTIVE };
                    vme_address_mod <= 6'b111111;

                    if (vme_dtack == INACTIVE && vme_berr == INACTIVE && request_vme == ACTIVE && bus_acquired == ACTIVE) begin
                        state <= ADDRESS;
                        vme_as <= ACTIVE;
                        vme_write <= cpu_write;

                        addr_low_oe <= ACTIVE;
                        a40_cross_oe <= INACTIVE;
                        data_low_oe <= INACTIVE;
                        d16_cross_oe <= INACTIVE;
                        md32_cross_oe <= INACTIVE;
                        data_low_dir <= DIR_OUT;
                        d16_cross_dir <= DIR_OUT;
                        md32_cross_dir <= DIR_OUT;

                        case (cpu_fc)
                            3'b001: vme_address_mod <= 6'h39; // user access, data space, A24
                            3'b010: vme_address_mod <= 6'h3A; // user access, program space, A24
                            3'b101: vme_address_mod <= 6'h3D; // supervisor access, data space, A24
                            3'b110: vme_address_mod <= 6'h3E; // supervisor access, program space, A24
                            default: begin
                                // If it's an interrupt acknowledge or reserved function code, then end the cycle early
                                vme_address_mod <= 6'h00;
                                state <= END;
                            end
                        endcase

                        if (cpu_siz == 2'b00) begin
                            // 32-bit Operation
                            vme_lword <= ACTIVE;
                            vme_ds <= { ACTIVE, ACTIVE };

                            addr_low_oe <= ACTIVE;
                            a40_cross_oe <= ACTIVE;
                        end else if (cpu_siz == 2'b01) begin
                            // 8-bit Operation
                            vme_lword <= INACTIVE;
                            vme_ds <= cpu_address[0] ? { ACTIVE, INACTIVE } : { INACTIVE, ACTIVE };
                        end else begin
                            // 16-bit Operation
                            vme_lword <= INACTIVE;
                            vme_ds <= { ACTIVE, ACTIVE };
                        end
                    end
                end
                ADDRESS: begin
                    status_led <= slow_clock;

                    // TODO it's possible the DS signal comes in too soon (the same time as AS) which would mean in A40 mode, there'd be no time to see the address
                    if (vme_dtack == INACTIVE && vme_berr == INACTIVE && cpu_ds == ACTIVE) begin
                        state <= DATA;
                        if (cpu_siz == 2'b00) begin
                            // 32-bit Operation
                            addr_low_oe <= INACTIVE;
                            a40_cross_oe <= INACTIVE;

                            data_low_oe <= ACTIVE;
                            md32_cross_oe <= ACTIVE;

                            data_low_dir <= cpu_write == ACTIVE ? DIR_OUT : DIR_IN;
                            md32_cross_dir <= cpu_write == ACTIVE ? DIR_OUT : DIR_IN;
                            vme_lword <= 1'bZ;
                        end else begin
                            // 16-bit or 8-bit Operation
                            d16_cross_oe <= ACTIVE;
                            d16_cross_dir <= cpu_write == ACTIVE ? DIR_OUT : DIR_IN;
                        end
                    end else if (request_vme == INACTIVE) begin
                        state <= END;
                    end
                end
                DATA: begin
                    status_led <= slow_div_2;

                    if (vme_dtack == ACTIVE) begin
                        state <= END;
                        if (cpu_siz == 2'b00) begin
                            cpu_dsack <= 2'b00;  // long operation
                        end else begin
                            cpu_dsack <= 2'b01;  // word operation
                        end
                    end
                end
                END: begin
                    status_led <= 1'b1;

                    if (cpu_ds == { INACTIVE, INACTIVE } && request_vme == INACTIVE) begin
                        state <= IDLE;
                        cpu_dsack <= { INACTIVE, INACTIVE };

                        vme_as <= INACTIVE;
                        vme_ds <= { INACTIVE, INACTIVE };
                        vme_lword <= INACTIVE;
                        vme_write <= INACTIVE;
                        vme_address_mod <= 6'bZZZZZZ;

                        // Turn off all the transceivers
                        addr_low_oe <= INACTIVE;
                        a40_cross_oe <= INACTIVE;
                        data_low_oe <= INACTIVE;
                        d16_cross_oe <= INACTIVE;
                        md32_cross_oe <= INACTIVE;
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
