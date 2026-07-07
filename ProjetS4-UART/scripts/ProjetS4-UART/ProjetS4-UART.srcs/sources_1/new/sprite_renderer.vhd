----------------------------------------------------------------------------------
-- sprite_renderer.vhd
--
-- Pour chaque pixel, vérifie si un des 8 acteurs le couvre.
-- Tous les acteurs sont vérifiés en PARALLÈLE (pas de latence).
--
-- Si un acteur couvre le pixel courant :
--   → on calcule l'adresse dans la tile_bram pour ce pixel de sprite
--   → on retourne le color_index (et sprite_active='1')
--
-- Si aucun acteur ne couvre le pixel :
--   → sprite_active='0' → le priority_mux affichera le fond
--
-- Priorité : l'acteur avec le plus petit index gagne (acteur 0 = priorité max)
--
-- Note sur la latence :
--   Ce module est combinatoire pour la détection (0 cycle).
--   La lecture de la tile_bram prend 1 cycle (géré dans ppu_top).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sprite_renderer is
    generic (
        NB_ACTEURS     : integer := 8;   -- Nombre d'acteurs simultanés
        TILE_SIZE      : integer := 8;   -- Taille d'une tuile en pixels
        BITS_PAR_PIXEL : integer := 2;   -- Bits par pixel (index couleur)
        BITS_TILE_ID   : integer := 4    -- Bits pour le tile_id
    );
    port (
        -- Position du pixel courant (venant du bg_renderer)
        pixel_x     : in  std_logic_vector(10 downto 0);  -- colonne courante
        pixel_y     : in  std_logic_vector(10 downto 0);  -- ligne courante

        -- Données OAM : tous les acteurs en parallèle
        rd_pos_x    : in  std_logic_vector(NB_ACTEURS*8-1 downto 0);
        rd_pos_y    : in  std_logic_vector(NB_ACTEURS*8-1 downto 0);
        rd_tile_id  : in  std_logic_vector(NB_ACTEURS*4-1 downto 0);

        -- Connexion vers tile_bram (lecture de la tuile du sprite actif)
        sprite_tile_addr  : out std_logic_vector(11 downto 0);  -- adresse tile_bram
        sprite_tile_data  : in  std_logic_vector(BITS_PAR_PIXEL-1 downto 0); -- color_index

        -- Résultat vers le priority_mux
        sprite_active     : out std_logic;   -- '1' si un sprite couvre ce pixel
        sprite_color      : out std_logic_vector(BITS_PAR_PIXEL-1 downto 0)  -- color_index
    );
end sprite_renderer;

architecture Behavioral of sprite_renderer is

    -- Signaux internes pour la détection en parallèle
    -- acteur_visible(i) = '1' si l'acteur i couvre le pixel courant
    signal acteur_visible : std_logic_vector(NB_ACTEURS-1 downto 0);

    -- Index de l'acteur gagnant (le plus petit index visible)
    signal acteur_gagnant : integer range 0 to NB_ACTEURS-1;
    signal un_acteur_actif : std_logic;

    -- Coordonnées du pixel courant en unsigned pour les comparaisons
    signal col : unsigned(10 downto 0);
    signal lig : unsigned(10 downto 0);

    -- Tile_id et offset du pixel dans la tuile du gagnant
    signal gagnant_tile_id : unsigned(BITS_TILE_ID-1 downto 0);
    signal gagnant_px      : unsigned(2 downto 0);  -- offset X dans tuile (0 à 7)
    signal gagnant_py      : unsigned(2 downto 0);  -- offset Y dans tuile (0 à 7)

begin

    col <= unsigned(pixel_x);
    lig <= unsigned(pixel_y);

    ------------------------------------------------------------
    -- ÉTAPE 1 : Détection en parallèle
    -- Pour chaque acteur i, on vérifie si le pixel courant
    -- est dans la zone [pos_x, pos_x+8[ × [pos_y, pos_y+8[
    ------------------------------------------------------------
    gen_detection : for i in 0 to NB_ACTEURS-1 generate
        acteur_visible(i) <= '1' when
            -- Le pixel est dans la zone horizontale de l'acteur
            col >= unsigned(rd_pos_x(i*8+7 downto i*8)) and
            col <  unsigned(rd_pos_x(i*8+7 downto i*8)) + TILE_SIZE and
            -- Le pixel est dans la zone verticale de l'acteur
            lig >= unsigned(rd_pos_y(i*8+7 downto i*8)) and
            lig <  unsigned(rd_pos_y(i*8+7 downto i*8)) + TILE_SIZE
        else '0';
    end generate;

    ------------------------------------------------------------
    -- ÉTAPE 2 : Priorité - trouver l'acteur gagnant
    -- On parcourt de l'acteur 7 vers l'acteur 0.
    -- L'acteur 0 écrase tous les autres → priorité maximale.
    ------------------------------------------------------------
    process(acteur_visible)
    begin
        acteur_gagnant  <= 0;
        un_acteur_actif <= '0';

        for i in NB_ACTEURS-1 downto 0 loop
            if acteur_visible(i) = '1' then
                acteur_gagnant  <= i;
                un_acteur_actif <= '1';
            end if;
        end loop;
    end process;

------------------------------------------------------------
    -- ÉTAPE 3 : Calcul de l'adresse dans tile_bram
    -- Même logique que pour le fond :
    --   adresse = tile_id * 64 + offset_y * 8 + offset_x
    --
    -- offset_x = col - pos_x de l'acteur gagnant
    -- offset_y = lig - pos_y de l'acteur gagnant
    ------------------------------------------------------------
    gagnant_tile_id <= unsigned(rd_tile_id(acteur_gagnant*4+3 downto acteur_gagnant*4));

    gagnant_px <= resize(
        col - unsigned(rd_pos_x(acteur_gagnant*8+7 downto acteur_gagnant*8)),
        3
    );

    gagnant_py <= resize(
        lig - unsigned(rd_pos_y(acteur_gagnant*8+7 downto acteur_gagnant*8)),
        3
    );

    -- Utilisation de resize() pour forcer le résultat sur 12 bits
    -- to_unsigned(64, 7) au lieu de 6, car il faut 7 bits pour écrire 64
    sprite_tile_addr <= std_logic_vector(resize(
        gagnant_tile_id * to_unsigned(TILE_SIZE * TILE_SIZE, 7)
        + gagnant_py * to_unsigned(TILE_SIZE, 4)
        + gagnant_px,
        12
    ));

    ------------------------------------------------------------
    -- ÉTAPE 4 : Sortie vers le priority_mux
    -- sprite_active indique si on a trouvé un acteur
    -- sprite_color est le color_index lu dans la tile_bram
    -- (la tile_bram répond 1 cycle après sprite_tile_addr)
    ------------------------------------------------------------
    sprite_active <= un_acteur_actif;
    sprite_color  <= sprite_tile_data;

end Behavioral;