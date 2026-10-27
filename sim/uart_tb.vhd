
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.env.all;

entity uart_tb is
end uart_tb;

architecture Behavioral of uart_tb is

    -- Параметри тестування
    constant CLK_PERIOD : time := 20 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    -- Сигнали передавача
    signal tx_start  : std_logic := '0';
    signal tx_data   : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_serial : std_logic;
    signal tx_busy   : std_logic;
    signal tx_done   : std_logic;

    -- Сигнали приймача
    signal rx_data : std_logic_vector(7 downto 0);
    signal rx_busy : std_logic;
    signal rx_done : std_logic;

    -- Тестові числа
    type byte_array is array (natural range <>)
        of std_logic_vector(7 downto 0);

    constant TEST_VALUES : byte_array :=
        (x"55", x"A5", x"00", x"FF");

begin

    -- Генерація тактового сигналу
    clk <= not clk after CLK_PERIOD / 2;

    -- Підключення передавача
    TX_UNIT: entity work.uart_tx
        generic map (
            CLK_FREQ  => 50000000,
            BAUD_RATE => 9600
        )
        port map (
            clk       => clk,
            rst       => rst,
            tx_start  => tx_start,
            tx_data   => tx_data,
            tx_serial => tx_serial,
            tx_busy   => tx_busy,
            tx_done   => tx_done
        );

    -- Підключення приймача
    RX_UNIT: entity work.uart_rx
        generic map (
            CLK_FREQ  => 50000000,
            BAUD_RATE => 9600
        )
        port map (
            clk       => clk,
            rst       => rst,
            rx_serial => tx_serial,
            rx_data   => rx_data,
            rx_busy   => rx_busy,
            rx_done   => rx_done
        );

    -- Основний процес тестування
    TEST_PROCESS: process
    begin

        -- Скидання модулів
        rst <= '1';
        wait for 100 ns;
        wait until falling_edge(clk);
        rst <= '0';

        -- Перевірка передачі кількох чисел
        for i in TEST_VALUES'range loop

            wait until falling_edge(clk);

            tx_data <= TEST_VALUES(i);
            tx_start <= '1';

            wait until falling_edge(clk);
            tx_start <= '0';

            -- Очікування отримання даних
            wait until rx_done = '1';
            wait for 1 ns;

            -- Перевірка правильності
            assert rx_data = TEST_VALUES(i)
                report "ERROR: Incorrect received data"
                severity failure;

            report "PASS: Byte " & integer'image(i)
                severity note;

            -- Очікування завершення передачі
            wait until tx_busy = '0';

        end loop;

        report "ALL UART TESTS PASSED"
            severity note;

        finish;
        wait;

    end process;

    -- Захист від нескінченного очікування
    WATCHDOG: process
    begin
        wait for 6 ms;
        assert false
            report "ERROR: Simulation timeout"
            severity failure;
        wait;
    end process;

end Behavioral;
