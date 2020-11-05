-- ** Nomes: Hêndrick Gonçalves e Eduardo Pereira
-- ** Arquivo: testbench.vhd
-- ** VLSI 1 -- T1
-- ** 2020/2

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_arith.all;
    use ieee.std_logic_unsigned.all;

entity rcv_fsm_tb is

end rcv_fsm_tb;

architecture rcv_fsm_tb_arch of rcv_fsm_tb is

signal clk_tb : std_logic := '0';
signal rst_tb : std_logic := '1';
signal data_sr_tb : std_logic := 'Z';
signal data_pl_out_tb : std_logic_vector(7 downto 0) := (others => 'Z');
signal data_pl_en_out_tb : std_logic := '0';
signal sync_out_tb : std_logic := 'Z';

signal frame : std_logic_vector(47 downto 0) := (others => 'Z'); -- sync word + payload
signal wrong_frame : std_logic_vector(47 downto 0) := (others => 'Z'); -- sync word + payload
signal sync_word : std_logic_vector(7 downto 0) := x"A5";
signal payload : std_logic_vector(39 downto 0) := x"4746425041"; -- GFBPA em hex - asc2
signal wrong_sync_word : std_logic_vector(7 downto 0) := x"FF"; -- para gerar o erro 

type tb_state_type is (RX, TX, GENERATE_ERROR); -- state type
signal state : tb_state_type := TX;   -- state

begin

    fsm_tb: entity work.rcv_fsm
        port map (clk_in => clk_tb, rst_in => rst_tb, data_sr_in => data_sr_tb, data_pl_en_out => data_pl_en_out_tb, 
        data_pl_out => data_pl_out_tb, sync_out => sync_out_tb);

    rst_tb <= '0' after 10 ns;

    frame(47 downto 40) <= sync_word;
    frame(39 downto 0) <= payload;

    wrong_frame(47 downto 40) <= wrong_sync_word;
    wrong_frame(39 downto 0) <= payload;

    process                          -- generates clock signal 
        begin
        wait for 10 ns;
        clk_tb <= '1';
        wait for 10 ns;
        clk_tb <= '0';
    end process;

    in_generator: process(clk_tb)
    
    variable frame_id : integer range 0 to 100 := 47;
    variable cnt_rx_buffer : integer range 0 to 100 := 0;
    variable cnt_rx_state : integer range 0 to 100 := 0; -- conta o número de vezes que entrou em RX para gerar o erro na segunda

    begin

        if clk_tb'event and clk_tb = '1' then
            
            case state is

                when TX => 
            
                    if data_pl_en_out_tb = '0' then
                        data_sr_tb <= frame(frame_id);

                        if frame_id > 0 then
                            frame_id := frame_id - 1;
                        else
                            frame_id := 47;
                        end if;     

                        state <= TX;
                    elsif data_pl_en_out_tb = '1' then 
                        frame_id := 47; -- reseta frame id
                        state <= RX;    -- e vai para RX
                        
                        if cnt_rx_state < 2 then
                            cnt_rx_state := cnt_rx_state + 1;
                        end if;
                    end if;
                    
                when RX =>
                    if cnt_rx_buffer < 4 and  data_pl_en_out_tb = '1' then
                        cnt_rx_buffer := cnt_rx_buffer + 1;

                        if cnt_rx_buffer = 4 and cnt_rx_state < 2 then
                            cnt_rx_buffer := 0;
                            state <= TX;
                        elsif cnt_rx_buffer = 4 and cnt_rx_state = 2 then
                            cnt_rx_buffer := 0;
                            state <= GENERATE_ERROR;
                        end if;

                    elsif cnt_rx_buffer < 4 and  data_pl_en_out_tb = '0' then
                        cnt_rx_buffer := cnt_rx_buffer;
                    end if;

                when GENERATE_ERROR => --  gera erro a cada 2 vezes que entra em rx normalmente
                    cnt_rx_state := 0;

                    data_sr_tb <= wrong_frame(frame_id);

                    if frame_id > 0 then
                        frame_id := frame_id - 1;
                        state <= GENERATE_ERROR;
                    else
                        frame_id := 47;
                        data_sr_tb <= 'Z';
                        state <= TX; -- volta a enviar corretamente
                    end if;    

            end case; 
            
            assert(sync_out_tb /= '1') report "Synzed!";
        end if;

    end process in_generator;

end rcv_fsm_tb_arch;