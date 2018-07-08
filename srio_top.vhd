----------------------------------------------------------------------------------
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

entity srio_top is
  port (
      sys_clkp           : in  std_logic;
      sys_clkn           : in  std_logic;
      srio_rst           : in  std_logic;
      srio_rxn0          : in  std_logic;
      srio_rxp0          : in  std_logic;
      srio_rxn1          : in  std_logic;
      srio_rxp1          : in  std_logic;
      srio_rxn2          : in  std_logic;
      srio_rxp2          : in  std_logic;
      srio_rxn3          : in  std_logic;
      srio_rxp3          : in  std_logic;
      
      srio_txn0          : out std_logic;
      srio_txp0          : out std_logic;
      srio_txn1          : out std_logic;
      srio_txp1          : out std_logic;
      srio_txn2          : out std_logic;
      srio_txp2          : out std_logic;
      srio_txn3          : out std_logic;
      srio_txp3          : out std_logic;
      led0               : out std_logic_vector(7 downto 0);
      
      user_clk           : in  std_logic;
      user_rst           : in  std_logic;
      user_cfg_src_id    : in std_logic_vector(15 downto 0);
      user_cfg_dec_id    : in std_logic_vector(15 downto 0);      
      srio_wr_data       : in  std_logic_vector(127 downto 0);
      srio_byte_tkeep    : in  std_logic_vector(7 downto 0);
      srio_wr_addr       : in  std_logic_vector(31 downto 0);
      srio_wr_en         : in  std_logic;
      
      srio_rd_data       : out std_logic_vector(65 downto 0);
      srio_rd_data_valid : out std_logic;
      srio_rd_addr       : in  std_logic_vector(31 downto 0);
      srio_rd_en         : in  std_logic;
      
      link_done          : out std_logic;
      srio_idle          : out std_logic;
      
      recv_wr_data       : out std_logic_vector(31 downto 0);
      recv_wr_addr       : out std_logic_vector(31 downto 0);
      recv_wr_data_valid : out std_logic;
      recv_wr_data_rdy   : in  std_logic;
      
      ack_rd_data        : in  std_logic_vector(63 downto 0);
      ack_rd_addr        : out std_logic_vector(31 downto 0);
      ack_rd_data_valid  : in  std_logic;
      ack_rd_en          : out std_logic
    );

end srio_top;

architecture RTL of srio_top is

  component srio_example_top
    port (
      sys_clkp           : in  std_logic;
      sys_clkn           : in  std_logic;
      sys_rst            : in  std_logic;
      srio_rxn0          : in  std_logic;
      srio_rxp0          : in  std_logic;
      srio_rxn1          : in  std_logic;
      srio_rxp1          : in  std_logic;
      srio_rxn2          : in  std_logic;
      srio_rxp2          : in  std_logic;
      srio_rxn3          : in  std_logic;
      srio_rxp3          : in  std_logic;
      srio_txn0          : out std_logic;
      srio_txp0          : out std_logic;
      srio_txn1          : out std_logic;
      srio_txp1          : out std_logic;
      srio_txn2          : out std_logic;
      srio_txp2          : out std_logic;
      srio_txn3          : out std_logic;
      srio_txp3          : out std_logic;
      led0               : out std_logic_vector(7 downto 0);
      user_clk           : in  std_logic;
      user_rst           : in  std_logic;
      user_cfg_src_id    : in std_logic_vector(15 downto 0);
      user_cfg_dec_id    : in std_logic_vector(15 downto 0);      
      srio_wr_data       : in  std_logic_vector(127 downto 0);
      srio_byte_tkeep    : in  std_logic_vector(7 downto 0);
      srio_wr_addr       : in  std_logic_vector(31 downto 0);
      srio_wr_en         : in  std_logic;
      srio_rd_data       : out std_logic_vector(65 downto 0);
      srio_rd_data_valid : out std_logic;
      srio_rd_addr       : in  std_logic_vector(31 downto 0);
      srio_rd_en         : in  std_logic;
      link_done          : out std_logic;
      srio_idle          : out std_logic;
      recv_wr_data       : out std_logic_vector(31 downto 0);
      recv_wr_addr       : out std_logic_vector(31 downto 0);
      recv_wr_data_valid : out std_logic;
      recv_wr_data_rdy   : in  std_logic;
      ack_rd_data        : in  std_logic_vector(63 downto 0);
      ack_rd_addr        : out std_logic_vector(31 downto 0);
      ack_rd_en          : out std_logic;
      ack_rd_data_valid  : in  std_logic); 
  end component;

  signal sim_srio_wr_data       : std_logic_vector(127 downto 0);
  signal sim_srio_byte_tkeep    : std_logic_vector(7 downto 0);
  signal sim_srio_wr_addr       : std_logic_vector(31 downto 0);
  signal sim_srio_wr_en         : std_logic;
  signal sim_srio_rd_data       : std_logic_vector(65 downto 0);
  signal sim_srio_rd_data_valid : std_logic;
  signal sim_srio_rd_addr       : std_logic_vector(31 downto 0);
  signal sim_srio_rd_en         : std_logic;
  signal sim_link_done          : std_logic;
  signal sim_srio_idle          : std_logic;
  signal sim_recv_wr_data       : std_logic_vector(31 downto 0);
  signal sim_recv_wr_addr       : std_logic_vector(31 downto 0);
  signal sim_recv_wr_data_valid : std_logic;
  signal sim_ack_rd_data        : std_logic_vector(63 downto 0);
  signal sim_ack_rd_addr        : std_logic_vector(31 downto 0);
  signal sim_ack_rd_en          : std_logic;
  signal sim_ack_rd_en_dly      : std_logic;  
  signal sim_ack_rd_data_valid  : std_logic;

  signal sim_cnt : std_logic_vector(31 downto 0);
  
