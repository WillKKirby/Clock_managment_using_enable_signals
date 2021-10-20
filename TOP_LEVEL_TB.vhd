library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TOP_LEVEL_TB is
end TOP_LEVEL_TB;

-- This test bench tests the circuit from the STUDENT_AREA.
-- It has the known good values for the first 3 tests in the below array.
-- It will trigger an enable and check the responces in the two test processes.

architecture Behavioral of TOP_LEVEL_TB is

-- Constants 
constant disp_delay : integer := 30; 
-- I choose 8ns for the clk_period since it will be enough got a 125MHz clk.
constant clk_period : time := 8ns;

-- Inputs
signal GCLK : std_logic;
signal BTN  : std_logic_vector(3 downto 0);
signal SW   : std_logic_vector(1 downto 0);
-- Output
signal LED  : std_logic_vector(3 downto 0);

-- Array of known good values for the first 3 outputs for self checking.
type int_vector is array (natural range<>) of std_logic_vector(3 downto 0);
constant known_good_answers : int_vector := (
    ("0100"),("1000"),("0000"),("0000"),("1100"),("0000"),("0000"),("1011"),
    ("0000"),("0000"),("0000"),("0000"),("1100"),("1010"),("0101"),("1111"),
    ("0000"),("0000"),("0000"),("0000"),("0101"),("0111"),("0000"),("1110") );

begin

UUT : entity work.TOP_LEVEL
GENERIC MAP ( disp_delay => disp_delay )
PORT MAP ( GCLK => GCLK,
           BTN => BTN,
           SW => SW,
           LED => LED );
            
-- Clk Process
clk_process : process
begin
    GCLK <= '1';
    wait for clk_period/2;
    GCLK <= '0';
    wait for clk_period/2;
end process clk_process;

-- Pushing inputs to the circuit.

Input_Process : process
begin
    
    -- Wait for initalisation
    wait for 200ns;
    wait until falling_edge(GCLK);
    
    -- Inital input values
    SW <= "00";
    
    -- To trigger the inital reset the first button needs to be pressed
    -- For the reset, it is the LSB of the BTN vector. 
    BTN <= "0001";
    wait for clk_period/2;
    BTN <= "0000";
    wait for clk_period/2;
    BTN <= "0001";
    wait for clk_period*2;
    BTN <= "0000";
    
    -- This will loop three times and trigger an enable each time. 
    for i in 0 to 2 loop
    
        -- Test the first 3 passes of inputs
        BTN <= "0100";
        wait for clk_period*2;
        BTN <= "0000"; 
        
        -- This value was choosen to allow the working to finsih, 
        --   and also have a short gap between the next. 
        wait for clk_period * 250;
        
    end loop;
    
    -- Then I will reset the circuit and run 1 more to check the values are again correct 
    
    BTN <= "0001";
    wait for clk_period*2;
    BTN <= "0000";
    wait for clk_period;
    
    -- Test the first 3 passes of inputs
    BTN <= "0100";
    wait for clk_period*2;
    BTN <= "0000"; 
        
    wait;
end process Input_Process;

-- Check for the outputs of the circuit. 

Test_Process : process

-- For checking the output, I run through the list of known good values.
-- Whenever a set (being the 8 nibbles) is complete it will then jump
--   to the beginning of the next set with a short delay. 


begin
    -- Again wait for all the same wait until the outputs start
    wait for 200ns;
    wait until falling_edge(GCLK); 
    
    -- delay to get to to the same place as the circuit above
    wait for clk_period*6;

    for i in known_good_answers'range loop
        
        -- Self checking statments for the outputs against the known good values. 
        assert (LED = known_good_answers(i))
        report " Test failed. Test ID: " & integer'image(i) & " Known good: " & integer'image(to_integer(unsigned(known_good_answers(i))))
         & " ~ Test Value: " & integer'image(to_integer(unsigned(LED)))
        severity error;
        
        assert (not(LED = known_good_answers(i)))
        report " Test passed. Test ID: " & integer'image(i) & " Known good: " & integer'image(to_integer(unsigned(known_good_answers(i)))) 
         & " ~ Test Value: " & integer'image(to_integer(unsigned(LED)))
        severity note;
        
        -- (not sure how good practice it is to have logic in the test bench)
        -- This logic statment checks if it is at the end of a set (7 or 15)
        -- If it is then it will jump 70 for the next set.
        -- If it isn't then 40 clk_periods ahead is where the next output value is.
        if (i = 7 or i = 15) then
            wait for clk_period*(disp_delay+5);
        else
            wait for clk_period*(disp_delay+1);
        end if;
        
    end loop;
    
    -- Checking the output after the reset
    wait for clk_period*7;
    
    for i in 0 to 7 loop
    
        assert (LED = known_good_answers(i))
        report " Test failed. Test ID: " & integer'image(i) & " Known good: " & integer'image(to_integer(unsigned(known_good_answers(i))))
         & " ~ Test Value: " & integer'image(to_integer(unsigned(LED)))
        severity error;
        
        assert (not(LED = known_good_answers(i)))
        report " Test passed. Test ID: " & integer'image(i) & " Known good: " & integer'image(to_integer(unsigned(known_good_answers(i)))) 
         & " ~ Test Value: " & integer'image(to_integer(unsigned(LED)))
        severity note;
        
        wait for clk_period*(disp_delay+1);
        
    end loop;
    
    wait;
end process Test_Process;

    
end Behavioral;
