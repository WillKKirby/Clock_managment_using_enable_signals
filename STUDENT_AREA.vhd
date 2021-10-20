library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.DigEng.all;

-- This is where your work goes. Of course, you will have to put
--   your own comments in, to describe your work.

entity STUDENT_AREA is
    Generic (disp_delay : natural := 62500000);
    Port ( CLK_125MHZ : in  STD_LOGIC;
           -- Debounced button inputs
           USER_PB : in  STD_LOGIC_VECTOR (3 downto 0);
           -- Board switches (not debounced)
           SWITCHES : in  STD_LOGIC_VECTOR (1 downto 0);
			  -- Board LEDs
           LED_DISPLAY : out  STD_LOGIC_VECTOR (3 downto 0);
			  -- Control signals for the data source
           RST_SOURCE : out  STD_LOGIC;
           EN_SOURCE : out  STD_LOGIC;
           SOURCE_DATA : in  STD_LOGIC_VECTOR (31 downto 0)
		);
end STUDENT_AREA;

architecture Behavioral of STUDENT_AREA is

-- FSM States and Signals.  output
-- My design uses 3 states, 
--   idle       - where it waites until a enable trigger.
--   nibble_up  - where the nibble counter is updated, changing the output.
--   wait_state - where it waits for the parameterizable counter,
--     allowing for the LEDs to show the output for the correct time.
type fsm_states is (idle, nibble_up, wait_state);
signal state, next_state : fsm_states;

-- I/O signals 
-- These allow for a specificed signal from the buttons.
signal en, rst : std_logic;

-- Counter Signals
-- Both counters have an enable and ouput signal. 
signal Param_Counter_en : std_logic;
signal Param_count_out : unsigned (log2(disp_delay)-1 downto 0);
signal Nibble_counter_en : std_logic;
signal Nibble_counter_out : unsigned (2 downto 0);

-- Signals for the output
signal LED_DISPLAY_int : std_logic_vector(3 downto 0);
begin

-- Pulling values from buttons for signals.
-- The state condition is ensure it is ignored if the circuit is running.
en <= USER_PB(2) when state = idle else '0';  -- Button 0
rst <= USER_PB(0);                            -- Button 2

-- Setting output signals from internal ones.
EN_SOURCE <= en; 
RST_SOURCE <= USER_PB(0); 

---------
-- FSM --
---------

-- FSM next state process
next_state_process : process (CLK_125MHZ) is
begin
    if rising_edge(CLK_125MHZ) then
        if rst = '1' then
            state <= idle;
        else
            state <= next_state;
        end if;
    end if;
end process next_state_process;

-- FSM State changes
state_changes : process (state, en, Param_count_out, Nibble_counter_out) is
begin
    case state is
        when idle => 
            if en = '1' then
                next_state <= wait_state;
            else
                next_state <= state;
            end if;
        when nibble_up => 
            next_state <= wait_state;
        when wait_state =>
            if Param_count_out = disp_delay-1 then
                if Nibble_counter_out = 7 then
                    next_state <= idle;
                else 
                    next_state <= nibble_up;
                end if;
            else
                next_state <= state;
            end if;
    end case;
end process state_changes;

-------------------------
-- Combinational Logic -- 
-------------------------

-- Only allow the Param_counter to run while the state is in the wait_state.
Param_Counter_en <= '1' when state = wait_state else '0';

-- This allows the nibble_counter to increment when it is in the nibble_up state,
--   also, it can increment in the idle state is the counter_out is 7.
-- This is due to my transitions jumping stright back to the idle state, 
--   leaving my nibble_counter needing to be reset back to 0.
Nibble_counter_en <= '1' when state = nibble_up else
                     '1' when state = idle and Nibble_counter_out = 7 else
                     '0';

-- This might not be the most pretty way of pushing the output but it works fine.
-- The logic just checks the nibble_counter and as long as the state isn't in idle, 
--   then it will push the correct output nibble from the source_data. 

with Nibble_counter_out select
LED_DISPLAY_int <= SOURCE_DATA(31 downto 28) when  "000",
                   SOURCE_DATA(27 downto 24) when  "001",
                   SOURCE_DATA(23 downto 20) when  "010",
                   SOURCE_DATA(19 downto 16) when  "011",
                   SOURCE_DATA(15 downto 12) when  "100",
                   SOURCE_DATA(11 downto 8) when  "101",
                   SOURCE_DATA(7 downto 4) when  "110",
                   SOURCE_DATA(3 downto 0) when  "111",
                   (others => '0') when others;
                   
LED_DISPLAY <= LED_DISPLAY_int when state /= idle else (others => '0');               

--------------
-- Counters -- 
--------------

-- Parameterizable counter for the display time
Display_counter : entity work.Param_Counter
GENERIC MAP ( LIMIT => disp_delay )
PORT MAP ( clk => CLK_125MHZ,
           rst => rst,
           en => Param_Counter_en,
           count_out => Param_count_out );

-- Counter for the nibble that is being shown
Nibble_counter : entity work.Param_Counter
GENERIC MAP (LIMIT => 8)
PORT MAP ( clk => CLK_125MHZ,
           rst => rst,
           en => Nibble_counter_en,
           count_out => Nibble_counter_out );

end Behavioral;

