----------------------------------------------------------------------------------
-- tile_bram.vhd
--
-- Mémoire BRAM qui stocke les données graphiques de toutes les tuiles.
-- Chaque tuile fait TILE_SIZE x TILE_SIZE pixels.
-- Chaque pixel est un index de couleur sur BITS_PAR_PIXEL bits.
--
-- Pour changer la taille des tuiles ou le nombre de couleurs,
-- il suffit de modifier les generics dans l'instantiation.
--
-- Adressage :
--   adresse = tile_id * (TILE_SIZE * TILE_SIZE)
--           + ligne_dans_tuile * TILE_SIZE
--           + colonne_dans_tuile
--
-- Exemple avec les valeurs par défaut (8x8, 2 bits/pixel, 16 tuiles) :
--   Taille totale = 16 tuiles * 64 pixels * 2 bits = 2048 bits = 256 bytes
--   -> Tient facilement dans une BRAM Xilinx
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tile_bram is
    generic (
        TILE_SIZE      : integer := 8;   -- Largeur ET hauteur d'une tuile en pixels
                                          -- Changer à 16 pour des tuiles 16x16
        BITS_PAR_PIXEL : integer := 2;   -- Bits par pixel = nombre de couleurs possibles
                                          -- 2 bits = 4 couleurs, 4 bits = 16 couleurs
        NB_TUILES      : integer := 16   -- Nombre de tuiles différentes
                                          -- 16 tuiles = index 0 à 15
    );
    port (
        clk         : in  std_logic;

        -- Port écriture (depuis le CPU/AXI pour charger les tuiles)
        we          : in  std_logic;                    -- Write Enable
        wr_addr     : in  std_logic_vector(11 downto 0); -- Adresse d'écriture
        wr_data     : in  std_logic_vector(BITS_PAR_PIXEL-1 downto 0); -- Donnée à écrire

        -- Port lecture (depuis le renderer pour dessiner)
        rd_addr     : in  std_logic_vector(11 downto 0); -- Adresse de lecture
        rd_data     : out std_logic_vector(BITS_PAR_PIXEL-1 downto 0)  -- Couleur du pixel
    );
end tile_bram;

