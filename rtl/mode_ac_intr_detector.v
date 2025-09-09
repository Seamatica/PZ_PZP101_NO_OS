`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/24/2025 06:25:28 PM
// Design Name: 
// Module Name: mode_ac_intr_detector
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


module mode_ac_intr_detector #(
    parameter WIDTH = 16,  // data_in width
    parameter P3_TOL = 3
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  rise_in,     // 1-cycle rising-edge strobe
    input  wire                  pulse_validated,    // width-qualified edge
    input  wire [WIDTH-1:0]      data_in,     // magnitude for peak

    output reg                   msg_valid,   // 1-cycle when msg_data is valid
    output reg                   p3_seen,   // 1-cycle when msg_data is valid
    output reg [WIDTH+7:0]       msg_data     // {mode_bits, p1_peak}; mode A = 2'b10, mode C = 2'b01
);
    // Local timing windows in clocks (set for your sample rate)
    localparam integer P2_LO       = 118;
    localparam integer P2_HI       = 128;
    localparam integer PEAK_SEARCH = 20;   // track P1 peak until just before P2 window
    localparam integer PEAK2_SEARCH = P2_HI + PEAK_SEARCH;

    localparam integer P3A_CENTER  = 492;
    localparam integer P3A_LO      = P3A_CENTER - P3_TOL;
    localparam integer P3A_HI      = P3A_CENTER + P3_TOL;

    localparam integer P3C_CENTER  = 1290;
    localparam integer P3C_LO      = P3C_CENTER - P3_TOL;
    localparam integer P3C_HI      = P3C_CENTER + P3_TOL;

    // States
    localparam [1:0] S_IDLE    = 2'd0,
                     S_WAIT_P2 = 2'd1,
                     S_WAIT_A  = 2'd2,
                     S_WAIT_C  = 2'd3;

    reg [1:0]  state;
    reg [15:0] cnt;               // cycles since P1

    // Peaks
    reg [WIDTH-1:0] p1_peak;
    reg [WIDTH-1:0] p1_peak_1;
    reg [WIDTH-1:0] p2_peak;    // simple sample at P2 edge for compare
    reg             p2_seen;

    // Window flags
    wire in_p2_win  = (cnt >= P2_LO)  && (cnt <= P2_HI);
    wire in_p3a_win = (cnt >= P3A_LO) && (cnt <= P3A_HI);
    wire in_p3c_win = (cnt >= P3C_LO) && (cnt <= P3C_HI);

    always @(posedge clk) begin
        if (rst || !pulse_validated) begin
            state     <= S_IDLE;
            cnt       <= 16'd0;
            p1_peak   <= {WIDTH{1'b0}};
            p1_peak_1   <= {WIDTH{1'b0}};
            p2_peak   <= {WIDTH{1'b0}};
            p3_seen   <= 1'b0;
            p2_seen   <= 1'b0;
            msg_valid <= 1'b0;
            msg_data  <= {(WIDTH+8){1'b0}};
        end else begin
            msg_valid <= 1'b0;
            p3_seen   <= 1'b0;

            case (state)
                // Wait for first valid edge, treat as P1
                S_IDLE: begin
                    cnt     <= 16'd0;
                    p1_peak <= {WIDTH{1'b0}};
                    p1_peak_1 <= {WIDTH{1'b0}};
                    p2_seen <= 1'b0;
                    p3_seen <= 1'b0;
                    if (rise_in) begin
                        p1_peak <= data_in;   // start P1 peak with first sample
                        state   <= S_WAIT_P2;
                        cnt     <= 16'd0;     // define cnt=0 at P1
                    end
                end

                // Track P1 peak until P1_PEAK_END. Only accept edges in P2 window.
                S_WAIT_P2: begin
                    // update P1 peak while before P2 window
                    if (cnt < PEAK_SEARCH) begin
                        if (data_in > p1_peak) p1_peak <= data_in;
                    end
                    
                    if (p2_seen) begin
                        if (cnt < PEAK2_SEARCH) begin
                            if (data_in > p2_peak) p2_peak <= data_in;
                        end
                        else if ( cnt == PEAK2_SEARCH) begin
                            if (p2_peak > p1_peak_1) begin
                                state <= S_IDLE;
                            end
                            
                        end     
                    end

                    if (rise_in) begin
                        if (in_p2_win) begin
                            // got P2
                            p2_peak <= data_in;
                            p2_seen   <= 1'b1;
                            p1_peak_1   <= p1_peak - (p1_peak >> 2);
                        end else begin
                            // any edge outside P2 window is a reject
                            state <= S_IDLE;
                        end
                    end

                    // move to A window when time reaches its start
                    if (cnt >= P3A_LO) state <= S_WAIT_A;
                    else               cnt   <= cnt + 1'b1;
                end

                // Accept only edges inside Mode A window
                S_WAIT_A: begin
                    if (rise_in) begin
                        if (in_p3a_win) begin
                            // Mode A detected
                            msg_data  <= {p1_peak,8'h01};
                            p3_seen   <= 1'b1;
                        end else begin
                            // edge outside A window is a reject
                            state <= S_IDLE;
                        end
                    end else if (p3_seen) begin
                        msg_valid <= 1'b1;
                        state     <= S_IDLE;
                    end else begin
                        if (cnt > P3A_HI) state <= S_WAIT_C;
                        else              cnt   <= cnt + 1'b1;
                    end
                end

                // Accept only edges inside Mode C window
                S_WAIT_C: begin
                    if (rise_in) begin
                        if (in_p3c_win) begin
                            // Mode C detected
                            msg_data  <= {p1_peak,8'h02};
                            p3_seen <= 1'b1;
                        end else begin
                            // edge outside C window is a reject
                            state <= S_IDLE;
                        end
                    end else if (p3_seen) begin
                        msg_valid <= 1'b1;
                        state     <= S_IDLE;
                    end else begin
                        if (cnt > P3C_HI) begin
                            // no P3 at A or C timing
                            state <= S_IDLE; // reject
                        end else begin
                            cnt <= cnt + 1'b1;
                        end
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule