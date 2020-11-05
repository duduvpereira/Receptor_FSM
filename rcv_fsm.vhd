  
-- ** Nomes: Hêndrick Gonçalves e Eduardo Pereira
-- ** Arquivo: rcv_fsm.vhd
-- ** VLSI 1 -- T1
-- ** 2020/2

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_arith.all;
    use ieee.std_logic_unsigned.all;

entity rcv_fsm is
port(
    clk_in : in std_logic;
    rst_in : in std_logic;
    data_sr_in : in std_logic;
    data_pl_out : out std_logic_vector(7 downto 0);
    data_pl_en_out : out std_logic;
    sync_out : out std_logic
);
end rcv_fsm;

architecture rcv_fsm_arch of rcv_fsm is

type state_type is (waitForSyncWord, waitForPayload, payloadHandler, updateBus, updateBusFlag); -- state type
signal state : state_type := waitForSyncWord;   -- state

signal rx_buffer : std_logic_vector(7 downto 0) := (others => 'Z');
--signal id : std_logic_vector(3 downto 0) := "0111"; -- id dos buffers, deve começar em 

signal payload : std_logic_vector(39 downto 0) := (others => 'Z');
signal payload_byte : std_logic_vector(7 downto 0) := (others => 'Z');
--signal id_pld : std_logic_vector(7 downto 0) := x"27"; --id do payload, deve começar em 39

--signal cnt_rx : std_logic_vector(3 downto 0) := "0000"; -- conta os sync words recebidos 
signal rx_started : std_logic := '0'; --flag 

--signal cnt_payload_buff : std_logic_vector(3 downto 0) := "0000";

signal sync_word : std_logic_vector(7 downto 0) := x"A5"; -- 1010 0101 

signal sync_word_signal : std_logic := 'Z';

begin

    fsm: process(clk_in)

    variable id : integer range 0 to 50 := 7;
    variable id_pld : integer range 0 to 50 := 39;
    variable cnt_rx : integer range 0 to 50 := 0;
    variable cnt_payload_buff : integer range 0 to 50 := 0;

    begin

        if clk_in'event and clk_in = '1' then
            if rst_in = '1' then
                sync_out <= 'Z';
                sync_word_signal <= 'Z';
                data_pl_en_out <= 'Z';
                state <= waitForSyncWord;
                cnt_rx := 0;
                id := 7;
                rx_buffer <= (others => 'Z');
                payload <= (others => 'Z');
                data_pl_out <= (others => 'Z');
                rx_started <= '0';
            else

                case state is

                    when waitForSyncWord =>
                        
                        if data_sr_in = '1' and rx_buffer(7) = 'Z' and rx_started = '0' then -- começou o rx da sync word
                            rx_buffer(id) <= data_sr_in;
                            
                            id := id - 1;
                            rx_started <= '1';
                            state <= waitForSyncWord;

                        elsif rx_started = '1' and id >= 0 and cnt_rx < 3 then
                            rx_buffer(id) <= data_sr_in;

                            if data_sr_in /= sync_word(id) then    
                                cnt_rx := 0;
                                id := 7;
                                sync_word_signal <= '0';
                                sync_out <= '0';
                                data_pl_en_out <= '0';
                                rx_started <= '0';
                                rx_buffer <= (others => 'Z'); 
                                state <= waitForSyncWord;
                            elsif id > 0 then
								id := id - 1;
                                state <= waitForSyncWord;
                            else 
                                cnt_rx := cnt_rx + 1;

                                if cnt_rx = 3 then
                                    sync_word_signal <= '1';
                                    sync_out <= '1';
                                end if;

                                id := 7;
                                payload <= (others => 'Z'); -- reseta payload antes de mudar de estado
                                rx_started <= '0';
                                state <= waitForPayload;   
							end if;

                        elsif rx_started = '1' and id >= 0 and cnt_rx = 3 then
                            rx_buffer(id) <= data_sr_in;
                            payload <= (others => 'Z');

                            if data_sr_in /= sync_word(id) then    
                                cnt_rx := 0;
                                id := 7;
                                sync_word_signal <= '0';
                                sync_out <= '0';
                                data_pl_en_out <= '0';
                                rx_started <= '0';
                                --rx_buffer <= (others => 'Z'); 
                                state <= waitForSyncWord;
                            elsif id > 0 then
								id := id - 1;
                                state <= waitForSyncWord;
                            else 
                                id := 7;
                                payload <= (others => 'Z'); -- reseta payload antes de mudar de estado
                                rx_started <= '0';
                                state <= waitForPayload;   
							end if;         
                        else 
                            cnt_rx := 0;
                            id := 7;
                            sync_word_signal <= '0';
                            sync_out <= '0';
                            data_pl_en_out <= '0';
                            rx_started <= '0';
                            rx_buffer <= (others => 'Z');
                            state <= waitForSyncWord;

                        end if;

                    when waitForPayload =>

                        if id_pld >= 0 then
                            payload(id_pld) <= data_sr_in;
                            
                            if id_pld > 0 then
                                id_pld := id_pld - 1;
                                state <= waitForPayload;    
                            elsif sync_word_signal = '0' then
                                id_pld := 39; -- reseta para 39
                                rx_buffer <= (others => 'Z'); -- reseta buffer de sync word
                                state <= waitForSyncWord;
                            elsif sync_word_signal = '1' then
                                id_pld := 39; -- reseta para 39
                                rx_buffer <= (others => 'Z');
                                state <= payloadHandler;
                            else 
                                state <= waitForPayload;
                            end if;
                        end if; 

                    when payloadHandler =>

                        state <= updateBus;

                    when updateBus =>
                        data_pl_en_out <= '0';
                        data_pl_out <= payload(id_pld downto ((id_pld+1)-8));
                        
                        if id_pld >= 8 then
                            id_pld := id_pld - 8;
                        end if;

                        state <= updateBusFlag;

                    when updateBusFlag =>

                        if cnt_payload_buff < 5 then -- conta os 5 bytes
                            data_pl_en_out <= '1';
                            cnt_payload_buff := cnt_payload_buff + 1;
                            state <= updateBus;
                        elsif cnt_payload_buff = 5 then
                            cnt_payload_buff := 0;
                            payload <= (others => 'Z'); -- reseta payload    
                            id_pld := 39;
                            state <= waitForSyncWord;
                        end if;

                
                end case;


            end if;

        end if; 

    end process fsm;

end rcv_fsm_arch;