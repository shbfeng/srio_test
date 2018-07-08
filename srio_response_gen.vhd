-- Company: 		    SGXB
-- Engineer: 		    Zhang Yan
-- 
-- Create Date:    	2017/08/30 
-- Design Name:    	emif interface
-- Module Name:    	emif_inf
-- Project Name:   	
-- Target Devices:
-- Tool versions:  	
-- Description:	    
-- Dependencies:	
-- 
-- Revision: 
-- Revision 1.0 - File Created
-- Additional Comments: 
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity srio_response_gen is
  
  port (
    log_clk : in std_logic;
    log_rst : in std_logic;

    deviceid  : in std_logic_vector(15 downto 0);
    sourceid  : in std_logic_vector(15 downto 0);

    user_cfg_src_id : in std_logic_vector(15 downto 0);
    user_cfg_dec_id : in std_logic_vector(15 downto 0);
    
    val_tresp_tvalid : out std_logic;
    val_tresp_tready : in  std_logic;
    val_tresp_tlast  : out std_logic;
    val_tresp_tdata  : out std_logic_vector(63 downto 0);
    val_tresp_tkeep  : out std_logic_vector(7 downto 0);
    val_tresp_tuser  : out std_logic_vector(31 downto 0);

    val_treq_tvalid  : in  std_logic;
    val_treq_tready  : out std_logic;
    val_treq_tlast   : in  std_logic;
    val_treq_tdata   : in  std_logic_vector(63 downto 0);
    val_treq_tkeep   : in  std_logic_vector(7 downto 0);
    val_treq_tuser   : in  std_logic_vector(31 downto 0);

    user_clk            : in  std_logic;
    user_rst            : in  std_logic;
    recv_wr_data        : out std_logic_vector(31 downto 0);
    recv_wr_addr        : out std_logic_vector(31 downto 0);
    recv_wr_data_valid  : out std_logic;
    recv_wr_data_rdy    : in  std_logic;

    ack_rd_data         : in  std_logic_vector(63 downto 0);
    ack_rd_addr         : out std_logic_vector(31 downto 0);
    ack_rd_en           : out std_logic;
    ack_rd_data_valid   : in  std_logic
    );

end srio_response_gen;

architecture RTL of srio_response_gen is
  component fifo_1024x64
    port (
      rst    : IN  STD_LOGIC;
      wr_clk : IN  STD_LOGIC;
      rd_clk : IN  STD_LOGIC;
      din    : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
      wr_en  : IN  STD_LOGIC;
      rd_en  : IN  STD_LOGIC;
      dout   : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      full   : OUT STD_LOGIC;
      empty  : OUT STD_LOGIC);
  end component;


  signal current_tid    : std_logic_vector(7 downto 0);
  signal current_ftype  : std_logic_vector(3 downto 0);
  signal current_ttype  : std_logic_vector(3 downto 0);
  signal current_size   : std_logic_vector(7 downto 0);
  signal current_prio   : std_logic_vector(1 downto 0);
  signal current_addr   : std_logic_vector(33 downto 0);
  signal current_src_id : std_logic_vector(15 downto 0);

  signal dec_id : std_logic_vector(15 downto 0);
  signal src_id  : std_logic_vector(15 downto 0);

  signal req_header_beat : std_logic_vector(63 downto 0);
  signal req_src_id : std_logic_vector(15 downto 0);
  signal req_dest_id : std_logic_vector(15 downto 0);
  signal response_header : std_logic_vector(63 downto 0);

  type resp_srio_pstate_type is(idle_s, dec_recv_valid_s, recv_wr_mod_s, wr_mod_recv_done_s,
                                recv_rd_mod_s, header_package_s, payload_1_s, payload_2_s,rd_mod_ack_done_s);
  signal resp_srio_pstate : resp_srio_pstate_type;
  signal sta_cnt : std_logic_vector(7 downto 0);

  signal recv_wr_fifo_din   : std_logic_vector(63 downto 0);
  signal recv_wr_fifo_wr_en : std_logic;
  signal recv_wr_fifo_rd_en : std_logic;
  signal recv_wr_fifo_dout  : std_logic_vector(63 downto 0);
  signal recv_wr_fifo_empty : std_logic;
  signal recv_wr_fifo_full  : std_logic;

  signal ack_rd_fifo_din   : std_logic_vector(63 downto 0);
  signal ack_rd_fifo_wr_en : std_logic;
  signal ack_rd_fifo_rd_en : std_logic;
  signal ack_rd_fifo_dout  : std_logic_vector(63 downto 0);
  signal ack_rd_fifo_empty : std_logic;
  signal ack_rd_fifo_full  : std_logic;

  signal val_treq_tvalid_dly : std_logic;
  signal val_treq_tdata_dly : std_logic_vector(63 downto 0);
  signal val_treq_tlast_dly : std_logic;
  signal val_treq_tkeep_dly : std_logic_vector(7 downto 0);
  signal val_treq_tuser_dly : std_logic_vector(31 downto 0);
  
  signal recv_wr_cnt : std_logic_vector(1 downto 0);
  signal lose_en : std_logic;
  signal debug_resp_srio_pstate : std_logic_vector(3 downto 0);

  attribute keep : string;
  attribute keep of debug_resp_srio_pstate: signal is "TRUE";

  attribute keep of val_treq_tvalid: signal is "TRUE";
  attribute keep of val_treq_tuser: signal is "TRUE";
  attribute keep of val_treq_tdata: signal is "TRUE";
  attribute keep of val_treq_tkeep: signal is "TRUE";
  
  attribute keep of recv_wr_cnt: signal is "TRUE";
  attribute keep of sta_cnt: signal is "TRUE";
  attribute keep of lose_en: signal is "TRUE";      
