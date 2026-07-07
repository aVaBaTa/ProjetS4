----------------------------------------------------------------------------------
-- priority_mux.vhd
--
-- Choisit entre le pixel du sprite et le pixel du fond.
--
-- Règle de priorité :
--   Si sprite_active = '1' ET sprite_color /= "00" (pas transparent)
--     → on affiche le sprite
--   Sinon
--     → on affiche le fond
--
-- La couleur index "00" est la couleur transparente des sprites.
-- Un sprite avec color_index "00" à un pixel laisse voir le fond.
--
-- Ce module est purement combinatoire - zéro latence.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity priority_mux is
    generic (
        BITS_PAR_PIXEL : integer := 2   -- 2 bits = 4 couleurs
    );
    port (
        -- Pixel du fond (venant de la palette via bg_renderer)
        bg_rgb          : in  std_logic_vector(23 downto 0);

        -- Pixel du sprite
        sprite_active   : in  std_logic;                                    -- '1' si un sprite couvre ce pixel
        sprite_color    : in  std_logic_vector(BITS_PAR_PIXEL-1 downto 0); -- color_index du sprite
        sprite_rgb      : in  std_logic_vector(23 downto 0);               -- RGB du sprite (via palette)

        -- Sortie finale vers m_axis_tdata
        pixel_rgb       : out std_logic_vector(23 downto 0)
    );
end priority_mux;

architecture Behavioral of priority_mux is

    -- Constante : color_index "00" = transparent
    constant TRANSPARENT : std_logic_vector(BITS_PAR_PIXEL-1 downto 0) := (others => '0');

begin

    ------------------------------------------------------------
    -- Règle de priorité (combinatoire, zéro latence)
    --
    --   sprite_active = '1'       → un sprite couvre ce pixel
    --   sprite_color /= "00"      → ce pixel du sprite n'est pas transparent
    --   → les deux conditions → on affiche le sprite
    --   → sinon               → on affiche le fond
    ------------------------------------------------------------
    pixel_rgb <= sprite_rgb when (sprite_active = '1' and sprite_color /= TRANSPARENT)
                 else bg_rgb;

end Behavioral;