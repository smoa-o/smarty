`timescale 1ns/1ps
`include "clock.v"
`include "regfile.v"

module tb_regfile;
	reg clk;
	reg rst_i;
	wire rst_o = rst_i;
	assign rst_o = rst_i;
	reg clk_en_i;
	wire clk_en = clk_en_i;
	assign clk_en = clk_en_i;
	wire div;

	clock u_clk (
		.clk (clk),
		.rst (rst_i),

		.clk_en (clk_en),
		.div (div)
	);

	reg [7:0] rida;
	reg [7:0] ridb;
	reg [7:0] wid;
	wire [15:0] rdta;
	wire [15:0] rdtb;
	reg [7:0] wdth;
	reg [7:0] wdtl;
	reg rena, renb, wen;
	wire rfna, rfnb, wfn;
	reg whswd;
	reg icpu;
	
	regfile u_dut (
		.clk (clk),
		.rst (rst_i),
		.rst_o (rst_o),
		.clk_en (clk_en_i),

		.rida (rida),
		.ridb (ridb),
		.rdta (rdta),
		.rdtb (rdtb),
		.rena (rena),
		.renb (renb),
		.rfna (rfna),
		.rfnb (rfnb),

		.wid (wid),
		.wdtl (wdtl),
		.wdth (wdth),
		.whswd (whswd),
		.wen (wen),
		.wfn (wfn),

		.icpu (icpu)
	);

	initial clk = 0;
	initial rst_i = 0;
	always #5 clk = ~clk;

	initial begin
		$monitor ({"t=%0t | clk=%b rst=%b clk_en=%b div=%b id=%0d~%0d:%0d dt=%0d~%0d:%0d~%0d en=%b~%b:%b",
			"fn=%b~%b:%b whswd=%b"}, $time, clk, rst_o, clk_en, div, rida, ridb, wid, rdta, rdtb, wdtl, wdth,
			rena, renb, wen, rfna, rfnb, wfn, whswd);
		$dumpfile ("temp.vcd");
		$dumpvars (0, tb_regfile);
		$display ("vcd complete");
	end

	initial begin
		$display ("::notice: id/en/fn: r*a~r*b:w* @ dt: r*a~r*b:w*l~w*h");

		rst_i <= 1;
		clk_en_i <= 1;
		repeat (20) @(posedge clk);
		rst_i <= 0;
		
		wid <= 10;
		wdtl <= 17;
		wdth <= 16;
		whswd <= 1;
		wen <= 1;
		repeat (20) @(posedge clk);
		wen <= 0;

		rida <= 10;
		rena <= 1;
		repeat (20) @(posedge clk);
		rena <= 1;

		$display ("::notice: watch rdta\n:: complete");
		
		rst_i <= 1;
		$finish;
	end
endmodule
