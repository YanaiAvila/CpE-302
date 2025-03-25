--------------------------------------------------------------------------------------------------------------
-- Library Declaration ---------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------------------------------------
-- Match Game Entity (Port Declarations) ---------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
entity match_game is
	port(
	clk, reset, LFSR_generate        : in std_logic;
	color_guess_1, color_guess_2     : in std_logic_vector(1 downto 0); -- vector 2 bits for color guesses
	color_guess_3, color_guess_4     : in std_logic_vector(1 downto 0);
		
	guess_segs_1, guess_segs_2       : out std_logic_vector(6 downto 0); -- vector 7 bits for 7-segment display
	guess_segs_3, guess_segs_4       : out std_logic_vector(6 downto 0); -- vector 7 bits for 7-segment display
			
	rng_segs_1, rng_segs_2       : out std_logic_vector(6 downto 0); -- vector 7 bits for 7-segment display
	rng_segs_3, rng_segs_4       : out std_logic_vector(6 downto 0)); -- vector 7 bits for 7-segment display
																   
	-- For VGA output --> Note: Was not able to get this part to work (future improvement)
	--red_out : out std_logic_vector(9 downto 0);
	--green_out : out std_logic_vector(9 downto 0);
	--blue_out : out std_logic_vector(9 downto 0);
	--hs_out : out std_logic;
	--clk25_out : out std_logic;
	--sync : out std_logic;
	--blank : out std_logic;
	--vs_out : out std_logic);

	--points!!
end match_game;  



--------------------------------------------------------------------------------------------------------------
-- Match Game Architecture Body ------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
architecture Behavioral of match_game is
--------------------------------------------------------------------------------------------------------------
-- Components ------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

-- used for displaying values on seven segments
 component seven_seg
	port(
		value_in : in std_logic_vector(3 downto 0);
		value_out : out std_logic_vector(6 downto 0));
end component; 

-- used to generate a random 8 bit number (sequence)
component LFSR
    port( 
		clk : in std_logic;
		reset : in std_logic;
		generate_num : in std_logic;
		rand_num : out std_logic_vector(7 downto 0));
end component; 

-- used to process the generated sequence or user input sequence for 7 segment display to take
component chooseSequence
    port( 
		color_1, color_2, color_3, color_4 : in std_logic_vector(1 downto 0); 
		color_1_out, color_2_out, color_3_out, color_4_out : out std_logic_vector(3 downto 0);
		sequence_guess : out std_logic_vector(7 downto 0));  -- concatination of all proccessed guesses
end component;	
	
-- used to compare the randomly generated sequence to the sequence the user inputs
component compareSequences
    Port( 
		clk, reset : in std_logic;
		sequence_guess, sequence_generated : in std_logic_vector(7 downto 0);
		points_earned : out std_logic);
end component;   

-- used to display the colors on a VGA monitor
-- Note: Was not able to get this part to work (future improvement)
component PlusSign
	port(
		clk50_in : in std_logic; 
		rng_color: in std_logic_vector(1 downto 0);
		red_out : out std_logic_vector(9 downto 0);
		green_out : out std_logic_vector(9 downto 0);
		blue_out : out std_logic_vector(9 downto 0);
		hs_out : out std_logic;
		clk25_out : out std_logic;
		sync : out std_logic;
		blank : out std_logic;
		vs_out : out std_logic);
end component;


--------------------------------------------------------------------------------------------------------------
-- Signals ---------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
signal clk_1, alarm_signal, result : std_logic; --1 bit value used for reduced clock, signaling the alarm, and LED sequence

signal guess_1_proccessed, guess_2_proccessed : std_logic_vector(3 downto 0);
signal guess_3_proccessed, guess_4_proccessed : std_logic_vector(3 downto 0);
signal rng_1_proccessed, rng_2_proccessed : std_logic_vector(3 downto 0);
signal rng_3_proccessed, rng_4_proccessed : std_logic_vector(3 downto 0);
		
signal chosen_sequence: std_logic_vector(7 downto 0);

