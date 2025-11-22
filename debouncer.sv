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

    always_ff @(posedge clk) begin
        key_meta <= key_in;
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
            key_stable <= 1'b0;
        end else begin
            if (key_meta != key_stable) begin
                if (counter == DEBOUNCE_CNT - 1) begin
                    key_stable <= key_meta;
                    counter <= 0;
                end else begin
                    counter <= counter + 1;
                end
            end else begin
                counter <= 0;
            end
        end
    end

    logic key_stable_dly = 1'b0;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            key_stable_dly <= 1'b0;
        end else begin
            key_stable_dly <= key_stable;
        end
    end

    assign key_pulse = key_stable & (~key_stable_dly);

endmodule