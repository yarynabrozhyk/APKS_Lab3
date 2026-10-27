
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_tx is
    generic (
        CLK_FREQ  : positive := 50000000;
        BAUD_RATE : positive := 9600
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        tx_start  : in  std_logic;
        tx_data   : in  std_logic_vector(7 downto 0);
        tx_serial : out std_logic;
        tx_busy   : out std_logic;
        tx_done   : out std_logic
    );
end uart_tx;

architecture Behavioral of uart_tx is

    -- Кількість тактів для передачі одного біта
    constant CLKS_PER_BIT : positive := CLK_FREQ / BAUD_RATE;

    -- Стани передавача
    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : state_type := IDLE;

    signal clk_count : integer range 0 to CLKS_PER_BIT-1 := 0;
    signal bit_index : integer range 0 to 7 := 0;
    signal data_reg  : std_logic_vector(7 downto 0) := (others => '0');

    signal tx_reg   : std_logic := '1';
    signal busy_reg : std_logic := '0';
    signal done_reg : std_logic := '0';

begin

    tx_serial <= tx_reg;
    tx_busy   <= busy_reg;
    tx_done   <= done_reg;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                clk_count <= 0;
                bit_index <= 0;
                data_reg <= (others => '0');
                tx_reg <= '1';
                busy_reg <= '0';
                done_reg <= '0';

            else
                done_reg <= '0';

                case state is

                    -- Очікування початку передачі
                    when IDLE =>
                        tx_reg <= '1';
                        busy_reg <= '0';

                        if tx_start = '1' then
                            data_reg <= tx_data;
                            clk_count <= 0;
                            tx_reg <= '0';
                            busy_reg <= '1';
                            state <= START_BIT;
                        end if;

                    -- Передача стартового біта
                    when START_BIT =>
                        if clk_count = CLKS_PER_BIT-1 then
                            clk_count <= 0;
                            bit_index <= 0;
                            tx_reg <= data_reg(0);
                            state <= DATA_BITS;
                        else
                            clk_count <= clk_count + 1;
                        end if;

                    -- Передача восьми бітів даних
                    when DATA_BITS =>
                        if clk_count = CLKS_PER_BIT-1 then
                            clk_count <= 0;

                            if bit_index = 7 then
                                tx_reg <= '1';
                                state <= STOP_BIT;
                            else
                                bit_index <= bit_index + 1;
                                tx_reg <= data_reg(bit_index + 1);
                            end if;

                        else
                            clk_count <= clk_count + 1;
                        end if;

                    -- Передача стопового біта
                    when STOP_BIT =>
                        if clk_count = CLKS_PER_BIT-1 then
                            clk_count <= 0;
                            busy_reg <= '0';
                            done_reg <= '1';
                            state <= IDLE;
                        else
                            clk_count <= clk_count + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

end Behavioral;
