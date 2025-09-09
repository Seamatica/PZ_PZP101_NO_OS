`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/09/2025 04:33:23 PM
// Design Name: 
// Module Name: mode_ac_edge_detector
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


module mode_ac_edge_detector #(
        parameter WIDTH                = 32,
        parameter RUN_NEEDED           = 6,
        parameter HOLD_TIME            = 20,
        parameter FINAL_TIME           = 15

    )(
        input  wire                 clk,
        input  wire                 rst,        
        input  wire [WIDTH-1:0]     init_threshold,
        input  wire                 data_valid,
        input  wire                 rearm_threshold,
        input  wire [WIDTH-1:0]     data_in,
        output reg                  rise_edge_out,
        output reg                  fall_edge_out
    );
         // State encoding
    localparam IDLE     = 3'd0,
               COUNTING = 3'd1,
               HOLD     = 3'd2,
               FALL     = 3'd3,
               END      = 3'd4;
               
    localparam RCW = $clog2(RUN_NEEDED+1);
    localparam HCW = $clog2(HOLD_TIME+1);
    localparam CCW = $clog2(FINAL_TIME+1);
    // Registers
    reg [2:0]           state;
    reg [RCW-1:0]       rise_count;
    reg [HCW-1:0]       hold_count;
    reg [WIDTH-1:0]     prev_val;
    reg [WIDTH-1:0]     threshold_reg;
    reg [WIDTH-1:0]     fall_threshold;
    always @(posedge clk) begin
        if (rst || rearm_threshold) begin
            // reset everything
            state           <= IDLE;
            rise_count           <= 0;
            threshold_reg  <= init_threshold;
            hold_count        <= 0;
            prev_val        <= 0;
            fall_threshold  <= 0;
        end else begin
            if (data_valid) begin
                rise_edge_out      <= 1'b0;
                fall_edge_out <= 1'b0;
                case (state)
                  IDLE: begin
                    rise_count <=0;
                    threshold_reg  <= init_threshold;
                    if (data_in >= threshold_reg && data_in > prev_val) begin
                        state <= COUNTING;
                        rise_count <= 1;
                    end
                  end
                  COUNTING: begin
                    if (data_in > prev_val) begin
                        if (rise_count == RUN_NEEDED-1) begin
                            fall_threshold <= data_in;
                            rise_edge_out     <= 1'b1;
                            state          <= HOLD;
                            hold_count       <= HOLD_TIME;
                            rise_count          <= 0;
                        end else begin
                            rise_count <= rise_count + 1;
                        end
                    end else begin
                        // run broken
                        state <= IDLE;
                        rise_count <= 0;
                    end
                  end

                  HOLD: begin
                    if (hold_count == 0) begin
                        state <= FALL;
                    end else begin
                        hold_count <= hold_count - 1;
                    end
                  end
                  FALL: begin
                    if (data_in <= fall_threshold) begin
                        fall_edge_out     <= 1'b1;
                        state         <= END;
                        hold_count      <= FINAL_TIME;
                    end
                  end
                  END: begin
                    if (hold_count == 0) begin
                        state <= IDLE;
                    end else begin
                        hold_count <= hold_count - 1;
                    end
                  end

                  default: begin
                    state <= IDLE;
                  end
                endcase
                prev_val <= data_in;
            end
        end
    end
endmodule