--  attribute keep : string;
--  attribute keep of sim_srio_wr_data: signal is "TRUE";
--  attribute keep of sim_srio_wr_addr: signal is "TRUE";
--  attribute keep of sim_srio_wr_en  : signal is "TRUE";
  
--  attribute keep of sim_srio_rd_data: signal is "TRUE";
--  attribute keep of sim_srio_rd_data_valid: signal is "TRUE";  

--  attribute keep of sim_link_done: signal is "TRUE";  

--  attribute keep of sim_recv_wr_data: signal is "TRUE";
--  attribute keep of sim_recv_wr_addr: signal is "TRUE";
--  attribute keep of sim_recv_wr_data_valid: signal is "TRUE";

--  attribute keep of sim_ack_rd_data: signal is "TRUE";
--  attribute keep of sim_ack_rd_addr: signal is "TRUE";
--  attribute keep of sim_ack_rd_en: signal is "TRUE";  
--  attribute keep of sim_ack_rd_data_valid: signal is "TRUE";


begin  -- RTL

  srio_example_top_1: srio_example_top
    port map (
      sys_clkp           => sys_clkp,
      sys_clkn           => sys_clkn,
      sys_rst            => srio_rst,
      srio_rxn0          => srio_rxn0,
      srio_rxp0          => srio_rxp0,
      srio_rxn1          => srio_rxn1,
      srio_rxp1          => srio_rxp1,
      srio_rxn2          => srio_rxn2,
      srio_rxp2          => srio_rxp2,
      srio_rxn3          => srio_rxn3,
      srio_rxp3          => srio_rxp3,
      srio_txn0          => srio_txn0,
      srio_txp0          => srio_txp0,
      srio_txn1          => srio_txn1,
      srio_txp1          => srio_txp1,
      srio_txn2          => srio_txn2,
      srio_txp2          => srio_txp2,
      srio_txn3          => srio_txn3,
      srio_txp3          => srio_txp3,
      led0               => led0,
      user_clk           => user_clk,
      user_rst           => user_rst,
      user_cfg_dec_id    => user_cfg_dec_id,
      user_cfg_src_id    => user_cfg_src_id,
      srio_wr_data       => srio_wr_data,
      srio_byte_tkeep    => srio_byte_tkeep,
      srio_wr_addr       => srio_wr_addr,
      srio_wr_en         => srio_wr_en,
      srio_rd_data       => srio_rd_data,
      srio_rd_data_valid => srio_rd_data_valid,
      srio_rd_addr       => srio_rd_addr,
      srio_rd_en         => srio_rd_en,
      link_done          => link_done,
      srio_idle          => srio_idle,
      recv_wr_data       => recv_wr_data,
      recv_wr_addr       => recv_wr_addr,
      recv_wr_data_valid => recv_wr_data_valid,
      recv_wr_data_rdy   => recv_wr_data_rdy,
      ack_rd_data        => ack_rd_data,
      ack_rd_addr        => ack_rd_addr,
      ack_rd_en          => ack_rd_en,
      ack_rd_data_valid  => ack_rd_data_valid);
  
