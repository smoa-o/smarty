// Copyright (c) 2026-present SeaMcOfficialAuthority
`timescale 1ns/1ps

`include "mem.v"
`include "clock.v"

module tb;

	reg u_clk;
	initial u_clk = 0;
	always #5 u_clk = ~u_clk;

	reg rst;
	wire div;
	wire clk_en;

	clock clk_div (
		.clk(u_clk),
		.rst(rst),
		.div(div),
		.clk_en(clk_en)
	);

	// ---- DUT interface ----
	reg  [31:0] rada, radb, wad;
	reg  [7:0]  wdt;
	reg         rena, renb, wen;
	reg  [3:0]  rlna, rlnb, wln;
	reg         rrya, rryb, wry;
	reg  [3:0]  rida, ridb, wid;
	reg  [3:0]  rtpia, rtpib, wtpi;
	reg  rokoa, rokob, woko;

	wire [7:0]  rdta, rdtb;
	wire        rvda, rvdb, wvd;
	wire        rlsa, rlsb, wls;
	wire [3:0]  rspa, rspb, wsp;
	wire [3:0]  rtsa, rtsb, wts;
	wire [3:0]  rcta, rctb, wct;
	wire [3:0]  rtpoa, rtpob, wtpo;

	wire [31:0] radoa, radob, wado;
	wire [7:0]  rdtoa, rdtob, wdto;
	wire        roka, rokb, wok, weno;

	mem dut (
		.rst(rst), .clk(u_clk), .clk_en(clk_en),
		.rada(rada), .radb(radb), .rdta(rdta), .rdtb(rdtb),
		.rena(rena), .renb(renb), .rvda(rvda), .rvdb(rvdb),
		.rlna(rlna), .rlnb(rlnb), .rrya(rrya), .rryb(rryb),
		.rlsa(rlsa), .rlsb(rlsb), .rida(rida), .ridb(ridb),
		.rspa(rspa), .rspb(rspb), .rtsa(rtsa), .rtsb(rtsb),
		.rcta(rcta), .rctb(rctb), .rtpia(rtpia), .rtpib(rtpib),
		.rtpoa(rtpoa), .rtpob(rtpob),
		.wad(wad), .wdt(wdt), .wen(wen), .wvd(wvd),
		.wln(wln), .wry(wry), .wls(wls), .wid(wid),
		.wsp(wsp), .wts(wts), .wct(wct), .wtpi(wtpi),
		.wtpo(wtpo),
		.radoa(radoa), .rdtoa(rdtoa), .roka(roka),
		.radob(radob), .rdtob(rdtob), .rokb(rokb),
		.wado(wado), .wdto(wdto), .wok(wok), .weno(weno),
		.rokoa(rokoa), .rokob(rokob), .woko(woko)
	);

	// ---- 手递手回环 ----
	always @(posedge u_clk or posedge rst) begin
		if (rst) begin
			wtpi  <= 0;
			rtpia <= 0;
			rtpib <= 0;
		end else if (clk_en) begin
			wtpi  <= wtpo;
			rtpia <= rtpoa;
			rtpib <= rtpob;
		end
	end

	// ---- 自动 ok 响应 ----
	always @(*) begin
		woko  = (wtpo == 2);
		rokoa = (rtpoa == 2);
		rokob = (rtpob == 2);
	end

	initial begin
		$dumpfile("temp.vcd");
		$dumpvars(0, tb);
	end

	initial begin
		$monitor("t=%0t | rst=%b clk_en=%b | wen=%b wad=%h wdt=%h wok=%b wtpo=%h | rena=%b rada=%h roka=%b rdta=%h rtpoa=%h | renb=%b radb=%h rokb=%b rdtb=%h rtpob=%h",
		$time, rst, clk_en,
		wen, wad, wdt, wok, wtpo,
		rena, rada, roka, rdta, rtpoa,
		renb, radb, rokb, rdtb, rtpob);
	end

	initial begin
		// init
		rst   = 1;
		rada  = 0; radb  = 0; wad = 0; wdt = 0;
		rena  = 0; renb  = 0; wen = 0;
		rlna  = 0; rlnb  = 0; wln = 0;
		rrya  = 0; rryb  = 0; wry = 0;
		rida  = 0; ridb  = 0; wid = 0;
		rtpia = 0; rtpib  = 0; wtpi = 0;

		repeat (10) @(posedge u_clk);
		rst = 0;

		// 等第一个 clk_en=1
		while (!clk_en) @(posedge u_clk);

		// ---- Step 1: write 0xaa to addr 0x10 ----
		$display(":: Step 1 - Write 0xaa to 0x10");
		wad  = 32'h10;
		wdt  = 8'haa;
		wln  = 4'h1;
		wid  = 4'h1;
		wen  = 1;

		// 保持 wen 直到 FSM 进入状态 1（确认采到）
		wait (wtpo != 0);
		@(posedge u_clk);
		wen  = 0;
		$display(":: wen deasserted, wtpo=%h", wtpo);

		// wait for write to complete
		wait (wtpo == 0);
		@(posedge u_clk);
		$display(":: Write done, wtpo back to 0");

		while (!clk_en) @(posedge u_clk);

		// ---- Step 2: read back from port A ----
		$display(":: Step 2 - Read from port A addr 0x10");
		rada = 32'h10;
		rlna = 4'h1;
		rida = 4'h1;
		rena = 1;

		wait (rtpoa != 0);
		@(posedge u_clk);
		rena = 0;

		wait (rtpoa == 0);
		@(posedge u_clk);
		$display(":: Read A done, rdta=0x%h roka=%b", rdta, roka);

		while (!clk_en) @(posedge u_clk);

		// ---- Step 3: read from port B ----
		$display(":: Step 3 - Read from port B addr 0x10");
		radb = 32'h10;
		rlnb = 4'h1;
		ridb = 4'h1;
		renb = 1;

		wait (rtpob != 0);
		@(posedge u_clk);
		renb = 0;

		wait (rtpob == 0);
		@(posedge u_clk);
		$display(":: Read B done, rdtb=0x%h rokb=%b", rdtb, rokb);

		repeat (5) @(posedge u_clk);
		$display(":: All tests done!");
		$finish;
	end

endmodule
