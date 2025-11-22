module game_top (
    input  logic        CLOCK_50,
    input  logic [3:0]  KEY,      // KEY3: Reset, KEY1: Back, KEY0: Confirm
    input  logic [9:0]  SW,       // Digit Input
    output logic [6:0]  HEX5, HEX4, HEX3, HEX2, // 顯示區域
    output logic [9:0]  LEDR      // [9:6]: Result, [4:0]: Chances
);

    // --- 1. 參數與變數宣告 ---
    
    // 狀態定義
    typedef enum logic [3:0] {
        S_IDLE,
        // 設定階段
        S_SET_D3, S_SET_D2, S_SET_D1, S_SET_D0,
        // 猜測階段
        S_GUESS_D3, S_GUESS_D2, S_GUESS_D1, S_GUESS_D0,
        // 結算與結果
        S_SHOW_RESULT,
        S_WIN,
        S_LOSE
    } state_t;

    state_t current_state, next_state;

    // 內部訊號
    logic p0_pulse, p1_pulse;       // 按鍵脈衝
    logic reset_n;                  // 系統重置
    logic [3:0] sw_val;             // SW 編碼後的數值
    logic sw_valid;                 // 是否有 SW 被按下
    logic [3:0] lfsr_val;           // 亂數數值
    logic blink_pulse;              // 1Hz 閃爍訊號
    
    // 遊戲暫存器
    logic [3:0] target [3:0];       // 答案: target[3]=千位 ... target[0]=個位
    logic [3:0] guess  [3:0];       // 猜測: guess[3]=千位 ... guess[0]=個位
    logic [2:0] chances;            // 剩餘機會 (0-5)

    // A/B 計算結果
    logic [2:0] result_A, result_B;
    logic is_duplicate;             // 判斷當前輸入是否重複
    logic [3:0] candidate;          // 當前準備寫入的數值 (SW 或 LFSR)

    assign reset_n = KEY[3];        // KEY3 為非同步重置

    // --- 2. 子模組實例化 (Sub-modules) ---

    // 按鍵去彈跳
    debouncer db0 (.clk(CLOCK_50), .reset_n(reset_n), .key_in(KEY[0]), .key_pulse(p0_pulse));
    debouncer db1 (.clk(CLOCK_50), .reset_n(reset_n), .key_in(KEY[1]), .key_pulse(p1_pulse));

    // 優先權編碼器
    priority_encoder enc0 (.sw(SW), .bin_out(sw_val), .sw_valid(sw_valid));

    // 亂數產生器
    lfsr_generator lfsr0 (.clk(CLOCK_50), .reset_n(reset_n), .rand_digit(lfsr_val));

    // --- 3. 輔助邏輯 (閃爍 & 候選值) ---

    // 產生約 1Hz 的閃爍訊號 (50MHz / 25M toggles)
    logic [24:0] cnt_blink;
    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) cnt_blink <= 0;
        else begin
            if (cnt_blink == 25000000 - 1) cnt_blink <= 0;
            else cnt_blink <= cnt_blink + 1;
        end
    end
    
    logic blink_on; // High 為亮, Low 為滅
    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) blink_on <= 0;
        else if (cnt_blink == 0) blink_on <= ~blink_on;
    end

    // 決定當前輸入值 (SET 階段 SW 優先，否則 LFSR；GUESS 階段強制 SW)
    // 注意：GUESS 階段若 sw_valid=0，此值無效，由 FSM 邏輯擋住
    assign candidate = sw_valid ? sw_val : lfsr_val;

    // --- 4. 重複檢查邏輯 (Duplicate Check) ---
    // 根據當前狀態，檢查 candidate 是否與已存入的暫存器衝突
    always_comb begin
        is_duplicate = 1'b0;
        case (current_state)
            // 設定階段：檢查 Target 暫存器
            S_SET_D2:   if (candidate == target[3]) is_duplicate = 1'b1;
            S_SET_D1:   if (candidate == target[3] || candidate == target[2]) is_duplicate = 1'b1;
            S_SET_D0:   if (candidate == target[3] || candidate == target[2] || candidate == target[1]) is_duplicate = 1'b1;
            
            // 猜測階段：檢查 Guess 暫存器 (本次輸入不重複)
            S_GUESS_D2: if (candidate == guess[3]) is_duplicate = 1'b1;
            S_GUESS_D1: if (candidate == guess[3] || candidate == guess[2]) is_duplicate = 1'b1;
            S_GUESS_D0: if (candidate == guess[3] || candidate == guess[2] || candidate == guess[1]) is_duplicate = 1'b1;
            default:    is_duplicate = 1'b0;
        endcase
    end

    // --- 5. FSM 狀態轉移與資料路徑 (State & Datapath) ---
    // 使用 always_ff 同步更新狀態與暫存器
    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            current_state <= S_IDLE;
            chances <= 5;
            for(int i=0; i<4; i++) begin 
                target[i] <= 4'd0; 
                guess[i]  <= 4'd0; 
            end
        end else begin
            case (current_state)
                // --- IDLE ---
                S_IDLE: begin
                    if (p0_pulse) current_state <= S_SET_D3;
                    chances <= 5; // 重置機會
                end

                // --- SETTING PHASE ---
                S_SET_D3: begin
                    if (p0_pulse) begin
                        target[3] <= candidate;
                        current_state <= S_SET_D2;
                    end
                    // P1 ignored
                end
                S_SET_D2: begin
                    if (p0_pulse && !is_duplicate) begin
                        target[2] <= candidate;
                        current_state <= S_SET_D1;
                    end
                    else if (p1_pulse) current_state <= S_SET_D3;
                end
                S_SET_D1: begin
                    if (p0_pulse && !is_duplicate) begin
                        target[1] <= candidate;
                        current_state <= S_SET_D0;
                    end
                    else if (p1_pulse) current_state <= S_SET_D2;
                end
                S_SET_D0: begin
                    if (p0_pulse && !is_duplicate) begin
                        target[0] <= candidate;
                        current_state <= S_GUESS_D3; // 進入遊戲
                    end
                    else if (p1_pulse) current_state <= S_SET_D1;
                end

                // --- GUESSING PHASE ---
                S_GUESS_D3: begin
                    // GUESS 階段必須有 SW 輸入 (sw_valid)
                    if (p0_pulse && sw_valid) begin
                        guess[3] <= candidate;
                        current_state <= S_GUESS_D2;
                    end
                    // P1 ignored
                end
                S_GUESS_D2: begin
                    if (p0_pulse && sw_valid && !is_duplicate) begin
                        guess[2] <= candidate;
                        current_state <= S_GUESS_D1;
                    end
                    else if (p1_pulse) current_state <= S_GUESS_D3;
                end
                S_GUESS_D1: begin
                    if (p0_pulse && sw_valid && !is_duplicate) begin
                        guess[1] <= candidate;
                        current_state <= S_GUESS_D0;
                    end
                    else if (p1_pulse) current_state <= S_GUESS_D2;
                end
                S_GUESS_D0: begin
                    if (p0_pulse && sw_valid && !is_duplicate) begin
                        guess[0] <= candidate;
                    end
                    else if (p1_pulse) current_state <= S_GUESS_D1;
                end
                
                S_SHOW_RESULT: begin
                    // 顯示結果，等待 P0 繼續
                    if (p0_pulse) begin
                        // 清空 Guess (設為 0 或無效值，這裡不重要因為會被覆寫)
                        current_state <= S_GUESS_D3;
                    end
                end
                
                S_WIN: ; // 等待 Reset
                S_LOSE: ; // 等待 Reset

            endcase
            // 為了處理 4A 判斷與機會扣減，我們重寫 S_GUESS_D0 的 P0 行為
            if (current_state == S_GUESS_D0 && p0_pulse && sw_valid && !is_duplicate) begin
                // 先計算假設寫入後的 A 值
                int temp_A;
                temp_A = 0;
                if (guess[3] == target[3]) temp_A++;
                if (guess[2] == target[2]) temp_A++;
                if (guess[1] == target[1]) temp_A++;
                if (candidate == target[0]) temp_A++; // 注意這裡是 candidate

                if (temp_A == 4) begin
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
                // 當然也要存入數值
                guess[0] <= candidate;
            end
        end
    end

    // --- 6. 1A2B 計算邏輯 (Combinational) ---
    // 用於 S_SHOW_RESULT 顯示
    always_comb begin
        result_A = 0;
        result_B = 0;
        // 只有在比較階段才有意義，但我們一直計算也無妨
        for(int i=0; i<4; i++) begin
            if (guess[i] == target[i]) 
                result_A++;
            else begin
                // 檢查 B: 數值存在但位置不同
                for(int j=0; j<4; j++) begin
                    if (i != j && guess[i] == target[j]) 
                        result_B++;
                end
            end
        end
    end

    // --- 7. 顯示輸出邏輯 (Output Logic) ---
    
    // 暫存用變數
    logic [3:0] hex_val [3:0]; // 對應 HEX5, HEX4, HEX3, HEX2
    logic [3:0] disp_char [3:0]; // 最終送顯的 4bit code (含特殊符號)

    // 定義特殊字元編碼 (配合 hex_decoder)
    localparam C_0 = 4'h0;
    localparam C_A = 4'hA; // 'A'
    localparam C_b = 4'hB; // 'b'
    localparam C_U = 4'hC; // '_' (Underscore)
    localparam C_BLK = 4'hF; // Blank

    always_comb begin
        // 預設全滅
        disp_char[3] = C_BLK; // HEX5
        disp_char[2] = C_BLK; // HEX4
        disp_char[1] = C_BLK; // HEX3
        disp_char[0] = C_BLK; // HEX2
        
        // LEDR 預設行為
        LEDR[9:6] = 0; 
        LEDR[4:0] = 0;

        // 機會燈號 (Thermometer code)
        case (chances)
            5: LEDR[4:0] = 5'b11111;
            4: LEDR[4:0] = 5'b01111;
            3: LEDR[4:0] = 5'b00111;
            2: LEDR[4:0] = 5'b00011;
            1: LEDR[4:0] = 5'b00001;
            0: LEDR[4:0] = 5'b00000;
        endcase

        case (current_state)
            // --- IDLE: "1 A 2 b", LEDR 閃爍 ---
            S_IDLE: begin
                disp_char[3] = 4'd1;
                disp_char[2] = C_A;
                disp_char[1] = 4'd2;
                disp_char[0] = C_b;
                if (blink_on) LEDR = 10'b1111111111;
                else          LEDR = 10'b0000000000;
            end

            // --- SET PHASE ---
            // 邏輯：已鎖定顯示數字，正在輸入顯示(數字or底線)且閃爍，未輸入顯示底線
            S_SET_D3: begin
                // 正在輸入 D3
                if (blink_on) disp_char[3] = sw_valid ? candidate : C_U; // 閃爍: 數字 或 底線
                else          disp_char[3] = C_BLK;                      // 滅
                
                disp_char[2] = C_U; disp_char[1] = C_U; disp_char[0] = C_U;
            end
            S_SET_D2: begin
                disp_char[3] = target[3]; // 鎖定
                if (blink_on) disp_char[2] = sw_valid ? candidate : C_U;
                else          disp_char[2] = C_BLK;
                disp_char[1] = C_U; disp_char[0] = C_U;
            end
            S_SET_D1: begin
                disp_char[3] = target[3]; disp_char[2] = target[2];
                if (blink_on) disp_char[1] = sw_valid ? candidate : C_U;
                else          disp_char[1] = C_BLK;
                disp_char[0] = C_U;
            end
            S_SET_D0: begin
                disp_char[3] = target[3]; disp_char[2] = target[2]; disp_char[1] = target[1];
                if (blink_on) disp_char[0] = sw_valid ? candidate : C_U;
                else          disp_char[0] = C_BLK;
            end

            // --- GUESS PHASE ---
            S_GUESS_D3: begin
                // 新回合，D2-D0 顯示底線
                if (blink_on) disp_char[3] = sw_valid ? candidate : C_U;
                else          disp_char[3] = C_BLK;
                disp_char[2] = C_U; disp_char[1] = C_U; disp_char[0] = C_U;
            end
            S_GUESS_D2: begin
                disp_char[3] = guess[3];
                if (blink_on) disp_char[2] = sw_valid ? candidate : C_U;
                else          disp_char[2] = C_BLK;
                disp_char[1] = C_U; disp_char[0] = C_U;
            end
            S_GUESS_D1: begin
                disp_char[3] = guess[3]; disp_char[2] = guess[2];
                if (blink_on) disp_char[1] = sw_valid ? candidate : C_U;
                else          disp_char[1] = C_BLK;
                disp_char[0] = C_U;
            end
            S_GUESS_D0: begin
                disp_char[3] = guess[3]; disp_char[2] = guess[2]; disp_char[1] = guess[1];
                if (blink_on) disp_char[0] = sw_valid ? candidate : C_U;
                else          disp_char[0] = C_BLK;
            end

            // --- RESULT ---
            S_SHOW_RESULT: begin
                // HEX 顯示剛剛猜的數字
                disp_char[3] = guess[3];
                disp_char[2] = guess[2];
                disp_char[1] = guess[1];
                disp_char[0] = guess[0];
                
                // LEDR 逐位回饋邏輯 (Positional Feedback)
                // 規則：
                // 1. 若該位數字 == Target 該位數字 -> A (恆亮)
                // 2. 若該位數字 != Target 該位，但出現在 Target 其他位置 -> B (閃爍)
                // 3. 否則 -> 滅

                // --- LEDR9 對應 HEX5 (Guess[3]) ---
                if (guess[3] == target[3]) begin
                    LEDR[9] = 1'b1; // A: 恆亮
                end else begin
                    // 檢查是否為 B (數字存在於其他位置)
                    if (guess[3] == target[2] || guess[3] == target[1] || guess[3] == target[0])
                        LEDR[9] = blink_on; // B: 閃爍
                    else
                        LEDR[9] = 1'b0;     // 錯: 滅
                end

                // --- LEDR8 對應 HEX4 (Guess[2]) ---
                if (guess[2] == target[2]) begin
                    LEDR[8] = 1'b1;
                end else begin
                    if (guess[2] == target[3] || guess[2] == target[1] || guess[2] == target[0])
                        LEDR[8] = blink_on;
                    else
                        LEDR[8] = 1'b0;
                end

                // --- LEDR7 對應 HEX3 (Guess[1]) ---
                if (guess[1] == target[1]) begin
                    LEDR[7] = 1'b1;
                end else begin
                    if (guess[1] == target[3] || guess[1] == target[2] || guess[1] == target[0])
                        LEDR[7] = blink_on;
                    else
                        LEDR[7] = 1'b0;
                end

                // --- LEDR6 對應 HEX2 (Guess[0]) ---
                if (guess[0] == target[0]) begin
                    LEDR[6] = 1'b1;
                end else begin
                    if (guess[0] == target[3] || guess[0] == target[2] || guess[0] == target[1])
                        LEDR[6] = blink_on;
                    else
                        LEDR[6] = 1'b0;
                end
            end

            // --- WIN: "4 A 0 b", LEDR 全閃 ---
            S_WIN: begin
                disp_char[3] = 4'd4;
                disp_char[2] = C_A;
                disp_char[1] = 4'd0;
                disp_char[0] = C_b;
                if (blink_on) LEDR = 10'b1111111111;
                else          LEDR = 10'b0000000000;
            end

            // --- LOSE: 顯示答案 ---
            S_LOSE: begin
                disp_char[3] = target[3];
                disp_char[2] = target[2];
                disp_char[1] = target[1];
                disp_char[0] = target[0];
                LEDR = 10'd0; // 全滅
            end
        endcase
    end

    // --- 8. HEX 解碼器實例化 ---
    hex_decoder h5 (.hex_in(disp_char[3]), .hex_out(HEX5));
    hex_decoder h4 (.hex_in(disp_char[2]), .hex_out(HEX4));
    hex_decoder h3 (.hex_in(disp_char[1]), .hex_out(HEX3));
    hex_decoder h2 (.hex_in(disp_char[0]), .hex_out(HEX2));

endmodule
