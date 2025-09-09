module net_udp_loop(
    input              clk_200m,
    input              clk_50m,
    input              sys_rst_n,    // System Reset, active low
    
    input wire [87:0] i_payload,
    input wire         trigger_valid,
    
    // ip address configurations
    input wire [47:0]  board_mac,
    input wire [31:0]  board_ip,
    input wire [47:0]  pc_mac,
    input wire [31:0]  pc_ip,
    input wire [15:0]  board_port,
    input wire [15:0]  pc_port,
    
    
    // RGMII Interface to PHY
    output             eth_mdc,
    inout              eth_mdio,
    input              net_rxc,      // RGMII Receive Clock
    input              net_rx_ctl,   // RGMII Receive Control (Data Valid)
    input       [3:0]  net_rxd,      // RGMII Receive Data
    output             net_txc,      // RGMII Transmit Clock
    output             net_tx_ctl,   // RGMII Transmit Control (Data Valid)
    output      [3:0]  net_txd,      // RGMII Transmit Data
    output             net_rst_n     // PHY Reset, active low
    );

// --- Configuration Parameters ---
parameter  IDELAY_VALUE = 0;


// UDP Packet Settings
parameter  UDP_PAYLOAD_BYTES = 11; // Set the desired number of data bytes per packet

// --- Wires and Registers ---
wire          gmii_rx_clk;      // GMII Receive Clock
wire          gmii_rx_en;       // GMII Receive Data Valid
wire  [7:0]   gmii_rxd;         // GMII Receive Data
wire          gmii_tx_clk;      // GMII Transmit Clock
wire          gmii_tx_en;       // GMII Transmit Data Valid
wire  [7:0]   gmii_txd;         // GMII Transmit Data

// Wires for ARP module
wire          arp_gmii_tx_en;
wire  [7:0]   arp_gmii_txd;
wire          arp_rx_done;
wire          arp_rx_type;
wire  [47:0]  src_mac;
wire  [31:0]  src_ip;
wire          arp_tx_en;
wire          arp_tx_type;
wire  [47:0]  des_mac;
wire  [31:0]  des_ip;
wire          arp_tx_done;

// Wires for UDP module
wire          udp_gmii_tx_en;
wire  [7:0]   udp_gmii_txd;
wire          udp_tx_done;
wire          tx_req;
wire  [31:0]  tx_data;

// --- Transmit Trigger and Data Generation ---
wire          tx_start_en;
//reg  [26:0]   trigger_cnt;


/*
// This logic creates a single pulse on tx_start_en periodically to send a packet.
always @(posedge gmii_tx_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        trigger_cnt <= 0;
        tx_start_en <= 1'b0;
    end
    else begin
        // De-assert trigger after one cycle
        tx_start_en <= 1'b0;

        if (trigger_cnt >= 27'd12_500_000 - 1) begin // Approx every 100ms at 125MHz
            tx_start_en <= 1'b1; // Assert trigger for one clock cycle
            trigger_cnt <= 0;
        end
        else begin
            trigger_cnt <= trigger_cnt + 1;
        end
    end
end
*/

assign tx_start_en = trigger_valid;

// Data payload generator
// 24 bytes => 6 words
localparam integer WORDS = (UDP_PAYLOAD_BYTES + 3) / 4;

//reg  [191:0] payload = 192'h0123_4567_89AB_CDEF_FEDC_BA98_7654_3210_8888_8888_8888_8888;
wire [87:0] payload; 
assign payload = i_payload;
reg  [2:0]   word_idx;
reg  [31:0]  tx_data_r;
assign tx_data = tx_data_r; // to udp/udp_tx

