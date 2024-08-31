module k30logic(
    input 
);
    wire [3:0] V_OE; // AH, AL, DH, DL

    assign is_external = /* address matches */

    if (L_AS == ACTIVE && is_external) begin
        V_OE <= 4'b1111;    // set all transceiver outputs to off
        V_DIR <= 4'b0000;
        L_DSACK0 <= INACTIVE;
        L_DSACK1 <= INACTIVE;

        V_BR <= ACTIVE;
        if (V_BGIN == ACTIVE) begin
            case (L_SIZ)
                2'b00: begin
                    // TODO implement controls for DS, LWORD, etc
                    V_LWORD <= 1'b0;
                    V_OE <= 4'b0000;
                end
            endcase

            V_WRITE <= L_RW;
            if (L_RW == ACTIVE) begin
                V_DIR <= 4'b1100;
            end else begin
                V_DIR <= 4'b1111;
            end

            V_AS <= ACTIVE;

            if (V_DTACK == ACTIVE) begin
                L_DSACK0 <= ACTIVE;
                L_DSACK1 <= ACTIVE;
                V_AS <= INACTIVE;
            end
        end
    end
endmodule
