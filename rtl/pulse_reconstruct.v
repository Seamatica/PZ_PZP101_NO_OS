`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/03/2025 03:11:35 PM
// Design Name: 
// Module Name: pulse_reconstruct
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


module pulse_reconstruct (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  reset,
    input  wire                  rising_edge,
    input  wire                  falling_edge,
    output wire                  pulse_out
);

    // Internal state
    localparam IDLE   = 1'b0;
    localparam ACTIVE = 1'b1;

    reg state;
    reg pulse;
    assign pulse_out = ((state == IDLE && rising_edge) || pulse) && !reset;
    always @(posedge clk) begin
        if (rst || reset) begin
            state          <= IDLE;
            pulse      <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (rising_edge) begin
                        pulse           <= 1'b1;
                        state           <= ACTIVE;
                    end else begin
                        pulse <= 1'b0;
                    end
                end

                ACTIVE: begin
                    if (falling_edge) begin
                        pulse <= 1'b0;
                        state     <= IDLE;
                    end else begin
                        pulse<= 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
