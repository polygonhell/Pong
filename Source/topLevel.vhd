library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--library UNISIM;
--use UNISIM.VComponents.all;

entity topLevel is
    Port ( sys_clk : in  STD_LOGIC;
			  tx : out STD_LOGIC;
			  led: out STD_LOGIC_VECTOR (7 downto 0);
			  joy_left : in STD_LOGIC;
			  joy_right : in STD_LOGIC;
           vga_vsync : out  STD_LOGIC;
           vga_hsync : out  STD_LOGIC;
           vga_red : out  STD_LOGIC_VECTOR (2 downto 0);
           vga_green : out  STD_LOGIC_VECTOR (2 downto 0);
           vga_blue : out  STD_LOGIC_VECTOR (1 downto 0));

end topLevel;

architecture Behavioral of topLevel is

	component clock
	port(
		CLK_IN1           : in     std_logic;
		CLK_OUT1          : out    std_logic
	 );
	end component;
	
	signal clk : std_logic;

	COMPONENT VGASyncGen
	PORT(
		clk : IN std_logic;
		X : OUT unsigned (9 downto 0);
		Y : OUT unsigned (8 downto 0);    
		active : OUT std_logic;
		HSync : OUT std_logic;
		VSync : OUT std_logic
		);
	END COMPONENT;
	
	signal VGAActive : std_logic;
	signal VGAXPos : unsigned (9 downto 0);
	signal VGAYPos : unsigned (8 downto 0);
	
	signal r, g, b : unsigned (2 downto 0);
	
	signal paddlePosition : unsigned (9 downto 0) := to_unsigned(256, 10);
	constant paddlePositionMax : unsigned (9 downto 0) := to_unsigned(512, 10);
	signal ballX : unsigned (9 downto 0) := to_unsigned(256, 10);
	signal ballY : unsigned (8 downto 0) := to_unsigned(256, 9);
	signal ballXDir : Boolean := false;
	signal ballYDir : Boolean := false;
	signal collisionX1 : Boolean := false;
	signal collisionX2 : Boolean := false;
	signal collisionY1 : Boolean := false;
	signal collisionY2 : Boolean := false;
	signal collisionObject : Boolean := false;
	signal resetCollision : Boolean := false;

	signal UpdateTime : Boolean;
	
	signal border : unsigned (2 downto 0);
	signal paddle : unsigned (2 downto 0);
	signal ball : unsigned (2 downto 0);
	
	
	
-- Main State machine variables
	type fsmState is (delayStart,  printSomething);
	signal state : fsmState := delayStart;
	constant initialDelayCount : integer := 32000000;
	signal delayCount : integer range 0 to initialDelayCount := initialDelayCount;

begin
	led(7 downto 3) <= "11111";
	led(0) <= joy_right;
	led(1) <= joy_left;
	led(2) <= '1' when collisionObject = true else '0';

	-- Move the Paddle
	process(clk) begin
		if rising_edge (clk) then
			if updateTime then
				if paddlePosition /= paddlePositionMax and joy_right = '0' then
					paddlePosition <= paddlePosition+1;
				elsif paddlePosition /= 0 and joy_left = '0' then
					paddlePosition <= paddlePosition-1;
				end if;
			end if;
		end if;
	end process;
	

	
	process(clk) begin
		if rising_edge(clk) then
			if UpdateTime then
				if (ballXDir) then 
					ballX <= ballX + 1;
				else
					ballX <= ballX + ("11"&X"FF") ;	-- -1
				end if;
				if (ballYDir) then 
					ballY <= ballY + 1;
				else
					ballY <= ballY + ("1"&X"FF");	-- -1
				end if;
				
				if (collisionX1) then ballXDir <= true;
				elsif (collisionX2) then ballXDir <= false; end if;

				if (collisionY1) then ballYDir <= true;
				elsif (collisionY2) then ballYDir <= false; end if;
			end if;
		end if;
	end process;
	

	
	
	
	
	-- Draw the border
	with  (VGAXpos(9 downto 3)=0) or 
			(VGAXpos(9 downto 3)=79) or 
			(VGAYpos(8 downto 3)=0) or 
			(VGAYpos(8 downto 3)=59) select border <= 
		"111" when true,
		"000" when others;
	-- And the Paddle
	with (VGAXpos >= paddlePosition+8) and 
		  (VGAXpos <= paddlePosition+120) and
		  (VGAYpos(8 downto 4) = 27) select paddle <=
		"111" when true,
		"000" when others;
		
	--- And the Ball
	with unsigned(signed(VGAXpos) - signed(ballX)) < 16 and 
		  unsigned(signed(VGAYpos) - signed(ballY)) < 16 select ball <=
		"111" when true,
		"000" when others;
		
	r <= border or paddle or ball;
	g <= border or paddle or ball;
	b <= border or paddle or ball;
	
	-- And the ball
	-- Set the collition flags
	collisionObject <= (paddle or border) /= "000"; 
	process(clk) begin
		if rising_edge(clk) then
			collisionX1 <= (not resetCollision) and 
				(collisionX1 or (collisionObject and VGAXPos = ballX and VGAYPos = ballY+8));
			collisionX2 <= (not resetCollision) and 
				(collisionX2 or (collisionObject and VGAXPos = ballX+16 and VGAYPos = ballY+8));
			collisionY1 <= (not resetCollision) and 
				(collisionY1 or (collisionObject and VGAXPos = ballX+8 and VGAYPos = ballY));
			collisionY2 <= (not resetCollision) and 
				(collisionY2 or (collisionObject and VGAXPos = ballX+8 and VGAYPos = ballY+16));
		end if;
	end process;
	
	-- reset the collision flags
	process(clk) begin
		if rising_edge(clk) then
			resetCollision <= false;
			if updateTime then
				resetCollision <= true;
			end if;
		end if;
	end process;
			
	process(clk) begin
		if rising_edge(clk) then
			updateTime <= false;
			if VGAXPos = 1 and VGAYPos = 1 then
				updateTime <= true;
			end if;
		end if;
	end process;

			

	
	process (clk) 
		variable mask : unsigned (2 downto 0);
		variable blueOut : std_logic_vector (2 downto 0);
	begin
		if rising_edge(clk) then
			mask := (others => VGAActive);
			vga_red <= std_logic_vector(r and mask);
			vga_green <= std_logic_vector(g and mask);		
			blueOut := std_logic_vector(b and mask);
			vga_blue <= blueOut(2 downto 1);		
		end if;
	end process;


	mainClock : clock port map( CLK_IN1 => sys_clk, CLK_OUT1 => clk );
   

	Inst_VGASyncGen: VGASyncGen PORT MAP(
		clk => clk,
		active => VGAActive,
		X => VGAXPos,
		Y => VGAYPos,
		HSync => vga_hsync,
		VSync => vga_vsync 
	);
		

end Behavioral;

