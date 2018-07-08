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

entity srio_request_gen is
  port (
    log_clk         : in  std_logic;
    log_rst         : in  std_logic;
    
    deviceid        : in  std_logic_vector(15 downto 0);
    sourceid        : in  std_logic_vector(15 downto 0);

    user_cfg_src_id : in std_logic_vector(15 downto 0);
    user_cfg_dec_id : in std_logic_vector(15 downto 0);

    val_ireq_tvalid : out std_logic;
    val_ireq_tready : in  std_logic;
    val_ireq_tlast  : out std_logic;
    val_ireq_tdata  : out std_logic_vector(63 downto 0);
    val_ireq_tkeep  : out std_logic_vector(7 downto 0);
    val_ireq_tuser  : out std_logic_vector(31 downto 0);

    val_iresp_tvalid : in  std_logic;
    val_iresp_tready : out std_logic;
    val_iresp_tlast  : in  std_logic;
    val_iresp_tdata  : in  std_logic_vector(63 downto 0);
    val_iresp_tkeep  : in  std_logic_vector(7 downto 0);
    val_iresp_tuser  : in  std_logic_vector(31 downto 0);  

    link_initialized : in  std_logic;

    user_clk         : in  std_logic;
    user_rst         : in  std_logic;
    srio_wr_data     : in  std_logic_vector(127 downto 0);
    srio_byte_tkeep  : in  std_logic_vector(7 downto 0);
    srio_wr_addr     : in  std_logic_vector(31 downto 0);
    srio_wr_en       : in  std_logic;

    srio_rd_data       : out std_logic_vector(65 downto 0);
    srio_rd_data_valid : out std_logic;
    srio_rd_addr       : in  std_logic_vector(31 downto 0);
    srio_rd_en         : in  std_logic;
    
    link_done          : out std_logic;
    srio_idle          : out std_logic
    );
  
end srio_request_gen;

architecture RTL of srio_request_gen is

  component fifo_1024x66
    port (
      rst    : IN  STD_LOGIC;
      wr_clk : IN  STD_LOGIC;
      rd_clk : IN  STD_LOGIC;
      din    : IN  STD_LOGIC_VECTOR(65 DOWNTO 0);
      wr_en  : IN  STD_LOGIC;
      rd_en  : IN  STD_LOGIC;
      dout   : OUT STD_LOGIC_VECTOR(65 DOWNTO 0);
      full   : OUT STD_LOGIC;
      empty  : OUT STD_LOGIC);
  end component;

  component fifo_1024x180
    port (
      rst    : IN  STD_LOGIC;
      wr_clk : IN  STD_LOGIC;
      rd_clk : IN  STD_LOGIC;
      din    : IN  STD_LOGIC_VECTOR(179 DOWNTO 0);
      wr_en  : IN  STD_LOGIC;
      rd_en  : IN  STD_LOGIC;
      dout   : OUT STD_LOGIC_VECTOR(179 DOWNTO 0);
      full   : OUT STD_LOGIC;
      empty  : OUT STD_LOGIC);
  end component;
  
signal srio_buf_fifo_empty : std_logic;
signal srio_buf_fifo_din   : std_logic_vector(179 downto 0);
signal srio_buf_fifo_wr_en : std_logic;
signal srio_buf_fifo_dout  : std_logic_vector(179 downto 0);
signal srio_buf_fifo_rd_en : std_logic;
signal srio_buf_fifo_full  : std_logic;

signal current_ftype : std_logic_vector(3 downto 0);
signal current_ttype : std_logic_vector(3 downto 0);
signal current_size  : std_logic_vector(7 downto 0);
signal srio_addr     : std_logic_vector(35 downto 0);
signal src_id        : std_logic_vector(15 downto 0);
signal dest_id       : std_logic_vector(15 downto 0);
signal src_id_dly    : std_logic_vector(15 downto 0);
signal dest_id_dly   : std_logic_vector(15 downto 0);  
signal prio          : std_logic_vector(1 downto 0);
signal tid           : std_logic_vector(7 downto 0);
signal header_beat   : std_logic_vector(63 downto 0);

