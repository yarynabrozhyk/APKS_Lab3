
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_top is
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
        tx_done   : out std_logic;

        rx_serial : in  std_logic;
        rx_data   : out std_logic_vector(7 downto 0);
        rx_busy   : out std_logic;
        rx_done   : out std_logic
    );
end uart_top;

architecture Behavioral of uart_top is
begin

    -- Модуль передавача UART
    TX_UNIT: entity work.uart_tx
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
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

    -- Модуль приймача UART
    RX_UNIT: entity work.uart_rx
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk       => clk,
            rst       => rst,
            rx_serial => rx_serial,
            rx_data   => rx_data,
            rx_busy   => rx_busy,
            rx_done   => rx_done
        );

end Behavioral;
