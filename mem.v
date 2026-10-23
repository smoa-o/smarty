// Copyright (c) 2026-present SeaMcOfficialAuthority
`include "mem/read.vh"
`include "mem/write.vh"

module mem (
	input wire rst,
	input wire clk,
	input wire clk_en,

	input wire [31:0] rada,
	input wire [31:0] radb,
	output reg [7:0] rdta,
	output reg [7:0] rdtb,
	input wire rena,
	input wire renb,
	output reg rvda,
	output reg rvdb,
	input wire [3:0] rlna,
	input wire [3:0] rlnb,
	input wire rrya,
	input wire rryb,
	output reg rlsa,
	output reg rlsb,
	input wire [3:0] rida,
	input wire [3:0] ridb,
	output reg [3:0] rspa,
	output reg [3:0] rspb,
	output reg [3:0] rtsa,
	output reg [3:0] rtsb,
	output reg [3:0] rcta,
	output reg [3:0] rctb,
	input wire [3:0] rtpia,
	input wire [3:0] rtpib,
	output reg [3:0] rtpoa,
	output reg [3:0] rtpob,

	input wire [31:0] wad,
	input wire [7:0] wdt,
	input wire wen,
	output reg wvd,
	input wire [3:0] wln,
	input wire wry,
	output reg wls,
	input wire [3:0] wid,
	output reg [3:0] wsp,
	output reg [3:0] wts,
	output reg [3:0] wct,
	input wire [3:0] wtpi,
	output reg [3:0] wtpo,

	output wire [31:0] radoa,
	output wire [7:0] rdtoa,
	output reg roka,
	output wire [31:0] radob,
	output wire [7:0] rdtob,
	output reg rokb,
	output reg [31:0] wado,
	output reg [7:0] wdto,
	output reg wok,
	output reg weno,

	input wire rokoa,
	input wire rokob,
	input wire woko
);

	reg [7:0] mem [0:1023];
	integer i;

	wire [31:0] radoa_w, radob_w, wado_w;
	wire [7:0] rdta_w, rdtb_w, rdtoa_w, rdtob_w, wdto_w;
	wire rvda_w, rvdb_w, wvd_w;
	wire rlsa_w, rlsb_w, wls_w;
	wire [3:0] rspa_w, rspb_w, wsp_w, rtpoa_w, rtpob_w, wtpo_w;
	wire [3:0] rtsa_w, rtsb_w, wts_w, rcta_w, rctb_w, wct_w;
	wire roka_w, rokb_w, wok_w;

	mem_read rdra (
		.clk(clk), .rst(rst), .clk_en(clk_en),
		.rad(rada), .rdt(rdta_w), .ren(rena), .rvd(rvda_w),
		.rln(rlna), .rry(rrya), .rls(rlsa_w), .rid(rida),
		.rsp(rspa_w), .rts(rtsa_w), .rct(rcta_w), .rtpi(rtpia), .rtpo(rtpoa_w),
		.ad(radoa_w), .dt(rdtoa_w), .ok(roka_w)
	);

	mem_read rdrb (
		.clk(clk), .rst(rst), .clk_en(clk_en),
		.rad(radb), .rdt(rdtb_w), .ren(renb), .rvd(rvdb_w),
		.rln(rlnb), .rry(rryb), .rls(rlsb_w), .rid(ridb),
		.rsp(rspb_w), .rts(rtsb_w), .rct(rctb_w), .rtpi(rtpib), .rtpo(rtpob_w),
		.ad(radob_w), .dt(rdtob_w), .ok(rokb_w)
	);

	mem_write wdr (
		.clk(clk), .rst(rst), .clk_en(clk_en),
		.wad(wad), .wdt(wdt), .wen(wen), .wvd(wvd_w),
		.wln(wln), .wry(wry), .wls(wls_w), .wid(wid),
		.wsp(wsp_w), .wts(wts_w), .wct(wct_w), .wtpi(wtpi), .wtpo(wtpo_w),
		.ad(wado_w), .dt(wdto_w), .ok(wok_w)
	);

	assign wok_w  = woko;
	assign roka_w = rokoa;
	assign rokb_w = rokob;

	assign rdtoa_w = mem[radoa_w];
	assign rdtob_w = mem[radob_w];

	initial begin
		for (i = 0; i < 1024; i = i + 1)
			mem[i] = 8'h00;
	end

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			rdta <= 0; rdtb <= 0; rvda <= 0; rvdb <= 0;
			rlsa <= 0; rlsb <= 0; wvd <= 0; wls <= 0;
			rspa <= 0; rspb <= 0; wsp <= 0;
			rtsa <= 0; rtsb <= 0; wts <= 0;
			rcta <= 0; rctb <= 0; wct <= 0;
			rtpoa <= 0; rtpob <= 0; wtpo <= 0;
			wado <= 0; wdto <= 0;
			roka <= 0; rokb <= 0; wok <= 0;
		end else if (clk_en) begin
			rdta <= rdta_w; rdtb <= rdtb_w;
			rvda <= rvda_w; rvdb <= rvdb_w;
			rlsa <= rlsa_w; rlsb <= rlsb_w;
			wvd <= wvd_w; wls <= wls_w;
			rspa <= rspa_w; rspb <= rspb_w; wsp <= wsp_w;
			rtsa <= rtsa_w; rtsb <= rtsb_w; wts <= wts_w;
			rcta <= rcta_w; rctb <= rctb_w; wct <= wct_w;
			rtpoa <= rtpoa_w; rtpob <= rtpob_w; wtpo <= wtpo_w;
			wado <= wado_w;
			wdto <= wdto_w;
			if (wvd_w) begin
				mem[wado_w] <= wdto_w;
			end
			roka <= rokoa;
			rokb <= rokob;
			wok  <= woko;
		end
	end

	assign radoa = radoa_w;
	assign radob = radob_w;

endmodule
