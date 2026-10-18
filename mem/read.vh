// Copyright (c) 2026-present SeaMcOfficialAuthority
`timescale 1ns/1ps

module mem_read (
	input wire clk,
	input wire rst,
	input wire clk_en,

	input wire [31:0] rad,
	output reg [7:0] rdt,
	input wire ren,
	output reg rvd,
	input wire [3:0] rln,
	input wire rry,
	output reg rls,
	input wire [3:0] rid,
	output reg [3:0] rsp,
	output reg [3:0] rts,
	output reg [3:0] rct,
	input wire [3:0] rtpi,
	output reg [3:0] rtpo,

	output reg [31:0] ad,
	input wire [7:0] dt,
	input wire ok
);
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			rvd <= 0;
			rls <= 0;
			rsp <= 0;
			rtpo <= 0;
			rct <= 0;
			ad <= 0;
			rdt <= 0;
		end else if (clk_en) begin
		case (rtpi)
		0: begin // IDLE
			rvd <= 0;
			rls <= 0;
			if (ren) begin
				rct <= 0;
				rsp <= rid;
				rtpo <= 1;
			end
		end
		1: begin // RDY_READ
			ad <= rad + rct;
			rtpo <= 2;
		end
		2: begin // WAIT_OK
			if (ok) rtpo <= 3;
		end
		3: begin // READ
			rdt <= dt;
			rvd <= 1;
			if (rct == rln - 1) begin
				rls <= 1;
				rtpo <= 5;
			end else begin
				rct <= rct + 1;
				if (rln == 1)
					rtpo <= 5;
				else
					rtpo <= 4;
			end
		end
		4: begin // WAIT_RDY
			if (rry) rtpo <= 1;
		end
		5: begin // DONE
			rvd <= 0;
			rls <= 0;
			rsp <= 0;
			rtpo <= 0;
		end
		endcase
		end
	end
endmodule
