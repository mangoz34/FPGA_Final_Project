import game_types::*;

module DE1_SoC (
    input logic CLOCK_50,
    input logic [3:0] KEY,
    input logic [9:0] SW,
    output logic [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0,
    output logic [9:0] LEDR
);

    logic reset_n;
    logic p0_pulse, p1_pulse;
    logic [3:0] sw_val;
    logic sw_valid;
    logic [3:0] lfsr_val;
    logic blink_on;
    
    state_t current_state;
    logic [3:0] target [3:0];
    logic [3:0] guess [3:0];
    logic [3:0] candidate;
    logic [2:0] chances;
    logic [3:0] is_random;

    assign reset_n = KEY[3];

	 //Basic components
    debouncer db0 (CLOCK_50, reset_n, KEY[0], p0_pulse);
    debouncer db1 (CLOCK_50, reset_n, KEY[1], p1_pulse);
    priority_encoder enc0 (SW, sw_val, sw_valid);
    lfsr_generator lfsr0 (CLOCK_50, reset_n, lfsr_val);

    logic [24:0] cnt_blink;
    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin cnt_blink <= 0; blink_on <= 0; end
        else begin
            if (cnt_blink == 25000000-1) begin
                cnt_blink <= 0;
                blink_on <= ~blink_on;
            end else cnt_blink <= cnt_blink + 1;
        end
    end

    //Game Core Logic
    game_core core_inst (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .p0_pulse(p0_pulse),
        .p1_pulse(p1_pulse),
        .sw_val(sw_val),
        .sw_valid(sw_valid),
        .lfsr_val(lfsr_val),
        .current_state(current_state),
        .target(target),
        .guess(guess),
        .candidate(candidate),
        .chances(chances),
        .is_random(is_random)
    );

    //Handle FPGA I/O
    display_ctrl disp_inst (
        .state(current_state),
        .blink_on(blink_on),
        .target(target),
        .guess(guess),
        .candidate(candidate),
        .sw_valid(sw_valid),
        .chances(chances),
        .is_random(is_random),
        .HEX5(HEX5), .HEX4(HEX4), .HEX3(HEX3), .HEX2(HEX2),
        .LEDR(LEDR)
    );

endmodule