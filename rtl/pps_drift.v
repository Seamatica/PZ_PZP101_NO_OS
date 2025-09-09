`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// Create Date: 06/06/2025 04:05:41 PM
// Module Name: pps_timestamp
// Description: 
//   - Free-running cycle counter (clk_counter)
//   - PPS event counter (pps_count), resets clk_counter on each PPS
//   - Captures both counters when preamble_detected is asserted
//////////////////////////////////////////////////////////////////////////////////

module pps_drift #(
    parameter UTC_SECONDS_WIDTH        = 32,
    parameter DRIFT_COUNT_WIDTH        = 16,
    parameter COUNT_LAST_SECOND_WIDTH   = 32,
    parameter NOMINAL_CYCLES_PER_SEC   = 614_400_000
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         pps,

    // Event-captured outputs:
    output reg  [UTC_SECONDS_WIDTH-1:0]       event_utc_seconds,
    output reg  signed [DRIFT_COUNT_WIDTH-1:0] event_drift,
    output reg  ready
);
    reg  [COUNT_LAST_SECOND_WIDTH-1:0] clk_counter;
    reg  [UTC_SECONDS_WIDTH-1:0]       pps_count;
    reg  signed [DRIFT_COUNT_WIDTH-1:0] drift;
    reg drift_valid =0;
    reg [3:0] pps_count_10;

//--------------------------------------------------
// 1. PPS Synchronization with metastability protection
//--------------------------------------------------
    reg pps_meta, pps_sync, pps_sync_d;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pps_meta <= 0;
            pps_sync <= 0;
            pps_sync_d <= 0;
        end else begin
            pps_meta <= pps;               // Stage 1: Initial synchronization
            pps_sync <= pps_meta;          // Stage 2: Stabilized sync
            pps_sync_d <= pps_sync;        // For edge detection
        end
    end
    wire pps_rise = pps_sync & ~pps_sync_d;  // 1-clock strobe
    wire win_done = pps_rise && (pps_count_10 == 4'd9);
    //--------------------------------------------------
    // 2. Free-running counter reset on synchronized PPS
    //--------------------------------------------------
    reg [COUNT_LAST_SECOND_WIDTH-1:0] prev_cycles;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_counter <= 0;
            prev_cycles <= 0;
        end else if (win_done) begin
            prev_cycles <= clk_counter;  // exact cycles in the second
            clk_counter <= 0;
        end else begin
            clk_counter <= clk_counter + 1'b1;
        end
    end
    

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pps_count <= 0;
            pps_count_10 <= 0;
        end else if (pps_rise) begin
            pps_count <= pps_count + 1'b1;
            pps_count_10 <= (pps_count_10 == 4'd9) ? 0 : pps_count_10 + 1'b1;
        end
    end
    

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            drift <= 0;
            drift_valid <= 1'b0;
        end else if (win_done) begin
            drift <= $signed(clk_counter) - $signed(NOMINAL_CYCLES_PER_SEC);
            drift_valid <= 1'b1;
        end
        else drift_valid <= 1'b0;
    end


    always @(posedge clk or posedge rst) begin
        if (rst) begin;
            event_utc_seconds <= 0;
            event_drift <= 0;
            ready <= 1'b0;
        end else if (drift_valid) begin
            // Calculate actual time since last PPS 
            event_utc_seconds <= pps_count;
            event_drift <= drift;
            ready <= 1'b1;
        end
        else ready <= 1'b0;
    end

endmodule


