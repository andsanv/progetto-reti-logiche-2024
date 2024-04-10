library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE IEEE.NUMERIC_STD.ALL;
USE work.custom_types.ALL;



entity project_reti_logiche is
    port(
        i_clk       : in std_logic;
        i_rst       : in std_logic;
        i_start     : in std_logic;
        i_add       : in std_logic_vector(15 downto 0);
        i_k         : in std_logic_vector(9 downto 0);
        o_done      : out std_logic;
        o_mem_addr  : out std_logic_vector(15 downto 0);
        i_mem_data  : in std_logic_vector(7 downto 0);
        o_mem_data  : out std_logic_vector(7 downto 0);
        o_mem_we    : out std_logic;
        o_mem_en    : out std_logic
    );
end project_reti_logiche;



architecture FSM of project_reti_logiche is
    type state_type is (
        RESET,
        READY,
        SET_READ_MEM,
        WAIT_MEM,
        FETCH_DATA_MEM,
        UPDATE,
        STEP,
        DONE,
        FINISH
    );
    
    signal k, next_k                        : std_logic_vector(9 downto 0) := (others => '0');
    signal addr, next_addr                  : std_logic_vector(15 downto 0) := (others => '0');
    signal data, next_data                  : std_logic_vector(7 downto 0) := (others => '0');
    signal prev_data, next_prev_data        : std_logic_vector(7 downto 0) := (others => '0'); 
    signal credibility, next_credibility    : std_logic_vector(4 downto 0) := (others => '0');
    
    signal next_o_done                      : std_logic := '0';
    signal next_o_mem_addr                  : std_logic_vector(15 downto 0) := (others => '0');
    signal next_o_mem_data                  : std_logic_vector(7 downto 0) := (others => '0');
    signal next_o_mem_we                    : std_logic := '0';
    signal next_o_mem_en                    : std_logic := '0';

    signal state, next_state                : state_type := RESET;

begin
    STATE_REG : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            -- asynchronously reset the fsm
            state               <= RESET;
            next_state          <= RESET;

            k                   <= (others => '0');
            next_k              <= (others => '0');
            addr                <= (others => '0');
            next_addr           <= (others => '0');
            data                <= (others => '0');
            next_data           <= (others => '0');
            prev_data           <= (others => '0');
            next_prev_data      <= (others => '0');
            credibility         <= (others => '0');
            next_credibility    <= (others => '0');

            next_o_done         <= '0';
            next_o_mem_addr     <= (others => '0');
            next_o_mem_data     <= (others => '0');
            next_o_mem_we       <= '0';
            next_o_mem_en       <= '0';

        elsif rising_edge(i_clk) then
            -- update signals 
            k               <= next_k;
            addr            <= next_addr;
            prev_data       <= next_prev_data;
            credibility     <= next_credibility;
            o_done          <= next_o_done;
            o_mem_addr      <= next_o_mem_addr;
            o_mem_data      <= next_o_mem_data;
            o_mem_we        <= next_o_mem_we;
            o_mem_en        <= next_o_mem_en;
            state           <= next_state;
        end if
    end process

    LAMBDA : process(state, i_start, i_add, i_k, i_mem_data)
    begin
        case state is
            when RESET =>
                if i_rst = '1' then
                    next_state <= RESET;
                else
                    next_state <= READY;
                end if

            when READY =>
                if i_start = '1' then
                    if i_k > (others => '0') then
                        next_k      <= i_k;
                        next_state  <= SET_READ_MEM;
                    else
                        next_state  <= DONE;
                    end if
                else
                    next_state <= READY;
                end if

            when SET_READ_MEM =>
                next_o_mem_en   <= '1';
                next_o_mem_we   <= '0';
                next_o_mem_addr <= addr;
                next_state      <= WAIT_MEM;
            
            when WAIT_MEM =>
                next_state <= FETCH_DATA_MEM;
            
            when FETCH_DATA_MEM =>
                next_data <= i_mem_data;
                next_state <= UPDATE;

            when UPDATE =>
                
                
    end process

    DELTA : process(state, i_start, i_add, i_k, i_mem_data)
        case state is
            when RESET =>
                o_done      <= '0';
                o_mem_addr  <= (others => '0');
                o_mem_data  <= (others => '0');
                o_mem_we    <= '0';
                o_mem_en    <= '0';
    begin

    end process
end FSM;
