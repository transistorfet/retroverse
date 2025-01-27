
module address_decode(
    input cpu_as,
    input [3:0] address_high,
    input n_address_top,

    output request_ram,
    output request_rom,
    output request_serial,
    output request_vme_a16,
    output request_vme_a24,
    output request_vme_a40,
    output request_unmapped
);

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    // TODO testing whether the flip flops of the previous decode logic was causing problems with the VME cycle
    // it seems to reduce the frequency of issues, but the logic traces still show a double cycle when there shouldn't be one (CPU_AS only goes low once, but VME_AS goes low twice)
    assign request_rom = (cpu_as == ACTIVE) && (n_address_top == INACTIVE) && (address_high == 4'h0) ? ACTIVE : INACTIVE;
    assign request_ram = (cpu_as == ACTIVE) && (n_address_top == INACTIVE) && (address_high == 4'h1 || address_high == 4'h2) ? ACTIVE : INACTIVE;
    assign request_serial = (cpu_as == ACTIVE) && (n_address_top == INACTIVE) && (address_high == 4'h7) ? ACTIVE : INACTIVE;
    assign request_vme_a16 = (cpu_as == ACTIVE) && (n_address_top == ACTIVE) && (address_high == 4'hF) ? ACTIVE : INACTIVE;
    assign request_vme_a24 = (cpu_as == ACTIVE) && (n_address_top == ACTIVE) && (address_high != 4'hF) ? ACTIVE : INACTIVE;
    assign request_vme_a40 = INACTIVE;
    assign request_unmapped = INACTIVE;

/*
    always @(*) begin
        request_ram <= INACTIVE;
        request_rom <= INACTIVE;
        request_serial <= INACTIVE;
        request_vme_a16 <= INACTIVE;
        request_vme_a24 <= INACTIVE;
        request_vme_a40 <= INACTIVE;
        request_unmapped <= INACTIVE;

        if (cpu_as == ACTIVE) begin
            if (n_address_top == INACTIVE) begin
                case (address_high)
                    4'h0: request_rom <= ACTIVE;
                    4'h1: request_ram <= ACTIVE;
                    4'h2: request_ram <= ACTIVE;
                    4'h7: request_serial <= ACTIVE;
                    default: begin
                        request_vme_a40 <= ACTIVE;
                        //request_unmapped <= ACTIVE;
                    end
                endcase
            end else begin
                if (address_high == 4'hF) begin
                    request_vme_a16 <= ACTIVE;
                end else begin
                    request_vme_a24 <= ACTIVE;
                end
            end
        end
    end
*/
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
        ram_ds <= 4'b1111;
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


