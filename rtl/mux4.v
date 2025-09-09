`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/14/2025 11:01:06 AM
// Design Name: 
// Module Name: mux4
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


module mux4(
    input a,
    input b,
    input c,
    input d,
    input [1:0] sel,
    output muxout
    );
    
reg outmux;

always @ *
begin
case(sel)
2'b00 : outmux = a;
2'b01 : outmux = b;
2'b10 : outmux = c;
2'b11 : outmux = d;
endcase
end   

assign  muxout = outmux;

endmodule
