import game_types::*;

module game_core (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        p0_pulse,       // 確認
    input  logic        p1_pulse,       // 返回/撤銷
    input  logic [3:0]  sw_val,         // 開關數值
    input  logic        sw_valid,       // 開關是否有開
    input  logic [3:0]  lfsr_val,       // 亂數數值
    
    output state_t      current_state,  // 輸出給顯示模組用
    output logic [3:0]  target [3:0],   // 答案
    output logic [3:0]  guess  [3:0],   // 猜測值
    output logic [3:0]  candidate,      // 當前準備輸入的值
    output logic [2:0]  chances         // 剩餘機會
);

    // 內部變數
    state_t next_state;
    logic is_duplicate;
    
    // 決定候選值 (設定階段 SW 優先，GUESS 階段強制 SW)
    assign candidate = sw_valid ? sw_val : lfsr_val;

    // --- 重複檢查邏輯 ---
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

    // --- 暫存器與狀態更新 (Sequential) ---
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_state <= S_IDLE;
            chances <= 5;
            for(int i=0; i<4; i++) begin target[i] <= 0; guess[i] <= 0; end
        end else begin
            case (current_state)
                S_IDLE: begin
                    if (p0_pulse) begin 
                        current_state <= S_SET_D3; 
                        chances <= 5;
                    end
                end

                // --- SETTING ---
                S_SET_D3: if (p0_pulse) begin target[3] <= candidate; current_state <= S_SET_D2; end
                S_SET_D2: begin
                    if (p0_pulse && !is_duplicate) begin target[2] <= candidate; current_state <= S_SET_D1; end
                    else if (p1_pulse) current_state <= S_SET_D3;
                end
                S_SET_D1: begin
                    if (p0_pulse && !is_duplicate) begin target[1] <= candidate; current_state <= S_SET_D0; end
                    else if (p1_pulse) current_state <= S_SET_D2;
                end
                S_SET_D0: begin
                    if (p0_pulse && !is_duplicate) begin target[0] <= candidate; current_state <= S_GUESS_D3; end
                    else if (p1_pulse) current_state <= S_SET_D1;
                end

                // --- GUESSING ---
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
                
                // --- 關鍵比對時刻 ---
                S_GUESS_D0: begin
                    if (p0_pulse && sw_valid && !is_duplicate) begin
                        guess[0] <= candidate;
                        // 預判 A 的數量
                        if ( (guess[3] == target[3] ? 1:0) + 
                             (guess[2] == target[2] ? 1:0) + 
                             (guess[1] == target[1] ? 1:0) + 
                             (candidate == target[0] ? 1:0) == 4 ) begin
                            current_state <= S_WIN;
                        end else begin
                            // 沒猜對，扣機會
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

                // --- RESULT & END ---
                S_SHOW_RESULT: if (p0_pulse) current_state <= S_GUESS_D3;
                S_WIN: ; // Wait for Reset
                S_LOSE: ; // Wait for Reset
            endcase
        end
    end
endmodule
