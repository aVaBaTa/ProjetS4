----------------------------------------------------------------------------------
-- ppu_top.vhd (version 2 - avec sprites)
--
-- Connecte tous les modules du PPU :
--   - tile_bram        : données graphiques des tuiles (fond ET sprites)
--   - tilemap_bram     : grille de l'arrière-plan
--   - oam              : table des 8 acteurs (sprites)
--   - palette          : index couleur → RGB (partagée fond et sprites)
--   - bg_renderer      : génère les pixels du fond
--   - sprite_renderer  : détecte et lit les pixels des sprites
--   - priority_mux     : choisit entre fond et sprite
--
-- Plan d'adressage AXI-Lite (slv_reg0 = commande, slv_reg1 = donnée) :
--
--   Écriture tile_bram  : slv_reg0[21:20]="00", [31:22]=adresse(12b), [0]=1
--                         slv_reg1[1:0] = color_index (2 bits)
--
--   Écriture tilemap    : slv_reg0[21:20]="01", [31:22]=adresse(10b), [0]=1
--                         slv_reg1[3:0] = tile_id (4 bits)
--
--   Écriture palette    : slv_reg0[21:20]="10", [31:22]=adresse(2b),  [0]=1
--                         slv_reg1[23:0] = RGB 24 bits
--
--   Écriture OAM        : slv_reg0[21:20]="11", [24:22]=index acteur, [0]=1
--                         slv_reg1[7:0]   = pos_x
--                         slv_reg1[15:8]  = pos_y
--                         slv_reg1[19:16] = tile_id
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ppu_top is
    generic (
        C_S00_AXI_DATA_WIDTH : integer := 32;
        C_S00_AXI_ADDR_WIDTH : integer := 4
    );
    port (
        -- Interface AXI-Stream vers v_proc_ss_0
        m_axis_tuser   : out std_logic;
        m_axis_tlast   : out std_logic;
        m_axis_tvalid  : out std_logic;
        m_axis_tdata   : out std_logic_vector(23 downto 0);
        m_axis_tready  : in  std_logic;

        -- Interface AXI-Lite depuis le PS
        s00_axi_aclk    : in  std_logic;
        s00_axi_aresetn : in  std_logic;
        s00_axi_awaddr  : in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_awprot  : in  std_logic_vector(2 downto 0);
        s00_axi_awvalid : in  std_logic;
        s00_axi_awready : out std_logic;
        s00_axi_wdata   : in  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_wstrb   : in  std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
        s00_axi_wvalid  : in  std_logic;
        s00_axi_wready  : out std_logic;
        s00_axi_bresp   : out std_logic_vector(1 downto 0);
        s00_axi_bvalid  : out std_logic;
        s00_axi_bready  : in  std_logic;
        s00_axi_araddr  : in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_arprot  : in  std_logic_vector(2 downto 0);
        s00_axi_arvalid : in  std_logic;
        s00_axi_arready : out std_logic;
        s00_axi_rdata   : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_rresp   : out std_logic_vector(1 downto 0);
        s00_axi_rvalid  : out std_logic;
        s00_axi_rready  : in  std_logic
    );
end ppu_top;

