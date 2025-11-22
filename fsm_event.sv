module fsm_event (
    input logic clk,
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
    
    // ------------------- 1. FSM 狀態定義 --------------------
    typedef enum logic [3:0] {
        S_IDLE = 4'h0, S_INPUT_D3 = 4'h1, S_INPUT_D2 = 4'h2, S_INPUT_D1 = 4'h3, S_INPUT_D0 = 4'h4,
        S_GUESS_D3 = 4'h5, S_GUESS_D2 = 4'h6, S_GUESS_D1 = 4'h7, S_GUESS_D0 = 4'h8,
        S_CALCULATE = 4'h9, S_SHOW_RESULT = 4'hA, S_GAME_OVER = 4'hB
    } state_t;

    logic [3:0] current_state, next_state; 
    
    // ------------------- 2. 內部暫存器 --------------------
    logic [3:0] Secret_reg [0:3];
    logic [3:0] Guess_reg  [0:3];
    logic [2:0] turn_count_reg; 
    
    // ------------------- 3. 數據寫入與控制信號 --------------------
    logic is_turn_increment;
    logic is_duplicate;
    logic [1:0] input_idx_reg;

    // ----------------------------------------------------
    // I. 狀態暫存器 (Current State) - 同步重置
    // ----------------------------------------------------
    always_ff @(posedge clk) begin
        if (P3_pulse) begin // P3 是同步重置
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // ----------------------------------------------------
    // II. 數據暫存器 (Data Registers) - 同步重置
    // ----------------------------------------------------
    always_ff @(posedge clk) begin 
        if (P3_pulse) begin // P3 是同步重置
            for (int i=0; i<4; i++) begin
                Secret_reg[i] <= 4'hA; // 4'hA = '_' 符號
                Guess_reg[i] <= 4'hA;
            end 
            turn_count_reg <= 0;
        end else begin
            // --- 回合數遞增 ---
            if (is_turn_increment) begin
                turn_count_reg <= turn_count_reg + 1;
            end
        
            // --- P0 數字寫入 (數據寫入邏輯) ---
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

            // --- P1 撤銷邏輯 ---
            if (P1_pulse) begin
                unique case (current_state)
                    S_INPUT_D2: Secret_reg[3] <= 4'hA; 
                    S_INPUT_D1: Secret_reg[2] <= 4'hA;
                    S_INPUT_D0: Secret_reg[1] <= 4'hA;
                    S_GUESS_D2: Guess_reg[3] <= 4'hA;
                    S_GUESS_D1: Guess_reg[2] <= 4'hA;
                    S_GUESS_D0: Guess_reg[1] <= 4'hA