architecture Behavioral of tile_bram is

    -- Calcul automatique de la taille de la mémoire
    -- NB_TUILES tuiles, chacune de TILE_SIZE*TILE_SIZE pixels
    constant MEM_SIZE : integer := NB_TUILES * TILE_SIZE * TILE_SIZE;
    -- Exemple défaut : 16 * 8 * 8 = 1024 entrées

    -- Déclaration de la mémoire
    -- Chaque entrée = un pixel = BITS_PAR_PIXEL bits (index de couleur)
    type tile_mem_t is array(0 to MEM_SIZE-1) of
        std_logic_vector(BITS_PAR_PIXEL-1 downto 0);

    -- La mémoire elle-même, avec des tuiles de test pré-chargées
    -- Tuile 0 : toute noire (couleur index 0)
    -- Tuile 1 : tuile avec un "X" en couleur 1 sur fond 0
    -- Tuile 2 : tuile pleine en couleur 2
    -- Tuiles 3-15 : toutes noires pour l'instant
    signal tile_mem : tile_mem_t := (
        -- =====================
        -- TUILE 0 : fond noir (couleur 0 partout)
        -- =====================
        -- 8 lignes x 8 colonnes = 64 pixels
        0  => "00", 1  => "00", 2  => "00", 3  => "00",
        4  => "00", 5  => "00", 6  => "00", 7  => "00",  -- ligne 0
        8  => "00", 9  => "00", 10 => "00", 11 => "00",
        12 => "00", 13 => "00", 14 => "00", 15 => "00",  -- ligne 1
        16 => "00", 17 => "00", 18 => "00", 19 => "00",
        20 => "00", 21 => "00", 22 => "00", 23 => "00",  -- ligne 2
        24 => "00", 25 => "00", 26 => "00", 27 => "00",
        28 => "00", 29 => "00", 30 => "00", 31 => "00",  -- ligne 3
        32 => "00", 33 => "00", 34 => "00", 35 => "00",
        36 => "00", 37 => "00", 38 => "00", 39 => "00",  -- ligne 4
        40 => "00", 41 => "00", 42 => "00", 43 => "00",
        44 => "00", 45 => "00", 46 => "00", 47 => "00",  -- ligne 5
        48 => "00", 49 => "00", 50 => "00", 51 => "00",
        52 => "00", 53 => "00", 54 => "00", 55 => "00",  -- ligne 6
        56 => "00", 57 => "00", 58 => "00", 59 => "00",
        60 => "00", 61 => "00", 62 => "00", 63 => "00",  -- ligne 7

        -- =====================
        -- TUILE 1 : carré plein couleur 1 (ex: blanc)
        -- =====================
        64 => "01", 65 => "01", 66 => "01", 67 => "01",
        68 => "01", 69 => "01", 70 => "01", 71 => "01",
        72 => "01", 73 => "01", 74 => "01", 75 => "01",
        76 => "01", 77 => "01", 78 => "01", 79 => "01",
        80 => "01", 81 => "01", 82 => "01", 83 => "01",
        84 => "01", 85 => "01", 86 => "01", 87 => "01",
        88 => "01", 89 => "01", 90 => "01", 91 => "01",
        92 => "01", 93 => "01", 94 => "01", 95 => "01",
        96 => "01", 97 => "01", 98 => "01", 99 => "01",
        100=> "01", 101=> "01", 102=> "01", 103=> "01",
        104=> "01", 105=> "01", 106=> "01", 107=> "01",
        108=> "01", 109=> "01", 110=> "01", 111=> "01",
        112=> "01", 113=> "01", 114=> "01", 115=> "01",
        116=> "01", 117=> "01", 118=> "01", 119=> "01",
        120=> "01", 121=> "01", 122=> "01", 123=> "01",
        124=> "01", 125=> "01", 126=> "01", 127=> "01",

        -- =====================
        -- TUILE 2 : bordure couleur 2, intérieur couleur 0
        -- =====================
        128=> "10", 129=> "10", 130=> "10", 131=> "10",
        132=> "10", 133=> "10", 134=> "10", 135=> "10",  -- ligne 0 : pleine
        136=> "10", 137=> "00", 138=> "00", 139=> "00",
        140=> "00", 141=> "00", 142=> "00", 143=> "10",  -- ligne 1 : bordure
        144=> "10", 145=> "00", 146=> "00", 147=> "00",
        148=> "00", 149=> "00", 150=> "00", 151=> "10",  -- ligne 2
        152=> "10", 153=> "00", 154=> "00", 155=> "00",
        156=> "00", 157=> "00", 158=> "00", 159=> "10",  -- ligne 3
        160=> "10", 161=> "00", 162=> "00", 163=> "00",
        164=> "00", 165=> "00", 166=> "00", 167=> "10",  -- ligne 4
        168=> "10", 169=> "00", 170=> "00", 171=> "00",
        172=> "00", 173=> "00", 174=> "00", 175=> "10",  -- ligne 5
        176=> "10", 177=> "00", 178=> "00", 179=> "00",
        180=> "00", 181=> "00", 182=> "00", 183=> "10",  -- ligne 6
        184=> "10", 185=> "10", 186=> "10", 187=> "10",
        188=> "10", 189=> "10", 190=> "10", 191=> "10",  -- ligne 7 : pleine

        -- Tuiles 3 à 15 : toutes noires (couleur 0)
        others => "00"
    );

begin

    -- Processus BRAM synchrone (lecture et écriture sur front montant)
    process(clk)
    begin
        if rising_edge(clk) then
            -- Écriture : si write enable actif, on écrit à l'adresse demandée
            if we = '1' then
                tile_mem(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;
            -- Lecture : toujours active, 1 cycle de latence (comportement BRAM)
            rd_data <= tile_mem(to_integer(unsigned(rd_addr)));
        end if;
    end process;

end Behavioral;