begin  -- RTL

  recv_wr_fifo: fifo_1024x64
    port map (
      rst    => log_rst,
      wr_clk => log_clk,
      rd_clk => user_clk,
      din    => recv_wr_fifo_din,
      wr_en  => recv_wr_fifo_wr_en,
      rd_en  => recv_wr_fifo_rd_en,
      dout   => recv_wr_fifo_dout,
      full   => recv_wr_fifo_full,
      empty  => recv_wr_fifo_empty);

--  ack_rd_fifo: fifo_1024x64
--    port map (
--      rst    => user_rst,
--      wr_clk => user_clk,
--      rd_clk => log_clk,
--      din    => ack_rd_fifo_din,
--      wr_en  => ack_rd_fifo_wr_en,
--      rd_en  => ack_rd_fifo_rd_en,
--      dout   => ack_rd_fifo_dout,
--      full   => ack_rd_fifo_full,
--      empty  => ack_rd_fifo_empty);
  
  ack_rd_fifo_din   <= ack_rd_data;
  ack_rd_fifo_wr_en <= ack_rd_data_valid;

  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        req_header_beat <= (others => '0');
        req_src_id      <= (others => '0');
        req_dest_id     <= (others => '0');
      elsif(val_treq_tvalid_dly = '1')then
        req_header_beat <= val_treq_tdata;
        req_src_id      <= val_treq_tuser(31 downto 16);
        req_dest_id     <= val_treq_tuser(15 downto 0);
      end if;
    end if;
  end process;
  
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        src_id <= x"0013";
        dec_id <= x"0017";
      else
        src_id <= user_cfg_src_id;                    --local src_id
        dec_id <= user_cfg_dec_id;                    --local dec_id
      end if;
    end if;
  end process;

  
  current_tid <= req_header_beat(63 downto 56);
  current_ftype <= req_header_beat(55 downto 52);
  current_ftype <= req_header_beat(51 downto 48);
  current_prio  <= req_header_beat(46 downto 45) + "01";
  current_size  <= req_header_beat(43 downto 36);
  current_addr  <= req_header_beat(33 downto 0);

  response_header <= current_tid & x"d" & x"8" & '0' & current_prio & x"0000_0000" & x"000" & '0';

  val_treq_tready <= '1';

