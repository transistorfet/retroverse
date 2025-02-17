
module vme_bus_arbitration(
    input clock,

    input request_vme,
    input vme_as_out,
    output reg bus_acquired,

    output reg vme_bus_request,
    input vme_bus_grant_in,
    output reg vme_bus_grant_out
);

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    always @(*) begin
        /*
        // TODO these will bypassed bus arbitration for testing
        bus_acquired <= ACTIVE;
        vme_bus_request <= ACTIVE;
        vme_bus_grant_out <= vme_bus_grant_in;
        */

        if (request_vme == ACTIVE || vme_as_out == ACTIVE) begin
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

    input request_vme_sync,
    input request_vme_a16,
    input request_vme_a24,
    input request_vme_a40,
    input bus_acquired_sync,

    input cpu_as_sync,
    input cpu_ds_sync,
    input cpu_write,
    input [1:0] cpu_siz,
    input [1:0] cpu_address,
    input [2:0] cpu_fc,
    output reg [1:0] cpu_dsack,
    output reg cpu_berr,

    output reg vme_as,
    output reg [1:0] vme_ds,
    output reg vme_lword,
    output reg vme_write,
    output reg [5:0] vme_address_mod,
    input vme_dtack_sync,
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
    localparam ADDRESS_A24 = 3'h1;
    localparam DATA_D16 = 3'h2;
    localparam ADDRESS_A40 = 3'h3;
    localparam DATA_MD32 = 3'h4;
    localparam WAIT_FOR_CPU = 3'h5;

    reg [2:0] state;

    initial begin
        state <= IDLE;
    end

    always @(negedge clock or negedge reset) begin
        if (reset == ACTIVE) begin
            state <= IDLE;
            status_led <= 1'b1;

            // All transceivers off
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

                    // All transceivers off
                    addr_low_oe <= INACTIVE;
                    a40_cross_oe <= INACTIVE;
                    data_low_oe <= INACTIVE;
                    d16_cross_oe <= INACTIVE;
                    md32_cross_oe <= INACTIVE;
                    data_low_dir <= DIR_OUT;
                    d16_cross_dir <= DIR_OUT;
                    md32_cross_dir <= DIR_OUT;

                    // All control lines inactive
                    vme_as <= INACTIVE;
                    vme_ds <= { INACTIVE, INACTIVE };
                    vme_lword <= INACTIVE;
                    vme_write <= INACTIVE;
                    cpu_dsack <= { INACTIVE, INACTIVE };
                    cpu_berr <= INACTIVE;
                    vme_address_mod <= 6'b111111;

                    //if (request_vme_a40 == ACTIVE && bus_acquired == ACTIVE && vme_dtack == INACTIVE && vme_berr == INACTIVE) begin
                        /*
                        state <= ADDRESS_A40;
                        vme_as <= ACTIVE;
                        vme_write <= cpu_write;
                        vme_address_mod <= 6'h34;

                        addr_low_oe <= ACTIVE;
                        a40_cross_oe <= ACTIVE;
                        data_low_oe <= INACTIVE;
                        d16_cross_oe <= INACTIVE;
                        md32_cross_oe <= INACTIVE;
                        data_low_dir <= DIR_OUT;
                        d16_cross_dir <= DIR_OUT;
                        md32_cross_dir <= DIR_OUT;

                        if (cpu_siz == 2'b00) begin
                            // 32-bit Operation
                            vme_lword <= ACTIVE;
                            vme_ds <= { ACTIVE, ACTIVE };
                        end else if (cpu_siz == 2'b01) begin
                            // 8-bit Operation
                            vme_lword <= INACTIVE;
                            vme_ds <= cpu_address[0] == 1'b0 ? { ACTIVE, INACTIVE } : { INACTIVE, ACTIVE };
                        end else begin
                            // 16-bit Operation
                            vme_lword <= INACTIVE;
                            vme_ds <= { ACTIVE, ACTIVE };
                        end
                        */
                    //end else
                    if (request_vme_sync == ACTIVE && (request_vme_a16 == ACTIVE || request_vme_a24 == ACTIVE) && bus_acquired_sync == ACTIVE && vme_dtack_sync == INACTIVE && vme_berr == INACTIVE) begin
                        state <= ADDRESS_A24;
                        vme_write <= cpu_write;
                        vme_lword <= INACTIVE;

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
                                state <= WAIT_FOR_CPU;
                            end
                        endcase
                    end
                end

                ADDRESS_A24: begin
                    status_led <= 1'b1;
                    vme_as <= ACTIVE;

                    if (cpu_ds_sync == ACTIVE) begin
                        state <= DATA_D16;

                        // 16-bit or 8-bit Operation
                        d16_cross_oe <= ACTIVE;
                        d16_cross_dir <= cpu_write == ACTIVE ? DIR_OUT : DIR_IN;
                    end

                    //if (request_vme == INACTIVE) begin
                    //    state <= WAIT_FOR_CPU;
                    //    cpu_berr <= ACTIVE;
                    //end
                end

                DATA_D16: begin
                    status_led <= 1'b1;

                    if (cpu_siz == 2'b01) begin
                        // 8-bit Operation
                        vme_ds <= cpu_address[0] == 1'b0 ? { ACTIVE, INACTIVE } : { INACTIVE, ACTIVE };
                    end else begin
                        // 16-bit Operation
                        vme_ds <= { ACTIVE, ACTIVE };
                    end

                    if (vme_dtack_sync == ACTIVE) begin
                        state <= WAIT_FOR_CPU;
                        cpu_dsack <= 2'b01;  // word-sized port
                    end else if (request_vme_sync == INACTIVE) begin
                        state <= WAIT_FOR_CPU;
                        cpu_berr <= ACTIVE;
                    end
                end

                /*
                ADDRESS_A40: begin
                    // TODO it's possible the DS signal comes in too soon (the same time as AS) which would mean in A40 mode, there'd be no time to see the address
                    if (vme_dtack == INACTIVE && vme_berr == INACTIVE && cpu_ds == ACTIVE) begin
                        state <= DATA_MD32;

                        if (cpu_siz == 2'b00) begin
                            // 32-bit Operation
                            addr_low_oe <= INACTIVE;
                            a40_cross_oe <= INACTIVE;

                            data_low_oe <= ACTIVE;
                            md32_cross_oe <= ACTIVE;

                            data_low_dir <= cpu_write == ACTIVE ? DIR_OUT : DIR_IN;
                            md32_cross_dir <= cpu_write == ACTIVE ? DIR_OUT : DIR_IN;
                        end else begin
                            // 16-bit or 8-bit Operation
                            d16_cross_oe <= ACTIVE;
                            d16_cross_dir <= cpu_write == ACTIVE ? DIR_OUT : DIR_IN;
                        end
                    end else if (request_vme == INACTIVE) begin
                        state <= WAIT_FOR_CPU;
                    end
                end

                DATA_MD32: begin
                    if (vme_dtack == ACTIVE) begin
                        state <= WAIT_FOR_CPU;
                        if (cpu_siz == 2'b00) begin
                            cpu_dsack <= 2'b00;  // long operation
                        end else begin
                            cpu_dsack <= 2'b01;  // word operation
                        end
                    end
                end
                */

                WAIT_FOR_CPU: begin
                    //status_led <= 1'b1;
                    status_led <= 1'b0;
                    cpu_dsack <= 2'b01;  // word-sized port

                    if (cpu_ds_sync == INACTIVE && request_vme_sync == INACTIVE) begin
                        state <= IDLE;

                        // All transceivers off
                        addr_low_oe <= INACTIVE;
                        a40_cross_oe <= INACTIVE;
                        data_low_oe <= INACTIVE;
                        d16_cross_oe <= INACTIVE;
                        md32_cross_oe <= INACTIVE;
                        data_low_dir <= DIR_OUT;
                        d16_cross_dir <= DIR_OUT;
                        md32_cross_dir <= DIR_OUT;

                        // Main control lines inactive
                        vme_as <= INACTIVE;
                        vme_ds <= { INACTIVE, INACTIVE };
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
