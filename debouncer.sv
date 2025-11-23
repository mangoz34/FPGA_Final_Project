module debouncer(clk, reset_n, key_in, key_pulse);
	input logic clk, reset_n, key_in;
	output logic key_pulse;
	logic [2:0] btn_sync;
	logic btn_stable, btn_prev;
	
	always_ff @(posedge clk or negedge reset_n) begin
		if(!reset_n) begin
			btn_sync <= 3'b111;
			btn_prev <= 1'b0;
		end else begin
			btn_sync <= {btn_sync[1:0], key_in};
			btn_prev <= btn_stable;
		end
	end
	
	assign btn_stable = (btn_sync == 3'b000);
	
	assign key_pulse = btn_stable && !btn_prev;

endmodule
