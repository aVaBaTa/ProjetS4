----------------------------------------------------------------------------------
-- oam.vhd
--
-- Object Attribute Memory : table des 8 acteurs (sprites).
-- Stockée dans des registres (pas de BRAM) pour permettre
-- la lecture de tous les acteurs en parallèle en 1 cycle.
--
-- Chaque acteur contient :
--   pos_x   : position horizontale (0 à 255)
--   pos_y   : position verticale   (0 à 223)
--   tile_id : numéro de tuile      (0 à 15)
--
-- Le PS écrit les acteurs via les ports wr_*.
-- Le renderer lit tous les acteurs simultanément via les ports rd_*.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity oam is
    generic (
        NB_ACTEURS : integer := 8    -- Nombre d'acteurs simultanés
                                      -- Changer à 16 pour plus d'acteurs
    );
    port (
        clk         : in  std_logic;

        -- Port écriture (depuis le PS pour placer les acteurs)
        we          : in  std_logic;
        wr_index    : in  std_logic_vector(2 downto 0);  -- 3 bits = acteur 0 à 7
        wr_pos_x    : in  std_logic_vector(7 downto 0);  -- position X
        wr_pos_y    : in  std_logic_vector(7 downto 0);  -- position Y
        wr_tile_id  : in  std_logic_vector(3 downto 0);  -- numéro de tuile

        -- Ports lecture (tous les acteurs disponibles simultanément)
        -- Le renderer lit ces signaux directement, sans latence
        rd_pos_x    : out std_logic_vector(NB_ACTEURS*8-1 downto 0);   -- X de chaque acteur
        rd_pos_y    : out std_logic_vector(NB_ACTEURS*8-1 downto 0);   -- Y de chaque acteur
        rd_tile_id  : out std_logic_vector(NB_ACTEURS*4-1 downto 0)    -- tile_id de chaque acteur
    );
end oam;

architecture Behavioral of oam is

    -- Type pour un acteur
    type acteur_t is record
        pos_x   : std_logic_vector(7 downto 0);
        pos_y   : std_logic_vector(7 downto 0);
        tile_id : std_logic_vector(3 downto 0);
    end record;

    -- Tableau des 8 acteurs
    type oam_t is array(0 to NB_ACTEURS-1) of acteur_t;

    -- Valeurs initiales : tous les acteurs hors écran (pos_x=255, pos_y=255)
    -- Un acteur à pos_y=255 ne croisera jamais une ligne visible → invisible
    signal oam_reg : oam_t := (
        others => (
            pos_x   => x"FF",   -- hors écran
            pos_y   => x"FF",   -- hors écran
            tile_id => x"0"     -- tuile 0
        )
    );

begin

    ------------------------------------------------------------
    -- Écriture : le PS met à jour un acteur à la fois
    ------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                oam_reg(to_integer(unsigned(wr_index))).pos_x   <= wr_pos_x;
                oam_reg(to_integer(unsigned(wr_index))).pos_y   <= wr_pos_y;
                oam_reg(to_integer(unsigned(wr_index))).tile_id <= wr_tile_id;
            end if;
        end if;
    end process;

    ------------------------------------------------------------
    -- Lecture : tous les acteurs disponibles en permanence
    -- On "aplatit" le tableau en un grand vecteur pour les ports
    --
    -- Convention : acteur 0 dans les bits les plus bas
    --   rd_pos_x[7:0]   = pos_x de l'acteur 0
    --   rd_pos_x[15:8]  = pos_x de l'acteur 1
    --   ...
    --   rd_pos_x[63:56] = pos_x de l'acteur 7
    ------------------------------------------------------------
    gen_lecture : for i in 0 to NB_ACTEURS-1 generate
        rd_pos_x  (i*8+7  downto i*8)   <= oam_reg(i).pos_x;
        rd_pos_y  (i*8+7  downto i*8)   <= oam_reg(i).pos_y;
        rd_tile_id(i*4+3  downto i*4)   <= oam_reg(i).tile_id;
    end generate;

end Behavioral;