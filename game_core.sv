import game_types::*;

module game_core (
    input logic clk,
    input logic reset_n,
    input logic p0_pulse,
    input logic p1_pulse,
    input logic [3:0] sw_val,
    input logic sw_valid,
    input logic [3:0] lfsr_val,
    
    output state_t current_state,
    output logic [3:0] target [3:0],
    output logic [3:0] guess  [3:0],
    output logic [3:0] candidate,
    output logic [2:0] chances,
    output logic [3:0] is_random
);


    logic is_duplicate;
    
    assign candidate = sw_valid ? sw_val : lfsr_val;

    always_comb begin
        is_duplicate = 1'b0;
        case (current_state)
            S_SET_D2:   if (candidate == target[3]) is_duplicate = 1'b1;
            S_SET_D1:   if (candidate == target[3] || candidate == target[2]) is_duplicate = 1'b1;
            S_SET_D0:   if (candidate == target[3] || candidate == target[2] || candidate == target[1]) is_duplicate = 1'b1;
            
            S_GUESS_D2: if (candidate == guess[3]) is_duplicate = 1'b1;
            S_GUESS_D1: if (candidate == guess[3] || candidate == guess[2]) is_duplicate = 1'b1;
            S_GUESS_D0: if (candidate == guess[3] || candidate == guess[2] || candidate == guess[1]) is_duplicate = 1'b1;
            default:    is_duplicate = 1'b0;
        endcase
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_state <= S_IDLE;
            chances <= 5;
            is_random <= 4'b0000;
            for(int i=0; i<4; i++) begin target[i] <= 0; guess[i] <= 0; end
        end else begin
            case (current_state)
                S_IDLE: begin
                    if (p0_pulse) begin 
                        current_state <= S_SET_D3; 
                        chances <= 5;
                        is_random <= 4'b0000;
                    end
                end

                //Setting Phase
                S_SET_D3: if (p0_pulse) begin 
                    target[3] <= candidate; 
                    is_random[3] <= !sw_valid;
                    current_state <= S_SET_D2; 
                end
                S_SET_D2: begin
                    if (p0_pulse && !is_duplicate) begin 
                        target[2] <= candidate; 
                        is_random[2] <= !sw_valid;
                        current_state <= S_SET_D1; 
                    end
                    else if (p1_pulse) current_state <= S_SET_D3;
                end
                S_SET_D1: begin
                    if (p0_pulse && !is_duplicate) begin 
                        target[1] <= candidate; 
                        is_random[1] <= !sw_valid;
                        current_state <= S_SET_D0; 
                    end
                    else if (p1_pulse) current_state <= S_SET_D2;
                end
                S_SET_D0: begin
                    if (p0_pulse && !is_duplicate) begin 
                        target[0] <= candidate; 
                        is_random[0] <= !sw_valid;
                        current_state <= S_GUESS_D3; 
                    end
                    else if (p1_pulse) current_state <= S_SET_D1;
                end

                //Guessing Phase
                S_GUESS_D3: begin
                    if (p0_pulse && sw_valid) begin guess[3] <= candidate; current_state <= S_GUESS_D2; end
                end
                S_GUESS_D2: begin
                    if (p0_pulse && sw_valid && !is_duplicate) begin guess[2] <= candidate; current_state <= S_GUESS_D1; end
                    else if (p1_pulse) current_state <= S_GUESS_D3;
                end
                S_GUESS_D1: begin
                    if (p0_pulse && sw_valid && !is_duplicate) begin guess[1] <= candidate; current_state <= S_GUESS_D0; end
                    else if (p1_pulse) current_state <= S_GUESS_D2;
                end
                
                S_GUESS_D0: begin
                    if (p0_pulse && sw_valid && !is_duplicate) begin
                        guess[0] <= candidate;
                        if ( (guess[3] == target[3] ? 1:0) + 
                             (guess[2] == target[2] ? 1:0) + 
                             (guess[1] == target[1] ? 1:0) + 
                             (candidate == target[0] ? 1:0) == 4 ) begin
                            current_state <= S_WIN;
                        end else begin
                            if (chances == 1) begin
                                chances <= 0;
                                current_state <= S_LOSE;
                            end else begin
                                chances <= chances - 1;
                                current_state <= S_SHOW_RESULT;
                            end
                        end
                    end 
                    else if (p1_pulse) current_state <= S_GUESS_D1;
                end

                S_SHOW_RESULT: if (p0_pulse) current_state <= S_GUESS_D3;
                S_WIN: ;
                S_LOSE: ;
            endcase
        end
    end
endmodule