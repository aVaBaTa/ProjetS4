----------------------------------------------------------------------------------
-- bg_renderer.vhd
--
-- Renderer de l'arrière-plan. Remplace le testPatternGenerator.
--
-- Il garde exactement la même machine à états (WAITING, STREAMING, EOL)
-- et les mêmes signaux AXI-Stream que le testPatternGenerator original.
--
-- La seule différence : au lieu d'alterner colorA/colorB,
-- il fait une chaîne de 2 lectures pour chaque pixel :
--
--   Cycle N   : on lit la tilemap  (adresse = ligne_case * 32 + col_case)
--   Cycle N+1 : on lit la tile_bram (adresse = tile_id * 64 + pixel_y * 8 + pixel_x)
--               EN PARALLÈLE on convertit l'index via la palette
--   Cycle N+2 : on a le RGB final, on l'envoie sur m_axis_tdata
--
-- Pour compenser ces 2 cycles de latence, on utilise 2 registres de délai
-- sur columnCpt et lineCpt (delayed_col, delayed_lin).
-- Le pixel affiché correspond toujours aux coordonnées d'il y a 2 cycles.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bg_renderer is
    generic (
        -- Résolution écran
        H_RES          : integer := 256;   -- pixels par ligne
        V_RES          : integer := 224;   -- lignes visibles

        -- Paramètres tuiles (doivent correspondre à tile_bram et tilemap_bram)
        TILE_SIZE      : integer := 8;     -- tuiles 8x8
        BITS_PAR_PIXEL : integer := 2;     -- 2 bits = 4 couleurs
        BITS_TILE_ID   : integer := 4      -- 4 bits = 16 tuiles
    );
    port (
        clk            : in  std_logic;
        rstn           : in  std_logic;

        -- Interface AXI-Stream vers v_proc_ss_0 (identique au testPatternGenerator)
        m_axis_tuser   : out std_logic;
        m_axis_tlast   : out std_logic;
        m_axis_tvalid  : out std_logic;
        m_axis_tdata   : out std_logic_vector(23 downto 0);
        m_axis_tready  : in  std_logic;

        -- Connexion vers tilemap_bram
        tilemap_addr   : out std_logic_vector(9 downto 0);
        tilemap_data   : in  std_logic_vector(BITS_TILE_ID-1 downto 0);

        -- Connexion vers tile_bram
        tile_addr      : out std_logic_vector(11 downto 0);
        tile_data      : in  std_logic_vector(BITS_PAR_PIXEL-1 downto 0);

        -- Connexion vers palette
        palette_index  : out std_logic_vector(BITS_PAR_PIXEL-1 downto 0);
        palette_rgb    : in  std_logic_vector(23 downto 0);

        -- Coordonnées du pixel actuellement en sortie sur m_axis_tdata
        -- (synchronisées avec palette_rgb, donc retardées de 2 cycles
        --  par rapport à columnCpt/lineCpt - voir delayed_col_2/lin_2)
        -- NE PAS utiliser pour piloter le sprite_renderer (voir o_pixel_x_sprite)
        o_pixel_x      : out std_logic_vector(10 downto 0);
        o_pixel_y      : out std_logic_vector(10 downto 0);

        -- Coordonnées retardées de 1 cycle (delayed_col_1/lin_1).
        -- À utiliser pour piloter le sprite_renderer : sa lecture de
        -- tile_bram (1 cycle) le remettra en phase avec bg_palette_rgb
        -- au cycle suivant, exactement comme le fond.
        o_pixel_x_sprite : out std_logic_vector(10 downto 0);
        o_pixel_y_sprite : out std_logic_vector(10 downto 0)
    );
end bg_renderer;

