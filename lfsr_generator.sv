module lfsr_generator (
    input  logic        clk,
    input  logic        reset_n,
    output logic [3:0]  rand_digit
);
    logic [15:0] lfsr_reg;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            lfsr_reg <= 16'hACE1;
        end else begin
            logic feedback;
            feedback = lfsr_reg[0] ^ lfsr_reg[2] ^ lfsr_reg[3] ^ lfsr_reg[5];
            lfsr_reg <= {feedback, lfsr_reg[15:1]};
        end
    end

    assign rand_digit = lfsr_reg[3:0] % 10; 

endmodule