signal rng_sequence: std_logic_vector(7 downto 0);	
signal rng_sequence2: std_logic_vector(7 downto 0);	

signal seq_snip: std_logic_vector(1 downto 0); -- input to vga module

signal points_earned: std_logic;


-- Main
begin	

	-- Takes in input from user and processes it
	process_chosen_sequence: chooseSequence port map(color_guess_1, color_guess_2, color_guess_3, color_guess_4,
							guess_1_proccessed, guess_2_proccessed, guess_3_proccessed, 
							guess_4_proccessed, chosen_sequence);

	-- Displays the user input onto the 4 rightmost 7-segment displays
	seven_seg1: seven_seg port map(guess_1_proccessed, guess_segs_1);
	seven_seg2: seven_seg port map(guess_2_proccessed, guess_segs_2);
	seven_seg3: seven_seg port map(guess_3_proccessed, guess_segs_3);
	seven_seg4: seven_seg port map(guess_4_proccessed, guess_segs_4);

	-- Generates a random 8-bit number
	generate_rand_seq: LFSR port map(clk, reset, LFSR_generate, rng_sequence);	
 
	-- Takes in the 8-bit number and processes it
	process_rng_sequence: chooseSequence port map(rng_sequence(7 downto 6), rng_sequence(5 downto 4),
								rng_sequence(3 downto 2), rng_sequence(1 downto 0),
								rng_1_proccessed, rng_2_proccessed, rng_3_proccessed, 
								rng_4_proccessed, rng_sequence2);		

	-- Displays the random number onto the 4 leftmost 7-segment displays										  									
	seven_seg5: seven_seg port map(rng_1_proccessed, rng_segs_1);
	seven_seg6: seven_seg port map(rng_2_proccessed, rng_segs_2);
	seven_seg7: seven_seg port map(rng_3_proccessed, rng_segs_3);
	seven_seg8: seven_seg port map(rng_4_proccessed, rng_segs_4);	  

	--VGA: PlusSign port map(clk, "11", red_out, green_out, blue_out, hs_out, clk25_out, sync, blank, vs_out);

	--  Compares the RNG sequence and the user sequence
	compare: compareSequences port map(clk, reset, chosen_sequence, rng_sequence, points_earned);
end Behavioral;	
		
		
--------------------------------------------------------------------------------------------------------------
-- LFSR that randomly generates a 8-bit value which will be used for the sequence of colors
--------------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LFSR is
    Port(
		clk : in std_logic;
		reset : in std_logic;
		generate_num : in std_logic;
		rand_num : out std_logic_vector(7 downto 0));
end LFSR;	  


architecture Behavioral of LFSR is	
-- signals-----
-- XOR of tap bits/positions
signal feedback: std_logic;	 
-- current combination of numbers(current random number)
signal currentCombo: std_logic_vector(7 downto 0) := "11001010";
					   
