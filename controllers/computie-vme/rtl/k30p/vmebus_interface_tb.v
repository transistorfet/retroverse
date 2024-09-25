`timescale 1ns / 1ps

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
            $finish; \
        end

module vme_data_transfer_tb();

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    reg clock = 1'b0;
    wire [1:0] state;

    reg request_vme;
    reg bus_acquired;

    reg cpu_as = 1'b1;
    reg cpu_ds = 1'b1;
    reg [1:0] cpu_siz = 2'b00;
    reg [1:0] cpu_address = 2'b00;
    reg cpu_write = 1'b1;
    wire [1:0] cpu_dsack = 2'b11;

    wire vme_as;
    wire [1:0] vme_ds;
    wire vme_lword;
    wire vme_write;
    wire [5:0] vme_address_mod;
    reg vme_dtack;
    reg vme_berr;

    wire addr_low_oe;
    wire a40_cross_oe;
    wire data_low_oe;
    wire data_low_dir;
    wire d16_cross_oe;
    wire d16_cross_dir;
    wire md32_cross_oe;
    wire md32_cross_dir;

    vme_data_transfer DTS(
        .clock(clock),

        .state(state),

        .request_vme(request_vme),
        .bus_acquired(bus_acquired),

        .cpu_as(cpu_as),
        .cpu_ds(cpu_ds),
        .cpu_write(cpu_write),
        .cpu_siz(cpu_siz),
        .cpu_address(cpu_address),
        .cpu_fc(3'b001),
        .cpu_dsack(cpu_dsack),

        .vme_as(vme_as),
        .vme_ds(vme_ds),
        .vme_lword(vme_lword),
        .vme_write(vme_write),
        .vme_address_mod(vme_address_mod),
        .vme_dtack(vme_dtack),
        .vme_berr(vme_berr),

        .addr_low_oe(addr_low_oe),
        .a40_cross_oe(a40_cross_oe),
        .data_low_oe(data_low_oe),
        .data_low_dir(data_low_dir),
        .d16_cross_oe(d16_cross_oe),
        .d16_cross_dir(d16_cross_dir),
        .md32_cross_oe(md32_cross_oe),
        .md32_cross_dir(md32_cross_dir)
    );

    initial begin
        $display("Starting");

        $dumpfile("vmebus_interface.vcd");
        $dumpvars(0, DTS);
    end

    always
        #1 clock = !clock;

    initial begin
        #0
            vme_dtack = INACTIVE;
            vme_berr = INACTIVE;
            cpu_as = INACTIVE;
            cpu_ds = INACTIVE;
            request_vme = INACTIVE;
            bus_acquired = INACTIVE;

        #10
            // 32-Bit A30/MD32 Cycle
            cpu_siz = 2'b00;
            cpu_as = ACTIVE;
            request_vme = ACTIVE;
            bus_acquired = ACTIVE;

        //#1
            cpu_ds = ACTIVE;

        #4
            `assert(data_low_oe, ACTIVE);
            `assert(md32_cross_oe, ACTIVE);
            `assert(d16_cross_oe, INACTIVE);

            vme_dtack = ACTIVE;
            while (cpu_dsack == 2'b11) begin
                #1;
            end
            cpu_as = INACTIVE;
            cpu_ds = INACTIVE;
            request_vme = INACTIVE;
            bus_acquired = INACTIVE;
        #1
            vme_dtack = INACTIVE;

        #10
            // 16-Bit Cycle
            cpu_siz = 2'b10;
            cpu_as = ACTIVE;
            request_vme = ACTIVE;
            bus_acquired = ACTIVE;

        //#1
            cpu_ds = ACTIVE;

        #4
            vme_dtack = ACTIVE;
            while (cpu_dsack == 2'b11) begin
                #1;
            end
            cpu_as = INACTIVE;
            cpu_ds = INACTIVE;
            request_vme = INACTIVE;
            bus_acquired = INACTIVE;
        #1
            vme_dtack = INACTIVE;


        #10
            // 8-Bit Even Cycle
            cpu_address = 2'b00;
            cpu_siz = 2'b01;
            cpu_as = ACTIVE;
            request_vme = ACTIVE;
            bus_acquired = ACTIVE;

        //#1
            cpu_ds = ACTIVE;

        #4
            vme_dtack = ACTIVE;
            while (cpu_dsack == 2'b11) begin
                #1;
            end
            cpu_as = INACTIVE;
            cpu_ds = INACTIVE;
            request_vme = INACTIVE;
            bus_acquired = INACTIVE;
        #1
            vme_dtack = INACTIVE;


        #10
            // 8-Bit Odd Cycle
            cpu_address = 2'b01;
            cpu_siz = 2'b01;
            cpu_as = ACTIVE;
            request_vme = ACTIVE;
            bus_acquired = ACTIVE;

        //#1
            cpu_ds = ACTIVE;

        #4
            vme_dtack = ACTIVE;
            while (cpu_dsack == 2'b11) begin
                #1;
            end
            cpu_as = INACTIVE;
            cpu_ds = INACTIVE;
            request_vme = INACTIVE;
            bus_acquired = INACTIVE;
        #1
            vme_dtack = INACTIVE;


        #50 $finish;
    end
endmodule
