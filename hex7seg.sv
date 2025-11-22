module seven_seg_decoder (
    input logic [3:0] data_in,
    output logic [7:0] hex_out
);

    localparam BCD_UNDERSCORE = 4'hA;
    localparam BCD_CLEAR      = 4'hF;

    always_comb begin
        case (data_in)
            4'd0: hex_out = 8'b1000000; // 0
            4'd1: hex_out = 8'b1111001; // 1
            4'd2: hex_out = 8'b0100100; // 2
            4'd3: hex_out = 8'b0110000; // 3
            4'd4: hex_out = 8'b0011001; // 4
            4'd5: hex_out = 8'b0010010; // 5
            4'd6: hex_out = 8'b0000010; // 6
            4'd7: hex_out = 8'b1111000; // 7
            4'd8: hex_out = 8'b0000000; // 8
            4'd9: hex_out = 8'b0010000; // 9

            // Special sign
            BCD_UNDERSCORE: hex_out = 8'b1111110;
            BCD_CLEAR:      hex_out = 8'b1111111;

            // A, B
            4'hA: hex_out = 8'b0001000; // A
            4'hB: hex_out = 8'b0000011; // B

            default: hex_out = 8'b1111111;
        endcase
    end

endmodule