process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        val_treq_tvalid_dly <= '0';
        val_treq_tlast_dly  <= '0';
        val_treq_tdata_dly  <= (others => '0');
        val_treq_tkeep_dly  <= (others => '0');
        val_treq_tuser_dly  <= (others => '0');
      else
        val_treq_tvalid_dly <= val_treq_tvalid;
        val_treq_tlast_dly  <= val_treq_tlast;
        val_treq_tdata_dly  <= val_treq_tdata;
        val_treq_tkeep_dly  <= val_treq_tkeep;
        val_treq_tuser_dly  <= val_treq_tuser;
      end if;
    end if;
  end process;
  
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        resp_srio_pstate <= idle_s;
        sta_cnt          <= (others => '0');
      else
        case resp_srio_pstate is
          when idle_s                       => if(recv_wr_data_rdy = '1')then
                                                 resp_srio_pstate <= dec_recv_valid_s;
                                               else
                                                 resp_srio_pstate <= idle_s;
                                               end if;
                                               
          when dec_recv_valid_s             => if(val_treq_tvalid_dly = '1'
                                                  and val_treq_tuser_dly(31 downto 16) = dec_id--
                                                                                           --17
                                                  and val_treq_tuser_dly(15 downto 0 ) = src_id--
                                                                                           --13
                                                  and val_treq_tdata_dly(55 downto 52) = "0101"
                                                  and val_treq_tdata_dly(51 downto 48) = "0100"
                                                  and src_id /= dec_id
                                                  and val_treq_tdata_dly /= val_treq_tdata
                                                  )then
                                                 resp_srio_pstate <= recv_wr_mod_s;
-------------------------------------------------------------------------------
                                               elsif(val_treq_tvalid_dly = '1'
                                                     and val_treq_tuser_dly(31 downto 16) = dec_id--
                                                                                              --17
                                                     and val_treq_tuser_dly(15 downto 0 ) = src_id--
                                                                                              --13
                                                     and val_treq_tdata_dly(55 downto 52) = "0101"
                                                     and val_treq_tdata_dly(51 downto 48) = "0100"
                                                     and src_id = dec_id
                                                     and val_treq_tdata_dly(31 downto 0 ) > x"8000_0000"
                                                     and val_treq_tdata_dly /= val_treq_tdata
                                                     )then
                                                 resp_srio_pstate <= recv_wr_mod_s;
-------------------------------------------------------------------------------
                                               elsif(val_treq_tvalid_dly = '1'
                                                     and val_treq_tuser_dly(31 downto 16) = dec_id--
                                                                                              --17
                                                     and val_treq_tuser_dly(15 downto 0)  = src_id
                                                     and val_treq_tdata_dly(55 downto 52) = "0010"
                                                     and val_treq_tdata_dly(51 downto 48) = "0100"
                                                     and val_treq_tdata_dly /= val_treq_tdata
                                                     )then
                                                 resp_srio_pstate <= recv_rd_mod_s;
                                               else
                                                 resp_srio_pstate <= dec_recv_valid_s;
                                               end if;

          when recv_wr_mod_s                  => if(val_treq_tlast_dly = '1' and recv_wr_data_rdy = '1')then
