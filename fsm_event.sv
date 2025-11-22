module fsm_event (
    input logic CLK,
    input logic RESET_N,
    input logic P0_pulse,
    input logic P1_pulse,
    input logic P3_pulse,
    input logic [3:0] D_candidate, 
    input logic sw_enable,         
    input logic [2:0] Count_A_in,  
    output logic [3:0] Secret [0:3],
    output logic [3:0] Guess  [0:3],
    output logic [2:0] turn_count, 
    output logic [1:0] current_input_index, 
    output logic in_setup_phase,
    output logic in_guess_phase,
    output logic output_result_phase,
    output logic game_over
);
    
    typedef enum logic [3:0] {
        S_IDLE = 4'h0, S_INPUT_D3 = 4'h1, S_INPUT_D2 = 4'h2, S_INPUT_D1 = 4'h3, S_INPUT_D0 = 4'h4,
        S_GUESS_D3 = 4'h5, S_GUESS_D2 = 4'h6, S_GUESS_D1 = 4'h7, S_GUESS_D0 = 4'h8,
        S_CALCULATE = 4'h9, S_SHOW_RESULT = 4'hA, S_GAME_OVER = 4'hB
    } state_t;

    logic [3:0] current_state, next_state; 
    
    logic [3:0] Secret_reg [0:3];
    logic [3:0] Guess_reg  [0:3];
    logic [2:0] turn_count_reg; 
    
    always_ff @(posedge CLK or negedge RESET_N) begin
        if (!RESET_N || P3_pulse) begin // 硬重置或 P3 重置
            current_state <= S_IDLE;
            for (int i=0; i<4; i++) begin
                Secret_reg[i] <= 4'hA; // 4'hA = '_' 符號
                Guess_reg[i] <= 4'hA;
            end 
            turn_count_reg <= 0;
        end else begin
            current_state <= next_state;
        end
    end

    logic is_turn_increment;

    always_ff @(posedge CLK) begin
        if (is_turn_increment) begin
            turn_count_reg <= turn_count_reg + 1;
        end
    
        unique case (current_state)
            S_INPUT_D3: if (next_state == S_INPUT_D2) Secret_reg[3] <= D_candidate;
            S_INPUT_D2: if (next_state == S_INPUT_D1) Secret_reg[2] <= D_candidate;
            S_INPUT_D1: if (next_state == S_INPUT_D0) Secret_reg[1] <= D_candidate;
            S_INPUT_D0: if (next_state == S_GUESS_D3) Secret_reg[0] <= D_candidate;

            S_GUESS_D3: if (next_state == S_GUESS_D2) Guess_reg[3] <= D_candidate;
            S_GUESS_D2: if (next_state == S_GUESS_D1) Guess_reg[2] <= D_candidate;
            S_GUESS_D1: if (next_state == S_GUESS_D0) Guess_reg[1] <= D_candidate;
            S_GUESS_D0: if (next_state == S_CALCULATE) Guess_reg[0] <= D_candidate;
        endcase

        if (P1_pulse) begin
            unique case (current_state)
                S_INPUT_D2: Secret_reg[3] <= 4'hA; 
                S_INPUT_D1: Secret_reg[2] <= 4'hA;
                S_INPUT_D0: Secret_reg[1] <= 4'hA;
                S_GUESS_D2: Guess_reg[3] <= 4'hA;
                S_GUESS_D1: Guess_reg[2] <= 4'hA;
                S_GUESS_D0: Guess_reg[1] <= 4'hA;
            endcase
        end
    end

    
    logic is_duplicate;
    logic [1:0] input_idx_reg;
    
    always_comb begin
        next_state = current_state; 
        is_duplicate = 1'b0;
        is_turn_increment = 1'b0;
        input_idx_reg = 2'd0; // 預設值

        unique case (current_state)
            S_INPUT_D2: is_duplicate = (D_candidate == Secret_reg[3]);
            S_INPUT_D1: is_duplicate = (D_candidate == Secret_reg[3]) || (D_candidate == Secret_reg[2]);
            S_INPUT_D0: is_duplicate = (D_candidate == Secret_reg[3]) || (D_candidate == Secret_reg[2]) || (D_candidate == Secret_reg[1]);
            
            S_GUESS_D2: is_duplicate = (D_candidate == Guess_reg[3]);
            S_GUESS_D1: is_duplicate = (D_candidate == Guess_reg[3]) || (D_candidate == Guess_reg[2]);
            S_GUESS_D0: is_duplicate = (D_candidate == Guess_reg[3]) || (D_candidate == Guess_reg[2]) || (D_candidate == Guess_reg[1]);
        endcase
        
        unique case (current_state)
            S_IDLE:         if (P0_pulse) next_state = S_INPUT_D3;

            S_INPUT_D3:     if (P0_pulse) next_state = S_INPUT_D2; 
            S_INPUT_D2:     if (P0_pulse && !is_duplicate) next_state = S_INPUT_D1; else if (P1_pulse) next_state = S_INPUT_D3;
            S_INPUT_D1:     if (P0_pulse && !is_duplicate) next_state = S_INPUT_D0; else if (P1_pulse) next_state = S_INPUT_D2;
            S_INPUT_D0:     if (P0_pulse && !is_duplicate) next_state = S_GUESS_D3; else if (P1_pulse) next_state = S_INPUT_D1;
            
            S_GUESS_D3:     if (P0_pulse && sw_enable) next_state = S_GUESS_D2; 
            S_GUESS_D2:     if (P0_pulse && sw_enable && !is_duplicate) next_state = S_GUESS_D1; else if (P1_pulse) next_state = S_GUESS_D3;
            S_GUESS_D1:     if (P0_pulse && sw_enable && !is_duplicate) next_state = S_GUESS_D0; else if (P1_pulse) next_state = S_GUESS_D2;
            S_GUESS_D0:     if (P0_pulse && sw_enable && !is_duplicate) next_state = S_CALCULATE; else if (P1_pulse) next_state = S_GUESS_D1;

            S_CALCULATE:    next_state = S_SHOW_RESULT; 
            
            S_SHOW_RESULT: begin
                if (Count_A_in == 4 || turn_count_reg >= 5) next_state = S_GAME_OVER; 
                else if (P0_pulse) begin
                    next_state = S_GUESS_D3; 
                    is_turn_increment = 1'b1; 
                end
            end
            
            default: next_state = current_state; 
        endcase
    
        unique case (current_state)
            S_INPUT_D3, S_GUESS_D3: input_idx_reg = 2'd3;
            S_INPUT_D2, S_GUESS_D2: input_idx_reg = 2'd2;
            S_INPUT_D1, S_GUESS_D1: input_idx_reg = 2'd1;
            S_INPUT_D0, S_GUESS_D0: input_idx_reg = 2'd0;
            default: input_idx_reg = 2'd0; 
        endcase
    end
    
    assign Secret[3] = Secret_reg[3]; assign Secret[2] = Secret_reg[2]; assign Secret[1] = Secret_reg[1]; assign Secret[0] = Secret_reg[0];
    assign Guess[3] = Guess_reg[3]; assign Guess[2] = Guess_reg[2]; assign Guess[1] = Guess_reg[1]; assign Guess[0] = Guess_reg[0];
    assign turn_count = turn_count_reg;
    assign current_input_index = input_idx_reg;

    assign in_setup_phase = (current_state == S_INPUT_D3) || (current_state == S_INPUT_D2) || (current_state == S_INPUT_D1) || (current_state == S_INPUT_D0);
    assign in_guess_phase = (current_state == S_GUESS_D3) || (current_state == S_GUESS_D2) || (current_state == S_GUESS_D1) || (current_state == S_GUESS_D0);
    
    assign output_result_phase = (current_state == S_SHOW_RESULT);
    assign game_over = (current_state == S_GAME_OVER);

endmodule
