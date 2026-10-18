// Copyright (c) 2026-present SeaMcOfficialAuthority
module alu (
	input wire clk,
	input wire rst,
	input wire clk_en,
	
	input wire [15:0] a,
	input wire [15:0] b,
	output reg [15:0] x,
	output reg [15:0] y,
	input wire [7:0] op,
	input wire enb, // enabled
	output reg fin,
	input wire whswd
);
	always @(posedge clk or posedge rst) begin
		if (!rst && clk_en && enb) begin
			// ADD SUB INC DEC AND OR XOR XNOR NOT SHL SHR
			if (whswd) begin
				case (op)
					0: {y[0], x} <= {1'b0, a} + {1'b0, b};
					1: begin x <= a - b; y[0] <= (a < b); end
					2: {y[0], x} <= a + 1;
					3: begin x <= a - 1; y[0] <= (a < 1); end
					4: x <= a & b;
					5: x <= a | b;
					6: x <= a ^ b;
					7: x <= ~(a ^ b);
					8: x <= ~a;
					9: x <= a << b;
					10: x <= a >> b;
				endcase
				fin <= 1;
			end else begin
				case (op)
					0: {y[0], x[7:0]} <= {1'b0, a[7:0]} + {1'b0, b[7:0]};
					1: begin x[7:0] <= a[7:0] - b[7:0]; y[0] <= (a[7:0] < b[7:0]); end
					2: {y[0], x[7:0]} <= a[7:0] + 1;
					3: begin x[7:0] <= a[7:0] - 1; y[0] <= (a[7:0] < 1); end
					4: x[7:0] <= a[7:0] & b[7:0];
					5: x[7:0] <= a[7:0] | b[7:0];
					6: x[7:0] <= a[7:0] ^ b[7:0];
					7: x[7:0] <= ~(a[7:0] ^ b[7:0]);
					8: x[7:0] <= ~a[7:0];
					9: x[7:0] <= a[7:0] << b[7:0];
					10: x[7:0] <= a[7:0] >> b[7:0];
				endcase
				fin <= 1;
			end
		end
	end
endmodule
