module Priority_Encoder (
    input logic [9:0] SW_in,
    output logic [3:0] D_manual,
    output logic sw_enable
);

    always_comb begin
        if      (SW_in[9])  D_manual = 4'd9;
        else if (SW_in[8])  D_manual = 4'd8;
        else if (SW_in[7])  D_manual = 4'd7;
        else if (SW_in[6])  D_manual = 4'd6;
        else if (SW_in[5])  D_manual = 4'd5;
        else if (SW_in[4])  D_manual = 4'd4;
        else if (SW_in[3])  D_manual = 4'd3;
        else if (SW_in[2])  D_manual = 4'd2;
        else if (SW_in[1])  D_manual = 4'd1;
        else if (SW_in[0])  D_manual = 4'd0;
        else                D_manual = 4'd0; // 如果所有 SW 都關閉，輸出 0
    end

    // check if sw is valid input(enable)
    assign sw_enable = |SW_in; // Reduce OR 運算

endmodule