signal link_initialized_cnt : std_logic_vector(19 downto 0);
signal link_initialized_delay : std_logic;

type master_pstate_type is(idle_s, rd_cmd_fifo_s, wr_package_header_s, wr_payload_1_s, wr_payload_2_s,
                           op_done_s, rd_package_header_s, rdy_local_recv_s, recv_payload_1_s,
                           recv_payload_2_s, cmd_err_s, addr_err_s,state_0_s);
signal master_pstate : master_pstate_type;
signal sta_cnt : std_logic_vector(3 downto 0);
  
signal resp_src_id : std_logic_vector(15 downto 0);
signal resp_dest_id : std_logic_vector(15 downto 0);
signal resp_header_beat : std_logic_vector(63 downto 0);

signal srio_master_recv_fifo_din   : std_logic_vector(65 downto 0);
signal srio_master_recv_fifo_rd_en : std_logic;
signal srio_master_recv_fifo_dout  : std_logic_vector(65 downto 0);
signal srio_master_recv_fifo_wr_en : std_logic;
signal srio_master_recv_fifo_empty : std_logic;
signal srio_master_recv_fifo_full  : std_logic;

signal debug_master_pstate  : std_logic_vector(3 downto 0);
signal link_initialized_flag : std_logic;
signal debug_trans_cnt : std_logic_vector(15 downto 0);
signal zy_en : std_logic;
signal zy_cnt : std_logic_vector(3 downto 0);
signal handshake_en : std_logic_vector(1 downto 0);
  
  attribute keep : string;
  attribute keep of debug_master_pstate: signal is "TRUE";
  attribute keep of link_initialized   : signal is "TRUE";
  attribute keep of link_initialized_delay   : signal is "TRUE";  
  attribute keep of link_initialized_flag: signal is "TRUE";
  attribute keep of link_initialized_cnt   : signal is "TRUE";

  attribute keep of val_ireq_tuser :signal is "TRUE";
  attribute keep of val_ireq_tdata :signal is "TRUE";
  attribute keep of val_ireq_tlast :signal is "TRUE";
  attribute keep of val_ireq_tvalid :signal is "TRUE";
  attribute keep of val_ireq_tready  :signal is "TRUE";

  attribute keep of debug_trans_cnt : signal is "TRUE";
  attribute keep of zy_cnt : signal is "TRUE";
  attribute keep of zy_en : signal is "TRUE";
  attribute keep of handshake_en : signal is "TRUE";    
  
begin  -- RTL
val_iresp_tready <= '1';
  srio_master_recv_fifo: fifo_1024x66
    port map (
      rst    => log_rst,
      wr_clk => log_clk,
      rd_clk => user_clk,
      din    => srio_master_recv_fifo_din,
      wr_en  => srio_master_recv_fifo_wr_en,
      rd_en  => srio_master_recv_fifo_rd_en,
      dout   => srio_master_recv_fifo_dout,
      full   => srio_master_recv_fifo_full,
      empty  => srio_master_recv_fifo_empty);

  srio_buf_fifo: fifo_1024x180
    port map (
      rst    => user_rst,
      wr_clk => user_clk,
      rd_clk => log_clk,
      din    => srio_buf_fifo_din,
      wr_en  => srio_buf_fifo_wr_en,
      rd_en  => srio_buf_fifo_rd_en,
      dout   => srio_buf_fifo_dout,
      full   => srio_buf_fifo_full,
      empty  => srio_buf_fifo_empty);
  
  srio_idle <= not srio_buf_fifo_full;

-------------------------------------------------------------------------------
-- analysis cmd
-------------------------------------------------------------------------------  
  process(user_clk)
  begin
    if(rising_edge(user_clk))then
      if(user_rst = '1')then
        srio_buf_fifo_wr_en <= '0';
        srio_buf_fifo_din   <=(others => '0');
      elsif(srio_wr_en = '1')then
        srio_buf_fifo_wr_en <= '1';
        srio_buf_fifo_din   <= srio_byte_tkeep
                               & "01010100"  --wr_cmd
                               & "0000" & srio_wr_addr
                               & srio_wr_data;
      elsif(srio_rd_en = '1')then
        srio_buf_fifo_wr_en <= '1';
        srio_buf_fifo_din   <= srio_byte_tkeep
                               & "00100100"  --rd_cmd
                               & "0000" & srio_rd_addr
                               & x"0000_0000_0000_0000"
                               & x"0000_0000_0000_0000";
      else
        srio_buf_fifo_wr_en <= '0';
        srio_buf_fifo_din   <=(others => '0');
      end if;
    end if;
  end process;
