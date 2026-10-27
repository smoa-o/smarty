module fpd (
	input wire clk,
	input wire rst,
	input wire clk_en,

	input wire enb,
	output reg fin,
	output reg err,

	output reg [6:0] inst,
	output reg hasvn,
	output reg [3:0] variant, // opt
	output reg [3:0] atype, // opt
	output reg [7:0] types, // opt
	output reg [15:0] arga, // opt
	output reg [15:0] argb, // opt

	// 1-port cpu register reader
	output reg rrgsyn,
	input wire rrgack,
	input wire rrgfin,
	output reg rrgcln,
	output reg [7:0] rrgid,
	input wire [15:0] rrgdt,
	output reg rrgen,
	input wire rrgfn,

	// 1-port memory reader
	output reg rmmsyn,
	input wire rmmack,
	input wire rmmfin,
	output reg rmmcln,
	output reg [31:0] rmmad,
	input wire [7:0] rmmdt,
	output reg rmmen,
	input wire rmmvd,
	output reg [3:0] rmmln,
	output reg rmmry,
	input wire rmmls,
	output reg [3:0] rmmid,
	input wire [3:0] rmmsp,

	input wire stp_i,
	output reg stp_o,
	input wire [7:0] exp_i,
	output reg [7:0] exp_o,
	input wire [7:0] clk_i,
	output reg [7:0] clk_o,
	input wire [7:0] dat_i,
	output reg [7:0] dat_o
);
	always @(posedge clk or posedge rst) begin
		if (!rst && clk_en && enb) begin
			case (stp_i) begin
				// 1. read a byte: inst, hasvn
				// {inst, hasvn} = mem[ip]
				0: begin // read ip
					rrgid <= 10; // read cfg.ip
					rrgen <= 1;
					clk_o <= 0;
					exp_o <= 10;
					rrgsyn <= 1;
					stp_o <= 1;
				end 1: begin
					if (rrgack) begin
						clk_o <= 0;
						exp_o <= 50;
						stp_o <= 3;
					end else if (exp_i == clk_i) begin
						err <= 1;
						stp_o <= 2;
					end
				end 2: ;
				3: begin
					if (rrgfin) begin
						rrgen <= 0;
						rrgsyn <= 0;
						// read [rrgdt]
						rmmad <= rrgdt;
						rmmln <= 1;
						rmmid <= 0;
						clk_o <= 0;
						exp_o <= 10;
						rmmen <= 1;
						rmmsyn <= 1;
						stp_o <= 4;
					end else if (exp_i == clk_i) begin
						err <= 1;
						stp_o <= 2;
					end
				end 4: begin
					if (rmmack) begin
						clk_o <= 0;
						exp_o <= 50;
						stp_o <= 5;
					end else if (exp_i == clk_i) begin
						err <= 1;
						stp_o <= 2;
					end
				end 5: begin
					if (rmmsp != 0 && (rmmfin || clk_i == exp_i)) begin
						clk_o <= 0;
						exp_o <= 50;
						stp_o <= 5;
					end if (rmmfin) begin
						dat_o <= rmmdt;
						rmmry <= 1;
						rmmen <= 0;
						rmmsyn <= 0;
						
						{inst, hasvn} <= dat_o;
						if (hasvn) stp_o <= 6;
						else begin
							stp_o <= // TODO
						end
					end else if (clk_i == exp_i) begin
						err <= 1;
						stp_o <= 2;
					end
				end 6: begin
					rmmad <= rrgdt + 1;
					rmmln <= 1;
					rmmid <= 0;
					clk_o <= 0;
					exp_o <= 10;
					rmmen <= 1;
					rmmsyn <= 1;
					stp_o <= 4;
				end
			end
			clk_o <= clk_o + 1;
		end
	end
endmodule
