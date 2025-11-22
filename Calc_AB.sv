module Calc_AB (
    input logic [3:0] Secret [3:0],
    input logic [3:0] Guess  [3:0],
    output logic [2:0] Count_A,
    output logic [2:0] Count_B,
    output logic [3:0] LED_A,
    output logic [3:0] LED_B
);

    // Variable for tracking A and B
    logic [3:0] consumed_D;
    logic [3:0] consumed_G;

    logic [2:0] count_B_temp;

    always_comb begin
        Count_A = 0;
        count_B_temp = 0;
        LED_A = 4'b0000;
        LED_B = 4'b0000;
        consumed_D = 4'b0000;
        consumed_G = 4'b0000;

        //Handling A event
        for (int i = 0; i < 4; i++) begin
            if (Guess[i] == Secret[i]) begin
                Count_A = Count_A + 1;
                LED_A[i] = 1'b1;
                consumed_G[i] = 1'b1;
                consumed_D[i] = 1'b1;
            end
        end

        // Handling B event
        for (int i = 0; i < 4; i++) begin
            if (!consumed_G[i]) begin
                for (int j = 0; j < 4; j++) begin
                    if ((Guess[i] == Secret[j]) && (!consumed_D[j])) begin

                        count_B_temp = count_B_temp + 1;
                        LED_B[i] = 1'b1;

                        consumed_D[j] = 1'b1;
                        consumed_G[i] = 1'b1;
                        break;
                    end
                end
            end
        end

        Count_B = count_B_temp;
    end

endmodule