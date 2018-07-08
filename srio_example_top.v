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
// File name:    srio_example_top.v
// Rev:          1.7
// Description:
// This hierarchy level contains modules useful for both simulation
// and hardware validation. This is the highest level that is still
// synthesizable.
//
// Hierarchy:
// SRIO_EXAMPLE_TOP
//   |____> SRIO_DUT
//     |____> SRIO_WRAPPER
//     |____> SRIO_CLK
//     |____> SRIO_RST
//   |____> SRIO_STATISTICS
//   |____> SRIO_REPORT
//   |____> SRIO_REQUEST_GEN
//   |____> SRIO_RESPONSE_GEN
//   |____> SRIO_QUICK_START
//
//-----------------------------------------------------------------------------

`timescale 1ps/1ps

module srio_example_top 
   // {{{ port declarations ----------------
   (
    // Clocks and Resets
    input            sys_clkp,              // MMCM reference clock 125MHz(LVDS)
    input            sys_clkn,              // MMCM reference clock

    input            sys_rst,               // Global reset signal //异步复位输入，输入给srio_rst模块

    // high-speed IO //x4 3.125G
    input           srio_rxn0,              // Serial Receive Data
    input           srio_rxp0,              // Serial Receive Data
    input           srio_rxn1,              // Serial Receive Data
    input           srio_rxp1,              // Serial Receive Data
    input           srio_rxn2,              // Serial Receive Data
    input           srio_rxp2,              // Serial Receive Data
    input           srio_rxn3,              // Serial Receive Data
    input           srio_rxp3,              // Serial Receive Data

    output          srio_txn0,              // Serial Transmit Data
    output          srio_txp0,              // Serial Transmit Data
    output          srio_txn1,              // Serial Transmit Data
    output          srio_txp1,              // Serial Transmit Data
    output          srio_txn2,              // Serial Transmit Data
    output          srio_txp2,              // Serial Transmit Data
    output          srio_txn3,              // Serial Transmit Data
    output          srio_txp3,              // Serial Transmit Data

    output  [7:0]   led0,
    //req
    input           user_clk,
    input           user_rst,
    input   [15:0]  user_cfg_src_id,
    input   [15:0]  user_cfg_dec_id,    
    input   [127:0] srio_wr_data,
    input   [7:0]   srio_byte_tkeep,
    input   [31:0]  srio_wr_addr,
    input           srio_wr_en,

    output  [65:0]  srio_rd_data,
    output          srio_rd_data_valid,
    input   [31:0]  srio_rd_addr,
    input           srio_rd_en,

    output          link_done,
    output          srio_idle,
    //resp
    output  [31:0]  recv_wr_data,
    output  [31:0]  recv_wr_addr,
    output          recv_wr_data_valid,
    input           recv_wr_data_rdy,
    
    input   [63:0]  ack_rd_data,
    output  [31:0]  ack_rd_addr,
    output          ack_rd_en,
    input           ack_rd_data_valid
   );

   // }}} ----------------------------------


  // {{{ wire declarations ----------------
    wire            log_clk; //用户使用log core时钟，频率取决由链接宽度和速度，x4 3.125G =125MHz
    wire            phy_clk; //phy clk
    wire            gt_pcs_clk;
    wire            log_rst; //用户使用log core复位，与log_clk同步
    wire            phy_rst;

    // signals into the DUT
    wire            ireq_tvalid;
    wire            ireq_tready;
    wire            ireq_tlast;
    (*KEEP="TRUE"*) wire   [63:0]   ireq_tdata;
    wire   [7:0]    ireq_tkeep;
    wire   [31:0]   ireq_tuser;

    wire            iresp_tvalid;
    wire            iresp_tready;
    wire            iresp_tlast;
   (*KEEP="TRUE"*) wire    [63:0]  iresp_tdata;
    wire    [7:0]   iresp_tkeep;
    wire    [31:0]  iresp_tuser;

    wire            treq_tvalid;
    wire            treq_tready;
    wire            treq_tlast;
   (*KEEP="TRUE"*) wire    [63:0]  treq_tdata;
    wire    [7:0]   treq_tkeep;
    wire    [31:0]  treq_tuser;

    wire            tresp_tvalid;
    wire            tresp_tready;
    wire            tresp_tlast;
    (*KEEP="TRUE"*)wire   [63:0]   tresp_tdata;
    wire   [7:0]    tresp_tkeep;
    wire   [31:0]   tresp_tuser;

    wire            maintr_rst;

    wire            maintr_awvalid;
    wire            maintr_awready;
    wire   [31:0]   maintr_awaddr;
    wire            maintr_wvalid;
    wire            maintr_wready;
    wire   [31:0]   maintr_wdata;
    wire            maintr_bvalid;
    wire            maintr_bready;
    wire   [1:0]    maintr_bresp;

    wire            maintr_arvalid;
    wire            maintr_arready;
    wire   [31:0]   maintr_araddr;
    wire            maintr_rvalid;
    wire            maintr_rready;
    wire   [31:0]   maintr_rdata;
    wire   [1:0]    maintr_rresp;


    // other core output signals that may be used by the user
    wire     [23:0] port_timeout;           // Timeout value user can use to detect a lost packet
    wire            phy_rcvd_mce;           // MCE control symbol received //no use
    wire            phy_rcvd_link_reset;    // Received 4 consecutive reset symbols //此标志位有效，表示从链路partner接收到复位指令，此时应sys_rst有效复位本地PHY，两个link partner应同时复位
    wire            port_error;             // In Port Error State //no use
    wire            mode_1x;                // Link is trained down to 1x mode //指示链路被训练下降到x1模式
    wire            srio_host;              // Endpoint is the system host //指示ep为系统主设备
    wire    [223:0] phy_debug;              // Useful debug signals
    wire            gtrx_disperr_or;        // GT disparity error (reduce ORed)
    wire            gtrx_notintable_or;     // GT not in table error (reduce ORed)
    wire     [15:0] deviceid;               // Device ID //设置为8bit，0xAB
    wire            port_decode_error;      // No valid output port for the RX transaction
    wire            idle_selected;          // The IDLE sequence has been selected  //no use
    wire            idle2_selected;         // The PHY is operating in IDLE2 mode	//no use
    wire            autocheck_error;        // when set, packet didn't match expected
    wire            port_initialized;       // Port is Initialized //指示port已经被初始化
    wire            link_initialized;       // Link is Initialized //指示srio链路已经被初始化
//  wire            exercise_done;          // sets when the generator(s) has completed
    wire            clk_lock;               // asserts from the MMCM //指示时钟有效
	
	 wire send_ok;
  wire [1:0] debug_line;
	 wire receive_ok;
    // other core input signals that may be used by the user
    wire            phy_mce = 1'b0;         // Send MCE control symbol
    wire            phy_link_reset = 1'b0;  // Send link reset control symbols //此位有效本地EP发出复位请求给link partner until the port_initialized output goes low.
    wire            force_reinit = 1'b0;    // Force reinitialization //强制重新初始化


    // convert to ports when not using the pattern generator
    wire            axis_ireq_tvalid;
    wire            axis_ireq_tready;
    wire            axis_ireq_tlast;
(*KEEP="TRUE"*)    wire   [63:0]   axis_ireq_tdata;
    wire   [7:0]    axis_ireq_tkeep;
    wire   [31:0]   axis_ireq_tuser;

    wire            axis_iresp_tvalid;
    wire            axis_iresp_tready;
    wire            axis_iresp_tlast;
(*KEEP="TRUE"*)    wire    [63:0]  axis_iresp_tdata;
    wire    [7:0]   axis_iresp_tkeep;
    wire    [31:0]  axis_iresp_tuser;

    wire            axis_treq_tvalid;
    wire            axis_treq_tready;
    wire            axis_treq_tlast;
(*KEEP="TRUE"*)    wire    [63:0]  axis_treq_tdata;
    wire    [7:0]   axis_treq_tkeep;
    wire    [31:0]  axis_treq_tuser;

    wire            axis_tresp_tvalid;
    wire            axis_tresp_tready;
    wire            axis_tresp_tlast;
(*KEEP="TRUE"*)    wire   [63:0]   axis_tresp_tdata;
    wire   [7:0]    axis_tresp_tkeep;
    wire   [31:0]   axis_tresp_tuser;

    wire            axis_maintr_rst = 1'b0;
    wire            axis_maintr_awvalid = 1'b0;
    wire            axis_maintr_awready;
    wire   [31:0]   axis_maintr_awaddr = 1'b0;
    wire            axis_maintr_wvalid = 1'b0;
    wire            axis_maintr_wready;
    wire   [31:0]   axis_maintr_wdata = 1'b0;
    wire   [3:0]    axis_maintr_wstrb = 1'b0;
    wire            axis_maintr_bvalid;
    wire            axis_maintr_bready = 1'b0;
    wire   [1:0]    axis_maintr_bresp;

    wire            axis_maintr_arvalid = 1'b0;
    wire            axis_maintr_arready;
    wire   [31:0]   axis_maintr_araddr = 1'b0;
    wire            axis_maintr_rvalid;
    wire            axis_maintr_rready = 1'b0;
    wire   [31:0]   axis_maintr_rdata;
    wire   [1:0]    axis_maintr_rresp;

    // Coregen signals
    wire [169:0]    sync_out;

    reg             continuous_in_process;
    reg             reset_continuous_set;
    reg             stop_continuous_test;
    reg   [15:0]    reset_continuous_srl;
    wire  [31:0]    stats_data;
  // }}} End wire declarations ------------


  // {{{ Drive LEDs to Development Board -------
//    assign led0[0] = port_initialized || link_initialized;	//驱动led1
	 assign led0[0] = send_ok;	//驱动led1
	 assign led0[1] = receive_ok; //驱动led2
    assign led0[2] = !mode_1x;
    assign led0[3] = port_initialized;
    assign led0[4] = link_initialized;
    assign led0[5] = debug_line[0];
  assign led0[6] = debug_line[1];
  assign led0[7] = gtrx_disperr_or & gtrx_notintable_or;
  // }}} End LEDs to Development Board ---------


    assign sync_out = 170'h0;


  // {{{ SRIO_DUT instantation -----------------
  srio_dut srio_dut_inst
     (.sys_clkp                (sys_clkp),
      .sys_clkn                (sys_clkn),
      .log_clk                 (log_clk),
      .phy_clk                 (phy_clk),
      .gt_pcs_clk              (gt_pcs_clk),

      .sys_rst                 (!sys_rst),//复位为高电平有效
      .log_rst                 (log_rst),
      .phy_rst                 (phy_rst),
      .clk_lock                (clk_lock),

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

      .ireq_tvalid             (ireq_tvalid),
      .ireq_tready             (ireq_tready),
      .ireq_tlast              (ireq_tlast),
      .ireq_tdata              (ireq_tdata),
      .ireq_tkeep              (ireq_tkeep),
      .ireq_tuser              (ireq_tuser),

      .iresp_tvalid            (iresp_tvalid),
      .iresp_tready            (iresp_tready),
      .iresp_tlast             (iresp_tlast),
      .iresp_tdata             (iresp_tdata),
      .iresp_tkeep             (iresp_tkeep),
      .iresp_tuser             (iresp_tuser),

      .tresp_tvalid            (tresp_tvalid),
      .tresp_tready            (tresp_tready),
      .tresp_tlast             (tresp_tlast),
      .tresp_tdata             (tresp_tdata),
      .tresp_tkeep             (tresp_tkeep),
      .tresp_tuser             (tresp_tuser),

      .treq_tvalid             (treq_tvalid),
      .treq_tready             (treq_tready),
      .treq_tlast              (treq_tlast),
      .treq_tdata              (treq_tdata),
      .treq_tkeep              (treq_tkeep),
      .treq_tuser              (treq_tuser),

      .maintr_rst              (maintr_rst),

      .maintr_awvalid          (maintr_awvalid),
      .maintr_awready          (maintr_awready),
      .maintr_awaddr           (maintr_awaddr),
      .maintr_wvalid           (maintr_wvalid),
      .maintr_wready           (maintr_wready),
      .maintr_wdata            (maintr_wdata),
      .maintr_bvalid           (maintr_bvalid),
      .maintr_bready           (maintr_bready),
      .maintr_bresp            (maintr_bresp),

      .maintr_arvalid          (maintr_arvalid),
      .maintr_arready          (maintr_arready),
      .maintr_araddr           (maintr_araddr),
      .maintr_rvalid           (maintr_rvalid),
      .maintr_rready           (maintr_rready),
      .maintr_rdata            (maintr_rdata),
      .maintr_rresp            (maintr_rresp),
      // PHY control signals
      .sim_train_en            (1'b0),  //input
      .phy_mce                 (phy_mce), //input
      .phy_link_reset          (phy_link_reset), //input
      .force_reinit            (force_reinit), //input

      .port_initialized        (port_initialized), //output
      .link_initialized        (link_initialized), //output
      .idle_selected           (idle_selected), //output
      .idle2_selected          (idle2_selected), //output
      .phy_rcvd_mce            (phy_rcvd_mce), //output
      .phy_rcvd_link_reset     (phy_rcvd_link_reset), //output
      .port_error              (port_error), //output
      .mode_1x                 (mode_1x), //output
      .port_timeout            (port_timeout),
      .srio_host               (srio_host),
      .phy_debug               (phy_debug),
      .gtrx_disperr_or         (gtrx_disperr_or),
      .gtrx_notintable_or      (gtrx_notintable_or),

      .deviceid                (deviceid), //output[15:0]
      .port_decode_error       (port_decode_error)
     );
  // }}} End of SRIO_DUT instantiation ---------


  // {{{ Initiator-driven side --------------------

  // {{{ IREQ Interface ---------------------------
  // Select between internally-driven sequences or user sequences
  assign ireq_tvalid =  axis_ireq_tvalid;
  assign ireq_tlast  =  axis_ireq_tlast;
  assign ireq_tdata  =  axis_ireq_tdata;
  assign ireq_tkeep  =  axis_ireq_tkeep;
  assign ireq_tuser  =  axis_ireq_tuser;

  assign axis_ireq_tready = ireq_tready;

  // }}} End of IREQ Interface --------------------


  // {{{ Initiator Generator/Checker --------------

  // 驱动ireq发送SRIO包,接收iresp响应包

  srio_request_gen  srio_request_gen_inst (
                                           .log_clk                 (log_clk),
                                           .log_rst                 (log_rst),

                                           .deviceid                (deviceid),
                                           .sourceid                (),
                                           
                                           .val_ireq_tvalid         (axis_ireq_tvalid),//output
                                           .val_ireq_tready         (axis_ireq_tready),//input
                                           .val_ireq_tlast          (axis_ireq_tlast), //output
                                           .val_ireq_tdata          (axis_ireq_tdata), //output[63:0]
                                           .val_ireq_tkeep          (axis_ireq_tkeep), //output[7:0]
                                           .val_ireq_tuser          (axis_ireq_tuser), //output[31:0]

                                           .val_iresp_tvalid        (axis_iresp_tvalid), //input
                                           .val_iresp_tready        (axis_iresp_tready), //output
                                           .val_iresp_tlast         (axis_iresp_tlast),  //input
                                           .val_iresp_tdata         (axis_iresp_tdata),  //input[63:0]
                                           .val_iresp_tkeep         (axis_iresp_tkeep),  //input[7:0]
                                           .val_iresp_tuser         (axis_iresp_tuser),  //input[31:0]

                                           .link_initialized        (link_initialized), //input
                                           
                                           .user_clk                (user_clk),
                                           .user_rst                (user_rst),
                                           .user_cfg_src_id         (user_cfg_src_id),
                                           .user_cfg_dec_id         (user_cfg_dec_id),
                                           .srio_wr_data            (srio_wr_data),
                                           .srio_byte_tkeep         (srio_byte_tkeep),
                                           .srio_wr_addr            (srio_wr_addr),
                                           .srio_wr_en              (srio_wr_en),
                                           
                                           .srio_rd_data            (srio_rd_data),
                                           .srio_rd_data_valid      (srio_rd_data_valid),
                                           .srio_rd_addr            (srio_rd_addr),
                                           .srio_rd_en              (srio_rd_en),

                                           .link_done               (link_done),
                                           .srio_idle               (srio_idle)
                                           );

  // }}} End of Initiator Generator/Checker -------


  // {{{ IRESP Interface --------------------------
  // Select between internally-driven sequences or user sequences

  assign iresp_tready = axis_iresp_tready;

  assign axis_iresp_tvalid = iresp_tvalid;
  assign axis_iresp_tlast  = iresp_tlast;
  assign axis_iresp_tdata  = iresp_tdata;
  assign axis_iresp_tkeep  = iresp_tkeep;
  assign axis_iresp_tuser  = iresp_tuser;

  // }}} End of Initiator-driven side -------------



  // {{{ Target-driven side -----------------------

  // {{{ TRESP Interface --------------------------
  // Select between internally-driven sequences or user sequences
  assign tresp_tvalid = axis_tresp_tvalid;
  assign tresp_tlast  = axis_tresp_tlast;
  assign tresp_tdata  = axis_tresp_tdata;
  assign tresp_tkeep  = axis_tresp_tkeep;
  assign tresp_tuser  = axis_tresp_tuser;

  assign axis_tresp_tready = tresp_tready;

  // }}} End of TRESP Interface -------------------


  // {{{ Target Generator/Checker -----------------

  // If internally-driven sequences are required
  srio_response_gen srio_response_gen_inst (
                                            .log_clk                 (log_clk),
                                            .log_rst                 (log_rst),

                                            .deviceid                (deviceid),
                                            .sourceid                (),
                                            .val_tresp_tvalid        (axis_tresp_tvalid),
                                            .val_tresp_tready        (axis_tresp_tready),
                                            .val_tresp_tlast         (axis_tresp_tlast),
                                            .val_tresp_tdata         (axis_tresp_tdata),
                                            .val_tresp_tkeep         (axis_tresp_tkeep),
                                            .val_tresp_tuser         (axis_tresp_tuser),

                                            .val_treq_tvalid         (axis_treq_tvalid),
                                            .val_treq_tready         (axis_treq_tready),
                                            .val_treq_tlast          (axis_treq_tlast),
                                            .val_treq_tdata          (axis_treq_tdata),
                                            .val_treq_tkeep          (axis_treq_tkeep),
                                            .val_treq_tuser          (axis_treq_tuser),

                                            .user_clk                (user_clk),
                                            .user_rst                (user_rst),
                                            .user_cfg_src_id         (user_cfg_src_id),
                                            .user_cfg_dec_id         (user_cfg_dec_id),
                                            .recv_wr_data            (recv_wr_data),
                                            .recv_wr_addr            (recv_wr_addr),
                                            .recv_wr_data_valid      (recv_wr_data_valid),
                                            .recv_wr_data_rdy        (recv_wr_data_rdy),
                                            
                                            .ack_rd_data             (ack_rd_data),
                                            .ack_rd_data_valid       (ack_rd_data_valid),
                                            .ack_rd_addr             (ack_rd_addr),
                                            .ack_rd_en               (ack_rd_en)
                                            );

  // }}} End of Target Generator/Checker ----------


  // {{{ TREQ Interface ---------------------------
  // Select between internally-driven sequences or user sequences

  assign treq_tready = axis_treq_tready;

  assign axis_treq_tvalid = treq_tvalid;
  assign axis_treq_tlast  = treq_tlast;
  assign axis_treq_tdata  = treq_tdata;
  assign axis_treq_tkeep  = treq_tkeep;
  assign axis_treq_tuser  = treq_tuser;

  // }}} End of TREQ Interface --------------------

  // }}} End of Target-driven side ----------------



  // {{{ Maintenance Interface --------------------

  // Select between internally-driven sequences or user sequences
  assign maintr_rst = axis_maintr_rst;
  
  assign maintr_awvalid = axis_maintr_awvalid;
  assign maintr_awaddr  = axis_maintr_awaddr;
  assign maintr_wvalid  = axis_maintr_wvalid;
  assign maintr_wdata   = axis_maintr_wdata;
  assign maintr_bready  = axis_maintr_bready;

  assign maintr_arvalid = axis_maintr_arvalid;
  assign maintr_araddr  = axis_maintr_araddr;
  assign maintr_rready  = axis_maintr_rready;


  assign axis_maintr_awready = maintr_awready;
  assign axis_maintr_wready =  maintr_wready;
  assign axis_maintr_bvalid =  maintr_bvalid;
  assign axis_maintr_bresp = maintr_bresp;

  assign axis_maintr_arready = maintr_arready;
  assign axis_maintr_rvalid = maintr_rvalid;
  assign axis_maintr_rdata = maintr_rdata;
  assign axis_maintr_rresp = maintr_rresp;
  
  

//不产生维护包请求
	 assign axis_maintr_rst       = 1'b0;
    assign axis_maintr_awvalid   = 1'b0;
    assign axis_maintr_awaddr    = 32'h0;
    assign axis_maintr_wvalid    = 1'b0;
    assign axis_maintr_wdata     = 32'h0;
    assign axis_maintr_bready    = 1'b0;
    assign axis_maintr_arvalid   = 1'b0;
    assign axis_maintr_araddr    = 32'h0;
    assign axis_maintr_rready    = 1'b0;


  // }}} End of Maintenance Interface -------------


endmodule
