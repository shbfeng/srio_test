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
// File name:    srio_request_gen.v
// Rev:          1.1
// Description:
// This module may be used to run sequences of fixed exercises or may
// be used to send random packets. There is a self-checking mode that
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

module srio_request_gen

  (
   input             log_clk,
   input             log_rst,

   input [15:0]      deviceid, //�豸ID����IP core���ֵ
   //  input      [15:0] dest_id,
   //  input      [15:0] source_id,

   output reg        val_ireq_tvalid,
   input             val_ireq_tready,
   output reg        val_ireq_tlast,
   output reg [63:0] val_ireq_tdata,
   output [7:0]      val_ireq_tkeep,
   output reg [31:0] val_ireq_tuser,

   input             val_iresp_tvalid,
   output reg        val_iresp_tready,
   input             val_iresp_tlast,
   input [63:0]      val_iresp_tdata,
   input [7:0]       val_iresp_tkeep,
   input [31:0]      val_iresp_tuser,

   input             link_initialized,
	 output reg        send_ok,
   output reg [1:0]  debug_line

   );


  
   reg  [15:0] log_rst_shift;
   wire        log_rst_q = log_rst_shift[15];

   reg  [12:0] link_initialized_cnt;
   wire        link_initialized_delay = link_initialized_cnt[12];

	//ireq������
	wire ireq_send_enable;
	
	parameter idle =12'h001, st1 =12'h002, st2 =12'h004, st3 =12'h008, st4 =12'h010, st5 =12'h020, st6 =12'h040, st7 =12'h080, st8 =12'h100, st9 =12'h200,st10 =12'h400,st11 =12'h800;
  (*KEEP="TRUE"*)	reg[11:0] st_ireq;

 
  wire [15:0] user_dest_id;
  wire [33:0] user_addr;//34bit����ַ
//  wire  [3:0] user_ftype;//4bit��FTYPE
//  wire  [3:0] user_ttype;//4bit��TTYPE
  (*KEEP="TRUE"*)  reg   [3:0] user_ftype;//4bit��FTYPE
  (*KEEP="TRUE"*)  reg   [3:0] user_ttype;//4bit��TTYPE

  (*KEEP="TRUE"*)  reg   [7:0]  link_display_cnt;
  (*KEEP="TRUE"*)  reg   [31:0] link_display_dly;
  (*KEEP="TRUE"*)  reg          sys_start_en;
  //   
  wire  [7:0] user_size;//8bit��SIZE
  wire  [63:0] user_data;//64bit��DATA

  wire [15:0] dest_id;
  wire [15:0] src_id;
  wire  [1:0] prio;
  wire  [7:0] tid;
  wire [35:0] srio_addr;
  wire [63:0] header_beat;

  wire  [3:0] current_ftype;
  wire  [3:0] current_ttype;
  wire  [7:0] current_size;


  // iresp ��Ӧ����
  (*KEEP="TRUE"*)  reg [15:0] resp_src_id;
  (*KEEP="TRUE"*)  reg [15:0] resp_dest_id;
  (*KEEP="TRUE"*)  reg [63:0] resp_header_beat;
  (*KEEP="TRUE"*)  reg [63:0] resp_data1;
  (*KEEP="TRUE"*)  reg [63:0] resp_data2;
  
  reg [31:0] delay_cnt;

  // }}} End wire declarations ------------

	assign ireq_send_enable = 1'b1;

	assign user_dest_id = 16'h0017; //����Ŀ������ID
//	assign user_dest_id = 16'h0013; //data loop
//NWRITE������	
//	assign user_ftype = 4'b0101;//ftype=5
//	assign user_ttype = 4'b0100;//ttype=4,NWRITE
//NREAD������	
//	assign user_ftype = 4'b0010;//ftype=2
//	assign user_ttype = 4'b0100;//ttype=4,NREAD
  
	assign user_size = 8'h0f;//���ݸ����ֽ�8�ı��������256��д��ֵΪsize-1������16�ֽ����ݣ�Ӧд��ֵ15
	//assign user_addr = {2'b00,32'h00900100};//���е�ַ���ߵĵ�3bit����Ϊ0��Ҳ���ǵ�ַ����8�ı���
	assign user_addr = {2'b00,32'h10802400};//���е�ַ���ߵĵ�3bit����Ϊ0��Ҳ���ǵ�ַ����8�ı���
	//////////////////////////////0c00_0000
  // Simple Assignments
  assign val_ireq_tkeep  = 8'hFF;
  assign src_id          = 16'h0013;//�豸ID��ΪԴ����ID
