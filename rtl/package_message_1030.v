`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: message_mux
// Description: Collects and formats Mode C and ADS-B messages with PPS timestamps
//              into a unified 160-bit packed message.
//////////////////////////////////////////////////////////////////////////////////

module package_message_1030 (
    input  wire         clk,
    input  wire         rst,

    // Mode C Inputs
    input  wire         valid_mode_ac,
    input  wire [23:0]  mode_ac_message,
    input  wire [25:0]  mode_ac_clk_ts,
    input  wire [5:0]   mode_ac_utc_ts,
    input  wire signed [12:0] mode_ac_drift,
    
    input  wire         valid_drift,
    input  wire [31:0]  pps_count,
    input  wire signed [15:0] drift_message,

    // Unified Output
    output reg          valid_out,
    output reg [87:0]  packed_message
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            packed_message <= 160'b0;
            valid_out      <= 1'b0;
        end else begin
            valid_out <= 1'b0;  // default

            if (valid_mode_ac) begin
                packed_message <= {
                    16'h0001,
                    mode_ac_utc_ts,               // [159:154]   (6 bits)
                    mode_ac_clk_ts,               // [153:128]   (26 bits)
                    mode_ac_drift,                // [127:115]   (13 bits)
                    3'b011,
                    mode_ac_message
                };
                valid_out <= 1'b1;
            end else if (valid_drift) begin
                packed_message <= {
                    21'h1FABAD,
                    16'h0001, // device id 
                    pps_count,              
                    3'b100,
                    drift_message 
                };
                valid_out <= 1'b1;
            end 
        end
    end

endmodule
