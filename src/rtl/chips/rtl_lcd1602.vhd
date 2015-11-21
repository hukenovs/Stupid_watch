-------------------------------------------------------------------------------
--
-- Title       : rtl_lcd1602
-- Author      : Alexander Kapitanov
-- Company     : Instrumental Systems
-- E-mail      : kapitanov@insys.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description :	Controller for LCD Display LCD1602				
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity rtl_lcd1602 is
	generic ( 
		TD				: in time;								--! simulation time;                       
		DIV_SCL			: in integer							--! clock division for SCL: clk50m/DIV_SCL 
		);														                                          
	port(														                                          
		-- global ports											                                          
		clk50m			: in     std_logic;  					--! system frequency (50 MHz)              
		rstn			: in     std_logic;	 					--! '0' - negative reset                   
		-- main interface										                                          
		start			: in	 std_logic;						--! start                                  
																                                         
		data_ena		: in     std_logic;						--! data enable	(S)                       
		data_int		: in	 std_logic_vector(7 downto 0);	--! data Tx                                
		data_sel		: in	 std_logic;						--! select: '0' - data, '1' - command      
		data_rw			: in	 std_logic;						--! data write: write - '0', read - '1'	  
																                                          
		lcd_ready		: out	 std_logic;						--! ready for data                              
		lcd_init		: out	 std_logic;						--! lcd initialization complete            
		-- lcd1602 interface									                                          
		lcd_dt			: out	 std_logic_vector(7 downto 0);	--! lcd data	                              
		lcd_en			: out	 std_logic;						--! lcd clock enable                       
		lcd_rw			: out	 std_logic;						--! lcd r/w:	write - '0', read - '1'	      
		lcd_rs			: out	 std_logic						--! lcd set: command - '0', data - '1'					
		);  
end rtl_lcd1602;

architecture rtl_lcd1602 of rtl_lcd1602 is

signal clk_r		: std_logic;
--signal clk_f		: std_logic;
signal clk_z		: std_logic;
                	
signal clk_low		: std_logic;
signal cnt_div 		: integer range 0 to DIV_SCL:=0;

type fsm_stage is (RDY_START, INIT, WAITING, DATA, DATA_WAIT, COM, COM_WAIT);				
signal STM_OP : fsm_stage; 

signal busy			: std_logic;

signal en			: std_logic; 
signal rw			: std_logic; 
signal rs			: std_logic; 
signal dt			: std_logic_vector(7 downto 0); 

signal lcd_cnt		: std_logic_vector(2 downto 0);

signal lcd_initr	: std_logic;

--signal clk_rise		: std_logic;
signal clk_en		: std_logic;

begin

-- clk_div generator:
pr_cnt_div: process(clk50m, rstn) is
begin
	if (rstn = '0') then
		cnt_div <= 0;
		clk_low <= '0';
	elsif (rising_edge(clk50m)) then
		if (cnt_div = DIV_SCL) then
			cnt_div <= 0 after td;
			clk_low <= not clk_low after td;
		else
			cnt_div <= cnt_div + 1 after td;
		end if;
	end if;
end process;

-- clk rising/falling
clk_z <= clk_low after td when rising_edge(clk50m);
clk_r <= (not clk_z) and clk_low after td when rising_edge(clk50m);
--clk_f <= (not clk_low) and clk_z after td when rising_edge(clk50m);

-- lcd_output data
--lcd_initr <= '0' when (rstn = '0') else lcd_cnt(2);	
lcd_init <= lcd_initr after td when rising_edge(clk50m);
lcd_ready <= busy after td when rising_edge(clk50m);

lcd_dt <= dt after td when rising_edge(clk50m);
lcd_en <= en after td when rising_edge(clk50m);
lcd_rw <= rw after td when rising_edge(clk50m);
lcd_rs <= rs after td when rising_edge(clk50m);	 

pr_en_clk: process(clk50m, rstn) is
begin
	if (rstn = '0') then
		en <= '0';	
	elsif (rising_edge(clk50m)) then
		if (clk_en = '1') then
			if (clk_r = '1') then
				en <= not en after td;
			end if;
		else
			en <= '0' after td;	
		end if;
	end if;
end process;

--clk_rise <= (clk_f and (not en)) after td when rising_edge(clk50m);

pr_fsm_operation: process(clk50m, rstn) is
variable cnt1: std_logic_vector(4 downto 0):="00000";
begin
	if (rstn = '0') then
		busy <= '0';
		rs <= '0';
		rw <= '0';
		dt <= x"00";
		clk_en <= '0';
		lcd_initr <= '0';
		lcd_cnt <= "000";
		STM_OP <= RDY_START;
	elsif (rising_edge(clk50m)) then
		case STM_OP is
			when RDY_START =>
				cnt1 := "11111";
				lcd_initr <= '0' after td;
				rs <= '0' after td;
				rw <= '0' after td;	
				lcd_cnt <= "001" after td;
				if ((start = '1') and (clk_r = '1')) then
					STM_OP <= INIT after td;
					clk_en <= '1' after td;
				end if;
			when INIT => 
				if (clk_r = '1') then
					rs <= '0' after td;
					rw <= '0' after td;
					STM_OP <= WAITING after td;
					if lcd_cnt = "001" then
						if (lcd_initr = '0') then
							dt <= x"01" after td;
						else
							dt <= x"00" after td;
						end if;
					elsif lcd_cnt = "010" then
						dt <= x"38" after td;
					elsif lcd_cnt = "011" then
						dt <= x"0C" after td;
					elsif lcd_cnt = "100" then
						dt <= x"06" after td;
					else
						null;
					end if;		
				end if;
			when WAITING =>
				if (clk_r = '1') then
					if lcd_cnt(2) = '1' then
						STM_OP <= DATA after td;
						busy <= '1' after td;
						lcd_initr <= '1' after td;
					else
						lcd_cnt <= lcd_cnt + '1' after td;
						STM_OP <= INIT after td;
					end if;					
				end if;
			when DATA_WAIT =>
				if (clk_r = '1') then
					busy <= '0' after td;
					STM_OP <= COM after td;
				end if;	
			when DATA =>
				if (clk_r = '1') then
					if (data_ena = '1') then
						busy <= '0' after td;
						rs <= '1' after td;
						rw <= data_rw after td;
						dt <= data_int after td;
						STM_OP <= DATA_WAIT after td;
					end if;
				end if;
			when COM_WAIT =>
				if (clk_r = '1') then
					STM_OP <= INIT after td;
				end if;					
			when COM =>
				if (clk_r = '1') then
					if (cnt1 < "11111") then
						cnt1 := cnt1 + 1;
					else
						cnt1 := "00000";
					end if;
					if (cnt1(4) = '0') then
						dt <= "10000000" + cnt1 after td;
					else
						dt <= "10110000" + cnt1 after td;--80H 
					end if;					
					rs <= '0' after td;
					rw <= '0' after td;
					lcd_cnt <= "001" after td;
					STM_OP <= COM_WAIT after td;
				end if;					
			end case;			
		end if;			
end process;
		
end rtl_lcd1602;