-------------------------------------------------------------------------------
-- assemble header_package
-------------------------------------------------------------------------------
  current_ftype  <= srio_buf_fifo_dout(171 downto 168) when zy_en = '0' else "0101";
  current_ttype  <= srio_buf_fifo_dout(167 downto 164) when zy_en = '0' else "0100";
  current_size   <= x"0F";
  srio_addr      <= srio_buf_fifo_dout(163 downto 128);
  prio           <= "01";
  tid            <= x"00";
  
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        src_id_dly  <= x"0013";
        dest_id_dly <= x"0013";         --17
      else
        src_id_dly  <= user_cfg_src_id;                    --local src_id
        dest_id_dly <= user_cfg_dec_id;                    --local dec_id
      end if;
    end if;
  end process;

  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        src_id  <= x"0013";
        dest_id <= x"0013";             --17
      else
        src_id  <= src_id_dly;                    --local src_id
        dest_id <= dest_id_dly;                    --local dec_id
      end if;
    end if;
  end process;

  header_beat    <= tid & current_ftype & current_ttype & '0' & prio & '0' & current_size & srio_addr;
-------------------------------------------------------------------------------
-- link delay 
-------------------------------------------------------------------------------
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        link_initialized_cnt <= (others => '0');
      elsif(link_initialized = '1' and link_initialized_delay = '0')then
        link_initialized_cnt <= link_initialized_cnt + 1;
      elsif(link_initialized = '0')then
        link_initialized_cnt <= (others => '0');
      else
        link_initialized_cnt <= link_initialized_cnt;
      end if;
    end if;
  end process;

  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        link_initialized_flag <= '0';
      elsif(link_initialized = '1')then
        link_initialized_flag <= '1';
      end if;
    end if;
  end process;
  
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        link_initialized_delay <= '0';        
      elsif(link_initialized = '0')then
        link_initialized_delay <= '0';
      elsif(link_initialized_cnt = x"10000")then
        link_initialized_delay <= '1';
      end if;
    end if;
  end process;
  
  link_done <= link_initialized_delay;
-------------------------------------------------------------------------------
-- srio_buf_fifo op
-------------------------------------------------------------------------------
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        srio_buf_fifo_rd_en <= '0';
      elsif(master_pstate = wr_payload_2_s
            and handshake_en /= "01" and zy_en = '0')then
        srio_buf_fifo_rd_en <= '1';

      elsif(master_pstate = cmd_err_s
            or master_pstate = addr_err_s)then
        srio_buf_fifo_rd_en <= '1';
      else
        srio_buf_fifo_rd_en <= '0';
      end if;
    end if;
  end process;

