----------------------------------------------------------------------------------
-- palette.vhd
--
-- Convertit un index de couleur (venant de la tile_bram) en couleur RGB 24 bits.
--
-- Avec BITS_PAR_PIXEL = 2, on a 4 couleurs possibles (index 0 à 3).
-- Chaque couleur est stockée comme RGB sur 24 bits (8 bits par canal).
--
-- Le CPU peut modifier les couleurs via les ports d'écriture,
-- ce qui permet de changer l'apparence du jeu sans toucher aux tuiles.
--
-- Exemple avec les valeurs par défaut :
--   Index 0 -> Noir       (000000)
--   Index 1 -> Blanc      (FFFFFF)
--   Index 2 -> Rouge      (FF0000)
--   Index 3 -> Vert       (00FF00)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity palette is
    generic (
        NB_COULEURS    : integer := 4;   -- 2^BITS_PAR_PIXEL de tile_bram
                                          -- 4 couleurs pour 2 bits/pixel
                                          -- 16 couleurs pour 4 bits/pixel
        BITS_COULEUR   : integer := 24   -- 24 bits = RGB 8-8-8
                                          -- Garder à 24 pour compatibilité AXI-Stream
    );
    port (
        clk         : in  std_logic;

        -- Port écriture (depuis le CPU pour changer les couleurs)
        we          : in  std_logic;
        wr_addr     : in  std_logic_vector(1 downto 0);   -- 2 bits = 4 couleurs
        wr_data     : in  std_logic_vector(BITS_COULEUR-1 downto 0);

        -- Port lecture (depuis le renderer)
        -- Entrée : index de couleur venant de la tile_bram
        color_index : in  std_logic_vector(1 downto 0);   -- 2 bits = 4 couleurs
        -- Sortie : couleur RGB prête pour l'AXI-Stream
        rgb_out     : out std_logic_vector(BITS_COULEUR-1 downto 0)
    );
end palette;

architecture Behavioral of palette is

    -- La palette : tableau de NB_COULEURS entrées de 24 bits chacune
    type palette_t is array(0 to NB_COULEURS-1) of
        std_logic_vector(BITS_COULEUR-1 downto 0);

    -- Couleurs par défaut (modifiables par le CPU)
    -- Format : RGB sur 24 bits -> "RRRRRRRRGGGGGGGGBBBBBBBB"
    signal palette_mem : palette_t := (
        0 => x"000000",   -- Index 0 : Noir
        1 => x"FFFFFF",   -- Index 1 : Blanc
        2 => x"FF0000",   -- Index 2 : Rouge
        3 => x"00FF00"    -- Index 3 : Vert
    );

begin

    process(clk)
    begin
        if rising_edge(clk) then
            -- Écriture : le CPU peut changer une couleur
            if we = '1' then
                palette_mem(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;
            -- Lecture : convertit l'index en RGB (1 cycle de latence)
            rgb_out <= palette_mem(to_integer(unsigned(color_index)));
        end if;
    end process;

end Behavioral;