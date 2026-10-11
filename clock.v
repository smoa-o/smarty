// License: https://gitee.com/smoa-new/smarty/blob/master/LICENSE

module clock (
	input wire clk,
	input wire rst,
	output reg div,
	output reg clk_en
);
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			div <= 0;
			clk_en <= 0;
		end else begin
			div <= ~div;
			clk_en <= ~div;
		end
	end
endmodule