//  assign src_id          = user_dest_id;//�豸ID��ΪԴ����ID
  assign dest_id			 = user_dest_id;
  assign prio            = 2'h1;
  assign tid             = 8'h00; //Դ����ID
  assign srio_addr       = {2'b00 ,user_addr} ;
  assign current_ftype   = user_ftype ;
  assign current_ttype   = user_ttype ;
  //���������ֽ����������256�ֽڣ�sizeֵ������Ϊ7, 15, 31, 63, 95 (reads only), 127, 159 (reads only), 191 (reads only),223 (reads only), and 255.
  assign current_size    = user_size ; 
  assign header_beat     = {tid, current_ftype, current_ttype, 1'b0, prio, 1'b0, current_size, srio_addr};
  // End Simple Assignments

//��λ��ʱ65536ʱ������
  always @(posedge log_clk or posedge log_rst) begin
    if (log_rst)
      log_rst_shift <= 16'hFFFF;
    else
      log_rst_shift <= {log_rst_shift[14:0], 1'b0};
  end


  // put a sufficient delay on the initialization to improve simulation time.
  // Not needed for actual hardware but does no damage if kept.
  // ��·��ʼ����ʱ
  always @(posedge log_clk) begin
    if (log_rst_q) begin
      link_initialized_cnt <= 0;
    end else if (link_initialized && !link_initialized_delay) begin
      link_initialized_cnt <= link_initialized_cnt + 1;
    end else if (!link_initialized) begin
      link_initialized_cnt <= 0;
    end
  end



  // }}} End Common-use Signals -----------


  // {{{ Request Packet Formatter ---------
  
  always @(posedge log_clk) begin
	if (log_rst_q) 
	begin
		val_ireq_tvalid <= 1'b0;
		val_ireq_tlast <= 1'b0;
		val_ireq_tdata <= 0;
		val_ireq_tuser <= 32'h00000000;
	
		val_iresp_tready <= 1'b0;
		resp_src_id <= 16'h0000;
		resp_dest_id <= 16'h0000;
		resp_header_beat <= 0;
		resp_data1 <= 0;
		resp_data2 <= 0;
		st_ireq <= idle;
		delay_cnt <= 32'h000000;
		send_ok <= 1'b0;

	end 
	else
	begin
		case(st_ireq)
			idle :
				begin
//					if (link_initialized_delay == 1'b1) begin //��·��ʼ�����
					if (sys_start_en == 1'b1) begin //��·��ʼ�����          
						st_ireq <= st1;
					end else begin
						st_ireq <= idle;
					end
				end
			st1 :
				begin
				
					if (ireq_send_enable && val_ireq_tready) 
						begin //����ʹ��and IP���ܹ���������
						
						if (user_ftype == 4'b0101 && user_ttype==4'b0100) begin //�жϴ˰�ΪNWRITE goto st2
								st_ireq <= st2;
						end else if (user_ftype == 4'b0010 && user_ttype==4'b0100) begin //�жϴ˰�ΪNREAD goto st6
								st_ireq <= st6;
						end else begin
								st_ireq <= idle;//�˰�����δʵ�֣�goto idle
						end
					 
						end 
					else begin
						st_ireq <= st1;//wait
					end
				end
			//NWRITE������
			st2 :
				begin
				val_ireq_tvalid <= 1'b1;
				val_ireq_tdata <= header_beat;
				val_ireq_tuser <= {src_id, dest_id};//Դid+Ŀ��id
				val_ireq_tlast <= 1'b0; //�������һ��������
				st_ireq <= st11;
				end
			st11 :
				begin
				st_ireq <= st3;
				end
			st3 :
				begin
				val_ireq_tvalid <= 1'b1;
				val_ireq_tdata <= 64'h1122334455667788;
//            val_ireq_tdata <= 64'haa55aa55aa55aa55;
				val_ireq_tlast <= 1'b0; //�������һ��������
				st_ireq <= st4;
				end
			st4 :
				begin
				val_ireq_tvalid <= 1'b1;
				val_ireq_tdata <= 64'hbb66bb66bb66bb66;
				val_ireq_tlast <= 1'b1; //���һ��������
				st_ireq <= st5;
				end
			st5 :
				begin
					val_ireq_tvalid <= 1'b0;
					val_ireq_tlast <= 1'b0;
					val_ireq_tdata <= 0;
					val_ireq_tuser <= 32'h00000000;
					send_ok <= ~send_ok;
					st_ireq <= st10;			
				end
				
			//NREAD������
			st6 :
				begin
				val_ireq_tvalid <= 1'b1;
				val_ireq_tdata <= header_beat;
				val_ireq_tuser <= {src_id,dest_id};//Դid+Ŀ��id
				val_ireq_tlast <= 1'b1; //���һ��������
				st_ireq <= st7;
				end
	
			
			//�������ʽΪNREAD��ִ������Ĳ��������Ӧ��
   		st7 :
				begin
					val_ireq_tvalid <= 1'b0;
					val_ireq_tlast <= 1'b0;
					val_ireq_tdata <= 0;
					val_ireq_tuser <= 32'h00000000;
					
					val_iresp_tready <= 1'b1;//ָʾ����׼���ý�������rapidio�İ�
					if (val_iresp_tvalid) begin
						resp_src_id <= val_iresp_tuser[31:16];//��Ӧ��ԴID
						resp_dest_id <= val_iresp_tuser[15:0];//��Ӧ��Ŀ��ID
						resp_header_beat <= val_iresp_tdata;
						st_ireq <= st8;
					end
				end
			st8 :
				begin
					resp_data1 <= val_iresp_tdata;
					st_ireq <= st9;
				end 
			st9 :
				begin
					if (val_iresp_tlast == 1'b1) begin
						resp_data2 <= val_iresp_tdata;
						end
						send_ok <= ~send_ok;
						st_ireq <= st10;
				end
			st10 :
				begin
//					if (delay_cnt==32'h0ee6b280) begin//��ʱ2s
               if (delay_cnt==32'h00000080) begin//��ʱ2s
						delay_cnt <= 32'h000000;
						st_ireq <= idle;
						end
					else begin
						delay_cnt <= delay_cnt+1;
						st_ireq <= st10; //wait
					end
					
				end
				
			default :
				begin
				st_ireq <= idle;
				end
			endcase
	end
end
/////////////////////////////////////////////////////////////////
  always @(posedge log_clk) begin
    if (log_rst_q) begin
      user_ftype <= 4'b0101;//ftype=5
      user_ttype <= 4'b0100;//ttype=4,NWRITE
    end else if (st_ireq == st5 && user_ftype == 4'b0101 && user_ttype==4'b0100) begin//wr_done
      user_ftype <= 4'b0010;//ftype=2
      user_ttype <= 4'b0100;//ttype=4,NREND
//      user_ftype <= 4'b0101;//ftype=5
//      user_ttype <= 4'b0100;//ttype=4,NWRITE      
    end else if (st_ireq == st9 && user_ftype == 4'b0010 && user_ttype==4'b0100) begin//rd_done
      user_ftype <= 4'b0101;//ftype=5
      user_ttype <= 4'b0100;//ttype=4,NWRITE
    end
  end


  always @(posedge log_clk) begin
    if (log_rst_q) begin
      link_display_cnt <= 16'b0;
    end else if (link_initialized == 1'b0) begin
      link_display_cnt <= link_display_cnt + 1'b1;
    end else if (link_initialized == 1'b1) begin
      link_display_cnt <= link_display_cnt;
    end
  end

  always @(posedge log_clk) begin
    if (log_rst_q) begin
      link_display_dly <= 32'h0;
    end else if (link_display_dly == 32'h5FFFFFFF) begin
      link_display_dly <= link_display_dly;
    end else if (link_initialized == 1'b1) begin
      link_display_dly <= link_display_dly + 1;
    end
  end 

  always @(posedge log_clk) begin
    if (log_rst_q) begin
      sys_start_en <= 1'b0;
    end else if (link_display_dly == 32'h5FFFFFFF) begin
      sys_start_en <= 1'b1;
    end else begin
      sys_start_en <= 1'b0;
    end
  end // 
  
////

  always @(posedge log_clk) begin
    if (log_rst_q) begin
      debug_line <= 2'b00;
    end else if (resp_data1 == 64'hFFFFFFFFFFFFFFFF && resp_data2 == 64'hFFFFFFFFFFFFFFFF) begin
      debug_line <= 2'b01;
    end else if (resp_data1 == 64'h0000000000000000 && resp_data2 == 64'h5555555FFFFFFFFF) begin
      debug_line <= 2'b10;
    end
  end
endmodule