--                                                   resp_srio_pstate <= wr_mod_recv_done_s;
                                                   resp_srio_pstate <= dec_recv_valid_s;
                                                   sta_cnt          <= (others => '0');
                                                 elsif(val_treq_tlast_dly = '1' and recv_wr_data_rdy = '0')then
                                                   resp_srio_pstate <= idle_s;
                                                   sta_cnt          <= (others => '0');
                                                 else
                                                   sta_cnt          <= sta_cnt + 1;
                                                   resp_srio_pstate <= recv_wr_mod_s;
                                                 end if;

          when wr_mod_recv_done_s             => resp_srio_pstate <= idle_s;

          when recv_rd_mod_s                  => if(val_tresp_tready = '1' and ack_rd_fifo_empty = '0')then
                                                   resp_srio_pstate <= header_package_s;
                                                   sta_cnt          <= (others => '0');
                                                 elsif(sta_cnt < 3)then
                                                   resp_srio_pstate <= recv_rd_mod_s;
                                                   sta_cnt          <= sta_cnt + 1;
                                                 else
                                                   resp_srio_pstate <= recv_rd_mod_s;
                                                   sta_cnt          <= sta_cnt;
                                                 end if;

          when header_package_s               => if(sta_cnt = 1)then
                                                   sta_cnt          <= (others => '0');
                                                   resp_srio_pstate <= payload_1_s;
                                                 else
                                                   resp_srio_pstate <= header_package_s;
                                                   sta_cnt          <= sta_cnt + 1;
                                                 end if;

          when payload_1_s                    => if(ack_rd_fifo_empty = '0')then
                                                   resp_srio_pstate <= payload_2_s;
                                                 else
                                                   resp_srio_pstate <= payload_1_s;
                                                 end if;

          when payload_2_s                    => if(ack_rd_fifo_empty = '0')then
                                                   resp_srio_pstate <= rd_mod_ack_done_s;
                                                 else
                                                   resp_srio_pstate <= payload_2_s;
                                                 end if;

          when rd_mod_ack_done_s              => resp_srio_pstate <= idle_s;
                                                 
                                                 
          when others => null;
        end case;

      end if;
    end if;
  end process;

-------------------------------------------------------------------------------
-- ack_rd_fifo
-------------------------------------------------------------------------------
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        val_tresp_tdata  <= (others => '0');
        val_tresp_tvalid <= '0';
        val_tresp_tlast  <= '0';
        val_tresp_tuser  <= (others => '0');
      elsif(resp_srio_pstate = header_package_s)then
        val_tresp_tdata  <= response_header;
        val_tresp_tvalid <= '1';
        val_tresp_tlast  <= '0';
        val_tresp_tuser  <= src_id & req_src_id;
      elsif(ack_rd_fifo_empty = '0' and resp_srio_pstate = payload_1_s)then
        val_tresp_tdata  <= ack_rd_fifo_dout;
        val_tresp_tvalid <= '1';
        val_tresp_tlast  <= '0';
      elsif(ack_rd_fifo_empty = '0' and resp_srio_pstate = payload_2_s)then
        val_tresp_tdata  <= ack_rd_fifo_dout;
        val_tresp_tvalid <= '1';
        val_tresp_tlast  <= '1';        
      else
        val_tresp_tvalid <= '0';
      end if;
    end if;
  end process;
  val_tresp_tkeep <= x"FF";
