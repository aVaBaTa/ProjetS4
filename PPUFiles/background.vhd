----------------------------------------------------------------------------------
-- tilemap_bram.vhd
--
-- Mémoire qui stocke la grille de l'arrière-plan.
-- Chaque entrée = un numéro de tuile (tile_id) pour une case de l'écran.
--
-- Pour un écran 256x224 avec des tuiles 8x8 :
--   32 colonnes x 28 lignes = 896 cases
--   Chaque case = 4 bits (index de tuile 0 à 15)
--
-- Adressage :
--   adresse = ligne * NB_COLONNES + colonne
--
-- Exemple : case (colonne=3, ligne=2) -> adresse = 2*32 + 3 = 67
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tilemap_bram is
    generic (
        NB_COLONNES    : integer := 32;  -- 256 pixels / 8 pixels par tuile
        NB_LIGNES      : integer := 28;  -- 224 pixels / 8 pixels par tuile
        BITS_TILE_ID   : integer := 4    -- 4 bits = 16 tuiles possibles (0 à 15)
                                         -- Changer à 8 pour 256 tuiles possibles
    );
    port (
        clk      : in  std_logic;

        -- Port écriture (depuis le CPU pour modifier la carte)
        we       : in  std_logic;
        wr_addr  : in  std_logic_vector(9 downto 0);  -- 10 bits = 1024 > 896 cases
        wr_data  : in  std_logic_vector(BITS_TILE_ID-1 downto 0);

        -- Port lecture (depuis le renderer)
        rd_addr  : in  std_logic_vector(9 downto 0);
        rd_data  : out std_logic_vector(BITS_TILE_ID-1 downto 0)
    );
end tilemap_bram;

architecture Behavioral of tilemap_bram is

    constant MEM_SIZE : integer := NB_COLONNES * NB_LIGNES;  -- 896 cases

    type tilemap_t is array(0 to MEM_SIZE-1) of
        std_logic_vector(BITS_TILE_ID-1 downto 0);

    -- Carte de test :
    -- La plupart des cases = tuile 0 (fond noir)
    -- Quelques cases = tuile 1 ou 2 pour voir quelque chose
    --
    -- Visuellement (les chiffres = numéro de tuile) :
    --
    --  Col: 0  1  2  3  4 ... 31
    -- Lig0: 0  0  0  0  0 ...  0   <- fond noir
    -- Lig1: 0  1  1  1  0 ...  0   <- 3 tuiles pleines
    -- Lig2: 0  1  2  1  0 ...  0   <- tuile bordure au centre
    -- Lig3: 0  1  1  1  0 ...  0
    -- Lig4: 0  0  0  0  0 ...  0
    -- ...
    signal tilemap_mem : tilemap_t := (
        -- Ligne 0 : toute noire (cases 0 à 31)
        0   => "0000", 1   => "0000", 2   => "0000", 3   => "0000",
        4   => "0000", 5   => "0000", 6   => "0000", 7   => "0000",
        8   => "0000", 9   => "0000", 10  => "0000", 11  => "0000",
        12  => "0000", 13  => "0000", 14  => "0000", 15  => "0000",
        16  => "0000", 17  => "0000", 18  => "0000", 19  => "0000",
        20  => "0000", 21  => "0000", 22  => "0000", 23  => "0000",
        24  => "0000", 25  => "0000", 26  => "0000", 27  => "0000",
        28  => "0000", 29  => "0000", 30  => "0000", 31  => "0000",

        -- Ligne 1 : cases 32 à 63
        -- case (col=1,lig=1)=addr 33, (col=2)=34, (col=3)=35 -> tuile 1
        32  => "0000", 33  => "0001", 34  => "0001", 35  => "0001",
        36  => "0000", 37  => "0000", 38  => "0000", 39  => "0000",
        40  => "0000", 41  => "0000", 42  => "0000", 43  => "0000",
        44  => "0000", 45  => "0000", 46  => "0000", 47  => "0000",
        48  => "0000", 49  => "0000", 50  => "0000", 51  => "0000",
        52  => "0000", 53  => "0000", 54  => "0000", 55  => "0000",
        56  => "0000", 57  => "0000", 58  => "0000", 59  => "0000",
        60  => "0000", 61  => "0000", 62  => "0000", 63  => "0000",

        -- Ligne 2 : cases 64 à 95
        -- (col=1)=65 -> tuile 1, (col=2)=66 -> tuile 2 (bordure), (col=3)=67 -> tuile 1
        64  => "0000", 65  => "0001", 66  => "0010", 67  => "0001",
        68  => "0000", 69  => "0000", 70  => "0000", 71  => "0000",
        72  => "0000", 73  => "0000", 74  => "0000", 75  => "0000",
        76  => "0000", 77  => "0000", 78  => "0000", 79  => "0000",
        80  => "0000", 81  => "0000", 82  => "0000", 83  => "0000",
        84  => "0000", 85  => "0000", 86  => "0000", 87  => "0000",
        88  => "0000", 89  => "0000", 90  => "0000", 91  => "0000",
        92  => "0000", 93  => "0000", 94  => "0000", 95  => "0000",

        -- Ligne 3 : cases 96 à 127
        96  => "0000", 97  => "0001", 98  => "0001", 99  => "0001",
        100 => "0000", 101 => "0000", 102 => "0000", 103 => "0000",
        104 => "0000", 105 => "0000", 106 => "0000", 107 => "0000",
        108 => "0000", 109 => "0000", 110 => "0000", 111 => "0000",
        112 => "0000", 113 => "0000", 114 => "0000", 115 => "0000",
        116 => "0000", 117 => "0000", 118 => "0000", 119 => "0000",
        120 => "0000", 121 => "0000", 122 => "0000", 123 => "0000",
        124 => "0000", 125 => "0000", 126 => "0000", 127 => "0000",

        -- Lignes 4 à 27 : toutes noires
        others => "0000"
    );

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                tilemap_mem(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;
            rd_data <= tilemap_mem(to_integer(unsigned(rd_addr)));
        end if;
    end process;

end Behavioral;