module clock_divider (
    input logic CLK_50MHZ,
    input logic RESET_N,
    output logic blink_en
);

    localparam CNT_WIDTH   = 25; 
    localparam COUNTER_MAX = 25_000_000 - 1; 

    logic [CNT_WIDTH-1:0] counter = 0; 
    
    always_ff @(posedge CLK_50MHZ or negedge RESET_N) begin
        if (!RESET_N) begin
            counter <= 0;
            blink_en <= 1'b0;
        end else begin
            if (counter == COUNTER_MAX) begin
                counter <= 0;
                blink_en <= ~blink_en;
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
