`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2025 03:00:55 PM
// Design Name: 
// Module Name: mavg_fir
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


module mavg_fir #(
    parameter WIDTH  = 16,     // input sample bit-width
    parameter WINDOW = 4       // number of taps (power of 2)
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         data_valid,
    input  wire [WIDTH-1:0]             data_in,
    output reg                          data_valid_out,
    output reg [WIDTH+$clog2(WINDOW)-1:0] avg_out
);

    localparam LG = $clog2(WINDOW);
    localparam ACC_WIDTH = WIDTH + LG;

    // Circular buffer
    reg [LG-1:0]        ptr;
    reg [WIDTH-1:0]     buffer [0:WINDOW-1];
    reg [ACC_WIDTH-1:0] acc;
    reg [LG:0]          sample_cnt;  // Needs to count up to WINDOW

    wire [ACC_WIDTH-1:0] sum_next = acc + data_in - buffer[ptr];

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            ptr            <= 0;
            acc            <= 0;
            sample_cnt     <= 0;
            data_valid_out <= 0;
            avg_out        <= 0;
            for (i = 0; i < WINDOW; i = i + 1)
                buffer[i] <= 0;
        end
        else if (data_valid) begin
            acc         <= sum_next;
            buffer[ptr] <= data_in;
            ptr         <= ptr + 1;

            // Increment sample count until it reaches WINDOW
            if (sample_cnt < WINDOW)
                sample_cnt <= sample_cnt + 1;

            // Assert data_valid_out only when buffer is full
            if (sample_cnt >= WINDOW-1) begin
                data_valid_out <= 1;
                avg_out        <= sum_next >> LG;  // Logical shift for division
            end else begin
                data_valid_out <= 0;
            end
        end else begin
            data_valid_out <= 0;
        end
    end
endmodule