begin
	process(clk, reset)
	begin 
		-- feedback is xor of bits 4, 13, 15 and 16
		feedback <= (currentCombo(1) xor currentCombo(2) xor currentCombo(3) xor currentCombo(7));
		
		if(reset = '1') then
			currentCombo <= "00000001"; -- don't want this to be 0 
		-- at rising edge
		elsif(clk'event and clk='1') then	 
			-- shift current combination to the right and make the feedback signal the first bit			
			currentCombo <= feedback & currentCombo(7 downto 1);	 
		end if;
	end process;

	-- When pushbutton is pressed
	process(generate_num)	 
	begin	
		-- if reset, random_num set to 0
		if (reset = '1') then
			rand_num <= "00000000";
		-- else random_num(output) gets currentCombo
		else rand_num <= currentCombo;
		end if;
	end process;
end Behavioral;


--------------------------------------------------------------------------------------------------------------
-- Lookup table that allows the user to input their guess and see it on the 7 segment displays
-- (also used for generated number processing)
--------------------------------------------------------------------------------------------------------------										   
-- 00 will be Blue (8)
-- 01 will be Green (6)
-- 10 will be Purple (P)
-- 11 will be Yellow (y)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity chooseSequence is
    Port(
		color_1, color_2, color_3, color_4 : in std_logic_vector(1 downto 0); 
		color_1_out, color_2_out : out std_logic_vector(3 downto 0);
		color_3_out, color_4_out : out std_logic_vector(3 downto 0);
		sequence_guess : out std_logic_vector(7 downto 0));  -- concatination of all proccessed guesses
end chooseSequence;	  


architecture Behavioral of chooseSequence is	
begin
	process(color_1, color_2, color_3, color_4)
	begin  
		-- case for color guessed 1
		case(color_1) is
			when "00" => color_1_out <= "0000"; --B (8)
			when "01" => color_1_out <= "0001"; --G (6)
			when "10" => color_1_out <= "0010"; --P
			when "11" => color_1_out <= "0011"; --Y
			when others => color_1_out <= "1111";
		end case;  
		
		-- case for color guessed 2
		case(color_2) is
			when "00" => color_2_out <= "0000"; --B (8)
			when "01" => color_2_out <= "0001"; --G (6)
			when "10" => color_2_out <= "0010"; --P
			when "11" => color_2_out <= "0011"; --Y
			when others => color_2_out <= "1111";
		end case; 
		
		-- case for color guessed 3
		case(color_3) is
			when "00" => color_3_out <= "0000"; --B (8)
			when "01" => color_3_out <= "0001"; --G (6)
			when "10" => color_3_out <= "0010"; --P
			when "11" => color_3_out <= "0011"; --Y
			when others => color_3_out <= "1111";
		end case; 
		
		-- case for color guessed 4
		case(color_4) is
			when "00" => color_4_out <= "0000"; --B (8)
			when "01" => color_4_out <= "0001"; --G (6)
			when "10" => color_4_out <= "0010"; --P
			when "11" => color_4_out <= "0011"; --Y
			when others => color_4_out <= "1111";
		end case; 

		-- Combines all guesses into 1 vector
		sequence_guess <= color_4 & color_3 & color_2 & color_1;
	end process;
end Behavioral;


--------------------------------------------------------------------------------------------------------------
-- Comparator to compare the RNG sequence and the sequence that the user inputted
--------------------------------------------------------------------------------------------------------------	
	library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;

	entity compareSequences is
		Port(
			clk, reset : in std_logic;
			sequence_guess, sequence_generated : in std_logic_vector(7 downto 0);
			points_earned : out std_logic);
	end compareSequences;  


	architecture Behavioral of compareSequences is	
	begin  	
		process(clk)  
		begin
		-- points <= 0;
			if(sequence_guess = sequence_generated) then
				points_earned <= '1';
			else points_earned <= '0';
			end if;
	end process;
end Behavioral;


---------------------------------------------------------------------------------------------------------------
-- Entity used for displaying values on a 7 segment display
---------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
entity seven_seg is
	port(
		value_in : in std_logic_vector(3 downto 0);
		value_out : out std_logic_vector(6 downto 0));
end seven_seg;

architecture Behavioral of seven_seg is
begin
	process(value_in)
	begin
		case(value_in) is
			when "0000" => value_out <= "0000000"; --B
			when "0001" => value_out <= "0000010"; --G
			when "0010" => value_out <= "0001100"; --P
			when "0011" => value_out <= "0010001"; --Y
			when "0100" => value_out <= "0011001"; --4
			when "0101" => value_out <= "0010010"; --5
			when "0110" => value_out <= "0000010"; --6
			when "0111" => value_out <= "1111000"; --7
			when "1000" => value_out <= "0000000"; --8
			when "1001" => value_out <= "0010000"; --9
			when "1010" => value_out <= "0001000"; --a
			when "1011" => value_out <= "0000011"; --b
			when "1100" => value_out <= "1000110"; --c
			when "1101" => value_out <= "0100001"; --d
			when "1110" => value_out <= "0000110"; --e
			when others => value_out <= "0001110";
		end case;
	end process;
end Behavioral;

-- segment encoding
--      0
--     ---  
--  5 |   | 1
--     ---   <- 6
--  4 |   | 2
--     ---
--      3
