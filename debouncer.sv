module debouncer (
    input logic clk,       
    input logic reset_n,   
    input logic key_in,
    output logic key_pulse
);
    localparam DEBOUNCE_CNT = 1_000_000;
    localparam CNT_WIDTH    = 20; 

    logic [CNT_WIDTH-1:0] counter = 0;
    logic key_meta = 1'b0;   
    logic key_stable = 1'b0; 
    logic key_stable_dly = 1'b0;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin // 非同步重置
            counter <= 0;
            key_stable <= 1'b1;
            key_meta <= 1'b1;
            key_stable_dly <= 1'b1;
        end else begin
            // 1. 同步輸入與延遲
            key_meta <= key_in;
            key_stable_dly <= key_stable;

            // 2. 去抖計數器與穩定狀態更新
            if (key_meta != key_stable) begin
                // 訊號正在變化，開始或繼續計數
                if (counter == DEBOUNCE_CNT - 1) begin
                    key_stable <= key_meta; // 達到閾值，更新穩定狀態
                    counter <= 0;
                end else begin
                    counter <= counter + 1; 
                end
            end else begin
                counter <= 0; // 訊號穩定，重置計數器
            end
        end
    end
    
    // 3. 組合邏輯輸出：單週期脈衝 (key_stable 從 0 變為 1)
    // 只有當 key_stable 穩定在 1 且前一個週期為 0 時，輸出 1 個週期的高電平。
    assign key_pulse = key_stable & (~key_stable_dly);
    
endmodule
