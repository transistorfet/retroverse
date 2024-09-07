module buslogic(
    input clock,
    input cpu_address_strobe,
    output data_strobe_0,
    output data_strobe_1,
    output reg [1:0] counter
);

    reg output_enable = 1'b1;
    reg [1:0] data_strobe = 2'b01;

    assign data_strobe_0 = output_enable ? 1'bZ : data_strobe[0];
    assign data_strobe_1 = output_enable ? 1'bZ : data_strobe[1];

    always @(posedge clock) begin
        counter <= counter + 1;
        if (cpu_address_strobe == 1'b1) begin
            output_enable = 1'b1;
        end else begin
            output_enable = 1'b0;
        end
    end

endmodule
// Pin assignment for the experimental Yosys FLoow
//
//PIN: CHIP "counter" ASSIGNED TO AN PLCC84
//PIN: clock      : 54
//PIN: counter_0  : 69
//PIN: counter_1  : 67
//PIN: data_strobe_0 : 64
//PIN: data_strobe_1 : 60
//PIN: cpu_address_strobe : 51
