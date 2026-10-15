`timescale 1ns/1ps

module mem_write (
	input wire clk,
	input wire rst,
	input wire clk_en,

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

	output reg [31:0] ad,
	output reg [7:0] dt,
	input wire ok
);
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			wvd <= 0;
			wls <= 0;
			wsp <= 0;
			wtpo <= 0;
			wct <= 0;
			ad <= 0;
			dt <= 0;
		end else if (clk_en) begin
		case (wtpi)
		0: begin // IDLE
			wvd <= 0;
			wls <= 0;
			if (wen) begin
				wct <= 0;
				wsp <= wid;
				wtpo <= 1;
			end
		end
		1: begin // RDY_WRITE
			ad <= wad + wct;
			dt <= wdt;
			wtpo <= 2;
		end
		2: begin // WAIT_OK
			if (ok) wtpo <= 3;
		end
		3: begin // WRITE
			wvd <= 1;
			if (wct == wln - 1) begin
				wls <= 1;
				wtpo <= 5;
			end else begin
				wct <= wct + 1;
				wtpo <= 4;
			end
		end
		4: begin // WAIT_RDY
			if (wry) wtpo <= 1;
		end
		5: begin // DONE
			wvd <= 0;
			wls <= 0;
			wsp <= 0;
			wtpo <= 0;
		end
		endcase
		end
	end
endmodule
