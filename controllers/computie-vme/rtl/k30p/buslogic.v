`include "interrupts.v"
`include "local_peripherals.v"
`include "vmebus_interface.v"

module buslogic(
    input clock,
    output reg cpu_clock,

    output [3:0] ram_ds,

    output reg vme_bus_request,
    input vme_bus_grant_in,
    output reg vme_bus_grant_out,

    input cpu_as,
    input cpu_ds,
    input cpu_write,
    input [1:0] cpu_siz,
    input [23:20] cpu_address_high,
    input [1:0] cpu_address_low,
    input [2:0] cpu_fc,
    inout [1:0] cpu_dsack,
    input cpu_berr,
    output reg [2:0] cpu_ipl,

    /*
    inout vme_as,
    inout [1:0] vme_ds,
    inout vme_lword,
    inout vme_write,
    inout [5:0] vme_address_mod,
    input vme_dtack,
    input vme_berr,
    input [2:0] vme_ipl,
    inout vme_iack,
    */

    input serial_irq,
    output serial_iack,
    //input serial_op2,
    //input serial_op3,
    //input serial_ip4,
    //input serial_ip5,

    output reg addr_low_oe,
    output reg a40_cross_oe,
    output reg data_low_oe,
    output reg data_low_dir,
    output reg d16_cross_oe,
    output reg d16_cross_dir,
    output reg md32_cross_oe,
    output reg md32_cross_dir
);

    reg bus_acquired;
    reg request_ram;
    reg request_rom;
    reg request_serial;
    reg request_vme_a16;
    reg request_vme_a24;
    reg request_vme_a40;

    //assign cpu_clock = clock;
    reg [2:0] clock_counter;
    always @(posedge clock) begin
        clock_counter <= clock_counter + 3'b001;
        cpu_clock <= clock_counter[1];
    end

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

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

    /*
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
    */

    always @(*) begin
        addr_low_oe <= serial_ip4;
        md32_cross_oe <= !serial_ip4;
        md32_cross_dir <= serial_ip5;

        addr_low_oe <= INACTIVE;
        md32_cross_oe <= INACTIVE;
        md32_cross_dir <= INACTIVE;

        a40_cross_oe <= INACTIVE;

        //data_low_oe <= serial_op2;
        //d16_cross_oe <= !serial_op2;
        //data_low_dir <= serial_op3;
        //d16_cross_dir <= serial_op3;

        data_low_oe <= INACTIVE;
        d16_cross_oe <= INACTIVE;
        data_low_dir <= INACTIVE;
        d16_cross_dir <= INACTIVE;

        vme_address_mod <= 6'bXXXXXX;

        cpu_dsack <= 2'bZZ;
        if (request_ram) begin
            cpu_dsack <= 2'b00;
        end else if (request_rom || request_serial) begin
            cpu_dsack <= 2'bZ0;
        end
    end

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

// Pin assignment for the experimental Yosys FLoow
//
//PIN: CHIP "buslogic" ASSIGNED TO AN TQFP100
//PIN: clock                : 87
//PIN: cpu_clock            : 85
//PIN: status_led           : 24

//PIN: cpu_as               : 1
//PIN: cpu_ds               : 2
//PIN: cpu_siz_0            : 5
//PIN: cpu_siz_1            : 6
//PIN: cpu_write            : 7
//PIN: cpu_dsack_0          : 8
//PIN: cpu_dsack_1          : 9
//PIN: cpu_berr             : 10

//PIN: cpu_fc_0             : 12
//PIN: cpu_fc_1             : 13
//PIN: cpu_fc_2             : 14

//PIN: cpu_ipl_0            : 96
//PIN: cpu_ipl_1            : 94
//PIN: cpu_ipl_2            : 93

//PIN: cpu_address_high_3   : 49
//PIN: cpu_address_high_2   : 48
//PIN: cpu_address_high_1   : 47
//PIN: cpu_address_high_0   : 46
//PIN: cpu_address_low_1    : 36
//PIN: cpu_address_low_0    : 35

//PIN: addr_low_oe          : 27
//PIN: a40_cross_oe         : 28
//PIN: data_low_oe          : 31
//PIN: d16_cross_oe         : 29
//PIN: md32_cross_oe        : 25
//PIN: data_low_dir         : 32
//PIN: d16_cross_dir        : 30
//PIN: md32_cross_dir       : 33

//PIN: request_ram          : 84
//PIN: request_rom          : 85
//PIN: ram_ds_0             : 78
//PIN: ram_ds_1             : 79
//PIN: ram_ds_2             : 80
//PIN: ram_ds_3             : 81

//PIN: request_serial       : 16
//PIN: serial_irq           : 17
//PIN: serial_iack          : 19
//PIN: serial_op2           : 20
//PIN: serial_op3           : 21
//PIN: serial_ip4           : 22
//PIN: serial_ip5           : 23

//PIN: vme_bus_request      : 55
//PIN: vme_bus_grant_in     : 54
//PIN: vme_bus_grant_out    : 53

//P IN: vme_as               : 69
//P IN: vme_ds_0             : 67
//P IN: vme_ds_1             : 64
//P IN: vme_lword            : 60
//P IN: vme_write            : 27
//P IN: vme_dtack            : 9

//P IN: vme_address_mod_0    : 22
//P IN: vme_address_mod_1    : 28
//P IN: vme_address_mod_2    : 25
//P IN: vme_address_mod_3    : 21
//P IN: vme_address_mod_4    : 16
//P IN: vme_address_mod_5    : 17