architecture Behavioral of ppu_top is

    ------------------------------------------------------------
    -- Déclaration des composants
    ------------------------------------------------------------
    component tile_bram is
        generic (
            TILE_SIZE      : integer := 8;
            BITS_PAR_PIXEL : integer := 2;
            NB_TUILES      : integer := 16
        );
        port (
            clk      : in  std_logic;
            we       : in  std_logic;
            wr_addr  : in  std_logic_vector(11 downto 0);
            wr_data  : in  std_logic_vector(1 downto 0);
            rd_addr  : in  std_logic_vector(11 downto 0);
            rd_data  : out std_logic_vector(1 downto 0)
        );
    end component;

    component tilemap_bram is
        generic (
            NB_COLONNES  : integer := 32;
            NB_LIGNES    : integer := 28;
            BITS_TILE_ID : integer := 4
        );
        port (
            clk      : in  std_logic;
            we       : in  std_logic;
            wr_addr  : in  std_logic_vector(9 downto 0);
            wr_data  : in  std_logic_vector(3 downto 0);
            rd_addr  : in  std_logic_vector(9 downto 0);
            rd_data  : out std_logic_vector(3 downto 0)
        );
    end component;

    component oam is
        generic (NB_ACTEURS : integer := 8);
        port (
            clk        : in  std_logic;
            we         : in  std_logic;
            wr_index   : in  std_logic_vector(2 downto 0);
            wr_pos_x   : in  std_logic_vector(7 downto 0);
            wr_pos_y   : in  std_logic_vector(7 downto 0);
            wr_tile_id : in  std_logic_vector(3 downto 0);
            rd_pos_x   : out std_logic_vector(63 downto 0);
            rd_pos_y   : out std_logic_vector(63 downto 0);
            rd_tile_id : out std_logic_vector(31 downto 0)
        );
    end component;

    component palette is
        generic (
            NB_COULEURS  : integer := 4;
            BITS_COULEUR : integer := 24
        );
        port (
            clk         : in  std_logic;
            we          : in  std_logic;
            wr_addr     : in  std_logic_vector(1 downto 0);
            wr_data     : in  std_logic_vector(23 downto 0);
            color_index : in  std_logic_vector(1 downto 0);
            rgb_out     : out std_logic_vector(23 downto 0)
        );
    end component;

    component bg_renderer is
        generic (
            H_RES          : integer := 256;
            V_RES          : integer := 224;
            TILE_SIZE      : integer := 8;
            BITS_PAR_PIXEL : integer := 2;
            BITS_TILE_ID   : integer := 4
        );
        port (
            clk           : in  std_logic;
            rstn          : in  std_logic;
            m_axis_tuser  : out std_logic;
            m_axis_tlast  : out std_logic;
            m_axis_tvalid : out std_logic;
            m_axis_tdata  : out std_logic_vector(23 downto 0);
            m_axis_tready : in  std_logic;
            tilemap_addr  : out std_logic_vector(9  downto 0);
            tilemap_data  : in  std_logic_vector(3  downto 0);
            tile_addr     : out std_logic_vector(11 downto 0);
            tile_data     : in  std_logic_vector(1  downto 0);
            palette_index : out std_logic_vector(1  downto 0);
            palette_rgb   : in  std_logic_vector(23 downto 0);
            -- Coordonnées courantes exposées pour le sprite_renderer
            o_pixel_x        : out std_logic_vector(10 downto 0);
            o_pixel_y        : out std_logic_vector(10 downto 0);
            o_pixel_x_sprite : out std_logic_vector(10 downto 0);
            o_pixel_y_sprite : out std_logic_vector(10 downto 0)
        );
    end component;

    component sprite_renderer is
        generic (
            NB_ACTEURS     : integer := 8;
            TILE_SIZE      : integer := 8;
            BITS_PAR_PIXEL : integer := 2;
            BITS_TILE_ID   : integer := 4
        );
        port (
            pixel_x          : in  std_logic_vector(10 downto 0);
            pixel_y          : in  std_logic_vector(10 downto 0);
            rd_pos_x         : in  std_logic_vector(63 downto 0);
            rd_pos_y         : in  std_logic_vector(63 downto 0);
            rd_tile_id       : in  std_logic_vector(31 downto 0);
            sprite_tile_addr : out std_logic_vector(11 downto 0);
            sprite_tile_data : in  std_logic_vector(1  downto 0);
            sprite_active    : out std_logic;
            sprite_color     : out std_logic_vector(1  downto 0)
        );
    end component;

    component priority_mux is
        generic (BITS_PAR_PIXEL : integer := 2);
        port (
            bg_rgb        : in  std_logic_vector(23 downto 0);
            sprite_active : in  std_logic;
            sprite_color  : in  std_logic_vector(1  downto 0);
            sprite_rgb    : in  std_logic_vector(23 downto 0);
            pixel_rgb     : out std_logic_vector(23 downto 0)
        );
    end component;

    ------------------------------------------------------------
    -- Signaux internes
    ------------------------------------------------------------

    -- Fond
    signal tilemap_rd_addr   : std_logic_vector(9  downto 0);
    signal tilemap_rd_data   : std_logic_vector(3  downto 0);
    signal bg_tile_addr      : std_logic_vector(11 downto 0);
    signal bg_tile_data      : std_logic_vector(1  downto 0);
    signal bg_palette_index  : std_logic_vector(1  downto 0);
    signal bg_palette_rgb    : std_logic_vector(23 downto 0);
    signal bg_tuser          : std_logic;
    signal bg_tlast          : std_logic;
    signal bg_tvalid         : std_logic;
    signal bg_tdata          : std_logic_vector(23 downto 0);

    -- Coordonnées courantes exposées par le bg_renderer
    signal current_pixel_x   : std_logic_vector(10 downto 0);
    signal current_pixel_y   : std_logic_vector(10 downto 0);
    signal sprite_pixel_x    : std_logic_vector(10 downto 0);
    signal sprite_pixel_y    : std_logic_vector(10 downto 0);

    -- Sprites
    signal sprite_tile_addr  : std_logic_vector(11 downto 0);
    signal sprite_tile_data  : std_logic_vector(1  downto 0);
    signal sprite_active     : std_logic;
    signal sprite_color      : std_logic_vector(1  downto 0);
    signal sprite_palette_rgb: std_logic_vector(23 downto 0);
    signal oam_pos_x         : std_logic_vector(63 downto 0);
    signal oam_pos_y         : std_logic_vector(63 downto 0);
    signal oam_tile_id       : std_logic_vector(31 downto 0);

    -- Sortie finale du priority_mux
    signal final_rgb         : std_logic_vector(23 downto 0);

    -- AXI-Lite
    signal slv_reg0          : std_logic_vector(31 downto 0);
    signal slv_reg1          : std_logic_vector(31 downto 0);
    signal wr_target         : std_logic_vector(1 downto 0);
    signal wr_enable         : std_logic;
    signal we_tile           : std_logic;
    signal we_tilemap        : std_logic;
    signal we_palette        : std_logic;
    signal we_oam            : std_logic;
    signal axi_awaddr        : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    signal axi_awready       : std_logic;
    signal axi_wready        : std_logic;
    signal axi_bresp         : std_logic_vector(1 downto 0);
    signal axi_bvalid        : std_logic;
    signal axi_araddr        : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    signal axi_arready       : std_logic;
    signal axi_rresp         : std_logic_vector(1 downto 0);
    signal axi_rvalid        : std_logic;

    constant ADDR_LSB          : integer := (C_S00_AXI_DATA_WIDTH/32) + 1;
    constant OPT_MEM_ADDR_BITS : integer := 1;
    signal mem_logic           : std_logic_vector(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);

    constant Idle  : std_logic_vector(1 downto 0) := "00";
    constant Raddr : std_logic_vector(1 downto 0) := "10";
    constant Rdata : std_logic_vector(1 downto 0) := "11";
    constant Waddr : std_logic_vector(1 downto 0) := "10";
    constant Wdata : std_logic_vector(1 downto 0) := "11";
    signal state_read  : std_logic_vector(1 downto 0);
    signal state_write : std_logic_vector(1 downto 0);

