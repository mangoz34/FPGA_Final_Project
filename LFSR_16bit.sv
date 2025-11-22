module LFSR_16bit (
    input logic CLK,
    input logic RESET_N,
    output logic [15:0] rand_out,
    output logic [3:0] rand_digit
);

    logic [15:0] lfsr_reg;

    logic feedback;
    assign feedback = lfsr_reg[15] ^ lfsr_reg[13] ^ lfsr_reg[12] ^ lfsr_reg[10];

    always_ff @(posedge CLK or negedge RESET_N) begin
        if (!RESET_N) begin
            lfsr_reg <= 16'hBEEF;
        end else begin
            lfsr_reg <= {lfsr_reg[14:0], feedback};
        end
    end

    assign rand_out = lfsr_reg;

    //use the remainer as simulation of random output
    assign rand_digit = lfsr_reg[3:0] % 4'd10;

endmodule