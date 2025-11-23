module priority_encoder (
    input  logic [9:0] sw,
    output logic [3:0] hex_val,
    output logic valid
);

    always_comb begin
        valid = 1'b1;
        hex_val = 4'd0;

        if      (sw[9]) hex_val = 4'd9;
        else if (sw[8]) hex_val = 4'd8;
        else if (sw[7]) hex_val = 4'd7;
        else if (sw[6]) hex_val = 4'd6;
        else if (sw[5]) hex_val = 4'd5;
        else if (sw[4]) hex_val = 4'd4;
        else if (sw[3]) hex_val = 4'd3;
        else if (sw[2]) hex_val = 4'd2;
        else if (sw[1]) hex_val = 4'd1;
        else if (sw[0]) hex_val = 4'd0;
        else begin
            valid = 1'b0;
            hex_val = 4'd0;
        end
    end

endmodule