architecture Behavioral of bg_renderer is

    -- Machine à états (identique au testPatternGenerator)
    type state_videostr is (WAITING, STREAMING, EOL);
    signal current_state : state_videostr := WAITING;
    signal next_state    : state_videostr := WAITING;

    -- Compteurs de pixels (identiques au testPatternGenerator)
    signal columnCpt : unsigned(10 downto 0) := (others => '0');
    signal lineCpt   : unsigned(10 downto 0) := (others => '0');

    -- Registres de délai pour compenser la latence des BRAMs
    -- delayed_col/lin_1 = coordonnées d'il y a 1 cycle (après lecture tilemap)
    -- delayed_col/lin_2 = coordonnées d'il y a 2 cycles (après lecture tile_bram)
    signal delayed_col_1 : unsigned(10 downto 0) := (others => '0');
    signal delayed_lin_1 : unsigned(10 downto 0) := (others => '0');
    signal delayed_col_2 : unsigned(10 downto 0) := (others => '0');
    signal delayed_lin_2 : unsigned(10 downto 0) := (others => '0');

    -- Constantes calculées automatiquement depuis les generics
    -- Nombre de colonnes de cases dans la tilemap
    constant NB_COL_CASES : integer := H_RES / TILE_SIZE;   -- 256/8 = 32
    -- Nombre de lignes de cases dans la tilemap
    constant NB_LIG_CASES : integer := V_RES / TILE_SIZE;   -- 224/8 = 28
    -- Valeur max de columnCpt (H_RES - 1 = 255)
    constant COL_MAX      : unsigned(10 downto 0) :=
        to_unsigned(H_RES - 1, 11);
    -- Valeur max de lineCpt (V_RES - 1 = 223)
    constant LIN_MAX      : unsigned(10 downto 0) :=
        to_unsigned(V_RES - 1, 11);

