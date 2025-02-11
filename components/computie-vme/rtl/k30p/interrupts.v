module interrupts(
    // TODO should these pins have 7405 open collector buffers on them?  There is still a need for a hardware serial interrupt on the same lines
    output [2:0] cpu_ipl,
    input cpu_as,
    input [2:0] cpu_fc,
    input address_16,

    input [2:0] vme_ipl,
    output vme_iack,

    input serial_irq,
    output serial_iack,
);

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    wire cpu_iack;

    assign cpu_ipl = serial_irq == ACTIVE ? 3'b010 : vme_ipl;
    assign cpu_iack = (cpu_as == ACTIVE && cpu_fc == 3'b111 && address_16 == 1'b1) ? ACTIVE : INACTIVE;
    assign serial_iack = (serial_irq == ACTIVE && cpu_iack == ACTIVE) ? ACTIVE : INACTIVE;
    // NOTE: vme_iack has an open collector inverter between the CPLD and the bus, so it's positive logic
    assign vme_iack = (serial_irq == INACTIVE && vme_ipl != 3'b111 && cpu_iack == ACTIVE) ? 1'b1 : 1'b0;

endmodule
