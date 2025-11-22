import game_types::*;

module display_ctrl (
    input  state_t      state,
    input  logic        blink_on,
    input  logic [3:0]  target [3:0],
    input  logic [3:0]  guess  [3:0],
    input  logic [3:0]  candidate,
    input  logic        sw_valid,
    input  logic [2:0]  chances,
    
    output logic [6:0]  HEX5, HEX4, HEX3, HEX2,
    output logic [9:0]  LEDR
);
    // 內部變數
    logic [3:0] char_val [3:0];
    
    // 特殊字元常數
    localparam C_A = 4'hA; localparam C_b = 4'hB; 
    localparam C_U = 4'hC; localparam C_BLK = 4'hF;

    // --- 顯示邏輯主體 ---
    always_comb begin
        // 1. 【預設值】防止 Latch 的關鍵！
        char_val[3] = C_BLK; char_val[2] = C_BLK; 
        char_val[1] = C_BLK; char_val[0] = C_BLK;
        LEDR = 10'd0;

        // 2. 機會燈 (Thermometer Code)
        case (chances)
            5: LEDR[4:0] = 5'b11111;
            4: LEDR[4:0] = 5'b01111;
            3: LEDR[4:0] = 5'b00111;
            2: LEDR[4:0] = 5'b00011;
            1: LEDR[4:0] = 5'b00001;
            default: LEDR[4:0] = 5'b00000;
        endcase

        // 3. 狀態顯示邏輯
        case (state)
            S_IDLE: begin
                char_val[3] = 4'd1; char_val[2] = C_A; 
                char_val[1] = 4'd2; char_val[0] = C_b;
                if (blink_on) LEDR = 10'b1111111111;
            end

            // --- SETTING ---
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

            // --- GUESSING ---
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

            // --- RESULT: 位置對應 A/B 邏輯 ---
            S_SHOW_RESULT: begin
                char_val[3] = guess[3]; char_val[2] = guess[2];
                char_val[1] = guess[1]; char_val[0] = guess[0];

                // Positional Feedback Logic (你的需求)
                // LEDR9 (對應 HEX5/Guess[3])
                if (guess[3] == target[3]) LEDR[9] = 1'b1;
                else if (guess[3] == target[2] || guess[3] == target[1] || guess[3] == target[0]) LEDR[9] = blink_on;
                
                // LEDR8 (對應 HEX4/Guess[2])
                if (guess[2] == target[2]) LEDR[8] = 1'b1;
                else if (guess[2] == target[3] || guess[2] == target[1] || guess[2] == target[0]) LEDR[8] = blink_on;

                // LEDR7 (對應 HEX3/Guess[1])
                if (guess[1] == target[1]) LEDR[7] = 1'b1;
                else if (guess[1] == target[3] || guess[1] == target[2] || guess[1] == target[0]) LEDR[7] = blink_on;

                // LEDR6 (對應 HEX2/Guess[0])
                if (guess[0] == target[0]) LEDR[6] = 1'b1;
                else if (guess[0] == target[3] || guess[0] == target[2] || guess[0] == target[1]) LEDR[6] = blink_on;
            end

            S_WIN: begin
                char_val[3] = 4'd4; char_val[2] = C_A; 
                char_val[1] = 4'd0; char_val[0] = C_b;
                if (blink_on) LEDR = 10'b1111111111;
            end

            S_LOSE: begin
                char_val[3] = target[3]; char_val[2] = target[2]; 
                char_val[1] = target[1]; char_val[0] = target[0];
            end
        endcase
    end

    // 解碼器實例化
    hex_decoder h5(char_val[3], HEX5);
    hex_decoder h4(char_val[2], HEX4);
    hex_decoder h3(char_val[1], HEX3);
    hex_decoder h2(char_val[0], HEX2);

endmodule
