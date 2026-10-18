// Copyright (c) 2026-present SeaMcOfficialAuthority
`timescale 1ns/1ps

`include "clock.v"

module tb_clock;
	reg clk;
	reg rst;
	wire div;
	wire clk_en;

	clock u_clk (
	    .clk(clk),
	    .rst(rst),
	    .div(div),
	    .clk_en(clk_en)
	);

`ifdef SELFTEST
	reg rclk_en;
`endif

	always #5 clk = ~clk;

	initial begin
	    $dumpfile("temp.vcd");
	    $dumpvars(0, tb_clock);
	end

	initial begin
	    $monitor("t=%0t | clk=%b rst=%b | div=%b clk_en=%b",
	             $time, clk, rst, div, clk_en);
	end

	initial begin
	    clk = 0;
	    rst = 0;

	    #200 rst = 1;
	    @(posedge clk);
	    rst = 0;

`ifdef SELFTEST
		rclk_en <= clk_en;
		repeat (3) @(posedge clk);
		if (rclk_en != ~clk_en) begin
			$display ("Self-Test Failed: expected clk_en=%b, but inverted. ", ~rclk_en);
			$fatal;
		end
`endif
	    
	    repeat (20) @(posedge clk);
		#200 $display("Terminate.");
		$finish;
	end

endmodule
