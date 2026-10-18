// Copyright (c) 2026-present SeaMcOfficialAuthority
`timescale 1ns/1ps
`include "clock.v"
`include "alu.v"

module tb_alu;

	reg clk;
	reg rst_i;
	wire rst_o;
	assign rst_o = rst_i;
	reg clk_en_i;
	wire clk_en;
	assign clk_en = clk_en_i;
	wire div;

	clock u_clk (
		.clk    (clk),
		.rst    (rst_i),
		.clk_en (clk_en),
		.div    (div)
	);

	reg [15:0] a_i;
	reg [15:0] b_i;
	wire [15:0] x_o;
	wire [15:0] y_o;
	reg [7:0] op_i;
	reg enb_i;
	wire fin_o;
	reg whswd_i;

	alu u_dut (
		.clk    (clk),
		.rst    (rst_i),
		.clk_en (clk_en_i),
		.a      (a_i),
		.b      (b_i),
		.x      (x_o),
		.y      (y_o),
		.op     (op_i),
		.enb    (enb_i),
		.fin    (fin_o),
		.whswd  (whswd_i)
	);

	initial clk = 0;
	initial rst_i = 0;
	always #5 clk = ~clk;

	initial begin
		$monitor ({"t=%0t | clk=%b rst=%b clk_en=%b div=%b op=%0d",
			" a=%0d b=%0d x=%0d y=%0d enb=%b fin=%b whswd=%b"},
			$time, clk, rst_o, clk_en, div, op_i, a_i, b_i, x_o, y_o, enb_i, fin_o, whswd_i);
		$dumpfile ("temp.vcd");
		$dumpvars (0, tb_alu);
		$display ("vcd complete");
	end
	
	integer i;
	
	initial begin
		$display ("::notice: op/a/b/x/y/enb/fin/whswd");

		rst_i <= 1;
		clk_en_i <= 1;
		enb_i <= 0;
		whswd_i <= 1;
		a_i <= 0;
		b_i <= 0;
		op_i <= 0;
		repeat (20) @(posedge clk);
		rst_i <= 0;

		// ---- word mode (whswd=1) ----

		// op0: ADD
		$display ("::notice: ADD word (exp 137)");
		a_i <= 16'd100; b_i <= 16'd37; op_i <= 0; enb_i <= 1;
		repeat (20) @(posedge clk);
		enb_i <= 0;
`ifdef SELFTEST
		if (x_o != 137) begin
			$display ("Self-Test Failed: scope: add");
			$fatal;
		end
`endif
		repeat (20) @(posedge clk);

		// op1: SUB with borrow check
		$display ("::notice: SUB word (exp 65386, borrow)");
		a_i <= 16'd50; b_i <= 16'd200; op_i <= 1; enb_i <= 1;
		repeat (20) @(posedge clk);
		enb_i <= 0;
`ifdef SELFTEST
        if (x_o != 65386 || y_o != 1) begin
            $display ("Self-Test Failed: scope: sub");
            $fatal;
        end
`endif
		repeat (20) @(posedge clk);

		// op2: INC
		$display ("::notice: INC word (exp 0, carry)");
		a_i <= 16'd65535; op_i <= 2; enb_i <= 1;
		repeat (20) @(posedge clk);
		enb_i <= 0;
`ifdef SELFTEST
        if (x_o != 0 || y_o != 1 ) begin
            $display ("Self-Test Failed: scope: inc");
            $fatal;
        end
`endif
		repeat (20) @(posedge clk);

		// op3: DEC
		$display ("::notice: DEC word (exp 65535, borrow)");
		a_i <= 16'd0; op_i <= 3; enb_i <= 1;
		repeat (20) @(posedge clk);
		enb_i <= 0;
`ifdef SELFTEST
        if (x_o != 65535 || y_o != 1 ) begin
            $display ("Self-Test Failed: scope: dec");
            $fatal;
        end
`endif
		repeat (20) @(posedge clk);

		// op4~8: logic
		$display ("::notice: logic ops word (exp 2640 45045 42397 23138 21930)");
		a_i <= 16'hAA55; b_i <= 16'h0FF0;
		for (i = 4; i <= 8; i = i + 1) begin
			op_i <= i; enb_i <= 1;
			repeat (20) @(posedge clk);
			enb_i <= 0;
			repeat (10) @(posedge clk);
		end

		// op9: SHL
		$display ("::notice: SHL word (10) (ex_op 16)");
		a_i <= 16'h0001; b_i <= 16'd4; op_i <= 9; enb_i <= 1;
		repeat (20) @(posedge clk);
		enb_i <= 0;
`ifdef SELFTEST
        if (x_o != 16) begin
            $display ("Self-Test Failed: scope: shl");
            $fatal;
        end
`endif
		repeat (20) @(posedge clk);

		// op10: SHR
		$display ("::notice: SHR word (2048)");
		a_i <= 16'h8000; b_i <= 16'd4; op_i <= 10; enb_i <= 1;
		repeat (20) @(posedge clk);
		enb_i <= 0;
`ifdef SELFTEST
        if (x_o != 2048) begin
            $display ("Self-Test Failed: scope: shr");
            $fatal;
        end
`endif
		repeat (20) @(posedge clk);

		// ---- byte mode (whswd=0) ----
		$display ("::notice: byte mode tests");
		whswd_i <= 0;

		// byte ADD
		$display ("::notice: ADD byte (exp 0, carry)");
		a_i <= 16'h00FF; b_i <= 16'h0001; op_i <= 0; enb_i <= 1;
		repeat (20) @(posedge clk);
		enb_i <= 0;
		repeat (20) @(posedge clk);

		// byte SUB
		$display ("::notice: SUB byte (exp 245, borrow)");
		a_i <= 16'h0005; b_i <= 16'h0010; op_i <= 1; enb_i <= 1;
		repeat (20) @(posedge clk);
		enb_i <= 0;
		repeat (20) @(posedge clk);

		// byte logic
		$display ("::notice: logic ops byte (exp 0 255 255 0 85)");
		a_i <= 16'h00AA; b_i <= 16'h0055;
		for (i = 4; i <= 8; i = i + 1) begin
			op_i <= i; enb_i <= 1;
			repeat (20) @(posedge clk);
			enb_i <= 0;
			repeat (10) @(posedge clk);
		end

		// byte shift
		$display ("::notice: SHL/SHR byte (exp 0 32)");
		a_i <= 16'h0080; b_i <= 16'h0002; op_i <= 9; enb_i <= 1;
		repeat (20) @(posedge clk);
		enb_i <= 0;
		repeat (10) @(posedge clk);
		op_i <= 10; enb_i <= 1;
		repeat (20) @(posedge clk);
		enb_i <= 0;
		repeat (20) @(posedge clk);

		$display ("::notice: watch x/y/fin\n:: complete");
		rst_i <= 1;
		$finish;
	end
endmodule
