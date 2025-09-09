`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2025 06:41:33 PM
// Design Name: 
// Module Name: pulse_width_checker
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pulse_width_checker #(
    parameter integer WIDTH_BITS = 16,      // bits for width counter
    parameter integer MIN_PW     = 5,       // minimum acceptable width (in clk cycles)
    parameter integer MAX_PW     = 20       // maximum acceptable width
)(
    input  wire                clk,
    input  wire                rst,        // active-high sync reset
    input  wire                pulse_in,   
    output reg                 width_validated
//    output reg [WIDTH_BITS-1:0] last_width // latched width at pulse end
);

    reg pulse_in_d = 0;
    always @(posedge clk) begin
        pulse_in_d <= pulse_in;
    end

    // 2. Edge detect
    wire rising  =  pulse_in & ~pulse_in_d;
    // 3. Width counter
    reg measuring;
    reg [WIDTH_BITS-1:0] cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            measuring   <= 1'b0;
            cnt         <= {WIDTH_BITS{1'b0}};
//            last_width  <= {WIDTH_BITS{1'b0}};
            width_validated <= 1'b1;
        end else begin
            width_validated <= 1'b1;  // default clear

            if (rising) begin
                measuring <= 1'b1;
                cnt       <= 1;
            end else if (measuring) begin
                if (pulse_in && cnt <= MAX_PW ) begin
                    // still high ? keep counting
                    cnt <= cnt + 1;
                end else begin
                    // just fell ? latch and validate
                    measuring   <= 1'b0;
//                    last_width  <= cnt;
                    width_validated <= (cnt >= MIN_PW && cnt <= MAX_PW);
                end
            end
        end
    end
endmodule

