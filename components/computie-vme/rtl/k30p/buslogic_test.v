`include "interrupts.v"
`include "vmebus_interface.v"
`include "output_7seg.v"

// Pin assignment for the experimental Yosys FLoow
//
//PIN: CHIP "counter" ASSIGNED TO AN TQFP100
//PIN: clock                : 83
// LED1
//PIN: vme_as               : 69
// LED2
//PIN: vme_ds_0             : 67
// LED3
//PIN: vme_ds_1             : 64
// LED4
//PIN: vme_lword            : 60
// LED5
//PIN: vme_write            : 27

// LED8
//PIN: request_vme          : 15

// D1A
//PIN: cpu_dsack_0          : 68
// D1B
//PIN: cpu_dsack_1          : 74

// D2A
//PIN: addr_low_oe          : 52
// D2B
//PIN: a40_cross_oe         : 57
// D2C
//PIN: data_low_oe          : 55
// D2D
//PIN: d16_cross_oe         : 48
// D2E
//PIN: md32_cross_oe        : 41
// D2F
//PIN: data_low_dir         : 50
// D2G
//PIN: d16_cross_dir        : 45

// SW1
//PIN: cpu_as               : 54
// SW2
//PIN: cpu_ds               : 51
// SW3
//PIN: cpu_siz_0            : 49
// SW4
//PIN: cpu_siz_1            : 44
// SW5
//PIN: vme_dtack            : 9

// D3A
//PIN: vme_address_mod_0    : 22
// D3B
//PIN: vme_address_mod_1    : 28
// D3C
//PIN: vme_address_mod_2    : 25
// D3D
//PIN: vme_address_mod_3    : 21
// D3E
//PIN: vme_address_mod_4    : 16
// D3F
//PIN: vme_address_mod_5    : 17

// D4A
//PIN: state_7seg_0    : 5
// D4B
//PIN: state_7seg_1    : 10
// D4C
//PIN: state_7seg_2    : 8
// D4D
//PIN: state_7seg_3    : 79
// D4E
//PIN: state_7seg_4    : 76
// D4F
//PIN: state_7seg_5    : 77
// D4G
//PIN: state_7seg_6    : 75


// TODO this is for testing
module buslogic_test(
    input clock,

    //output [3:0] ram_ds,

    //output vme_bus_request,
    //input vme_bus_grant_in,
    //output vme_bus_grant_out,

    input cpu_as,
    input cpu_ds,
    input cpu_write,
    input [1:0] cpu_siz,
    //input [23:20] cpu_address_high,
    //input [1:0] cpu_address_low,
    //input [2:0] cpu_fc,
    output [1:0] cpu_dsack,
    //output [2:0] cpu_ipl,

    output [6:0] state_7seg,

    output vme_as,
    output [1:0] vme_ds,
    output vme_lword,
    output vme_write,
    output [5:0] vme_address_mod,
    input vme_dtack,
    input vme_berr,
    //input [2:0] vme_ipl,
    //output vme_iack,

    //input serial_irq,
    //output serial_iack,

    output addr_low_oe,
    output a40_cross_oe,
    output data_low_oe,
    output data_low_dir,
    output d16_cross_oe,
    output d16_cross_dir,
    output md32_cross_oe,
    output md32_cross_dir
);

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    reg bus_acquired;
    reg request_ram;
    reg request_rom;
    reg request_serial;
    reg request_vme;

    wire inv_cpu_as;
    assign inv_cpu_as = !cpu_as;

    wire [1:0] state;

    /*
    address_decode address_decode(
        .cpu_as(cpu_as),
        .address(cpu_address_high),

        .request_ram(request_ram),
        .request_rom(request_rom),
        .request_serial(request_serial),
        .request_vme(request_vme)
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

        .request_vme(request_vme),
        .bus_acquired(bus_acquired),

        .vme_bus_request(vme_bus_request),
        .vme_bus_grant_in(vme_bus_grant_in),
        .vme_bus_grant_out(vme_bus_grant_out),
    );
    */

    output_7seg state_display(
        .number(state),
        .segments(state_7seg)
    );

    vme_data_transfer vme_data_transfer(
        .clock(clock),

        .state(state),

        .request_vme(inv_cpu_as),
        .bus_acquired(ACTIVE),

        .cpu_as(inv_cpu_as),
        .cpu_ds(!cpu_ds),
        .cpu_write(cpu_write),
        .cpu_siz(cpu_siz),
        .cpu_address(2'b00),
        .cpu_fc(3'b001),
        .cpu_dsack(cpu_dsack),

        .vme_as(vme_as),
        .vme_ds(vme_ds),
        .vme_lword(vme_lword),
        .vme_write(vme_write),
        .vme_address_mod(vme_address_mod),
        .vme_dtack(!vme_dtack),
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

    /*
    interrupts interrupts(
        .cpu_as(cpu_as),
        .cpu_fc(cpu_fc),
        .cpu_ipl(cpu_ipl),
        .vme_ipl(vme_ipl),
        .vme_iack(vme_iack),
        .serial_irq(serial_irq),
        .serial_iack(serial_iack)
    );
    */

endmodule



