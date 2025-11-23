import game_types::*;

module display_ctrl (
    input  state_t      state,
    input  logic        blink_on,
    input  logic [3:0]  target [3:0],
    input  logic [3:0]  guess  [3:0],
    input  logic [3:0]  candidate,
    input  logic        sw_valid,
    input  logic [2:0]  chances, // 0-5
    
    output logic [6:0]  HEX5, HEX4, HEX3, HEX2,
    output logic [9:0]  LEDR
);
    // 內部變數
    logic [3:0] char_val [3:0];
    
    // 特殊字元常數
    localparam C_L = 4'hD; // L
    localparam C_O = 4'h0; // 0 (O)
    localparam C_S = 4'h5; // 5 (S)
    localparam C_E = 4'hE; // E
    localparam C_A = 4'hA; 
    localparam C_b = 4'hB; 
    localparam C_U = 4'hC; 
    localparam C_BLK = 4'hF;

    always_comb begin
        // 1. 【全域預設值】
        char_val[3] = C_BLK; char_val[2] = C_BLK; 
        char_val[1] = C_BLK; char_val[0] = C_BLK;
        LEDR = 10'd0; // 預設 LED 全關 (包含 SET 階段)

        // 2. 【機會燈邏輯 (LEDR4-0)】
        // 根據狀態不同，採用不同的顯示策略
        
        // 情況 A: 猜測階段 (GUESS) -> 最高位閃爍 (緊張感)
        if (state == S_GUESS_D3 || state == S_GUESS_D2 || state == S_GUESS_D1 || state == S_GUESS_D0) begin
            case (chances)
                5: begin LEDR[4] = blink_on; LEDR[3:0] = 4'b1111; end
                4: begin LEDR[3] = blink_on; LEDR[2:0] = 3'b111; end
                3: begin LEDR[2] = blink_on; LEDR[1:0] = 2'b11; end
                2: begin LEDR[1] = blink_on; LEDR[0] = 1'b1; end
                1: begin LEDR[0] = blink_on; end
                default: LEDR[4:0] = 5'b0;
            endcase
        end
        
        // 情況 B: 結果顯示階段 (SHOW_RESULT) -> 恆亮 (穩定顯示)
        else if (state == S_SHOW_RESULT) begin
            case (chances)
                5: LEDR[4:0] = 5'b11111;
                4: LEDR[4:0] = 5'b01111;
                3: LEDR[4:0] = 5'b00111;
                2: LEDR[4:0] = 5'b00011;
                1: LEDR[4:0] = 5'b00001;
                default: LEDR[4:0] = 5'b0;
            endcase
        end
        
        // 情況 C: 設定階段 (SET) -> 不做任何事，維持預設值 (全滅)


        // 3. 【主要狀態顯示邏輯 (HEX & LEDR9-6)】
        case (state)
            S_IDLE: begin
                char_val[3] = 4'd1; char_val[2] = C_A; 
                char_val[1] = 4'd2; char_val[0] = C_b;
                if (blink_on) LEDR = 10'b1111111111;
            end

            // --- SETTING PHASE (LEDR 維持全滅) ---
            S_SET_D3: begin
                char_val[3] = blink_on ? (sw_valid ? candidate : C_U) : C_BLK;
                char_val[2] = C_U; char_val[1] = C_U; char_val[0] = C_U;
            end
            S_SET_D2: begin
                char_val[3] = target[3];
                char_val[2] = blink_on ? (sw_valid ? candidate : C_U) : C_BLK;
                char_val[1] = C_U; char_val[0] = C_U;
            end
            S_SET_D1: begin
                char_val[3] = target[3]; char_val[2] = target[2];
                char_val[1] = blink_on ? (sw_valid ? candidate : C_U) : C_BLK;
                char_val[0] = C_U;
            end
            S_SET_D0: begin
                char_val[3] = target[3]; char_val[2] = target[2]; char_val[1] = target[1];
                char_val[0] = blink_on ? (sw_valid ? candidate : C_U) : C_BLK;
            end

            // --- GUESSING PHASE (LEDR9-6 OFF, LEDR4-0 由上面邏輯處理) ---
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

            // --- RESULT ---
            S_SHOW_RESULT: begin
                char_val[3] = guess[3]; char_val[2] = guess[2];
                char_val[1] = guess[1]; char_val[0] = guess[0];

                // LEDR9-6: Positional Feedback (A=恆亮, B=閃爍)
                // 這裡直接複寫 LEDR 的高位，不會影響低位的機會燈
                
                // HEX5 (Guess[3]) Check
                if (guess[3] == target[3]) LEDR[9] = 1'b1;
                else if (guess[3] == target[2] || guess[3] == target[1] || guess[3] == target[0]) LEDR[9] = blink_on;
                
                // HEX4 (Guess[2]) Check
                if (guess[2] == target[2]) LEDR[8] = 1'b1;
                else if (guess[2] == target[3] || guess[2] == target[1] || guess[2] == target[0]) LEDR[8] = blink_on;

                // HEX3 (Guess[1]) Check
                if (guess[1] == target[1]) LEDR[7] = 1'b1;
                else if (guess[1] == target[3] || guess[1] == target[2] || guess[1] == target[0]) LEDR[7] = blink_on;

                // HEX2 (Guess[0]) Check
                if (guess[0] == target[0]) LEDR[6] = 1'b1;
                else if (guess[0] == target[3] || guess[0] == target[2] || guess[0] == target[1]) LEDR[6] = blink_on;
            end

            // --- WIN ---
            S_WIN: begin
                char_val[3] = 4'd4; char_val[2] = C_A; 
                char_val[1] = 4'd0; char_val[0] = C_b;
                if (blink_on) LEDR = 10'b1111111111;
            end

            // --- LOSE ---
            S_LOSE: begin
                char_val[3] = C_L; char_val[2] = C_O; 
                char_val[1] = C_S; char_val[0] = C_E;
                if (blink_on) LEDR = 10'b1111111111;
            end
        endcase
    end

    hex_decoder h5(char_val[3], HEX5);
    hex_decoder h4(char_val[2], HEX4);
    hex_decoder h3(char_val[1], HEX3);
    hex_decoder h2(char_val[0], HEX2);

endmodule