-------------------------------------------------------------------------------
-- ack wr
-------------------------------------------------------------------------------

  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        lose_en <= '0';
      elsif(resp_srio_pstate = recv_wr_mod_s and sta_cnt = 0
            and val_treq_tlast_dly = '1')then
        lose_en <= '1';
      else
        lose_en <= '0';
      end if;
    end if;
  end process;
  
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        recv_wr_fifo_din   <= (others => '0');
        recv_wr_fifo_wr_en <= '0';
      elsif(resp_srio_pstate = recv_wr_mod_s)then
        recv_wr_fifo_din   <= val_treq_tdata_dly;
        recv_wr_fifo_wr_en <= '1';
      elsif(lose_en = '1')then
        recv_wr_fifo_din   <= val_treq_tdata_dly;
        recv_wr_fifo_wr_en <= '1';
      else
        recv_wr_fifo_din   <= (others => '0');
        recv_wr_fifo_wr_en <= '0';
      end if;
    end if;
  end process;


  process(user_clk)
  begin
    if(rising_edge(user_clk))then
      if(user_rst = '1')then
        recv_wr_data      <= (others => '0');
        recv_wr_data_valid <= '0';
      elsif(recv_wr_fifo_empty = '0' and recv_wr_data_rdy = '1'
            and val_treq_tkeep_dly = x"FF")then
        recv_wr_data_valid <= '1';
        case recv_wr_cnt is

          when "00" =>         recv_wr_data <= recv_wr_fifo_dout(39 downto 32)
                                               & recv_wr_fifo_dout(47 downto 40)
                                               & recv_wr_fifo_dout(55 downto 48)
                                               & recv_wr_fifo_dout(63 downto 56);

          when "01" =>         recv_wr_data <= recv_wr_fifo_dout(7 downto 0)
                                               & recv_wr_fifo_dout(15 downto 8)
                                               & recv_wr_fifo_dout(23 downto 16)
                                               & recv_wr_fifo_dout(31 downto 24);

          when "10" =>         recv_wr_data <= recv_wr_fifo_dout(39 downto 32)
                                               & recv_wr_fifo_dout(47 downto 40)
                                               & recv_wr_fifo_dout(55 downto 48)
                                               & recv_wr_fifo_dout(63 downto 56);

          when "11" =>         recv_wr_data <= recv_wr_fifo_dout(7 downto 0)
                                               & recv_wr_fifo_dout(15 downto 8)
                                               & recv_wr_fifo_dout(23 downto 16)
                                               & recv_wr_fifo_dout(31 downto 24);
                               

          when others => null;
        end case;
      else
        recv_wr_data       <= (others => '0');
        recv_wr_data_valid <= '0';
      end if;
    end if;
  end process; 
  
  process(user_clk)
  begin
    if(rising_edge(user_clk))then
      if(user_rst = '1')then
        recv_wr_fifo_rd_en <= '0';
      elsif(recv_wr_fifo_empty = '0' and
            (recv_wr_cnt = "00" or recv_wr_cnt = "10") and recv_wr_data_rdy = '1')then
        recv_wr_fifo_rd_en <= '1';
      elsif(recv_wr_data_rdy = '0' and recv_wr_fifo_empty = '0')then
        recv_wr_fifo_rd_en <= '1';      --clr//length_addr_data--for self_loop_check
      else
        recv_wr_fifo_rd_en <= '0';
      end if;
    end if;
  end process;

  process(user_clk)
  begin
    if(rising_edge(user_clk))then
      if(user_rst = '1')then
        recv_wr_cnt <= "00";
      elsif(recv_wr_fifo_empty = '1')then
        recv_wr_cnt <= "00";
      elsif(recv_wr_fifo_empty = '0' and recv_wr_data_rdy = '1')then
        recv_wr_cnt <= recv_wr_cnt + 1;
      elsif(recv_wr_cnt = "11")then
        recv_wr_cnt <= "00";
      end if;
    end if;
  end process;

-------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------  
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        ack_rd_addr <= (others => '0');
        ack_rd_en   <= '0';
      elsif(resp_srio_pstate = recv_rd_mod_s and sta_cnt = x"00")then
        ack_rd_en   <= '1';
        ack_rd_addr <= current_addr(31 downto 0);
      else
        ack_rd_addr <= x"000000" & val_treq_tkeep;
        ack_rd_en   <= '0';
      end if;
    end if;
  end process;
-------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        debug_resp_srio_pstate <= (others => '0');
      else
        case resp_srio_pstate is
          when idle_s                    => debug_resp_srio_pstate <= x"0";
          when dec_recv_valid_s          => debug_resp_srio_pstate <= x"1";
          when recv_wr_mod_s             => debug_resp_srio_pstate <= x"2";
          when wr_mod_recv_done_s        => debug_resp_srio_pstate <= x"3";
          when recv_rd_mod_s             => debug_resp_srio_pstate <= x"4";
          when header_package_s          => debug_resp_srio_pstate <= x"5";
          when payload_1_s               => debug_resp_srio_pstate <= x"6";
          when payload_2_s               => debug_resp_srio_pstate <= x"7";
          when rd_mod_ack_done_s         => debug_resp_srio_pstate <= x"8";
          when others => null;
        end case;

      end if;
    end if;
  end process;
-------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------

end RTL;

--  process(log_clk)
--  begin
--    if(rising_edge(log_clk))then
--      if(log_rst = '1')then

--      else

--      end if;
--    end if;
--  end process;
