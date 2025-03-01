`include "interrupts.v"
`include "local_peripherals.v"
`include "vmebus_interface.v"

module buslogic(
    input clock,
    input reset,
    output reg cpu_clock,
    output reg status_led,

    output request_ram,
    output request_rom,
    output [3:0] ram_ds,
    output request_serial,

    output reg vme_bus_request,
    input vme_bus_grant_in,
    output reg vme_bus_grant_out,

    input cpu_as,
    input cpu_ds,
    input cpu_write,
    input [1:0] cpu_siz,
    input cpu_address_top,
    input [3:0] cpu_address_high,
    input cpu_address_mid_0,
    input [1:0] cpu_address_low,
    input [2:0] cpu_fc,
    inout [1:0] cpu_dsack,
    inout cpu_berr,
    output reg [2:0] cpu_ipl,

    inout vme_as,
    inout [1:0] vme_ds,
    inout vme_lword,
    inout vme_write,
    inout [5:0] vme_address_mod,
    input vme_dtack,
    input vme_berr,
    input [2:0] vme_ipl,
    inout vme_iack,

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
    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    reg bus_acquired;
    reg request_vme_a16;
    reg request_vme_a24;
    reg request_vme_a40;
    reg request_unmapped;

    reg [1:0] cpu_dsack_out;
    reg [1:0] vme_dsack_out;
    reg cpu_berr_out;
    reg vme_berr_out;

    reg vme_as_out;
    reg [1:0] vme_ds_out;
    reg vme_lword_out;
    reg vme_write_out;
    reg [5:0] vme_address_mod_out;

    wire inv_clock;
    assign inv_clock = !clock;

    //assign cpu_clock = clock;
    reg [3:0] clock_counter;
    always @(posedge inv_clock) begin
        clock_counter <= clock_counter + 4'b0001;
        cpu_clock <= clock_counter[0];
    end

    reg [1:0] cpu_as_fifo;
    reg [1:0] cpu_ds_fifo;
    reg [1:0] bus_acquired_fifo;
    reg [1:0] vme_dtack_fifo;

    // Synchronizing the input signals from the CPU
    // It uses both the negative and positive edges to decrease the time needed
    // Starting on the negative edge because the CPU starts on the positive edge
    always @(negedge clock) begin
        cpu_as_fifo[1] <= cpu_as;
        cpu_ds_fifo[1] <= cpu_ds;
        bus_acquired_fifo[1] <= bus_acquired;
        vme_dtack_fifo[1] <= vme_dtack;
    end

    always @(posedge clock) begin
        cpu_as_fifo[0] <= cpu_as_fifo[1];
        cpu_ds_fifo[0] <= cpu_ds_fifo[1];
        bus_acquired_fifo[0] <= bus_acquired_fifo[1];
        vme_dtack_fifo[0] <= vme_dtack_fifo[1];
    end

    address_decode address_decode(
        .cpu_as(cpu_as_fifo[0]),
        .address_high(cpu_address_high),
        .n_address_top(cpu_address_top),

        .request_ram(request_ram),
        .request_rom(request_rom),
        .request_serial(request_serial),
        .request_vme_a16(request_vme_a16),
        .request_vme_a24(request_vme_a24),
        .request_vme_a40(request_vme_a40),
        .request_unmapped(request_unmapped)
    );

    wire request_vme;
    assign request_vme = (request_vme_a16 == ACTIVE) || (request_vme_a24 == ACTIVE) || (request_vme_a40 == ACTIVE) ? ACTIVE : INACTIVE;

    ram_select ram_select(
        .request_ram(request_ram),
        .cpu_ds(cpu_ds),
        .cpu_siz(cpu_siz),
        .address(cpu_address_low),

        .ram_ds(ram_ds)
    );

    vme_bus_arbitration vme_bus_arbitration(
        .clock(inv_clock),

        .request_vme(request_vme),
        .vme_as_out(vme_as_out),
        .bus_acquired(bus_acquired),

        .vme_bus_request(vme_bus_request),
        .vme_bus_grant_in(vme_bus_grant_in),
        .vme_bus_grant_out(vme_bus_grant_out),
    );

    assign vme_as = bus_acquired == ACTIVE ? vme_as_out : 1'bZ;
    assign vme_ds = bus_acquired == ACTIVE ? vme_ds_out : 2'bZZ;
    assign vme_lword = bus_acquired == ACTIVE ? vme_lword_out : 1'bZ;
    assign vme_write = bus_acquired == ACTIVE ? vme_write_out : 1'bZ;
    assign vme_address_mod = bus_acquired == ACTIVE ? vme_address_mod_out : 6'bZZZZZZ;

    vme_data_transfer vme_data_transfer(
        .clock(inv_clock),
        .reset(reset),
        .status_led(status_led),

        .request_vme_sync(request_vme),
        .request_vme_a16(request_vme_a16),
        .request_vme_a24(request_vme_a24),
        .request_vme_a40(request_vme_a40),
        .bus_acquired_sync(bus_acquired_fifo[0]),

        .cpu_as_sync(cpu_as_fifo[0]),
        .cpu_ds_sync(cpu_ds_fifo[0]),
        .cpu_write(cpu_write),
        .cpu_siz(cpu_siz),
        .cpu_address(cpu_address_low),
        .cpu_fc(cpu_fc),
        .cpu_dsack(vme_dsack_out),
        .cpu_berr(vme_berr_out),

        .vme_as(vme_as_out),
        .vme_ds(vme_ds_out),
        .vme_lword(vme_lword_out),
        .vme_write(vme_write_out),
        .vme_address_mod(vme_address_mod_out),
        .vme_dtack_sync(vme_dtack_fifo[0]),
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

    assign cpu_dsack[0] = cpu_dsack_out[0] == ACTIVE ? 1'b0 : 1'bZ;
    assign cpu_dsack[1] = cpu_dsack_out[1] == ACTIVE ? 1'b0 : 1'bZ;
    assign cpu_berr = ((cpu_berr_out == ACTIVE) || (vme_berr_out == ACTIVE)) ? 1'b0 : 1'bZ;

    /*
    assign cpu_dsack_out[0] = ( (cpu_as == ACTIVE) && (cpu_fc != 3'b111) && (
        (request_vme == ACTIVE && vme_dsack_out[0] == ACTIVE) ||
        (vme_as_out != ACTIVE &&
            (request_ram == ACTIVE) ||
            (request_rom == ACTIVE)
        )
    )) ? ACTIVE : INACTIVE;

    assign cpu_dsack_out[1] = ( (cpu_as == ACTIVE) && (cpu_fc != 3'b111) && (
        (request_vme == ACTIVE && vme_dsack_out[1] == ACTIVE) ||
        (vme_as_out != ACTIVE &&
            (request_ram == ACTIVE)
        )
    )) ? ACTIVE : INACTIVE;

    //assign cpu_berr_out = INACTIVE;
    assign cpu_berr_out = ( (cpu_as == ACTIVE) && (cpu_fc != 3'b111) && (
        (request_vme != ACTIVE && vme_as_out != ACTIVE && request_ram != ACTIVE && request_rom != ACTIVE && request_serial != ACTIVE)
    )) ? ACTIVE : INACTIVE;
    */

    always @(*) begin
        if (cpu_fc == 3'b111) begin
            cpu_dsack_out <= 2'b11;
            cpu_berr_out <= INACTIVE;
        end else if (request_vme == ACTIVE) begin
            cpu_dsack_out <= vme_dsack_out;
            cpu_berr_out <= INACTIVE;
        end else if (!(request_vme == ACTIVE || vme_as_out == ACTIVE || vme_dsack_out == ACTIVE)) begin
            if (request_ram == ACTIVE) begin
                cpu_dsack_out <= 2'b00;
                cpu_berr_out <= INACTIVE;
            end else if (request_rom == ACTIVE) begin
                cpu_dsack_out <= 2'b10;
                cpu_berr_out <= INACTIVE;
            end else if (request_unmapped == ACTIVE) begin
                cpu_dsack_out <= 2'b11;
                cpu_berr_out <= ACTIVE;
            end else begin
                cpu_dsack_out <= 2'b11;
                cpu_berr_out <= INACTIVE;
            end
        end else begin
            cpu_dsack_out <= 2'b11;
            cpu_berr_out <= INACTIVE;
        end
    end

    /*
    assign cpu_dsack[0] = cpu_dsack_out[0] == ACTIVE ? 1'b0 : 1'bZ;
    assign cpu_dsack[1] = cpu_dsack_out[1] == ACTIVE ? 1'b0 : 1'bZ;

    assign vme_as = bus_acquired == ACTIVE ? vme_as_out : 1'bZ;
    assign vme_ds = bus_acquired == ACTIVE ? vme_ds_out : 1'bZ;
    assign vme_lword = bus_acquired == ACTIVE ? vme_lword_out : 1'bZ;
    assign vme_write = bus_acquired == ACTIVE ? vme_write_out : 1'bZ;
    assign vme_address_mod = bus_acquired == ACTIVE ? vme_address_mod_out : 1'bZ;

    always @(*) begin
        //addr_low_oe <= serial_ip4;
        //md32_cross_oe <= !serial_ip4;
        //md32_cross_dir <= serial_ip5;

        addr_low_oe <= INACTIVE;
        md32_cross_oe <= INACTIVE;
        md32_cross_dir <= 1'b0;

        a40_cross_oe <= INACTIVE;

        //data_low_oe <= serial_op2;
        //d16_cross_oe <= !serial_op2;
        //data_low_dir <= serial_op3;
        //d16_cross_dir <= serial_op3;

        data_low_oe <= INACTIVE;
        d16_cross_oe <= INACTIVE;
        data_low_dir <= 1'b0;
        d16_cross_dir <= 1'b0;

        vme_as_out <= 1'b1;
        vme_ds_out <= 2'b11;
        vme_lword_out <= 1'b1;
        vme_write_out <= 1'b1;
        vme_address_mod_out <= 6'b101010;

        if (request_ram == ACTIVE) begin
            cpu_dsack_out <= 2'b00;
        end else if (request_rom == ACTIVE) begin
            cpu_dsack_out <= 2'b10;
        end else begin
            cpu_dsack_out <= 2'b11;
        end
    end
    */

    /*
    assign serial_iack = 1'b1;
    assign cpu_ipl = 1'b111;
    assign vme_iack = 1'b1;
    */
    interrupts interrupts(
        .cpu_as(cpu_as),
        .cpu_fc(cpu_fc),
        .cpu_ipl(cpu_ipl),
        .address_16(cpu_address_mid_0),
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
//PIN: reset                : 89
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
//PIN: cpu_avec             : 92

//PIN: cpu_address_top      : 50
//PIN: cpu_address_high_3   : 49
//PIN: cpu_address_high_2   : 48
//PIN: cpu_address_high_1   : 47
//PIN: cpu_address_high_0   : 46
//PIN: cpu_address_mid_0    : 41
//PIN: cpu_address_low_1    : 36
//PIN: cpu_address_low_0    : 35

//PIN: cpu_bus_request      : 98
//PIN: cpu_bus_grant        : 99
//PIN: cpu_bus_grant_ack    : 100

//PIN: addr_low_oe          : 27
//PIN: a40_cross_oe         : 28
//PIN: data_low_oe          : 31
//PIN: d16_cross_oe         : 29
//PIN: md32_cross_oe        : 25
//PIN: data_low_dir         : 32
//PIN: d16_cross_dir        : 30
//PIN: md32_cross_dir       : 33

//PIN: request_rom          : 83
//PIN: request_ram          : 84
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
//PIN: vme_bus_busy         : 52

//PIN: vme_as               : 77
//PIN: vme_lword            : 76
//PIN: vme_write            : 75
//PIN: vme_ds_1             : 72
//PIN: vme_ds_0             : 71
//PIN: vme_dtack            : 70
//PIN: vme_berr             : 69

//PIN: vme_address_mod_0    : 68
//PIN: vme_address_mod_1    : 67
//PIN: vme_address_mod_2    : 65
//PIN: vme_address_mod_3    : 64
//PIN: vme_address_mod_4    : 63
//PIN: vme_address_mod_5    : 61

//PIN: vme_ipl_0            : 60
//PIN: vme_ipl_1            : 58
//PIN: vme_ipl_2            : 57
//PIN: vme_iack             : 56