-------------------------------------------------------------------------------
--master_pstate 
------------------------------------------------------------------------------- 
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        master_pstate <= idle_s;
        sta_cnt       <= (others => '0');
      else
        case master_pstate is
          when idle_s               => if(link_initialized_delay = '1' and zy_en = '0'
                                          and val_ireq_tready ='1' and handshake_en = "11"
                                          and srio_buf_fifo_empty = '0' and src_id /= dest_id)then
                                         master_pstate <= state_0_s;
                                       elsif(link_initialized_delay = '1' and srio_buf_fifo_empty = '0'
                                          and val_ireq_tready = '1')then
                                         master_pstate <= rd_cmd_fifo_s;
                                       elsif(link_initialized_delay = '1' and zy_en = '1'
                                             and val_ireq_tready = '1')then
                                         master_pstate <= state_0_s;
                                       else
                                         master_pstate <= idle_s;
                                       end if;

          when rd_cmd_fifo_s        => if(srio_buf_fifo_dout(129 downto 128)/= "00")then
                                         master_pstate <= addr_err_s;
                                       elsif(srio_buf_fifo_dout(171 downto 164) = "01010100")then
                                         master_pstate <= wr_package_header_s;
                                       elsif(srio_buf_fifo_dout(171 downto 164) = "00100100")then
                                         master_pstate <= rd_package_header_s;
                                       else
                                         master_pstate <= cmd_err_s;
                                       end if;
                                       
          when state_0_s            => master_pstate <= wr_package_header_s;
                                       
          when wr_package_header_s  => if(sta_cnt = 1)then
                                         master_pstate <= wr_payload_1_s;
                                         sta_cnt       <= (others => '0');
                                       else
                                         sta_cnt       <= sta_cnt + 1;
                                         master_pstate <= wr_package_header_s;
                                       end if;

          when wr_payload_1_s       => master_pstate <= wr_payload_2_s;

          when wr_payload_2_s       => master_pstate <= op_done_s;

          when op_done_s            => master_pstate <= idle_s;

          when rd_package_header_s  => master_pstate <= rdy_local_recv_s;

          when rdy_local_recv_s     => if(val_iresp_tvalid = '1')then
                                         master_pstate <= recv_payload_1_s;
                                       else
                                         master_pstate <= rdy_local_recv_s;
                                       end if;

          when recv_payload_1_s     => master_pstate <= recv_payload_2_s;

          when recv_payload_2_s     => master_pstate <= op_done_s;

          when cmd_err_s            => master_pstate <= idle_s;

          when addr_err_s           => master_pstate <= idle_s;

          when others =>  master_pstate <= idle_s;
        end case;
        
      end if;
    end if;
  end process;

-------------------------------------------------------------------------------
--assemble package of srio 
-------------------------------------------------------------------------------  
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        val_ireq_tvalid <= '0';
				val_ireq_tdata  <= (others => '0');
				val_ireq_tuser  <= (others => '0');--源id+目的id
				val_ireq_tlast  <= '0';            --最后一个数据字
      elsif(master_pstate = idle_s)then
				val_ireq_tuser  <= src_id & dest_id;
-------------------------------------------------------------------------------
      elsif(master_pstate = wr_package_header_s and handshake_en = "01")then
				val_ireq_tvalid <= '1';
				val_ireq_tdata  <= header_beat;
				val_ireq_tuser  <= src_id & dest_id;
				val_ireq_tlast  <= '0';
      elsif(master_pstate = wr_payload_1_s and handshake_en = "01")then
				val_ireq_tvalid <= '1';
				val_ireq_tdata  <= x"5a5a_5a5a_5a5a_5a5a";
				val_ireq_tlast  <= '0';
      elsif(master_pstate = wr_payload_2_s and handshake_en = "01")then
				val_ireq_tvalid <= '1';
				val_ireq_tdata  <= x"8888_6666_8888_6666";
				val_ireq_tlast  <= '1';
-------------------------------------------------------------------------------
      elsif(master_pstate = wr_package_header_s)then
				val_ireq_tvalid <= '1';
				val_ireq_tdata  <= header_beat;
				val_ireq_tuser  <= src_id & dest_id;
				val_ireq_tlast  <= '0';
      elsif(master_pstate = wr_payload_1_s)then
				val_ireq_tvalid <= '1';
				val_ireq_tdata  <= srio_buf_fifo_dout(63 downto 0);
				val_ireq_tlast  <= '0';
      elsif(master_pstate = wr_payload_2_s)then
				val_ireq_tvalid <= '1';
				val_ireq_tdata  <= srio_buf_fifo_dout(127 downto 64);
				val_ireq_tlast  <= '1';
        
      elsif(master_pstate = rd_package_header_s)then
				val_ireq_tvalid <= '1';
				val_ireq_tdata  <= header_beat;
				val_ireq_tuser  <= src_id & dest_id;
				val_ireq_tlast  <= '1';
      else
        val_ireq_tvalid <= '0';
				val_ireq_tdata  <= (others => '0');
