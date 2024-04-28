library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


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
        SET_READ_DATA,
        WAIT_MEM,
        FETCH_DATA,
        UPDATE,
        WRITE_DATA,
        WRITE_CREDIBILITY,
        ITERATE,
        DONE
    );
    
    signal k, next_k                                : std_logic_vector(9 downto 0) := (others => '0');
    signal addr, next_addr                          : std_logic_vector(15 downto 0) := (others => '0');
    signal data, next_data                          : std_logic_vector(7 downto 0) := (others => '0');
    signal last_valid_data, next_last_valid_data    : std_logic_vector(7 downto 0) := (others => '0'); 
    signal credibility, next_credibility            : std_logic_vector(7 downto 0) := (others => '0');
    
    signal next_o_done                              : std_logic := '0';
    signal next_o_mem_addr                          : std_logic_vector(15 downto 0) := (others => '0');
    signal next_o_mem_data                          : std_logic_vector(7 downto 0) := (others => '0');
    signal next_o_mem_we                            : std_logic := '0';
    signal next_o_mem_en                            : std_logic := '0';

    signal state, next_state                        : state_type := RESET;
    
    constant zero                                   : std_logic_vector(9 downto 0) := (others => '0');

begin
    STATE_REG : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            -- asynchronously reset the fsm
            state                   <= RESET;

            k                       <= (others => '0');
            addr                    <= (others => '0');
            data                    <= (others => '0');
            last_valid_data         <= (others => '0');
            credibility             <= (others => '0');

            o_done                  <= '0';
            o_mem_addr              <= (others => '0');
            o_mem_data              <= (others => '0');
            o_mem_en                <= '0';
            o_mem_we                <= '0';
        elsif rising_edge(i_clk) then
            -- update signals 
            k                       <= next_k;
            addr                    <= next_addr;
            data                    <= next_data;
            last_valid_data         <= next_last_valid_data;
            credibility             <= next_credibility;

            o_done                  <= next_o_done;
            o_mem_addr              <= next_o_mem_addr;
            o_mem_data              <= next_o_mem_data;
            o_mem_we                <= next_o_mem_we;
            o_mem_en                <= next_o_mem_en;

            state                   <= next_state;
        end if;
    end process;

    LAMBDA_DELTA : process(state, i_start, i_add, i_k, i_mem_data, k, addr, data, credibility, last_valid_data)
    begin
        -- resetting singals and outputs to avoid inferred latches
        -- this way, from one state to another, the "next" signals will keep their values instead of being reinitialized to zero
        next_k                  <= k;
        next_addr               <= addr;
        next_data               <= data;
        next_last_valid_data    <= last_valid_data;
        next_credibility        <= credibility;
        
        next_o_done             <= o_done;
        next_o_mem_addr         <= o_mem_addr;
        next_o_mem_data         <= o_mem_data;
        next_o_mem_we           <= o_mem_we;
        next_o_mem_en           <= o_mem_en;

        next_state              <= state;
    
        case state is
            when RESET =>
                if i_rst = '1' then
                    next_state  <= RESET;
                else
                    next_state  <= READY;
                end if;

            when READY =>
                if i_start = '1' then
                    if i_k > zero then
                        next_k      <= i_k;
                        next_addr   <= i_add;
                        next_state  <= SET_READ_DATA;
                    else
                        next_o_done <= '1';
                        next_state  <= DONE;
                    end if;
                else
                    next_state      <= READY;
                end if;

            when SET_READ_DATA =>
                next_o_mem_en   <= '1';
                next_o_mem_addr <= addr;
                next_state      <= WAIT_MEM;
            
            when WAIT_MEM =>
                next_state      <= FETCH_DATA;
            
            when FETCH_DATA =>
                next_o_mem_en   <= '0';
                next_data       <= i_mem_data;

                next_state      <= UPDATE;

            when UPDATE =>
                if data /= zero(7 downto 0) then
                    next_last_valid_data    <= data;
                    next_credibility        <= std_logic_vector(to_unsigned(31, next_credibility'length));
                else
                    if credibility /= zero(7 downto 0) then
                        next_credibility    <= std_logic_vector(UNSIGNED(credibility) - 1);
                    end if;
                end if;

                next_state  <= WRITE_DATA;

            when WRITE_DATA =>
                next_o_mem_en   <= '1';
                next_o_mem_we   <= '1';
                next_o_mem_addr <= addr;
                next_o_mem_data <= last_valid_data;
                
                next_addr       <= std_logic_vector(UNSIGNED(addr) + 1);
                next_state      <= WRITE_CREDIBILITY;
                
            when WRITE_CREDIBILITY =>
                next_o_mem_addr <= addr;
                next_o_mem_data <= credibility;
                next_state      <= ITERATE;

            when ITERATE =>
                next_o_mem_en   <= '0';
                next_o_mem_we   <= '0';
            
                if k /= zero then
                    next_k      <= std_logic_vector(UNSIGNED(k) - 1);
                    next_addr   <= std_logic_vector(UNSIGNED(addr) + 1);
                    next_state  <= SET_READ_DATA;
                else
                    next_o_done <= '1';
                    next_state  <= DONE;
                end if;

            when DONE =>
                if i_start = '1' then
                    next_state              <= DONE;
                else
                    next_k                  <= (others => '0');
                    next_addr               <= (others => '0');
                    next_data               <= (others => '0');
                    next_last_valid_data    <= (others => '0');
                    next_credibility        <= (others => '0');
                    
                    -- o_mem_en and o_mem_we already set to zero
                    next_o_mem_addr         <= (others => '0');
                    next_o_mem_data         <= (others => '0');
                    next_o_done             <= '0';

                    next_state              <= READY;
                end if;
        end case;
    end process;
end FSM;