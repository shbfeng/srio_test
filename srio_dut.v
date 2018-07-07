//-----------------------------------------------------------------------------
//
// (c) Copyright 2010 - 2013 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//     
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.

//-----------------------------------------------------------------------------
//
// File name:    srio_dut.v
// Rev:          1.7
// Description:
// This hierarchy level encapsulates all of the components required to
// use Xilinx's complete sRIO solution. This level includes the core and
// clock manager
//
// Hierarchy:
// SRIO_DUT
//   |____> SRIO_WRAPPER
//   |____> SRIO_CLK
//   |____> SRIO_RST
//
//-----------------------------------------------------------------------------

`timescale 1ps/1ps

module srio_dut
   // {{{ port declarations ----------------
   (
    // Clocks and Resets
    input             sys_clkp,                // System reference clock
    input             sys_clkn,                // MMCM reference clock
    output            log_clk,                 // LOG interface clock
    output            phy_clk,                 // PHY interface clock
    output            gt_pcs_clk,              // GT fabric interface clock
    output            clk_lock,

    input             sys_rst,                 // Global reset signal
    output            log_rst,                 // Reset for LOG clock Domain
    output            phy_rst,                 // Reset for PHY clock Domain
    input             maintr_rst,              // Reset for maintr interface, on LOG clk domain

    // high-speed IO
    input             srio_rxn0,               // Serial Receive Data
    input             srio_rxp0,               // Serial Receive Data
    input             srio_rxn1,               // Serial Receive Data
    input             srio_rxp1,               // Serial Receive Data
    input             srio_rxn2,               // Serial Receive Data
    input             srio_rxp2,               // Serial Receive Data
    input             srio_rxn3,               // Serial Receive Data
    input             srio_rxp3,               // Serial Receive Data

    output            srio_txn0,               // Serial Transmit Data
    output            srio_txp0,               // Serial Transmit Data
    output            srio_txn1,               // Serial Transmit Data
    output            srio_txp1,               // Serial Transmit Data
    output            srio_txn2,               // Serial Transmit Data
    output            srio_txp2,               // Serial Transmit Data
    output            srio_txn3,               // Serial Transmit Data
    output            srio_txp3,               // Serial Transmit Data

    // I/O Port
    input             ireq_tvalid,             // Indicates Valid Input on the Request Channel
    output            ireq_tready,             // Beat has been accepted
    input             ireq_tlast,              // Indicates last beat
    input  [63:0]     ireq_tdata,              // Req Data Bus
    input  [7:0]      ireq_tkeep,              // Req Keep Bus
    input  [31:0]     ireq_tuser,              // Req User Bus

    output            iresp_tvalid,            // Indicates Valid Output on the Response Channel
    input             iresp_tready,            // Beat has been accepted
    output            iresp_tlast,             // Indicates last beat
    output  [63:0]    iresp_tdata,             // Resp Data Bus
    output  [7:0]     iresp_tkeep,             // Resp Keep Bus
    output  [31:0]    iresp_tuser,             // Resp User Bus

    output            treq_tvalid,             // Indicates Valid Output on the Response Channel
    input             treq_tready,             // Beat has been accepted
    output            treq_tlast,              // Indicates last beat
    output  [63:0]    treq_tdata,              // Resp Data Bus
    output  [7:0]     treq_tkeep,              // Resp Keep Bus
    output  [31:0]    treq_tuser,              // Resp User Bus

    input             tresp_tvalid,            // Indicates Valid Input on the Request Channel
    output            tresp_tready,            // Beat has been accepted
    input             tresp_tlast,             // Indicates last beat
    input  [63:0]     tresp_tdata,             // Req Data Bus
    input  [7:0]      tresp_tkeep,             // Req Keep Bus
    input  [31:0]     tresp_tuser,             // Req User Bus

    // Maintenance Port
    input             maintr_awvalid,          // Write Command Valid
    output            maintr_awready,          // Write Port Ready
    input  [31:0]     maintr_awaddr,           // Write Address
    input             maintr_wvalid,           // Write Data Valid
    output            maintr_wready,           // Write Port Ready
    input  [31:0]     maintr_wdata,            // Write Data
    output            maintr_bvalid,           // Write Response Valid
    input             maintr_bready,           // Write Response Fabric Ready
    output [1:0]      maintr_bresp,            // Write Response

    input             maintr_arvalid,          // Read Command Valid
    output            maintr_arready,          // Read Port Ready
    input  [31:0]     maintr_araddr,           // Read Address
    output            maintr_rvalid,           // Read Response Valid
    input             maintr_rready,           // Read Response Fabric Ready
    output [31:0]     maintr_rdata,            // Read Data
    output [1:0]      maintr_rresp,            // Read Response


    // PHY control signals
    input             sim_train_en,            // Reduce timers for inialization for simulation
    input             phy_mce,                 // Send MCE control symbol
    input             phy_link_reset,          // Send link reset control symbols
    input             force_reinit,            // Force reinitialization


    // PHY Informational signals
    output            port_initialized,        // Port is intialized
    output            link_initialized,        // Ready to transmit data
    output            idle_selected,           // The IDLE sequence has been selected
    output            idle2_selected,          // The PHY is operating in IDLE2 mode
    output            phy_rcvd_mce,            // MCE control symbol received
    output            phy_rcvd_link_reset,     // Received 4 consecutive reset symbols
    output            port_error,              // In Port Error State
    output            mode_1x,                 // Link is trained down to 1x mode
    output [23:0]     port_timeout,            // Timeout occurred
    output            srio_host,               // Endpoint is the system host
    output [223:0]    phy_debug,               // Useful debug signals
    output            gtrx_disperr_or,         // GT disparity error (reduce ORed)
    output            gtrx_notintable_or,      // GT not in table error (reduce ORed)
    output [15:0]     deviceid,                // Device ID
    output            port_decode_error        // No valid output port for the RX transaction
   );
   // }}} ----------------------------------


  // {{{ local parameters -----------------

  // }}} End local parameters -------------


  // {{{ wire declarations ----------------

  // MMCM signals
  wire              gt_clk;                  // GT fabric interface clock
  wire              refclk;                  // GT reference clock
  wire              drpclk;                  // GT Dynamic Reconfiguration Port clock
  wire              buf_rst;                 // Reset for the BUF clock domain
  wire              gt_pcs_rst;              // Reset for the GT Fabric clock domain

  wire              controlled_force_reinit; // Force reinitialization

  // }}} End wire declarations ------------


  // {{{ SRIO_WRAPPER instantation ----------------
  SRIOx4_LC srio_wrapper_inst
     (
      .log_clk_in                 (log_clk),
      .phy_clk_in                 (phy_clk),
      .gt_clk_in                  (gt_clk),
      .gt_pcs_clk_in              (gt_pcs_clk),
      .refclk_in                  (refclk),
      .drpclk_in                  (drpclk),
      .cfg_rst_in                 (cfg_rst),
      .log_rst_in                 (log_rst),
      .buf_rst_in                 (buf_rst),
      .phy_rst_in                 (phy_rst),
      .gt_pcs_rst_in              (gt_pcs_rst),
      .s_axi_maintr_rst           (maintr_rst),

      .clk_lock_in                (clk_lock),
//      .gt0_qpll_clk_in (gt0_qpll_clk_in),
//      .gt0_qpll_out_refclk_in(gt0_qpll_out_refclk_in),
      .srio_rxn0               (srio_rxn0),
      .srio_rxp0               (srio_rxp0),
      .srio_rxn1               (srio_rxn1),
      .srio_rxp1               (srio_rxp1),
      .srio_rxn2               (srio_rxn2),
      .srio_rxp2               (srio_rxp2),
      .srio_rxn3               (srio_rxn3),
      .srio_rxp3               (srio_rxp3),

      .srio_txn0               (srio_txn0),
      .srio_txp0               (srio_txp0),
      .srio_txn1               (srio_txn1),
      .srio_txp1               (srio_txp1),
      .srio_txn2               (srio_txn2),
      .srio_txp2               (srio_txp2),
      .srio_txn3               (srio_txn3),
      .srio_txp3               (srio_txp3),
      
      .s_axis_ireq_tvalid             (ireq_tvalid),
      .s_axis_ireq_tready             (ireq_tready),
      .s_axis_ireq_tlast              (ireq_tlast),
      .s_axis_ireq_tdata              (ireq_tdata),
      .s_axis_ireq_tkeep              (ireq_tkeep),
      .s_axis_ireq_tuser              (ireq_tuser),

      .m_axis_iresp_tvalid            (iresp_tvalid),
      .m_axis_iresp_tready            (iresp_tready),
      .m_axis_iresp_tlast             (iresp_tlast),
      .m_axis_iresp_tdata             (iresp_tdata),
      .m_axis_iresp_tkeep             (iresp_tkeep),
      .m_axis_iresp_tuser             (iresp_tuser),

      .s_axis_tresp_tvalid            (tresp_tvalid),
      .s_axis_tresp_tready            (tresp_tready),
      .s_axis_tresp_tlast             (tresp_tlast),
      .s_axis_tresp_tdata             (tresp_tdata),
      .s_axis_tresp_tkeep             (tresp_tkeep),
      .s_axis_tresp_tuser             (tresp_tuser),

      .m_axis_treq_tvalid             (treq_tvalid),
      .m_axis_treq_tready             (treq_tready),
      .m_axis_treq_tlast              (treq_tlast),
      .m_axis_treq_tdata              (treq_tdata),
      .m_axis_treq_tkeep              (treq_tkeep),
      .m_axis_treq_tuser              (treq_tuser),

      .s_axi_maintr_awvalid          (maintr_awvalid),
      .s_axi_maintr_awready          (maintr_awready),
      .s_axi_maintr_awaddr           (maintr_awaddr),
      .s_axi_maintr_wvalid           (maintr_wvalid),
      .s_axi_maintr_wready           (maintr_wready),
      .s_axi_maintr_wdata            (maintr_wdata),
      .s_axi_maintr_bvalid           (maintr_bvalid),
      .s_axi_maintr_bready           (maintr_bready),
      .s_axi_maintr_bresp            (maintr_bresp),

      .s_axi_maintr_arvalid          (maintr_arvalid),
      .s_axi_maintr_arready          (maintr_arready),
      .s_axi_maintr_araddr           (maintr_araddr),
      .s_axi_maintr_rvalid           (maintr_rvalid),
      .s_axi_maintr_rready           (maintr_rready),
      .s_axi_maintr_rdata            (maintr_rdata),
      .s_axi_maintr_rresp            (maintr_rresp),

      .sim_train_en            (sim_train_en),
      .phy_mce                 (phy_mce),
      .phy_link_reset          (phy_link_reset),
      .force_reinit            (controlled_force_reinit),

      .port_initialized        (port_initialized),
      .link_initialized        (link_initialized),
      .idle_selected           (idle_selected),
      .idle2_selected          (idle2_selected),
      .phy_rcvd_mce            (phy_rcvd_mce),
      .phy_rcvd_link_reset     (phy_rcvd_link_reset),
      .port_error              (port_error),
      .mode_1x                 (mode_1x),
      .port_timeout            (port_timeout),
      .srio_host               (srio_host),
      .phy_debug               (phy_debug),
      .gtrx_disperr_or         (gtrx_disperr_or),
      .gtrx_notintable_or      (gtrx_notintable_or),

      .deviceid                (deviceid),
      .port_decode_error       (port_decode_error)
     );
  // }}} End of SRIO_WRAPPER instantiation --------


  // {{{ SRIO_CLK Instantiaton --------------------
   srio_clk srio_clk_inst (
      .sys_clkp                (sys_clkp),
      .sys_clkn                (sys_clkn),
      .refclk                  (refclk),
      .drpclk                  (drpclk),
      .log_clk                 (log_clk),
      .phy_clk                 (phy_clk),
      .gt_clk                  (gt_clk),
      .gt_pcs_clk              (gt_pcs_clk),
      .sys_rst                 (sys_rst),
      .mode_1x                 (mode_1x),
      .clk_lock                (clk_lock)
     );
  // }}} End of SRIO_CLK instantiation ------------


  // {{{ SRIO_RST Instantiaton --------------------
   srio_rst srio_rst_inst (
      .cfg_clk                 (log_clk),
      .log_clk                 (log_clk),
      .phy_clk                 (phy_clk),
      .gt_pcs_clk              (gt_pcs_clk),

      .sys_rst                 (sys_rst),
      .port_initialized        (port_initialized),
      .phy_rcvd_link_reset     (phy_rcvd_link_reset),
      .force_reinit            (force_reinit),
      .clk_lock                (clk_lock),

      .controlled_force_reinit (controlled_force_reinit),

      .cfg_rst                 (cfg_rst),
      .log_rst                 (log_rst),
      .buf_rst                 (buf_rst),
      .phy_rst                 (phy_rst),
      .gt_pcs_rst              (gt_pcs_rst)
     );
  // }}} End of SRIO_RST instantiation ------------

endmodule
