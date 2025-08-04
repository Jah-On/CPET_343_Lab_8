library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity main is
end entity main;

architecture stim of main is
    component tlde is
        port (
            reset, clk              : in  std_logic;
            exec                    : in  std_logic;
            hex0, hex1, hex2        : out std_logic_vector(6 downto 0);
            state                   : out std_logic_vector(2 downto 0)
        );
    end component tlde;

    type ssd_arr_t     is array (2 downto 0) of std_logic_vector(6 downto 0);
    type ssd_res_arr_t is array (natural range<>) of ssd_arr_t;

    constant CYCLE_INTERVAL : time := 10ns;

    constant DSP_VALS    : ssd_res_arr_t := (
        ("1000000", "1000000", "1000000"),
        ("1000000", "1000000", "0011001"),
        ("1000000", "0110000", "0100100"),
        ("1000000", "0110000", "0100100"),
        ("1000000", "0100100", "0011001"),
        ("1000000", "1111001", "0100100"),
        ("1000000", "0110000", "0100100"),
        ("1000000", "1111001", "0000010")
    );

    signal done                         : std_logic                    := '0';

    signal reset                        : std_logic                    := '0';
    signal clk, exec                    : std_logic                    := '1';
    signal state                        : std_logic_vector(2 downto 0) := "000";
    signal hex_out                      : ssd_arr_t;

    function HexToInt(dsp_in: std_logic_vector(6 downto 0)) return integer is
    begin
        case dsp_in is
            when "1111001" => return 1;
            when "0100100" => return 2;
            when "0110000" => return 3;
            when "0011001" => return 4;
            when "0010010" => return 5;
            when "0000010" => return 6;
            when "1111000" => return 7;
            when "0000000" => return 8;
            when "0011000" => return 9;
            when others    => return 0;
        end case;
    end function;

    procedure DelayClocks(Cycles : integer := 1) is
    begin
        for iter in 0 to (Cycles - 1) loop
            wait until rising_edge(clk);
        end loop;
    end procedure;

    procedure CheckDisplay(Row : integer) is
        variable hex_int, dsp_int : integer;
    begin
        for dsp_index in 2 downto 0 loop
            hex_int := HexToInt(hex_out(dsp_index));
            dsp_int := HexToInt(DSP_VALS(Row)(dsp_index));
            assert hex_int = dsp_int
                report integer'image(Row) & ": Hex " & integer'image(dsp_index) & " of " 
                & integer'image(hex_int) & " does not match " & integer'image(dsp_int) &  "!" 
                    severity error;
        end loop;
    end procedure;
begin
    gen_clock: process
    begin
        report "*** Starting Simulation ***" severity note;

        while done /= '1' loop 
            clk <= not clk;
            
            wait for CYCLE_INTERVAL;
        end loop;

        report "*** Finished Simulation ***" severity note;

        wait;
    end process gen_clock;

    main: process
    begin
        DelayClocks(10);
        reset  <= '1';

        DelayClocks(4);

        -- CheckDisplay(0);

        for execs in 0 to 7 loop
            exec   <= '0';
            DelayClocks(3);
            exec   <= '1';
            DelayClocks(20);

            CheckDisplay(execs);
        end loop;

        done   <= '1';

        wait;
    end process main;

    uut : tlde
        port map (
            reset     => reset,
            clk       => clk,
            exec      => exec,
            hex2      => hex_out(2),
            hex1      => hex_out(1),
            hex0      => hex_out(0),
            state     => state
        );
end architecture stim;