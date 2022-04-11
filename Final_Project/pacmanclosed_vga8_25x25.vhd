library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity pacmanclosed_vga8_25x25 is
port (
	clk, en : in std_logic;
	addr : in unsigned(9 downto 0);
	data : out unsigned(27 downto 0));
end pacmanclosed_vga8_25x25;

architecture imp of pacmanclosed_vga8_25x25 is
	type rom_type is array (0 to 624) of unsigned(27 downto 0); -- unused[3]; is_background[1]; R[8]; G[8]; B[8]
	constant ROM : rom_type :=
	(	"0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000",
		"0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000",
		"0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000",
		"0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000",
		"0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000",
		"0001000000000000000000000000","0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000","0001000000000000000000000000",
		"0001000000000000000000000000","0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000","0001000000000000000000000000",
		"0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000",
		"0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000",
		"0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000",
		"0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000",
		"0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000",
		"0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000",
		"0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000",
		"0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000",
		"0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000",
		"0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000",
		"0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000",
		"0001000000000000000000000000","0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000","0001000000000000000000000000",
		"0001000000000000000000000000","0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000","0001000000000000000000000000",
		"0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000",
		"0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000",
		"0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000",
		"0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000",
		"0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0000111111011111111100000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000","0001000000000000000000000000"

);
begin
	process (clk)
	begin
		if rising_edge(clk) then
			if en = '1' then
				if addr <= "1001110000" then 
					data <= ROM(TO_INTEGER(addr)); 
				else
					data <= "0001000000000000000000000000";
				end if;
			else
				data <= "0001000000000000000000000000"; 
			end if;
		end if;
	end process;
end imp;