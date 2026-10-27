
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_rx is
    generic (
        CLK_FREQ  : positive := 50000000;
        BAUD_RATE : positive := 9600
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        rx_serial : in  std_logic;
        rx_data   : out std_logic_vector(7 downto 0);
        rx_busy   : out std_logic;
        rx_done   : out std_logic
    );
end uart_rx;

architecture Behavioral of uart_rx is

    -- Кількість тактів на один біт
    constant CLKS_PER_BIT : positive := CLK_FREQ / BAUD_RATE;

    -- Стани приймача
    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : state_type := IDLE;

    signal clk_count : integer range 0 to CLKS_PER_BIT-1 := 0;
    signal bit_index : integer range 0 to 7 := 0;

    signal data_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal data_out : std_logic_vector(7 downto 0) := (others => '0');

    signal busy_reg : std_logic := '0';
    signal done_reg : std_logic := '0';

    -- Синхронізація вхідного сигналу
    signal rx_meta : std_logic := '1';
    signal rx_sync : std_logic := '1';

begin

    assert CLKS_PER_BIT >= 2
        report "CLK_FREQ must be at least twice BAUD_RATE"
        severity failure;

    rx_data <= data_out;
    rx_busy <= busy_reg;
    rx_done <= done_reg;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                clk_count <= 0;
                bit_index <= 0;
                data_reg <= (others => '0');
                data_out <= (others => '0');
                busy_reg <= '0';
                done_reg <= '0';
                rx_meta <= '1';
                rx_sync <= '1';

            else
                -- Синхронізуємо вхід
                rx_meta <= rx_serial;
                rx_sync <= rx_meta;

                done_reg <= '0';

                case state is

                    -- Очікування стартового біта
                    when IDLE =>
                        busy_reg <= '0';
                        clk_count <= 0;

                        if rx_sync = '0' then
                            busy_reg <= '1';
                            state <= START_BIT;
                        end if;

                    -- Перевірка стартового біта
                    when START_BIT =>
                        if clk_count = (CLKS_PER_BIT / 2)-1 then
                            clk_count <= 0;

                            if rx_sync = '0' then
                                bit_index <= 0;
                                state <= DATA_BITS;
                            else
                                busy_reg <= '0';
                                state <= IDLE;
                            end if;
                        else
                            clk_count <= clk_count + 1;
                        end if;

                    -- Приймання восьми бітів
                    when DATA_BITS =>
                        if clk_count = CLKS_PER_BIT-1 then
                            clk_count <= 0;
                            data_reg(bit_index) <= rx_sync;

                            if bit_index = 7 then
                                state <= STOP_BIT;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        else
                            clk_count <= clk_count + 1;
                        end if;

                    -- Перевірка стопового біта
                    when STOP_BIT =>
                        if clk_count = CLKS_PER_BIT-1 then
                            clk_count <= 0;
                            busy_reg <= '0';

                            if rx_sync = '1' then
                                data_out <= data_reg;
                                done_reg <= '1';
                            end if;

                            state <= IDLE;
                        else
                            clk_count <= clk_count + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

end Behavioral;
