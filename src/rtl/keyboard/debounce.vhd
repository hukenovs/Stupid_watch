--------------------------------------------------------------------------------
--
--   FileName:         debounce.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 32-bit Version 11.1 Build 173 SJ Full Version
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
--   Version 1.0 3/26/2012 Scott Larson
--     Initial Public Release
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

entity debounce is
    generic(
        counter_size : integer		--! counter size (19 bits gives 10.5ms with 50MHz clock)
    );                                  
    port(                               
        clk     : in  std_logic;  	--! input clock
        button  : in  std_logic;  	--! input signal to be debounced
        result  : out std_logic		--! debounced signal
    ); 
end debounce;

architecture debounce of debounce is 

signal flipflops    : std_logic_vector(1 downto 0); --input flip flops
signal counter_set  : std_logic;                    --sync reset to zero
signal counter_out  : std_logic_vector(counter_size downto 0) := (others => '0'); --counter output 

begin

counter_set <= flipflops(0) xor flipflops(1);   --determine when to start/reset counter

pr_deb: process(clk)
begin
    if (clk'event and clk = '1') then
        flipflops(0) <= button;
        flipflops(1) <= flipflops(0);
        if (counter_set = '1') then                  --reset counter because input is changing
            counter_out <= (others => '0');
        elsif (counter_out(counter_size) = '0') then --stable input time is not yet met
            counter_out <= counter_out + 1;
        else                                         --stable input time is met
            result <= flipflops(1);
        end if;    
    end if;
end process; 

end debounce;