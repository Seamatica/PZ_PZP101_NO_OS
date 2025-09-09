`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/03/2025 04:07:09 PM (modified 06/05/2025)
// Module Name: pulse_to_hex (adsb_decoder updated)
// 
// Description:
//   • After detecting the preamble, waits 3.5 µs (fixed) and then begins
//     decoding 112 ADS-B bits at 1 µs intervals (61.44 cycles on average).
//   • Uses a Q8 accumulator so that each window length alternates between 61
//     and 62 cycles, eliminating drift.
//   • Samples at 0.25 µs and 0.75 µs within each window (with ±3-cycle tolerance).
//////////////////////////////////////////////////////////////////////////////////

module pulse_to_hex (
    input  wire        clk,               // 61.44 MHz (?16.276 ns period)
    input  wire        rst,               // synchronous active-high reset
    input  wire        adsb_signal,       // raw (smoothed) ADS-B pulse level
    input  wire        preamble_detected, // 1-clk strobe when preamble end is detected

    output wire [111:0] message_bits,     // MSB-first decoded bits
    output reg        message_valid     // 1-clk strobe when 112 bits are valid
);

    //-------------------------------------------------------------------------
    // Timing Parameters (in cycles @61.44 MHz), rounded to integer where needed
    //-------------------------------------------------------------------------
    localparam integer BIT_CNT     = 112;    // number of ADS-B bits
    localparam integer FULL_US_Q8  = 16'd15728; // Q8 = 61.44 × 256 = 15728
    localparam integer INIT_Q8     = 16'd55050; // Q8 = 3.5 × 61.44 × 256 ? 55040

    // For sampling inside each 1 µs window (61.44 ± tolerance)
    localparam integer FIRST_Q_CYC  = 8'd46;     // 0.25 µs ? 15.36 ? round to 15
    localparam integer THIRD_Q_CYC  = 8'd15;     // 0.75 µs ? 46.08 ? round to 46
    localparam integer TOL         = 8'd2;      // ±3-cycle tolerance (~50 ns)
        localparam [1:0]
        IDLE   = 2'd0,
        PWAIT  = 2'd1,   // "Preamble WAIT" (the 3.5 µs gap)
        DECODE = 2'd2;   // decode 1 µs windows

    reg [1:0]  state;

    //-------------------------------------------------------------------------
    // Bit-window generator state
    //-------------------------------------------------------------------------
    reg [15:0] acc_q8;        // Q8 accumulator: upper 8 bits = integer cycle count, lower 8 bits = fraction
    reg  [8:0] downcnt;       // countdown for the current bit window (61 or 62 cycles)
    reg  [6:0] bit_idx;       // which bit [0..111] we're currently decoding

    //-------------------------------------------------------------------------
    // Sampling flags and shift register
    //-------------------------------------------------------------------------
    reg        first_q_high;  // flagged if adsb_signal was high at first ± tol
    reg        third_q_high;  // flagged if adsb_signal was high at third ± tol
    reg [111:0] bits_reg;     // shift register for decoded bits (MSB-first)
    reg         message_valid_reg;
    reg [111:0] message_bits_reg;     // shift register for decoded bits (MSB-first)

    //-------------------------------------------------------------------------
    // Drive outputs
    //-------------------------------------------------------------------------
    assign message_bits = message_bits_reg;

    //-------------------------------------------------------------------------
    // Rising-edge detect for adsb_signal (needed to capture fast pulses)
    //-------------------------------------------------------------------------
    reg prev_sig;
    reg [15:0] next_acc;
    always @(posedge clk) prev_sig <= adsb_signal;
    wire rise_sig = adsb_signal & ~prev_sig;

    //-------------------------------------------------------------------------
    // Main FSM & bit-window logic
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            // Reset everything
            state            <= IDLE;
            acc_q8            <= 16'd0;
            downcnt           <= 8'd0;
            bit_idx           <= 7'd0;
            first_q_high      <= 1'b0;
            third_q_high      <= 1'b0;
            bits_reg          <= {112{1'b0}};
            message_bits_reg  <= {112{1'b0}};
            message_valid_reg <= 1'b0;
        end else begin
            // Clear strobe by default
            message_valid_reg <= 1'b0;
            case (state)
                // -------------------------------------------------------------
                // IDLE: wait for the last preamble edge
                // -------------------------------------------------------------
                IDLE: begin
                    if (preamble_detected) begin
                        // Start the 3.5 µs waiting period
                        acc_q8        <= INIT_Q8;          // Q8=3.5 µs
                        downcnt      <= INIT_Q8[15:8]-2;    // = ~215
                        bit_idx       <= 7'd0;
                        first_q_high  <= 1'b0;
                        third_q_high  <= 1'b0;
                        bits_reg      <= {112{1'b0}};
                        state         <= PWAIT;
                    end
                    message_valid <= message_valid_reg;
                    if (message_valid_reg) begin                            // All 112 bits done ? strobe valid & return to IDLE
                        message_bits_reg  <= bits_reg;  // latch the final message
                    end
                end
                // -------------------------------------------------------------
                // PWAIT: count down the 3.5 µs gap
                // No abort check here-just wait for downcnt?0, then switch to DECODE
                // -------------------------------------------------------------
                PWAIT: begin
                    if (downcnt != 0) begin
                        downcnt <= downcnt - 1;
                    end else begin
                        // 3.5 µs elapsed; now start the first 1 µs data window
                        //  1) Subtract integer part of INIT_Q8, add FULL_US_Q8:
                        acc_q8 <= (acc_q8 - {acc_q8[15:8], 8'd0}) + FULL_US_Q8;
                    

                        next_acc = (acc_q8 - { acc_q8[15:8], 8'd0 }) + FULL_US_Q8;
                        
                        // 2) Update acc_q8 for the next cycle
                        acc_q8 <= next_acc;
                        
                        // 3) Extract the integer part (upper 8 bits) for downcnt
                        downcnt <= next_acc[15:8]-1;
                        state    <= DECODE;
                        first_q_high <= 1'b0;
                        third_q_high <= 1'b0;
                    end
                end
                // -------------------------------------------------------------
                // DECODE: perform one 1 µs window each time downcnt?0, then decode/check
                // -------------------------------------------------------------
                DECODE: begin
                    if (downcnt != 0) begin
                        downcnt <= downcnt - 1;

                        // Sample at first-quarter (0.25 µs) ± tolerance
                        if ((downcnt <= FIRST_Q_CYC + TOL) &&
                            (downcnt >= FIRST_Q_CYC - TOL)) begin
                            first_q_high <= adsb_signal;
                        end

                        // Sample at third-quarter (0.75 µs) ± tolerance
                        if ((downcnt <= THIRD_Q_CYC + TOL) &&
                            (downcnt >= THIRD_Q_CYC - TOL)) begin
                            third_q_high <= adsb_signal;
                        end

                    end else begin
                        // downcnt has reached zero ? 1 µs window done

                        // If neither first_q_high nor third_q_high ever pulsed, ABORT:
                        if (!first_q_high && !third_q_high) begin
                            // No valid pulse in this 1 µs ? reset decoder
                            state            <= IDLE;
                        end else begin
                            // At least one sample detected a pulse ? shift in the bit
                            if (first_q_high)
                                bits_reg <= { bits_reg[110:0], 1'b1 };
                            else if (third_q_high) begin
                                bits_reg <= { bits_reg[110:0], 1'b0 };
                            end

                            if (bit_idx == (BIT_CNT - 1)) begin
                                message_valid_reg <= 1'b1;
                                state             <= IDLE;
                            end else begin
                                // Proceed to next window:
                                bit_idx <= bit_idx + 1;

                                // Subtract the integer part from the accumulator, leaving only the fractional:
                                acc_q8 <= (acc_q8 - {acc_q8[15:8], 8'd0}) + FULL_US_Q8;
                            
        
                                next_acc = (acc_q8 - { acc_q8[15:8], 8'd0 }) + FULL_US_Q8;
                                
                                // 2) Update acc_q8 for the next cycle
                                acc_q8 <= next_acc;
                                
                                // 3) Extract the integer part (upper 8 bits) for downcnt
                                downcnt <= next_acc[15:8]-1;

                                // Clear sample flags
                                first_q_high <= 1'b0;
                                third_q_high <= 1'b0;
                            end
                        end
                    end
                end
            endcase
        end
    end
endmodule
