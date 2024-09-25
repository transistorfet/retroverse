module interrupts(
    input [2:0] vme_ipl,
    output vme_iack,

    // TODO should these pins have 7405 open collector buffers on them?  There is still a need for a hardware serial interrupt on the same lines
    output [2:0] cpu_ipl,
    input cpu_as,
    input [2:0] cpu_fc,

    input serial_irq,
    output serial_iack
);

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    wire cpu_iack;

    assign cpu_ipl = serial_irq ? 3'b010 : vme_ipl;
    assign cpu_iack = !(cpu_fc == 3'b111);
    assign serial_iack = (serial_irq == ACTIVE && cpu_as == ACTIVE && cpu_iack == ACTIVE);
    assign vme_iack = (serial_irq == INACTIVE && vme_ipl != 3'b111 && cpu_as == ACTIVE && cpu_iack == ACTIVE);

endmodule
