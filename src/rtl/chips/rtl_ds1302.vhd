-------------------------------------------------------------------------------
--
-- Title       : rtl_ds1302
-- Author      : Alexander Kapitanov
-- Company     : Instrumental Systems
-- E-mail      : kapitanov@insys.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description :	There is a serial interface controller for ds1302 chip.
-- 					Serial interface has 3 ports (i/o, clk, enable).
--					User interface has 4 ports:
--						data_i - input data, from fpga to chip,
--						data_o - output data, from chip to fpga,
--						addr_i - sets address for read/write,
--						enable - start of operation.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity rtl_ds1302 is
	generic ( 
		TD				: in time;								--! simulation time;
		DIV_SCL			: in integer							--! clock division for SCL: clk50m/DIV_SCL
		);                                                          
	port(                                                           
		-- global ports                                             
		clk50m			: in     std_logic;  					--! system frequency (50 MHz)                
		rstn			: in     std_logic;	 					--! negative reset
		-- main interface                                           
		enable			: in     std_logic;						--! serial start (S)
		addr_i			: in	 std_logic_vector(7 downto 0);	--! address Tx: 7 bit - always '1', 0 bit - R/W ('0' - write, '1' - read)
		data_i			: in	 std_logic_vector(7 downto 0);	--! data (Tx)
		data_o			: out	 std_logic_vector(7 downto 0);	--! data (Rx)               
		data_v			: out	 std_logic;						--! valid Rx
                                                                    
		ready			: out	 std_logic;						--! ready for data                               
		-- serial interface                                         
		ds_data_i		: in	 std_logic;						--! serial data input
		ds_data_o		: out	 std_logic;						--! serial data output
		ds_data_t		: out	 std_logic;						--! serial data enable
		                                                            
		ds_clk			: out	 std_logic;						--! serial clock
		ds_ena			: out	 std_logic						--! clock enable for i2c		
		);  
end rtl_ds1302;

architecture rtl_ds1302 of rtl_ds1302 is


type fsm_serial is (	RDY, START, WAITING, DATA, ADDR,
						CLK_RISE, CLK_FALL, CLK_ONE,  
						WRITE, CLK_WR_R, CLK_WR1, CLK_WR_F,
						CLK_RD_R, CLK_RD1, CLK_RD_F, STOP);
					
signal STM : fsm_serial; 

signal dat_s	: std_logic;
signal dat_e	: std_logic;
signal clk_s	: std_logic;

signal clk_r	: std_logic;
signal clk_f	: std_logic;
signal clk_z	: std_logic;

signal cnt		: std_logic_vector(3 downto 0);
signal reg_iic	: std_logic_vector(7 downto 0);	
signal reg_in	: std_logic_vector(7 downto 0);

signal clk_low	: std_logic;
signal scl_cnt 	: integer range 0 to DIV_SCL:=0;

signal rdwr		: std_logic;
signal data_b	: std_logic;

signal data_vl	: std_logic;

-- delete this:
--signal ena_cnt	: std_logic_vector(12 downto 0);
--signal ena_stw	: std_logic;
--signal ena_vld	: std_logic:='0';
--signal ena_stwz	: std_logic;
--signal ena_stwx	: std_logic;

begin	  
	
-- test ce inactive time:
--ena_vld <= '1' when (enable = '1') else '0' when (data_vl = '1');
--pr_ce_inactive: process(clk50m, rstn) is
--begin
--	if (rstn = '0') then
--		ena_stw <= '0';
--		ena_cnt <= (others => '0');
--	elsif (rising_edge(clk50m)) then
--		if (ena_vld = '1') then
--			if ena_cnt(12) = '0' then
--				ena_stw <= '0' after td;
--				ena_cnt <= ena_cnt + 1 after td;
--			else
--				ena_stw <= '1' after td;
--			end if;
--		else
--			ena_cnt <= (others => '0') after td;
--		end if;
--	end if;
--end process;
--ena_stwz <= ena_stw after td when rising_edge(clk50m);	
--ena_stwx <= (ena_stw and not ena_stwz) after td when rising_edge(clk50m);	

rdwr <= addr_i(0);-- after td when rising_edge(clk);	

-- clk_low generator:
pr_cnt_serial: process(clk50m, rstn) is
begin
	if (rstn = '0') then
		scl_cnt <= 0;
		clk_low <= '0';
	elsif (rising_edge(clk50m)) then
		if (scl_cnt = DIV_SCL) then
			scl_cnt <= 0 after td;
			clk_low <= not clk_low after td;
		else
			scl_cnt <= scl_cnt + 1 after td;
		end if;
	end if;
end process;

