module output_7seg(
    input [1:0] number,
    output [6:0] segments
);

    always @(*) begin
        case (number)
            2'h0: segments <= 7'b1000000;
            2'h1: segments <= 7'b1111001;
            2'h2: segments <= 7'b0100100;
            2'h3: segments <= 7'b0110000;
            2'h4: segments <= 7'b0011001;
            2'h5: segments <= 7'b0010010;
            2'h6: segments <= 7'b0000010;
            2'h7: segments <= 7'b1111000;
            2'h8: segments <= 7'b0000000;
            2'h9: segments <= 7'b0010000;
        endcase
    end

endmodule


