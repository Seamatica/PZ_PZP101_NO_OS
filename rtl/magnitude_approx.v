`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2025 01:04:03 PM
// Design Name: 
// Module Name: magnitude_approx
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

module magnitude_approx #(
    parameter DATA_WIDTH = 16
)(
    input  wire rst,
    input  signed [DATA_WIDTH-1:0] i_data,  // I component
    input  signed [DATA_WIDTH-1:0] q_data,  // Q comp Valid flags
    output wire [DATA_WIDTH-1:0] magnitude       // Approximated magnitude
);

    // Absolute values
    wire [DATA_WIDTH-1:0] abs_i = (i_data < 0) ? -i_data : i_data;
    wire [DATA_WIDTH-1:0] abs_q = (q_data < 0) ? -q_data : q_data;

    // Max (A) and Min (B)
    wire [DATA_WIDTH-1:0] A = (abs_i > abs_q) ? abs_i : abs_q;
    wire [DATA_WIDTH-1:0] B = (abs_i > abs_q) ? abs_q : abs_i;

    // Safe scaled B
    wire [DATA_WIDTH+1:0] B_wide = B;
    wire [DATA_WIDTH+2:0] B_scaled_sum = (B_wide << 1) + B_wide; // 3*B
    wire [DATA_WIDTH-1:0] scaled_B = B_scaled_sum >> 3; // /8

    // Magnitude output
    assign magnitude = rst ? {DATA_WIDTH{1'b0}} : (A + scaled_B);

endmodule