-- clk rising/falling
clk_z <= clk_low after td when rising_edge(clk50m);
clk_r <= (not clk_z) and clk_low after td when rising_edge(clk50m);
clk_f <= (not clk_low) and clk_z after td when rising_edge(clk50m);

				
pr_fsm: process(clk50m, rstn) is
begin
	if (rstn = '0') then
		cnt 	<= x"0";
		clk_s 	<= '0';
		dat_s 	<= '0';
		dat_e 	<= '0';
		ds_ena 	<= '0';
		ready 	<= '0';
		reg_iic <= x"00";
		reg_in	<= x"00";
		data_o	<= x"00";
		data_vl	<= '0';
		STM 	<= RDY;
	elsif (rising_edge(clk50m)) then
		case (STM) is
			when RDY =>							
				data_vl	<= '0' after td;			
				ds_ena	<= '0' after td; 
				dat_e 	<= '0' after td;
				--if (ena_stwx = '1') then
				if (enable = '1') then
					STM <= START after td;
				end if;
				if (clk_r = '1') then--(clk_f = '1') then
					--dat_e 	<= '0' after td;
					--ds_ena	<= '0' after td;
					ready	<= '1' after td;
				end if;
			when START =>
				if (clk_r = '1') then
					clk_s	<= '0' after td;    
					reg_iic	<= addr_i after td;
					ready	<= '0' after td;    					
					cnt 	<= x"1" after td;
					ds_ena	<= '1' after td;
					STM 	<= ADDR after td;						
				end if;
			when ADDR => 
				if (clk_f = '1') then
					dat_s 	<= reg_iic(0) after td;	
					dat_e 	<= '0' after td;
					--ds_ena	<= '1' after td;
					STM 	<= CLK_RISE after td;					
				end if;			
			when CLK_RISE => 
				if (clk_r = '1') then
					clk_s 	<= '1' after td;      										   					
					STM 	<= CLK_ONE after td;
				end if;
			when CLK_ONE => 
				if (clk_f = '1') then    										   					
					reg_iic <= '0' & reg_iic(7 downto 1) after td;
					if cnt(3) = '0' then
						cnt 	<= cnt + '1' after td;
						STM 	<= CLK_FALL after td;
					else
						dat_e 	<= rdwr after td;
						--dat_s	<= '0' after td;
						STM 	<= WAITING after td;
					end if;	
				end if;				
			when CLK_FALL => 
				if (clk_r = '1') then
					clk_s 	<= '0' after td;
					STM 	<= ADDR after td;	
				end if;					
			when WAITING => 
				if (clk_r = '1') then
					clk_s <= '0' after td;
					if (rdwr = '0') then
						reg_iic	<= data_i after td;
						reg_in	<= x"00" after td;
						cnt 	<= x"1" after td;
						STM 	<= WRITE after td;
					else
						reg_iic	<= x"00" after td;
						cnt 	<= x"1" after td;
						dat_s	<= '0' after td;
						--dat_e 	<= '1' after td;
						reg_in 	<= data_b & reg_in(7 downto 1) after td;
						STM 	<= CLK_RD_R after td;
					end if;
					
				end if;				  
			when WRITE => 
				if (clk_f = '1') then
					dat_s 	<= reg_iic(0) after td;
					STM 	<= CLK_WR_R after td;
				end if;
			when CLK_WR_R => 
				if (clk_r = '1') then
					clk_s 	<= '1' after td;      										   					
					STM 	<= CLK_WR1 after td;
				end if;				
			when CLK_WR1 => 
				if (clk_f = '1') then    										   					
					reg_iic <= '0' & reg_iic(7 downto 1) after td;
					if cnt(3) = '0' then
						cnt 	<= cnt + '1' after td;
						STM 	<= CLK_WR_F after td;
					else
						--dat_s	<= '0' after td;
						dat_e 	<= '0' after td;
						STM 	<= STOP after td;
					end if;	
				end if;	
			when CLK_WR_F => 
				if (clk_r = '1') then
					clk_s 	<= '0' after td;
					STM 	<= WRITE after td;	
				end if;			
			when CLK_RD_R => 
				if (clk_r = '1') then
					clk_s 	<= '1' after td;      										   					
					STM 	<= CLK_RD1 after td;
				end if;
				if (clk_f = '1') then
					reg_in 	<= data_b & reg_in(7 downto 1) after td;
				end if;
			when CLK_RD1 => 				
				if (clk_f = '1') then    										   					
					--reg_in 	<= data_b & reg_in(7 downto 1) after td;
					if cnt(3) = '0' then
						cnt 	<= cnt + '1' after td;
						STM 	<= CLK_RD_F after td;
					else
						--dat_e 	<= '0' after td;
						STM 	<= STOP after td;	
					end if;	
				end if;
			when CLK_RD_F => 
				if (clk_r = '1') then
					clk_s 	<= '0' after td;
					STM 	<= CLK_RD_R after td;	
				end if;
			when STOP => 				
				if (clk_r = '1') then
					clk_s 	<= '0' after td;
					reg_iic <= x"00" after td;
					reg_in	<= x"00" after td;				
					data_o	<= reg_in after td;
					--data_vl <= '1' after td;
				end if;
				if (clk_f = '1') then
					data_vl <= '1' after td;
					dat_e 	<= '0' after td;
					STM 	<= RDY after td;
				end if;				
			when others => null;
		end case;
	end if;				   
end process;

data_v <= data_vl;	
data_b <= ds_data_i;-- when dat_e = '1';
ds_data_o <= dat_s;-- when dat_e = '0' else '0';
ds_data_t <= dat_e;
ds_clk <= clk_s;

end rtl_ds1302;