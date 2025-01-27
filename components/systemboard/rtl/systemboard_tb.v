module systemboard_tb();

    localparam ACTIVE = 1'b0;
    localparam INACTIVE = 1'b1;

    reg clock;
    reg reset;
    wire status_led;

    wire vme_sysclk;

    reg vme_address_strobe;
    reg [1:0] vme_data_strobe;
    reg vme_lword;
    reg vme_write;
    wire vme_dtack;
    reg [5:0] vme_address_mod;
    reg [23:0] vme_address;
    wire [7:0] vme_data;

    wire vme_bclr;
    wire [3:0] vme_bgout;
    reg [3:0] vme_br;

    systemboard DTS(
        .clock(clock),
        .reset(reset),
        .status_led(status_led),

        .vme_sysclk(vme_sysclk),

        .vme_address_strobe(vme_address_strobe),
        .vme_data_strobe(vme_data_strobe),
        .vme_lword(vme_lword),
        .vme_write(vme_write),
        .vme_dtack(vme_dtack),
        .vme_address_mod(vme_address_mod),
        .vme_address(vme_address),
        .vme_data(vme_data),

        .vme_bclr(vme_bclr),
        .vme_bgout(vme_bgout),
        .vme_br(vme_br)
    );

    initial begin
        $display("Starting");

        $dumpfile("systemboard.vcd");
        $dumpvars(0, DTS);
    end

    always
        #10 clock = !clock;

    initial begin
        #0
            reset = INACTIVE;
            vme_address_strobe = INACTIVE;
            vme_data_strobe = { INACTIVE, INACTIVE };
            vme_lword = INACTIVE;
            vme_write = INACTIVE;
            vme_address_mod = 6'b111111;
            vme_address = 24'hFFFFFF;
            vme_data = 8'hFF;

        #10

            vme_write = ACTIVE;

        #10
            vme_address = 24'h555554;
            vme_address_mod = 6'h3D;
            vme_address_strobe = ACTIVE;
        #8
            vme_data_strobe = { ACTIVE, ACTIVE };


            while (vme_dtack == INACTIVE) begin
                #10;
            end

        #10
            vme_address_strobe = INACTIVE;
            vme_data_strobe = INACTIVE;
            vme_write = INACTIVE;

        #50
            $finish;

    end

endmodule
