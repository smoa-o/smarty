module regfile (
	input wire clk,
	input wire rst,
	output reg rst_o,
	input wire clk_en,

	input wire [7:0] rida,
	input wire [7:0] ridb,
	output reg [15:0] rdta,
	output reg [15:0] rdtb,
	input wire rena,
	input wire renb,
	output reg rfna, // fin
	output reg rfnb, // fin

	input wire [7:0] wid,
	input wire [7:0] wdtl,
	input wire [7:0] wdth,
	input wire whswd, // has word
	input wire wen,
	output reg wfn,

	input wire icpu // is cpu
);
	// ax bx cx dx ex fx gx hx bp cfg.ip cfg.csp cfg.dsp cfg.flg cpu.r0 cpu.r1
	reg [15:0] regmem [14:0];

	always @(posedge clk or posedge rst) begin
		if (!rst && clk_en) begin
			if (rena) begin
				if (!icpu) begin
					case (rida)
						13: rst_o = 1;
						default: ;
					endcase
				end
				rdta <= regmem[rida];
				rfna <= 1;
			end if (renb) begin
				if (!icpu) begin
					case (ridb)
						13: rst_o = 1;
						default: ;
					endcase
				end
				rdtb <= regmem[ridb];
				rfnb <= 1;
			end if (wen) begin
				if (!icpu) begin
					case (wid)
						8,12,13,14: rst_o = 1;
						default: ;
					endcase
				end
				regmem[wid][7:0] <= wdtl;
				if (whswd) regmem[wid][15:8] <= wdth;
				wfn <= 1;
			end
		end
	end
endmodule
