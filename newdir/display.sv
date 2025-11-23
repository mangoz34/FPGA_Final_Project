import game_types::*;

module display_ctrl (
    input  state_t      state,
    input  logic        blink_on,
    input  logic [3:0]  target [3:0],
    input  logic [3:0]  guess  [3:0],
    input  logic [3:0]  candidate,
    input  logic        sw_valid,
    input  logic [2:0]  chances,    // 0-5
    input  logic [3:0]  is_random,  // 1=Random(顯示底線), 0=Manual(顯示數字)
    
    output logic [6:0]  HEX5, HEX4, HEX3, HEX2,
    output logic [9:0]  LEDR
);
    // 內部變數用來暫存要送給解碼器的數值
    logic [3:0] char_val [3:0];
    
    // 特殊字元常數定義 (需配合修改過的 hex_decoder)
    localparam C_L = 4'hD; // L (LOSE 用)
    localparam C_O = 4'h0; // 0 (LOSE 用)
    localparam C_S = 4'h5; // 5 (LOSE 用)
    localparam C_E = 4'hE; // E (LOSE 用)
    localparam C_A = 4'hA; // A
    localparam C_b = 4'hB; // b
    localparam C_U = 4'hC; // _ (底線)
    localparam C_BLK = 4'hF; // 全滅 (Blank)

    always_comb begin
        // 1. 【全域預設值】防止 Latch
        char_val[3] = C_BLK; char_val[2] = C_BLK; 
        char_val[1] = C_BLK; char_val[0] = C_BLK;
        LEDR = 10'd0;

        // 2. 【機會燈邏輯 (LEDR4-0)】
        // 分開處理 GUESS (閃爍) 和 SHOW_RESULT (恆亮)
        if (state == S_GUESS_D3 || state == S_GUESS_D2 || state == S_GUESS_D1 || state == S_GUESS_D0) begin
            // 猜測階段：最高位閃爍，增加緊張感
            case (chances)
                5: begin LEDR[4] = blink_on; LEDR[3:0] = 4'b1111; end
                4: begin LEDR[3] = blink_on; LEDR[2:0] = 3'b111; end
                3: begin LEDR[2] = blink_on; LEDR[1:0] = 2'b11; end
                2: begin LEDR[1] = blink_on; LEDR[0] = 1'b1; end
                1: begin LEDR[0] = blink_on; end
                default: LEDR[4:0] = 5'b0;
            endcase
        end else if (state == S_SHOW_RESULT) begin
            // 結果階段：恆亮，讓玩家看清楚
            case (chances)
                5: LEDR[4:0] = 5'b11111;
                4: LEDR[4:0] = 5'b01111;
                3: LEDR[4:0] = 5'b00111;
                2: LEDR[4:0] = 5'b00011;
                1: LEDR[4:0] = 5'b00001;
                default: LEDR[4:0] = 5'b0;
            endcase
        end

        // 3. 【主要狀態顯示邏輯 (HEX & LEDR9-6)】
        case (state)
            // --- IDLE: 1A2b, 全閃爍 ---
            S_IDLE: begin
                char_val[3] = 4'd1; char_val[2] = C_A; 
                char_val[1] = 4'd2; char_val[0] = C_b;
                if (blink_on) LEDR = 10'b1111111111;
            end

            // --- SETTING PHASE ---
            // 邏輯：
            // 1. 正在設定 (Active): 閃爍 (手動顯示數字, 隨機顯示底線)
            // 2. 已鎖定 (Locked): 恆亮 (手動顯示數字, 隨機顯示神祕底線)
            S_SET_D3: begin
                char_val[3] = blink_on ? (sw_valid ? candidate : C_U) : C_BLK;
                char_val[2] = C_U; char_val[1] = C_U; char_val[0] = C_U;
            end
            S_SET_D2: begin
                char_val[3] = is_random[3] ? C_U : target[3];
                char_val[2] = blink_on ? (sw_valid ? candidate : C_U) : C_BLK;
                char_val[1] = C_U; char_val[0] = C_U;
            end
            S_SET_D1: begin
                char_val[3] = is_random[3] ? C_U : target[3];
                char_val[2] = is_random[2] ? C_U : target[2];
                char_val[1] = blink_on ? (sw_valid ? candidate : C_U) : C_BLK;
                char_val[0] = C_U;
            end
            S_SET_D0: begin
                char_val[3] = is_random[3] ? C_U : target[3];
                char_val[2] = is_random[2] ? C_U : target[2];
                char_val[1] = is_random[1] ? C_U : target[1];
                char_val[0] = blink_on ? (sw_valid ? candidate : C_U) : C_BLK;
            end

            // --- GUESSING PHASE ---
            // 邏輯：輸入時顯示數字(若sw有效)或底線，並閃爍
            S_GUESS_D3: begin
                char_val[3] = blink_on ? (sw_valid ? candidate : C_U) : C_BLK;
                char_val[2] = C_U; char_val[1] = C_U; char_val[0] = C_U;
            end
            S_GUESS_D2: begin
                char_val[3] = guess[3];
                char_val[2] = blink_on ? (sw_valid ? candidate : C_U) : C_BLK;
                char_val[1] = C_U; char_val[0] = C_U;
            end
            S_GUESS_D1: begin
                char_val[3] = guess[3]; char_val[2] = guess[2];
                char_val[1] = blink_on ? (sw_valid ? candidate : C_U) : C_BLK;
                char_val[0] = C_U;
            end
            S_GUESS_D0: begin
                char_val[3] = guess[3]; char_val[2] = guess[2]; char_val[1] = guess[1];
                char_val[0] = blink_on ? (sw_valid ? candidate : C_U) : C_BLK;
            end

            // --- RESULT: 顯示猜測數字 + A/B 回饋 ---
            S_SHOW_RESULT: begin
                char_val[3] = guess[3]; char_val[2] = guess[2];
                char_val[1] = guess[1]; char_val[0] = guess[0];

                // LEDR9-6: Positional Feedback (A=恆亮, B=閃爍)
                // 這裡覆寫了高位 LEDR，低位保留給機會燈
                
                // Guess[3] vs Target (HEX5 / LEDR9)
                if (guess[3] == target[3]) LEDR[9] = 1'b1;
                else if (guess[3] == target[2] || guess[3] == target[1] || guess[3] == target[0]) LEDR[9] = blink_on;
                
                // Guess[2] vs Target (HEX4 / LEDR8)
                if (guess[2] == target[2]) LEDR[8] = 1'b1;
                else if (guess[2] == target[3] || guess[2] == target[1] || guess[2] == target[0]) LEDR[8] = blink_on;

                // Guess[1] vs Target (HEX3 / LEDR7)
                if (guess[1] == target[1]) LEDR[7] = 1'b1;
                else if (guess[1] == target[3] || guess[1] == target[2] || guess[1] == target[0]) LEDR[7] = blink_on;

                // Guess[0] vs Target (HEX2 / LEDR6)
                if (guess[0] == target[0]) LEDR[6] = 1'b1;
                else if (guess[0] == target[3] || guess[0] == target[2] || guess[0] == target[1]) LEDR[6] = blink_on;
            end

            // --- WIN: 4A0b, 全閃爍 ---
            S_WIN: begin
                char_val[3] = 4'd4; char_val[2] = C_A; 
                char_val[1] = 4'd0; char_val[0] = C_b;
                if (blink_on) LEDR = 10'b1111111111;
            end

            // --- LOSE: L05E, 全閃爍 ---
            S_LOSE: begin
                char_val[3] = C_L; char_val[2] = C_O; 
                char_val[1] = C_S; char_val[0] = C_E;
                if (blink_on) LEDR = 10'b1111111111;
            end
        endcase
    end

    // 4. 【解碼器實例化】
    hex_decoder h5(char_val[3], HEX5);
    hex_decoder h4(char_val[2], HEX4);
    hex_decoder h3(char_val[1], HEX3);
    hex_decoder h2(char_val[0], HEX2);

endmodule
