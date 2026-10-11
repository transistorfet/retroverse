`timescale 1ns / 1ps

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
            $finish; \
        end

module buslogic_tb();

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    reg clock = 1'b0;
    reg reset = 1'b1;
    wire cpu_clock;
    wire status_led;

    wire request_ram;
    wire request_rom;
    wire [3:0] ram_ds;
    wire request_serial;

    wire vme_bus_request;
    reg vme_bus_grant_in;
    wire vme_bus_grand_out;

    reg cpu_as = 1'b1;
    reg cpu_ds = 1'b1;
    reg [1:0] cpu_siz = 2'b00;
    reg [31:0] cpu_address = 32'h00000000;
    reg [2:0] cpu_fc;
    reg cpu_write = 1'b1;
    wire [1:0] cpu_dsack = 2'b11;
    wire cpu_berr;
    wire [2:0] cpu_ipl;

    wire vme_as;
    wire [1:0] vme_ds;
    wire vme_lword;
    wire vme_write;
    wire [5:0] vme_address_mod;
    reg vme_dtack;
    reg vme_berr;
    reg [2:0] vme_ipl;
    wire vme_iack;

    wire addr_low_oe;
    wire a40_cross_oe;
    wire data_low_oe;
    wire data_low_dir;
    wire d16_cross_oe;
    wire d16_cross_dir;
    wire md32_cross_oe;
    wire md32_cross_dir;

    buslogic DTS(
        .clock(clock),
        .reset(reset),
        .cpu_clock(cpu_clock),
        .status_led(status_led),

        .request_ram(request_ram),
        .request_rom(request_rom),
        .ram_ds(ram_ds),
        .request_serial(request_serial),

        .vme_bus_request(vme_bus_request),
        .vme_bus_grant_in(vme_bus_grant_in),
        .vme_bus_grant_out(vme_bus_grant_out),

        .cpu_as(cpu_as),
        .cpu_ds(cpu_ds),
        .cpu_write(cpu_write),
        .cpu_siz(cpu_siz),
        .cpu_address_top(cpu_address[31:24] != 8'hff),
        .cpu_address_high(cpu_address[23:20]),
        .cpu_address_mid_0(cpu_address[16]),
        .cpu_address_low(cpu_address[1:0]),
        .cpu_fc(cpu_fc),
        .cpu_dsack(cpu_dsack),
        .cpu_ipl(cpu_ipl),

        .vme_as(vme_as),
        .vme_ds(vme_ds),
        .vme_lword(vme_lword),
        .vme_write(vme_write),
        .vme_address_mod(vme_address_mod),
        .vme_dtack(vme_dtack),
        .vme_berr(vme_berr),
        .vme_ipl(vme_ipl),
        .vme_iack(vme_iack),

        .serial_irq(serial_irq),
        .serial_iack(serial_iack),

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

        $dumpfile("buslogic.vcd");
        $dumpvars(0, DTS);
    end

   // 20 ns clock
    always
        #10 clock = !clock;

    reg [7:0] loop = 8'd00;

    initial begin
        #0
            vme_dtack = INACTIVE;
            vme_berr = INACTIVE;
            cpu_as = INACTIVE;
            cpu_ds = INACTIVE;
            cpu_address = 32'h00000000;
            cpu_fc = 3'b110;
            vme_bus_grant_in = INACTIVE;

        while (loop != 8'd16) begin
/*
        #10
            // 32-Bit A40/MD32 Cycle
            cpu_siz = 2'b00;
            cpu_as = ACTIVE;
            request_vme_a40 = ACTIVE;
            vme_bus_grant_in = ACTIVE;

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
            request_vme_a40 = INACTIVE;
            vme_bus_grant_in = INACTIVE;
        #1
            vme_dtack = INACTIVE;
*/
        #40
            // 16-Bit Cycle
            cpu_siz = 2'b10;
            cpu_as = ACTIVE;
            cpu_address = 32'hFF800000;
            vme_bus_grant_in = ACTIVE;

        //#1
            cpu_ds = ACTIVE;

        #60
            vme_dtack = ACTIVE;
            while (cpu_dsack == 2'b11) begin
                #1;
            end
            cpu_as = INACTIVE;
            cpu_ds = INACTIVE;
            cpu_address = 32'h00000000;
            vme_bus_grant_in = INACTIVE;
        #1
            vme_dtack = INACTIVE;


        #40
            // 8-Bit Even Cycle
            cpu_address = 2'b00;
            cpu_siz = 2'b01;
            cpu_as = ACTIVE;
            cpu_address = 32'hFF800000;
            vme_bus_grant_in = ACTIVE;

        //#1
            cpu_ds = ACTIVE;

        #20
            vme_dtack = ACTIVE;
            while (cpu_dsack == 2'b11) begin
                #1;
            end
            cpu_as = INACTIVE;
            cpu_ds = INACTIVE;
            cpu_address = 32'h00000000;
            vme_bus_grant_in = INACTIVE;
        #1
            vme_dtack = INACTIVE;


        #40
            // 8-Bit Odd Cycle
            cpu_address = 2'b01;
            cpu_siz = 2'b01;
            cpu_as = ACTIVE;
            cpu_address = 32'hFF800000;
            vme_bus_grant_in = ACTIVE;

        //#1
            cpu_ds = ACTIVE;

        #20
            vme_dtack = ACTIVE;
            while (cpu_dsack == 2'b11) begin
                #1;
            end
            cpu_as = INACTIVE;
            cpu_ds = INACTIVE;
            cpu_address = 32'h00000000;
            vme_bus_grant_in = INACTIVE;
        #1
            vme_dtack = INACTIVE;

        #10
            loop = loop + 8'd01;
        end

        #50 $finish;
    end

    always
        #10000 $finish;

endmodule
