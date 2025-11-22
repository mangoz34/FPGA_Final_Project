module hex_decoder (
    input  logic [3:0] hex_in,
    output logic [6:0] hex_out
);
    always_comb begin
        case (hex_in)
            4'h0: hex_out = 7'b1000000; // 0
            4'h1: hex_out = 7'b1111001; // 1
            4'h2: hex_out = 7'b0100100; // 2
            4'h3: hex_out = 7'b0110000; // 3
            4'h4: hex_out = 7'b0011001; // 4
            4'h5: hex_out = 7'b0010010; // 5
            4'h6: hex_out = 7'b0000010; // 6
            4'h7: hex_out = 7'b1111000; // 7
            4'h8: hex_out = 7'b0000000; // 8
            4'h9: hex_out = 7'b0010000; // 9
            4'hA: hex_out = 7'b0001000; // A
            4'hB: hex_out = 7'b0000011; // b
            4'hC: hex_out = 7'b1110111; // _
            4'hD: hex_out = 7'b0100001; // d
            4'hE: hex_out = 7'b0000110; // E
            4'hF: hex_out = 7'b1111111; // Blank
            default: hex_out = 7'b1111111;
        endcase
    end
endmodule
