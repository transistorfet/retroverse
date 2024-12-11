
module address_decode(
    input cpu_as,
    input [23:20] address,
    input n_address_top,

    output reg request_ram,
    output reg request_rom,
    output reg request_serial,
    output reg request_vme_a16,
    output reg request_vme_a24,
    output reg request_vme_a40
);

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    always @(*) begin
        request_ram <= INACTIVE;
        request_rom <= INACTIVE;
        request_serial <= INACTIVE;
        request_vme_a16 <= INACTIVE;
        request_vme_a24 <= INACTIVE;
        request_vme_a40 <= INACTIVE;

        if (cpu_as == ACTIVE) begin
            case (address)
                4'h0: request_rom <= ACTIVE;
                4'h1: request_ram <= ACTIVE;
                4'h2: request_ram <= ACTIVE;
                4'h7: request_serial <= ACTIVE;
                default: begin
                    if (address == 4'hF && n_address_top == ACTIVE) begin
                        request_vme_a16 <= ACTIVE;
                    end else if (n_address_top == ACTIVE) begin
                        request_vme_a24 <= ACTIVE;
                    end else begin
                        request_vme_a40 <= ACTIVE;

                    end
                end
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


