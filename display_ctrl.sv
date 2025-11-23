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
    localparam C_L = 4'hD;
    localparam C_O = 4'h0;
    localparam C_S = 4'h5;
    localparam C_E = 4'hE;
    localparam C_A = 4'hA; 
    localparam C_b = 4'hB; 
    localparam C_U = 4'hC; 
    localparam C_BLK = 4'hF;

    always_comb begin
        // 1. 預設值
        char_val[3] = C_BLK; char_val[2] = C_BLK; 
        char_val[1] = C_BLK; char_val[0] = C_BLK;
        LEDR = 10'd0;

        if (state != S_LOSE && state != S_WIN && state != S_IDLE) begin
            case (chances)
                5: begin 
                    LEDR[4] = blink_on;
                    LEDR[3:0] = 4'b1111;
                end
                4: begin 
                    LEDR[3] = blink_on; 
                    LEDR[2:0] = 3'b111; 
                end
                3: begin 
                    LEDR[2] = blink_on; 
                    LEDR[1:0] = 2'b11; 
                end
                2: begin 
                    LEDR[1] = blink_on; 
                    LEDR[0] = 1'b1; 
                end
                1: begin 
                    LEDR[0] = blink_on; 
                end
            endcase
        end

      
        case (state)
            S_IDLE: begin
                char_val[3] = 4'd1; char_val[2] = C_A; 
                char_val[1] = 4'd2; char_val[0] = C_b;
                if (blink_on) LEDR = 10'b1111111111;
            end

            //Setting Phase
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

            //Guessing Phase
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

            //Show Result
            S_SHOW_RESULT: begin
                char_val[3] = guess[3]; char_val[2] = guess[2];
                char_val[1] = guess[1]; char_val[0] = guess[0];

                // LEDR9-6: A/B Positional Feedback
                if (guess[3] == target[3]) LEDR[9] = 1'b1;
                else if (guess[3] == target[2] || guess[3] == target[1] || guess[3] == target[0]) LEDR[9] = blink_on;
                
                if (guess[2] == target[2]) LEDR[8] = 1'b1;
                else if (guess[2] == target[3] || guess[2] == target[1] || guess[2] == target[0]) LEDR[8] = blink_on;

                if (guess[1] == target[1]) LEDR[7] = 1'b1;
                else if (guess[1] == target[3] || guess[1] == target[2] || guess[1] == target[0]) LEDR[7] = blink_on;

                if (guess[0] == target[0]) LEDR[6] = 1'b1;
                else if (guess[0] == target[3] || guess[0] == target[2] || guess[0] == target[1]) LEDR[6] = blink_on;
            end

            S_WIN: begin
                char_val[3] = 4'd4; char_val[2] = C_A; 
                char_val[1] = 4'd0; char_val[0] = C_b;
                if (blink_on) LEDR = 10'b1111111111;
            end

            S_LOSE: begin
                char_val[3] = C_L; // L
                char_val[2] = C_O; // 0 (O)
                char_val[1] = C_S; // 5 (S)
                char_val[0] = C_E; // E
                
                if (blink_on) LEDR = 10'b1111111111;
                else          LEDR = 10'b0000000000;
            end
        endcase
    end

    hex_decoder h5(char_val[3], HEX5);
    hex_decoder h4(char_val[2], HEX4);
    hex_decoder h3(char_val[1], HEX3);
    hex_decoder h2(char_val[0], HEX2);

endmodule