--				val_ireq_tuser  <= (others => '0');
				val_ireq_tlast  <= '0';
      end if;
    end if;
  end process;
  
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        val_ireq_tkeep <= (others => '0');
      elsif(master_pstate = rd_cmd_fifo_s)then
        val_ireq_tkeep <= srio_buf_fifo_dout(179 downto 172);
      end if;
    end if;
  end process;

-------------------------------------------------------------------------------
-- srio rd back data
-------------------------------------------------------------------------------
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        resp_src_id      <= (others => '0');
        resp_dest_id     <= (others => '0');
        resp_header_beat <= (others => '0');
      elsif(master_pstate = rdy_local_recv_s and val_iresp_tvalid = '1')then
        resp_src_id      <= val_iresp_tuser(31 downto 16);
        resp_dest_id     <= val_iresp_tuser(15 downto 0);
        resp_header_beat <= val_iresp_tdata;
      end if;
    end if;
  end process;

  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        srio_master_recv_fifo_din   <= (others => '0');
        srio_master_recv_fifo_wr_en <= '0';
      elsif(master_pstate = rdy_local_recv_s and val_iresp_tvalid = '1')then
        srio_master_recv_fifo_din   <= "10" & val_iresp_tdata;
        srio_master_recv_fifo_wr_en <= '1';
      elsif(master_pstate = recv_payload_1_s)then
        srio_master_recv_fifo_din   <= "00" & val_iresp_tdata;
        srio_master_recv_fifo_wr_en <= '1';
      elsif(master_pstate = recv_payload_2_s)then
        srio_master_recv_fifo_din   <= "01" & val_iresp_tdata;
        srio_master_recv_fifo_wr_en <= '1';
      else
        srio_master_recv_fifo_din   <= (others => '0');
        srio_master_recv_fifo_wr_en <= '0';
      end if;
    end if;
  end process;

  srio_rd_data_valid <= not srio_master_recv_fifo_empty;
  srio_rd_data       <= srio_master_recv_fifo_dout;
  srio_master_recv_fifo_rd_en <= not srio_master_recv_fifo_empty;
-------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------
  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        debug_master_pstate <= (others => '0');
      else
        case master_pstate is
          when idle_s                 => debug_master_pstate <= x"0";
          when rd_cmd_fifo_s          => debug_master_pstate <= x"1";
          when wr_package_header_s    => debug_master_pstate <= x"2";
          when wr_payload_1_s         => debug_master_pstate <= x"3";
          when wr_payload_2_s         => debug_master_pstate <= x"4";
          when op_done_s              => debug_master_pstate <= x"5";
          when rd_package_header_s    => debug_master_pstate <= x"6";
          when rdy_local_recv_s       => debug_master_pstate <= x"7";
          when recv_payload_1_s       => debug_master_pstate <= x"8";
          when recv_payload_2_s       => debug_master_pstate <= x"9";
          when cmd_err_s              => debug_master_pstate <= x"a";
          when addr_err_s             => debug_master_pstate <= x"b";
          when others => null;
        end case;
      end if;
    end if;
  end process;


  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        debug_trans_cnt <= (others => '0');
      elsif(master_pstate = op_done_s)then
        debug_trans_cnt <= debug_trans_cnt + 1;
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
        zy_cnt <= (others => '0');
      elsif(master_pstate = state_0_s)then
        zy_cnt <= zy_cnt + 1;
      end if;
    end if;
  end process;

  process(log_clk)
  begin
    if(rising_edge(log_clk))then
      if(log_rst = '1')then
        zy_en <= '1';
      elsif(master_pstate = op_done_s and val_ireq_tready = '0' and zy_cnt = x"F")then
        zy_en <= '0';
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
        handshake_en <= "11";
      elsif(link_initialized_delay = '1' and zy_en = '0'and srio_buf_fifo_empty = '0'
            and val_ireq_tready ='1' and handshake_en = "11" and src_id /= dest_id)then
        handshake_en <= "01";
      elsif(master_pstate = op_done_s and handshake_en = "01")then
        handshake_en <= "00";
      end if;
    end if;
  end process;


end RTL;

--  process(log_clk)
--  begin
--    if(rising_edge(log_clk))then
--      if(log_rst = '1')then

--      else

--      end if;
--    end if;
--  end process;