begin

    -----------------------------------------------------------------------
    -- PROCESSUS 1 : Compteurs de pixels (copié du testPatternGenerator)
    -- Avance columnCpt et lineCpt à chaque cycle quand tready est actif
    -----------------------------------------------------------------------
    process(clk)
    begin
        if rstn = '0' then
            current_state <= WAITING;
            columnCpt     <= (others => '0');
            lineCpt       <= (others => '0');
        elsif rising_edge(clk) then
            current_state <= next_state;

            if m_axis_tready = '1' then
                if columnCpt = COL_MAX then
                    columnCpt <= (others => '0');
                    if lineCpt = LIN_MAX then
                        lineCpt <= (others => '0');
                    else
                        lineCpt <= lineCpt + 1;
                    end if;
                else
                    columnCpt <= columnCpt + 1;
                end if;
            end if;

            -- Registres de délai : on mémorise les coordonnées
            -- pour savoir quel pixel correspond à la couleur qu'on reçoit
            delayed_col_1 <= columnCpt;
            delayed_lin_1 <= lineCpt;
            delayed_col_2 <= delayed_col_1;
            delayed_lin_2 <= delayed_lin_1;
        end if;
    end process;

    -----------------------------------------------------------------------
    -- PROCESSUS 2 : Machine à états (identique au testPatternGenerator)
    -----------------------------------------------------------------------
    process(current_state, m_axis_tready, columnCpt, lineCpt)
    begin
        case current_state is
            when WAITING =>
                if m_axis_tready = '1' then
                    next_state <= STREAMING;
                else
                    next_state <= WAITING;
                end if;

            when STREAMING =>
                if columnCpt = COL_MAX then
                    next_state <= EOL;
                else
                    next_state <= STREAMING;
                end if;

            when EOL =>
                if lineCpt = LIN_MAX then
                    next_state <= WAITING;
                else
                    next_state <= STREAMING;
                end if;
        end case;
    end process;

    -----------------------------------------------------------------------
    -- PROCESSUS 3 : Signaux AXI-Stream de contrôle
    -- (identique au testPatternGenerator)
    -----------------------------------------------------------------------
    process(current_state)
    begin
        case current_state is
            when WAITING =>
                m_axis_tvalid <= '1';
                m_axis_tuser  <= '1';   -- Start Of Frame
                m_axis_tlast  <= '0';
            when STREAMING =>
                m_axis_tvalid <= '1';
                m_axis_tuser  <= '0';
                m_axis_tlast  <= '0';
            when EOL =>
                m_axis_tvalid <= '1';
                m_axis_tuser  <= '0';
                m_axis_tlast  <= '1';   -- End Of Line
        end case;
    end process;

    -----------------------------------------------------------------------
    -- LOGIQUE COMBINATOIRE : Chaîne de lecture des mémoires
    --
    -- CYCLE N (coordonnées actuelles) :
    --   → On calcule l'adresse dans la tilemap
    --   → La tilemap répondra au cycle N+1 avec le tile_id
    --
    -- CYCLE N+1 (coordonnées dans delayed_*_1, tile_id vient d'arriver) :
    --   → On calcule l'adresse dans la tile_bram avec le tile_id reçu
    --   → On envoie aussi le color_index à la palette (si on l'avait déjà)
    --   → La tile_bram répondra au cycle N+2 avec le color_index
    --
    -- CYCLE N+2 (coordonnées dans delayed_*_2, color_index vient d'arriver) :
    --   → La palette nous donne le RGB final via palette_rgb
    --   → On met ce RGB sur m_axis_tdata
    -----------------------------------------------------------------------

    -- LECTURE TILEMAP (cycle N)
    -- Adresse = (lineCpt / TILE_SIZE) * NB_COL_CASES + (columnCpt / TILE_SIZE)
    -- Division par TILE_SIZE = décalage de 3 bits (car TILE_SIZE=8=2^3)
    tilemap_addr <= std_logic_vector(
        lineCpt(10 downto 3) * to_unsigned(NB_COL_CASES, 5)
        + columnCpt(10 downto 3)
    );

    -- LECTURE TILE_BRAM (cycle N+1)
    -- Le tile_id vient d'arriver (tilemap_data)
    -- Adresse = tile_id * (TILE_SIZE*TILE_SIZE)
    --         + pixel_y_dans_tuile * TILE_SIZE
    --         + pixel_x_dans_tuile
    -- pixel_y = delayed_lin_1 mod 8 = delayed_lin_1(2 downto 0)
    -- pixel_x = delayed_col_1 mod 8 = delayed_col_1(2 downto 0)
    tile_addr <= std_logic_vector(
        unsigned(tilemap_data) * to_unsigned(TILE_SIZE * TILE_SIZE, 6)
        + delayed_lin_1(2 downto 0) * to_unsigned(TILE_SIZE, 4)
        + delayed_col_1(2 downto 0)
    );

    -- LECTURE PALETTE (cycle N+1, résultat disponible au cycle N+2)
    -- On envoie le color_index qu'on vient de recevoir de la tile_bram
    -- Note : tile_data est le résultat de la lecture du cycle précédent
    palette_index <= tile_data;

    -- SORTIE PIXEL (cycle N+2)
    -- La palette nous donne le RGB final
    m_axis_tdata <= palette_rgb;

    -----------------------------------------------------------------------
    -- COORDONNÉES EXPOSÉES POUR LE SPRITE_RENDERER
    --
    -- Important : palette_rgb correspond aux coordonnées d'il y a 2 cycles
    -- (delayed_col_2/delayed_lin_2), PAS aux coordonnées actuelles
    -- (columnCpt/lineCpt). Le sprite_renderer doit donc recevoir
    -- delayed_col_2/delayed_lin_2 pour rester synchronisé avec le fond
    -- au moment où le priority_mux compare les deux couleurs.
    -----------------------------------------------------------------------
    o_pixel_x <= std_logic_vector(delayed_col_2);
    o_pixel_y <= std_logic_vector(delayed_lin_2);

    -- Pour le sprite_renderer : coordonnées d'il y a 1 cycle.
    -- Le sprite_renderer détecte (0 cycle) puis lit sa tile_bram (1 cycle),
    -- donc son sprite_color/sprite_palette_rgb arrivera 1 cycle après ça -
    -- exactement au même cycle que bg_palette_rgb (delayed_*_2).
    o_pixel_x_sprite <= std_logic_vector(delayed_col_1);
    o_pixel_y_sprite <= std_logic_vector(delayed_lin_1);

end Behavioral;