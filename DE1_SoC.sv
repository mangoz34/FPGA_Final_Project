module DE1_SoC (
    input logic CLOCK_50,
    input logic [9:0] SW,
    input logic [3:0] KEY,
    output logic [9:0] LEDR,
    output logic [7:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

    logic [7:0] hex_display [5:0];
    logic [7:0] seg_code [3:0];

    logic P0_pulse, P1_pulse, P3_pulse;
    logic blink_en, global_reset_n;

    logic [3:0] D_manual; logic sw_enable;
    logic [15:0] rand_out; logic [3:0] rand_digit;
    logic [3:0] D_candidate;
    logic [3:0] Secret [3:0]; logic [3:0] Guess [3:0];
    logic [2:0] Count_A, Count_B;
    logic [3:0] LED_A, LED_B;
    logic [2:0] turn_count_fsm;

    logic [1:0] input_idx;
    logic in_setup_phase, in_guess_phase, output_result_phase, game_over;


    assign global_reset_n = KEY[3];

    clock_divider U_CLK_DIV (.CLK_50MHZ(CLOCK_50), .RESET_N(global_reset_n), .blink_en(blink_en));

    debouncer U_P0 (.clk(CLOCK_50), .reset_n(global_reset_n), .key_in(KEY[0]), .key_pulse(P0_pulse));
    debouncer U_P1 (.clk(CLOCK_50), .reset_n(global_reset_n), .key_in(KEY[1]), .key_pulse(P1_pulse));
    debouncer U_P3_DUMMY (.clk(CLOCK_50), .reset_n(global_reset_n), .key_in(KEY[3]), .key_pulse());

    hex7seg U_DEC [3:0] (.data_in({HEX5_data, HEX4_data, HEX3_data, HEX2_data}), .hex_out(seg_code));

    LFSR_16bit U_LFSR (.CLK(CLOCK_50), .RESET_N(global_reset_n), .rand_out(rand_out), .rand_digit(rand_digit));
    Priority_Encoder U_ENC (.SW_in(SW), .D_manual(D_manual), .sw_enable(sw_enable));

    logic [3:0] current_input_source;

    assign current_input_source = sw_enable ? D_manual : in_setup_phase ? rand_digit : 4'd0;

    assign D_candidate = current_input_source;

    Calc_AB U_CALC (.Secret(Secret), .Guess(Guess),
                   .Count_A(Count_A), .Count_B(Count_B),
                   .LED_A(LED_A), .LED_B(LED_B));

    fsm_event U_FSM (.CLK(CLOCK_50), .RESET_N(global_reset_n),
                   .P0_pulse(P0_pulse), .P1_pulse(P1_pulse), .P3_pulse(P3_pulse),
                   .D_candidate(D_candidate), .sw_enable(sw_enable), .Count_A_in(Count_A),
                   .Secret(Secret), .Guess(Guess), .turn_count(turn_count_fsm),
                   .current_input_index(input_idx),
                   .in_setup_phase(in_setup_phase), .in_guess_phase(in_guess_phase),
                   .output_result_phase(output_result_phase), .game_over(game_over),
                   .led_turn_count_out(turn_count));

    //DE1_SoC IO handling
    logic [3:0] hex_data_in [3:0];
    logic [3:0] data_to_decode;

    always_comb begin
        for (int i=0; i<4; i++) begin
            data_to_decode = (in_setup_phase || game_over) ? Secret[i] : Guess[i];

            if ((in_setup_phase || in_guess_phase) && (input_idx == i)) begin
                if (blink_en) begin
                    hex_data_in[i] = sw_enable ? D_manual : 4'hA;
                end else begin
                    hex_data_in[i] = (Secret[i] == 4'hF) ? 4'hA : Secret[i];
                end
            end else if (game_over) begin
                hex_data_in[i] = Secret[i];
            end else begin
                hex_data_in[i] = data_to_decode;
            end
        end
    end

    always_comb begin
        LEDR[9:6] = 4'b0000;
        if (output_result_phase) begin
            for (int i=0; i<4; i++) begin
                if (LED_A[i]) LEDR[i+6] = 1'b1;
                else if (LED_B[i]) LEDR[i+6] = blink_en;
            end
        end

        LEDR[4:0] = 5'b11111;
        for (int i=0; i < turn_count_fsm; i++) begin
            if (i < 5) LEDR[i] = 1'b0;
        end
    end

    assign HEX5 = seg_code[3];
    assign HEX4 = seg_code[2];
    assign HEX3 = seg_code[1];
    assign HEX2 = seg_code[0];
    assign HEX1 = 8'hFF;
    assign HEX0 = 8'hFF;

endmodule