--  srio_example_top_1: srio_example_top
--    port map (
--      sys_clkp           => sys_clkp,
--      sys_clkn           => sys_clkn,
--      sys_rst            => srio_rst,
--      srio_rxn0          => srio_rxn0,
--      srio_rxp0          => srio_rxp0,
--      srio_rxn1          => srio_rxn1,
--      srio_rxp1          => srio_rxp1,
--      srio_rxn2          => srio_rxn2,
--      srio_rxp2          => srio_rxp2,
--      srio_rxn3          => srio_rxn3,
--      srio_rxp3          => srio_rxp3,
--      srio_txn0          => srio_txn0,
--      srio_txp0          => srio_txp0,
--      srio_txn1          => srio_txn1,
--      srio_txp1          => srio_txp1,
--      srio_txn2          => srio_txn2,
--      srio_txp2          => srio_txp2,
--      srio_txn3          => srio_txn3,
--      srio_txp3          => srio_txp3,
--      led0               => led0,
--      user_clk           => user_clk,
--      user_rst           => user_rst,
--      srio_wr_data       => sim_srio_wr_data,
--      srio_byte_tkeep    => sim_srio_byte_tkeep,
--      srio_wr_addr       => sim_srio_wr_addr,
--      srio_wr_en         => sim_srio_wr_en,
--      srio_rd_data       => sim_srio_rd_data,
--      srio_rd_data_valid => sim_srio_rd_data_valid,
--      srio_rd_addr       => sim_srio_rd_addr,
--      srio_rd_en         => sim_srio_rd_en,
--      link_done          => sim_link_done,
--      srio_idle          => sim_srio_idle,
--      recv_wr_data       => sim_recv_wr_data,
--      recv_wr_addr       => sim_recv_wr_addr,
--      recv_wr_data_valid => sim_recv_wr_data_valid,
--      ack_rd_data        => sim_ack_rd_data,
--      ack_rd_addr        => sim_ack_rd_addr,
--      ack_rd_en          => sim_ack_rd_en,
--      ack_rd_data_valid  => sim_ack_rd_data_valid);

--  process(user_clk)
--  begin
--    if(rising_edge(user_clk))then
--      if(user_rst = '1')then
--        sim_cnt <= (others => '0');
--      elsif(sim_cnt = x"0000_0FFF")then
--        sim_cnt <= (others => '0');
--      elsif(sim_link_done = '1')then
--        sim_cnt <= sim_cnt + 1;
--      else
--        sim_cnt <= (others => '0');
--      end if;
--    end if;
--  end process;

--  process(user_clk)
--  begin
--    if(rising_edge(user_clk))then
--      if(user_rst = '1')then
--        sim_srio_wr_data    <= (others => '0');
--        sim_srio_wr_addr    <= x"0000_0000";
--        sim_srio_wr_en      <= '0';
--        sim_srio_byte_tkeep <= x"FF";
--      elsif(sim_cnt = x"0000_0FFF")then
--        sim_srio_wr_data    <= x"11223344556677888877665544332211";
--        sim_srio_wr_addr    <= x"1080_2400";
--        sim_srio_wr_en      <= '1';
--        sim_srio_byte_tkeep <= x"FF";
--      else
--        sim_srio_wr_data    <= (others => '0');
--        sim_srio_wr_addr    <= x"0000_0000";
--        sim_srio_wr_en      <= '0';
--        sim_srio_byte_tkeep <= x"FF";
--      end if;
--    end if;
--  end process;

--  process(user_clk)
--  begin
--    if(rising_edge(user_clk))then
--      if(user_rst = '1')then
--        sim_ack_rd_data_valid <= '0';
--        sim_ack_rd_data       <= (others => '0');
--      elsif(sim_ack_rd_en = '1')then
--        sim_ack_rd_data_valid <= '1';
--        sim_ack_rd_data       <= x"aabbccdd11223344";
--      elsif(sim_ack_rd_en_dly = '1')then
--        sim_ack_rd_data_valid <= '1';
--        sim_ack_rd_data       <= x"55667788aabbccdd";
--      else
--        sim_ack_rd_data_valid <= '0';
--        sim_ack_rd_data       <= (others => '0');
--      end if;
--    end if;
--  end process;

--  process(user_clk)
--  begin
--    if(rising_edge(user_clk))then
--      if(user_rst = '1')then
--        sim_ack_rd_en_dly <= '0';
--      else
--        sim_ack_rd_en_dly <= sim_ack_rd_en;
--      end if;
--    end if;
--  end process;
  
end RTL;
