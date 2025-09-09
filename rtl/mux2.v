`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/14/2025 11:16:14 AM
// Design Name: 
// Module Name: mux2
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


module mux2(
    input a,
    input b,
    input sel,
    output muxout
    );
    
reg outmux;

always @ *
begin
case(sel)
1'b0 : outmux = a;
1'b1 : outmux = b;
endcase
end   

assign  muxout = outmux;    
    
endmodule