begin

    ------------------------------------------------------------
    -- Sorties AXI-Stream
    -- tuser/tlast/tvalid : timing géré par le bg_renderer
    -- tdata              : couleur finale choisie par le priority_mux
    ------------------------------------------------------------
    m_axis_tuser  <= bg_tuser;
    m_axis_tlast  <= bg_tlast;
    m_axis_tvalid <= bg_tvalid;
    m_axis_tdata  <= final_rgb;   -- ← priority_mux, pas bg_tdata

    ------------------------------------------------------------
    -- Connexions AXI-Lite
    ------------------------------------------------------------
    s00_axi_awready <= axi_awready;
    s00_axi_wready  <= axi_wready;
    s00_axi_bresp   <= axi_bresp;
    s00_axi_bvalid  <= axi_bvalid;
    s00_axi_arready <= axi_arready;
    s00_axi_rresp   <= axi_rresp;
    s00_axi_rvalid  <= axi_rvalid;

    mem_logic <= s00_axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB)
                 when s00_axi_awvalid = '1'
                 else axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);

    ------------------------------------------------------------
    -- Machine à états AXI-Lite écriture
    ------------------------------------------------------------
    process(s00_axi_aclk)
    begin
        if rising_edge(s00_axi_aclk) then
            if s00_axi_aresetn = '0' then
                axi_awready <= '0'; axi_wready <= '0';
                axi_bvalid  <= '0'; axi_bresp  <= (others => '0');
                state_write <= Idle;
            else
                case state_write is
                    when Idle =>
                        if s00_axi_aresetn = '1' then
                            axi_awready <= '1'; axi_wready <= '1';
                            state_write <= Waddr;
                        end if;
                    when Waddr =>
                        if s00_axi_awvalid = '1' and axi_awready = '1' then
                            axi_awaddr <= s00_axi_awaddr;
                            if s00_axi_wvalid = '1' then
                                axi_awready <= '1'; state_write <= Waddr;
                                axi_bvalid  <= '1';
                            else
                                axi_awready <= '0'; state_write <= Wdata;
                                if s00_axi_bready = '1' and axi_bvalid = '1' then
                                    axi_bvalid <= '0';
                                end if;
                            end if;
                        else
                            state_write <= state_write;
                            if s00_axi_bready = '1' and axi_bvalid = '1' then
                                axi_bvalid <= '0';
                            end if;
                        end if;
                    when Wdata =>
                        if s00_axi_wvalid = '1' then
                            state_write <= Waddr; axi_bvalid <= '1';
                            axi_awready <= '1';
                        else
                            state_write <= state_write;
                            if s00_axi_bready = '1' and axi_bvalid = '1' then
                                axi_bvalid <= '0';
                            end if;
                        end if;
                    when others =>
                        axi_awready <= '0'; axi_wready <= '0'; axi_bvalid <= '0';
                end case;
            end if;
        end if;
    end process;

    ------------------------------------------------------------
    -- Registres AXI-Lite (slv_reg0 = commande, slv_reg1 = donnée)
    ------------------------------------------------------------
    process(s00_axi_aclk)
    begin
        if rising_edge(s00_axi_aclk) then
            if s00_axi_aresetn = '0' then
                slv_reg0 <= (others => '0');
                slv_reg1 <= (others => '0');
            else
                if s00_axi_wvalid = '1' then
                    case mem_logic is
                        when "00" =>
                            for i in 0 to (C_S00_AXI_DATA_WIDTH/8 - 1) loop
                                if s00_axi_wstrb(i) = '1' then
                                    slv_reg0(i*8+7 downto i*8) <=
                                        s00_axi_wdata(i*8+7 downto i*8);
                                end if;
                            end loop;
                        when "01" =>
                            for i in 0 to (C_S00_AXI_DATA_WIDTH/8 - 1) loop
                                if s00_axi_wstrb(i) = '1' then
                                    slv_reg1(i*8+7 downto i*8) <=
                                        s00_axi_wdata(i*8+7 downto i*8);
                                end if;
                            end loop;
                        when others => null;
                    end case;
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------
    -- Machine à états AXI-Lite lecture
    ------------------------------------------------------------
    process(s00_axi_aclk)
    begin
        if rising_edge(s00_axi_aclk) then
            if s00_axi_aresetn = '0' then
                axi_arready <= '0'; axi_rvalid <= '0';
                axi_rresp   <= (others => '0'); state_read <= Idle;
            else
                case state_read is
                    when Idle =>
                        if s00_axi_aresetn = '1' then
                            axi_arready <= '1'; state_read <= Raddr;
                        end if;
                    when Raddr =>
                        if s00_axi_arvalid = '1' and axi_arready = '1' then
                            state_read <= Rdata; axi_rvalid <= '1';
                            axi_arready <= '0'; axi_araddr <= s00_axi_araddr;
                        end if;
                    when Rdata =>
                        if axi_rvalid = '1' and s00_axi_rready = '1' then
                            axi_rvalid <= '0'; axi_arready <= '1';
                            state_read <= Raddr;
                        end if;
                    when others =>
                        axi_arready <= '0'; axi_rvalid <= '0';
                end case;
            end if;
        end if;
    end process;

    s00_axi_rdata <=
        slv_reg0 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "00" else
        slv_reg1 when axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB) = "01" else
        (others => '0');

    ------------------------------------------------------------
    -- Décodage écriture vers les mémoires
    ------------------------------------------------------------
    wr_target  <= slv_reg0(21 downto 20);
    wr_enable  <= slv_reg0(0);
    we_tile    <= wr_enable when wr_target = "00" else '0';
    we_tilemap <= wr_enable when wr_target = "01" else '0';
    we_palette <= wr_enable when wr_target = "10" else '0';
    we_oam     <= wr_enable when wr_target = "11" else '0';

    ------------------------------------------------------------
    -- Instanciation des modules
    ------------------------------------------------------------

    -- Tile BRAM pour le fond (port lecture branché sur bg_renderer)
    u_tile_bram_bg : tile_bram
        generic map (TILE_SIZE => 8, BITS_PAR_PIXEL => 2, NB_TUILES => 16)
        port map (
            clk     => s00_axi_aclk,
            we      => we_tile,
            wr_addr => slv_reg0(31 downto 20),
            wr_data => slv_reg1(1 downto 0),
            rd_addr => bg_tile_addr,
            rd_data => bg_tile_data
        );

    -- Tile BRAM pour les sprites (même écriture, port lecture séparé)
    -- On duplique la BRAM pour permettre 2 lectures simultanées
    u_tile_bram_sprite : tile_bram
        generic map (TILE_SIZE => 8, BITS_PAR_PIXEL => 2, NB_TUILES => 16)
        port map (
            clk     => s00_axi_aclk,
            we      => we_tile,
            wr_addr => slv_reg0(31 downto 20),
            wr_data => slv_reg1(1 downto 0),
            rd_addr => sprite_tile_addr,
            rd_data => sprite_tile_data
        );

    u_tilemap_bram : tilemap_bram
        generic map (NB_COLONNES => 32, NB_LIGNES => 28, BITS_TILE_ID => 4)
        port map (
            clk     => s00_axi_aclk,
            we      => we_tilemap,
            wr_addr => slv_reg0(29 downto 20),
            wr_data => slv_reg1(3 downto 0),
            rd_addr => tilemap_rd_addr,
            rd_data => tilemap_rd_data
        );

    u_oam : oam
        generic map (NB_ACTEURS => 8)
        port map (
            clk        => s00_axi_aclk,
            we         => we_oam,
            wr_index   => slv_reg0(24 downto 22),
            wr_pos_x   => slv_reg1(7  downto 0),
            wr_pos_y   => slv_reg1(15 downto 8),
            wr_tile_id => slv_reg1(19 downto 16),
            rd_pos_x   => oam_pos_x,
            rd_pos_y   => oam_pos_y,
            rd_tile_id => oam_tile_id
        );

    -- Palette fond
    u_palette_bg : palette
        generic map (NB_COULEURS => 4, BITS_COULEUR => 24)
        port map (
            clk         => s00_axi_aclk,
            we          => we_palette,
            wr_addr     => slv_reg0(21 downto 20),
            wr_data     => slv_reg1(23 downto 0),
            color_index => bg_palette_index,
            rgb_out     => bg_palette_rgb
        );

    -- Palette sprites (même contenu, index différent en entrée)
    u_palette_sprite : palette
        generic map (NB_COULEURS => 4, BITS_COULEUR => 24)
        port map (
            clk         => s00_axi_aclk,
            we          => we_palette,
            wr_addr     => slv_reg0(21 downto 20),
            wr_data     => slv_reg1(23 downto 0),
            color_index => sprite_color,
            rgb_out     => sprite_palette_rgb
        );

    -- Background renderer
    u_bg_renderer : bg_renderer
        generic map (
            H_RES => 256, V_RES => 224,
            TILE_SIZE => 8, BITS_PAR_PIXEL => 2, BITS_TILE_ID => 4
        )
        port map (
            clk           => s00_axi_aclk,
            rstn          => s00_axi_aresetn,
            m_axis_tuser  => bg_tuser,
            m_axis_tlast  => bg_tlast,
            m_axis_tvalid => bg_tvalid,
            m_axis_tdata  => bg_tdata,
            m_axis_tready => m_axis_tready,
            tilemap_addr  => tilemap_rd_addr,
            tilemap_data  => tilemap_rd_data,
            tile_addr     => bg_tile_addr,
            tile_data     => bg_tile_data,
            palette_index => bg_palette_index,
            palette_rgb   => bg_palette_rgb,
            o_pixel_x     => current_pixel_x,
            o_pixel_y     => current_pixel_y,
            o_pixel_x_sprite => sprite_pixel_x,
            o_pixel_y_sprite => sprite_pixel_y
        );

    -- Sprite renderer
    u_sprite_renderer : sprite_renderer
        generic map (
            NB_ACTEURS => 8, TILE_SIZE => 8,
            BITS_PAR_PIXEL => 2, BITS_TILE_ID => 4
        )
        port map (
            pixel_x          => sprite_pixel_x,
            pixel_y          => sprite_pixel_y,
            rd_pos_x         => oam_pos_x,
            rd_pos_y         => oam_pos_y,
            rd_tile_id       => oam_tile_id,
            sprite_tile_addr => sprite_tile_addr,
            sprite_tile_data => sprite_tile_data,
            sprite_active    => sprite_active,
            sprite_color     => sprite_color
        );

    -- Priority mux : décide fond ou sprite
    u_priority_mux : priority_mux
        generic map (BITS_PAR_PIXEL => 2)
        port map (
            bg_rgb        => bg_palette_rgb,
            sprite_active => sprite_active,
            sprite_color  => sprite_color,
            sprite_rgb    => sprite_palette_rgb,
            pixel_rgb     => final_rgb
        );

end Behavioral;