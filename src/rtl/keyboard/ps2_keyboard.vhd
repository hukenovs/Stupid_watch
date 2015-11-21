--------------------------------------------------------------------------------
--
--   FileName:         ps2_keyboard.vhd
--   Dependencies:     debounce.vhd
--   Design Software:  Quartus II 32-bit Version 12.1 Build 177 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 11/25/2013 Scott Larson
--     Initial Public Release
--    
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity ps2_keyboard is
    generic(
        clk_freq     : integer; 							--! system clock frequency in Hz
        db_cnt_size  : integer								--! set such that (2^size)/clk_freq = 5us (size = 8 for 50MHz)
    );         		                                           
    port(													   
        clk          : in  std_logic;                     	--! system clock
        ps2_clk      : in  std_logic;                     	--! clock signal from PS/2 keyboard
        ps2_data     : in  std_logic;                     	--! data signal from PS/2 keyboard
        ps2_code_new : out std_logic;                     	--! new PS/2 code is available
        ps2_code     : out std_logic_vector(7 downto 0)		--! code received from PS/2
    ); 	
end ps2_keyboard;

architecture ps2_keyboard of ps2_keyboard is

signal sync_ffs      : std_logic_vector(1 downto 0);       	-- synchronizer flip-flops for ps/2 signals
signal ps2_clk_int   : std_logic;                          	-- debounced clock signal from ps/2 keyboard
signal ps2_data_int  : std_logic;                          	-- debounced data signal from ps/2 keyboard
signal ps2_word      : std_logic_vector(10 downto 0);      	-- stores the ps2 data word
signal error         : std_logic;                          	-- validate parity, start, and stop bits
signal count_idle    : integer range 0 to clk_freq/18_000; 	-- counter to determine ps/2 is idle
  
  --declare debounce component for debouncing PS2 input signals
component debounce is
    generic(
        counter_size : integer		-- Counter size (19 bits gives 10.5ms with 50MHz clock)
    ); 
    port(
        clk     : in  std_logic;  	-- Input clock
        button  : in  std_logic;  	-- Input signal to be debounced
        result  : out std_logic		-- Debounced signal
    ); 
end component;
  
begin
--synchronizer flip-flops
pr_clk: process(clk)
begin
    if (clk'event and clk = '1') then  	  -- rising edge of system clock
        sync_ffs(0) <= ps2_clk;           -- synchronize ps/2 clock signal
        sync_ffs(1) <= ps2_data;          -- synchronize ps/2 data signal
    end if;
end process;

--debounce PS2 input signals
debounce_ps2_clk: debounce
generic map(counter_size => db_cnt_size)
port map(clk => clk, button => sync_ffs(0), result => ps2_clk_int);

debounce_ps2_data: debounce
generic map(counter_size => db_cnt_size)
port map(clk => clk, button => sync_ffs(1), result => ps2_data_int);

--input PS2 data
pr_int: process(ps2_clk_int)
begin
    if (ps2_clk_int'event and ps2_clk_int = '0') then    --falling edge of ps2 clock
        ps2_word <= ps2_data_int & ps2_word(10 downto 1);   --shift in ps2 data bit
    end if;
end process;
    
--verify that parity, start, and stop bits are all correct
error <= NOT (NOT ps2_word(0) AND ps2_word(10) AND (ps2_word(9) XOR ps2_word(8) XOR
		ps2_word(7) XOR ps2_word(6) XOR ps2_word(5) XOR ps2_word(4) XOR ps2_word(3) XOR 
		ps2_word(2) XOR ps2_word(1)));  

  --determine if PS2 port is idle (i.e. last transaction is finished) and output result
pr_ps2:  process(clk)
begin
    if (clk'event and clk = '1') then                   --rising edge of system clock
        if (ps2_clk_int = '0') then                     --low ps2 clock, ps/2 is active
            count_idle <= 0;                            --reset idle counter
        elsif(count_idle /= clk_freq/18_000) then       --ps2 clock has been high less than a half clock period (<55us)
            count_idle <= count_idle + 1;               --continue counting
        end if;

        if(count_idle = clk_freq/18_000 and error = '0') then  --idle threshold reached and no errors detected
            ps2_code_new <= '1';                               --set flag that new ps/2 code is available
            ps2_code <= ps2_word(8 downto 1);                  --output new ps/2 code
        else                                                   --ps/2 port active or error detected
            ps2_code_new <= '0';                               --set flag that ps/2 transaction is in progress
        end if; 
    end if;
end process;
  
end ps2_keyboard;