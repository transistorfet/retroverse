
module address_decode(
    input cpu_as,
    input [23:20] address,

    output reg request_ram,
    output reg request_rom,
    output reg request_serial,
    output reg request_vme
);

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    always @(*) begin
        request_ram <= INACTIVE;
        request_rom <= INACTIVE;
        request_serial <= INACTIVE;
        request_vme <= INACTIVE;

        if (cpu_as == ACTIVE) begin
            case (address)
                4'b0000: request_rom <= ACTIVE;
                4'b0001: request_ram <= ACTIVE;
                4'b0010: request_ram <= ACTIVE;
                4'b0111: request_serial <= ACTIVE;
                default: request_vme <= ACTIVE;
            endcase
        end
    end
endmodule


module ram_select(
    input request_ram,
    input cpu_ds,
    input [1:0] cpu_siz,
    input [1:0] address,

    output reg [3:0] ram_ds
);

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    always @(*) begin
        ram_ds <= 4'b0000;
        if (request_ram == ACTIVE && cpu_ds == ACTIVE) begin
            case (cpu_siz)
                2'b01: ram_ds <= ~(4'b1000 >> address);
                2'b10: ram_ds <= ~(4'b1100 >> address);
                2'b11: ram_ds <= ~(4'b1110 >> address);
                2'b00: ram_ds <= ~(4'b1111 >> address);
                default: ram_ds <= 4'b1111;
            endcase
        end
    end
endmodule


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
        // TODO bypassed for testing
        bus_acquired <= ACTIVE;

        vme_bus_request <= ACTIVE;
        vme_bus_grant_out <= INACTIVE;
    end

endmodule


module vme_data_transfer(
    input clock,

    // TODO temporary
    output reg [1:0] state,

    input request_vme,
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

    // TODO double check these
    localparam DIR_IN = 1'b0;
    localparam DIR_OUT = 1'b1;

    localparam IDLE = 2'b00;
    localparam ADDRESS = 2'b01;
    localparam DATA = 2'b10;
    localparam END = 2'b11;

    // TODO temperorary for testing
    //reg [1:0] state;

    initial begin
        state <= IDLE;

    end

    always @(posedge clock) begin
        case (state)
            IDLE: begin
                addr_low_oe <= INACTIVE;
                a40_cross_oe <= INACTIVE;
                data_low_oe <= INACTIVE;
                d16_cross_oe <= INACTIVE;
                md32_cross_oe <= INACTIVE;
                data_low_dir <= DIR_OUT;
                d16_cross_dir <= DIR_OUT;
                md32_cross_dir <= DIR_OUT;
                cpu_dsack <= 2'b11;

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
                        vme_ds <= 2'b11;

                        addr_low_oe <= ACTIVE;
                        a40_cross_oe <= ACTIVE;
                    end else if (cpu_siz == 2'b01) begin
                        // 8-bit Operation
                        vme_lword <= INACTIVE;
                        vme_ds <= cpu_address[0] ? 2'b01 : 2'b10;
                    end else begin
                        // 16-bit Operation
                        vme_lword <= INACTIVE;
                        vme_ds <= 2'b11;
                    end
                end
            end
            ADDRESS: begin
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
                if (vme_dtack == ACTIVE || request_vme == INACTIVE) begin
                    state <= END;
                    if (cpu_siz == 2'b00) begin
                        cpu_dsack <= 2'b00;  // long operation
                    end else begin
                        cpu_dsack <= 2'b01;  // word operation
                    end
                end
            end
            END: begin
                if (cpu_as == INACTIVE) begin
                    state <= IDLE;

                    vme_as <= INACTIVE;
                    vme_ds <= 2'b11; // deactivate

                    // Turn off all the transceivers
                    addr_low_oe <= INACTIVE;
                    a40_cross_oe <= INACTIVE;
                    data_low_oe <= INACTIVE;
                    d16_cross_oe <= INACTIVE;
                    md32_cross_oe <= INACTIVE;
                    cpu_dsack <= 2'b11;  // deactivate

                    // tri-state all control signals
                    vme_as <= 1'bZ;
                    vme_ds <= 2'bZZ;
                    vme_lword <= 1'bZ;
                    vme_write <= 1'bZ;
                    vme_address_mod <= 6'bZZZZZZ;
                end
            end
            default: begin
                state <= IDLE;
            end
        endcase
    end

endmodule
