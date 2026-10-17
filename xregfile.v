module xregfile (
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
	input wire whswdl, // has word
	input wire whswdh,
	input wire wen,
	output reg wfn,
);
	// xr0~15: word
	reg [15:0] regmem [15:0];

	always @(posedge clk or posedge rst) begin
		if (!rst && clk_en) begin
			if (rena) begin
				rdta <= regmem[rida];
				rfna <= 1;
			end if (renb) begin
				rdtb <= regmem[ridb];
				rfnb <= 1;
			end if (wen) begin
				if (whswdl) regmem[wid][7:0] <= wdtl;
				if (whswdh) regmem[wid][15:8] <= wdth;
				wfn <= 1;
			end
		end
	end
endmodule
