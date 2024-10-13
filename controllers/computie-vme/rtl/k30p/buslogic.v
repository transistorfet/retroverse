`include "interrupts.v"
`include "local_peripherals.v"
`include "vmebus_interface.v"

module buslogic(
    input clock,
    output cpu_clock,

    output [3:0] ram_ds,

    output vme_bus_request,
    input vme_bus_grant_in,
    output vme_bus_grant_out,

    input cpu_as,
    input cpu_ds,
    input cpu_write,
    input [1:0] cpu_siz,
    input [23:20] cpu_address_high,
    input [1:0] cpu_address_low,
    input [2:0] cpu_fc,
    output [1:0] cpu_dsack,
    output [2:0] cpu_ipl,

    output vme_as,
    output [1:0] vme_ds,
    output vme_lword,
    output vme_write,
    output [5:0] vme_address_mod,
    input vme_dtack,
    input vme_berr,
    input [2:0] vme_ipl,
    output vme_iack,

    input serial_irq,
    output serial_iack,

    output addr_low_oe,
    output a40_cross_oe,
    output data_low_oe,
    output data_low_dir,
    output d16_cross_oe,
    output d16_cross_dir,
    output md32_cross_oe,
    output md32_cross_dir
);

    reg bus_acquired;
    reg request_ram;
    reg request_rom;
    reg request_serial;
    reg request_vme_a16;
    reg request_vme_a24;
    reg request_vme_a40;

    assign cpu_clock = clock;

    address_decode address_decode(
        .cpu_as(cpu_as),
        .address(cpu_address_high),

        .request_ram(request_ram),
        .request_rom(request_rom),
        .request_serial(request_serial),
        .request_vme_a16(request_vme_a16),
        .request_vme_a24(request_vme_a24),
        .request_vme_a40(request_vme_a40)
    );

    ram_select ram_select(
        .request_ram(request_ram),
        .cpu_ds(cpu_ds),
        .cpu_siz(cpu_siz),
        .address(cpu_address_low),

        .ram_ds(ram_ds)
    );

    vme_bus_arbitration vme_bus_arbitration(
        .clock(clock),

        .request_vme(request_vme_a16 || request_vme_a24 || request_vme_a40),

        .bus_acquired(bus_acquired),

        .vme_bus_request(vme_bus_request),
        .vme_bus_grant_in(vme_bus_grant_in),
        .vme_bus_grant_out(vme_bus_grant_out),
    );

    vme_data_transfer vme_data_transfer(
        .clock(clock),

        .request_vme_a16(request_vme_a16),
        .request_vme_a24(request_vme_a24),
        .request_vme_a40(request_vme_a40),
        .bus_acquired(bus_acquired),

        .cpu_as(cpu_as),
        .cpu_ds(cpu_ds),
        .cpu_write(cpu_write),
        .cpu_siz(cpu_siz),
        .cpu_address(cpu_address_low),
        .cpu_fc(cpu_fc),
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

    interrupts interrupts(
        .cpu_as(cpu_as),
        .cpu_fc(cpu_fc),
        .cpu_ipl(cpu_ipl),
        .vme_ipl(vme_ipl),
        .vme_iack(vme_iack),
        .serial_irq(serial_irq),
        .serial_iack(serial_iack)
    );

endmodule