// convenient MSB-first slicing: [base -: width]
wire [31:0] word_msb_first [0:2];
assign word_msb_first[0] = payload[87 -: 32];
assign word_msb_first[1] = payload[55 -: 32];
assign word_msb_first[2] = {payload[23 : 0], 8'h0};
//assign word_msb_first[3] = payload[ 95 -: 32];
//assign word_msb_first[4] = payload[ 63 -: 32];
//assign word_msb_first[5] = payload[ 31 -: 32];

always @(posedge gmii_tx_clk or negedge sys_rst_n) begin
  if (!sys_rst_n) begin
    word_idx  <= 0;
    tx_data_r <= 32'd0;
  end else begin
    if (tx_start_en) word_idx <= 0;           // new packet
    if (tx_req) begin                          // udp_tx asking for NEXT 32b
      tx_data_r <= word_msb_first[word_idx];   // load just-in-time
      word_idx  <= (word_idx == WORDS-1) ? 0 : (word_idx + 1);
    end
  end
end

// Set fixed destination for the ARP module
assign des_mac = pc_mac;
assign des_ip  = pc_ip;


// --- Module Instantiations ---
(* IODELAY_GROUP = "rgmii_delay" *) 
IDELAYCTRL  IDELAYCTRL_inst (
    .RDY(),                      // 1-bit output: Ready output
    .REFCLK(clk_200m),         // 1-bit input: Reference clock input
    .RST(1'b0)                   // 1-bit input: Active high reset input
);
// PHY Reset Generation
net_rstn u_net_rstn(
    .clk       (clk_50m),
    .sysrstn   (sys_rst_n),
    .net_rst_n (net_rst_n)
);

// PHY Configuration (MDC/MDIO)
RTL8211_Config_IP_0 inst_RTL8211_Config_IP_0 (
    .sys_clk   (clk_200m),
    .sys_rstn  (net_rst_n),
    .eth_mdc   (eth_mdc),
    .eth_mdio  (eth_mdio)
);

// GMII to RGMII Interface Converter
gmii_to_rgmii #(
    .IDELAY_VALUE (IDELAY_VALUE)
)
u_gmii_to_rgmii(
    .idelay_clk   (clk_200m),
    .gmii_rx_clk  (gmii_rx_clk),
    .gmii_rx_en   (gmii_rx_en),
    .gmii_rxd     (gmii_rxd),
    .gmii_tx_clk  (gmii_tx_clk),
    .gmii_tx_en   (gmii_tx_en),
    .gmii_txd     (gmii_txd),
    .rgmii_rxc    (net_rxc),
    .rgmii_rx_ctl (net_rx_ctl),
    .rgmii_rxd    (net_rxd),
    .rgmii_txc    (net_txc),
    .rgmii_tx_ctl (net_tx_ctl),
    .rgmii_txd    (net_txd)
);



// ARP Communication Module
arp u_arp(
    .rst_n        (sys_rst_n),
    .gmii_rx_clk  (gmii_rx_clk),
    .gmii_rx_en   (gmii_rx_en),
    .gmii_rxd     (gmii_rxd),
    .gmii_tx_clk  (gmii_tx_clk),
    .gmii_tx_en   (arp_gmii_tx_en),
    .gmii_txd     (arp_gmii_txd),
    .arp_rx_done  (arp_rx_done),
    .arp_rx_type  (arp_rx_type),
    .src_mac      (src_mac),
    .src_ip       (src_ip),
    .arp_tx_en    (arp_tx_en),
    .arp_tx_type  (arp_tx_type),
    .des_mac      (des_mac),
    .des_ip       (des_ip),
    .tx_done      (arp_tx_done),
    
    .board_mac    (board_mac),
    .board_ip     (board_ip)
);

// UDP Communication Module
udp u_udp(
    .rst_n        (sys_rst_n),
    .gmii_rx_clk  (gmii_rx_clk),
    .gmii_rx_en   (gmii_rx_en),
    .gmii_rxd     (gmii_rxd),
    .gmii_tx_clk  (gmii_tx_clk),
    .gmii_tx_en   (udp_gmii_tx_en),
    .gmii_txd     (udp_gmii_txd),

    // Tie off unused UDP receive ports
    .rec_pkt_done (),
    .rec_en       (),
    .rec_data     (),
    .rec_byte_num (),

    // Connect UDP transmit ports
    .tx_start_en  (tx_start_en),
    .tx_data      (tx_data),
    .tx_byte_num  (UDP_PAYLOAD_BYTES), // Use the fixed parameter for length
    .tx_done      (udp_tx_done),
    .tx_req       (tx_req),
    
    .board_mac    (board_mac),
    .board_ip     (board_ip),
    .des_mac      (pc_mac),
    .des_ip       (pc_ip),
    .board_port   (board_port),
    .des_port     (pc_port)
);

// Ethernet Transmit Controller/Multiplexer
net_ctrl u_net_ctrl(
    .clk            (gmii_tx_clk),
    .rst_n          (sys_rst_n),
    .arp_rx_done    (arp_rx_done),
    .arp_rx_type    (arp_rx_type),
    .arp_tx_en      (arp_tx_en),
    .arp_tx_type    (arp_tx_type),
    .arp_tx_done    (arp_tx_done),
    .arp_gmii_tx_en (arp_gmii_tx_en),
    .arp_gmii_txd   (arp_gmii_txd),
    .udp_gmii_tx_en (udp_gmii_tx_en),
    .udp_gmii_txd   (udp_gmii_txd),
    .gmii_tx_en     (gmii_tx_en),
    .gmii_txd       (gmii_txd)
);

endmodule