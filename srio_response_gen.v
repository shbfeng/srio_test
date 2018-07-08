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
// File name:    srio_response_gen.v
// Rev:          1.1
// Description:
// This module may be used to run sequences of fixed exercises or may
// be used to send random packet responses. There is a self-checking mode that
// may be used for simulation.
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

module srio_response_gen (
  input             log_clk,
  input             log_rst,

  input      [15:0] deviceid,//0x0015
// input     [15:0] source_id,
// input            id_override,

  output reg        val_tresp_tvalid,
  input             val_tresp_tready,
  output reg        val_tresp_tlast,
  output reg [63:0] val_tresp_tdata,
  output      [7:0] val_tresp_tkeep,
  output reg  [31:0] val_tresp_tuser,

  input             val_treq_tvalid,
  output reg        val_treq_tready,
  input             val_treq_tlast,
  input      [63:0] val_treq_tdata,
  input       [7:0] val_treq_tkeep,
  input      [31:0] val_treq_tuser,
  output reg        receive_ok
 );


	parameter idle0 =12'h001, s1 =12'h002, s2 =12'h004, s3 =12'h008, s4 =12'h010, s5 =12'h020, s6 =12'h040, s7 =12'h080, s8 =12'h100, s9 =12'h200;
(* KEEP="TRUE"*) 	reg[11:0] st_treq;

(* KEEP="TRUE"*) 	reg [15:0] req_src_id;
(* KEEP="TRUE"*)	reg [15:0] req_dest_id;
	reg [63:0] req_header_beat;
	wire [63:0] response_header;
	reg [63:0] req_data1;
	reg [63:0] req_data2;

  // {{{ wire declarations ----------------
  reg  [15:0] log_rst_shift;
  wire        log_rst_q = log_rst_shift[15];


  // incoming packet fields
  wire  [7:0] current_tid;
  wire  [3:0] current_ftype;
  wire  [3:0] current_ttype;
  wire  [7:0] current_size;
  wire  [1:0] current_prio;
  wire [33:0] current_addr;
  wire [15:0] current_srcid;
  wire [15:0] dest_id;
  wire [15:0] src_id;
 
  // }}} End wire declarations ------------


  // {{{ Common-use Signals ---------------

  // Simple Assignments
  assign val_tresp_tkeep  = 8'hFF;
//  assign src_id           = deviceid;
  assign src_id           = 16'h0013;
  // End Simple Assignments

  always @(posedge log_clk or posedge log_rst) begin
    if (log_rst)
      log_rst_shift <= 16'hFFFF;
    else
      log_rst_shift <= {log_rst_shift[14:0], 1'b0};
  end

  // }}} End Common-use Signals -----------

  assign current_tid   = req_header_beat[63:56];
  assign current_ftype = req_header_beat[55:52];
  assign current_ttype = req_header_beat[51:48];
  assign current_size  = req_header_beat[43:36];
  assign current_prio  = req_header_beat[46:45] + 2'b01;
  assign current_addr  = req_header_beat[33:0];
  assign current_srcid = req_header_beat[31:16];
  
  assign response_header = {current_tid,4'hd,4'h8,1'b0,current_prio,45'h0};

  // {{{ Request Logic --------------------
  always @(posedge log_clk) begin
	if (log_rst_q) 
	begin
		val_treq_tready <= 1'b0;
		req_src_id <= 16'h0000;
		req_dest_id <= 16'h0000;
		req_header_beat <= 0;
		req_data1 <= 0;
		req_data2 <= 0;
		receive_ok <= 1'b0;
		val_tresp_tvalid <= 1'b0;
		val_tresp_tuser <= 32'h00000000;
		val_tresp_tdata <= 0;
		val_tresp_tlast <= 1'b0;
		st_treq <= idle0;
	end 
	else
	begin
		case(st_treq)
			idle0 :
				begin
					val_treq_tready <= 1'b1;//指示用户可以接收rapidio包
					if (val_treq_tvalid ==1'b1) //检测有数据包
						begin
							req_src_id <= val_treq_tuser[31:16];
							req_dest_id <= val_treq_tuser[15:0];
							req_header_beat <= val_treq_tdata;
							if (val_treq_tuser[31:16]==16'h0017 && val_treq_tuser[15:0]==16'h0013) begin //包的源设备ID为0x18，目的设备ID为0x15
//							if (val_treq_tuser[31:16]==16'h0013 && val_treq_tuser[15:0]==16'h0013) begin //包的源设备ID为0x18，目的设备ID为0x15            
								if (val_treq_tdata[55:52] ==4'h5 && val_treq_tdata[51:48] ==4'h4) begin //如果包格式为NWRITE
									st_treq <= s1;
								end else if (val_treq_tdata[55:52] ==4'h2 && val_treq_tdata[51:48] ==4'h4 &&val_treq_tlast == 1'b1) begin//如果包格式为NREAD
									st_treq <= s4;
								end else begin
									st_treq <= idle0;
								end
								
							end else begin
								st_treq <= idle0;	
							end
						end
				end
			//NWRITE包接收	
			s1 :
				begin
					req_data1 <= val_treq_tdata;
					st_treq <= s2;
				end 
			s2 :
				begin
					if (val_treq_tlast == 1'b1) begin
						req_data2 <= val_treq_tdata;
						end
						st_treq <= s3;
				end
			s3 :
				begin
					receive_ok <= ~receive_ok;
					st_treq <= idle0;
				end
			//NREAD包接收，并回复response
			s4 :
				begin
					if (val_tresp_tready ==1'b1) begin //ip核指示可以接收包
						st_treq <= s5;
					end else begin
						st_treq <= s4;//wait
					end
				end
			s5 :
				begin
					val_tresp_tvalid <= 1'b1;
					val_tresp_tuser <= {src_id, req_src_id};//源ID+目的ID
					val_tresp_tdata <= response_header;
					val_tresp_tlast <= 1'b0;//不是最后一个数据字
					st_treq <= s6;
				end
			s6 :
				begin
					st_treq <= s7;
				end
			s7 :
				begin
					val_tresp_tvalid <= 1'b1;
					val_tresp_tdata <= 64'h1234567890abcdef;
					val_tresp_tlast <= 1'b0;//不是最后一个数据字
					st_treq <= s8;
				end
			s8 :
				begin
					val_tresp_tvalid <= 1'b1;
					val_tresp_tdata <= 64'h1357926680acebdf;
					val_tresp_tlast <= 1'b1;//是最后一个数据字
					st_treq <= s9;
					receive_ok <= ~receive_ok;
				end	
			s9 :
				begin
					val_tresp_tvalid <= 1'b0;
					val_tresp_tdata <= 64'h0;
					val_tresp_tlast <= 1'b0;
					st_treq <= idle0;
				end
			
			default :
				begin
				st_treq <= idle0;
				end
		endcase
	end
end
				
  // }}} End Request Logic ----------------


  // {{{ Local Data Storage ---------------

  // }}} End Response Logic ---------------


endmodule

