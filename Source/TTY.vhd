library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity TTY is
    Port ( clk : in  STD_LOGIC;
			  ready: out STD_LOGIC := '1';
			  tx: out STD_LOGIC;
			  data_write : in STD_LOGIC;
           data : in string (1 to 128) );
end TTY;

architecture Behavioral of TTY is

	-- Components
	COMPONENT uart_tx6
	PORT(
		data_in : IN std_logic_vector(7 downto 0);
		en_16_x_baud : IN std_logic;
		buffer_write : IN std_logic;
		buffer_reset : IN std_logic;
		clk : IN std_logic;          
		serial_out : OUT std_logic;
		buffer_data_present : OUT std_logic;
		buffer_half_full : OUT std_logic;
		buffer_full : OUT std_logic
		);
	END COMPONENT;

	-- Signals
	constant baudrate : integer := 9600;
	constant clkRate : integer := 25000000;
	constant baudMax : integer := clkRate/(16*baudrate) - 1;
	
	signal baudCount : integer range 0 to baudMax := 0;
	signal en_16_x_baud : std_logic := '0';
	signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
	signal tx_write : std_logic := '0';
	signal tx_buffer_full : std_logic := '0';
	
	type txFsmState is (waitForData, sendByte);
	signal txState : txFsmState := waitForData;
	
	signal index : integer range 1 to 128 := 1;
	signal dataToPrint : string (1 to 128) := (others => 'C') ;



begin

	baud_rate: process(clk) begin
		if rising_edge(clk) then 
			if baudCount = baudMax then		-- 3000000 @ 96MHz --1000000 @ 144 MHz -- 500000 200Mhz Clock
				baudCount <= 0;
				en_16_x_baud <= '1'; 
			else
				baudCount <= baudCount + 1;
				en_16_x_baud <= '0'; 
			end if;
		end if;
	end process baud_rate;

	main_process: process(clk) 
		variable c : integer range 0 to 255 := 0;
		variable c1 : character := 'A';
	begin
		if rising_edge(clk) then
			tx_write <= '0';
			
			case txState is
				when waitForData =>
					if data_write = '1' then
						dataToPrint <= data;
						txState <= sendByte;
						ready <= '0';
						index <= 1;
					end if;
				when sendByte =>
					c1 := dataToPrint(index);
					c := character'pos(c1);
					if c = 0 or index = 128 then
						ready <= '1';
						txState <= waitForData;
					elsif	tx_buffer_full = '0' then
						tx_data <= std_logic_vector(to_unsigned(c, 8));
						tx_write <= '1';
						index <= index+1;
					end if; 
					
				when others =>
					txState <= waitForData;
			end case;
		end if;
	end process;


	-- Component instances
	Inst_uart_tx6: uart_tx6 PORT MAP(
		data_in => tx_data,
		en_16_x_baud => en_16_x_baud,
		serial_out => tx,
		buffer_write => tx_write,
		buffer_data_present => open,
		buffer_half_full => open,
		buffer_full => tx_buffer_full,
		buffer_reset => '0',
		clk => clk
	);

end Behavioral;

