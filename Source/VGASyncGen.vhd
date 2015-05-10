library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--library UNISIM;
--use UNISIM.VComponents.all;

entity VGASyncGen is
    Port ( clk : in  STD_LOGIC;
           active : out  STD_LOGIC;
           X : out unsigned (9 downto 0);
           Y : out unsigned (8 downto 0);
           HSync : out  STD_LOGIC;
           VSync : out  STD_LOGIC);
end VGASyncGen;

architecture Behavioral of VGASyncGen is


	signal Xpos : integer range 0 to 799 := 0;
	signal Ypos : integer range 0 to 524 := 0;
	
	

begin

	main_proc : process(clk) begin
		if rising_edge(clk) then
			if Xpos = 799 then 
				Xpos <= 0;
				if Ypos = 524 then
					Ypos <= 0;
				else 
					Ypos <= Ypos + 1;
				end if;
			else
				Xpos <= Xpos + 1;		
			end if;
			
			VSync <= '1';
			HSync <= '1';
			
			if Ypos >= 490 and Ypos < 492 then
				VSync <= '0';
			end if;
			
			if Xpos >=656 and Xpos < 752 then
				HSync <= '0';
			end if;
			
			active <= '0';
			if Xpos < 640 and Ypos < 480 then
				active <= '1';
				X <= to_unsigned (Xpos, X'length);
				Y <= to_unsigned (Ypos, Y'length);
			end if;
			
		end if;
	end process;

end Behavioral;

