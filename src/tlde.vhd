/* 

Author: John Schulz
Date:   07/25/2025

Top level design entity for lab 8.

*/
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.synchronizers.all;

entity tlde is
    port (
        reset, clk              : in  std_logic;
        exec                    : in  std_logic;
        hex0, hex1, hex2        : out std_logic_vector(6  downto 0);
        state                   : out std_logic_vector(2  downto 0)
    );
end entity tlde;

architecture sig_map of tlde is
    component rom is
        port
        (
            clock		: in  std_logic                      := '1';
            address		: in  std_logic_vector ( 4 downto 0);
            q		    : out std_logic_vector (15 downto 0)
        );
    end component rom;

    component alu is
        port (
            clk           : in  std_logic;
            reset         : in  std_logic;
            a             : in  std_logic_vector(7 downto 0); 
            b             : in  std_logic_vector(7 downto 0);
            op            : in  std_logic_vector(1 downto 0); -- 00: add, 01: sub, 10: mult, 11: div
            result        : out std_logic_vector(7 downto 0)
        );
    end component alu;

    component fsm is
        port (
            reset, clk     : in  std_logic;
            mr, ms, exec   : in  std_logic;
            alu_in, mem_in : in  std_logic_vector(7 downto 0);
            write_mode     : out std_logic                    := '0';
            addr           : out std_logic_vector(1 downto 0) := "00";
            data_out       : out std_logic_vector(7 downto 0);
            state_out      : out std_logic_vector(2 downto 0)
        );
    end component fsm;

    component memory is 
        generic (
            addr_width : integer := 2;
            data_width : integer := 4
        );
        port (
            clk               : in  std_logic;
            we                : in  std_logic;
            addr              : in  std_logic_vector(addr_width - 1 downto 0);
            din               : in  std_logic_vector(data_width - 1 downto 0);
            dout              : out std_logic_vector(data_width - 1 downto 0)
        );
    end component memory;

    component ssd_d3 is
        generic (
            num_bits : integer := 9
        );
        port (
            reset                : in  std_logic;
            val                  : in  std_logic_vector((num_bits - 1) downto 0);
            ones, tens, hundreds : out std_logic_vector(6 downto 0)
        );
    end component ssd_d3;

    signal sync_exec                    : std_logic;
    signal alu_out, fsm_out, memory_out : std_logic_vector( 7 downto 0);
    signal enable_write                 : std_logic;
    signal mem_addr                     : std_logic_vector( 1 downto 0);

    signal rom_addr_int                 : integer                       := 0;
    signal rom_addr                     : std_logic_vector( 4 downto 0) := "00000";
    signal instruction                  : std_logic_vector(15 downto 0);

    alias number : std_logic_vector(7 downto 0) is instruction(7  downto 0);
    alias op     : std_logic_vector(1 downto 0) is instruction(15 downto 14);
    alias mr     : std_logic                    is instruction(13);
    alias ms     : std_logic                    is instruction(12);
begin
    increment_rom_addr: process(exec)
    begin
        if falling_edge(exec) then
            rom_addr_int <= rom_addr_int + 1;
            rom_addr     <= std_logic_vector(to_unsigned(rom_addr_int, rom_addr'length));
        end if;
    end process increment_rom_addr;

    rom_inst : rom
        port map (
            address => rom_addr,
            clock   => clk,
            q       => instruction
        );

    exec_res : rising_edge_synchronizer
        port map (
            clk        => clk,
            reset      => not reset,
            input      => not exec,
            edge       => sync_exec
        );

    fsm_inst : fsm
        port map (
            reset      => not reset,
            clk        => clk,
            mr         => mr,
            ms         => ms,
            exec       => sync_exec,
            alu_in     => alu_out,
            mem_in     => memory_out,
            write_mode => enable_write,
            addr       => mem_addr,
            data_out   => fsm_out,
            state_out  => state
        );

    alu_inst : alu
        port map (
            reset      => not reset,
            clk        => clk,
            a          => memory_out,
            b          => number,
            op         => op,
            result     => alu_out
        );

    memory_inst : memory
        generic map (
            addr_width => 2,
            data_width => 8
        )
        port map (
            clk        => clk,
            we         => enable_write,
            addr       => mem_addr,
            din        => fsm_out,
            dout       => memory_out
        );

    display : ssd_d3
        generic map (
            num_bits   => 8
        )
        port map (
            reset      => not reset,
            val        => memory_out,
            ones       => hex0,
            tens       => hex1,
            hundreds   => hex2
        );
end architecture sig_map;