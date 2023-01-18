library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

------------------------------------------------------------------------------------------------------------------------
-- 800*600 72Hz VGA
------------------------------------------------------------------------------------------------------------------------
entity VGA is

    -- 參數設定
    generic(
        -- 水平掃描參數設定
        LinePeriod   : integer := 1040;     -- 行週期數
        H_SyncPulse  : integer :=  120;     -- 行同步脈衝（Sync a）
        H_BackPorch  : integer :=   64;     -- 顯示後沿（Back porch b）
        H_ActivePix  : integer :=  800;     -- 顯示時序段（Display interval c）
        H_FrontPorch : integer :=   56;     -- 顯示前沿（Front porch d）
        Hde_start    : integer :=  184;
        Hde_end      : integer :=  984;
        H_unitlength : integer :=    1;

        -- 垂直掃描參數設定
        FramePeriod  : integer := 666;      -- 列週期數
        V_SyncPulse  : integer :=   6;      -- 列同步脈衝（Sync o）
        V_BackPorch  : integer :=  23;      -- 顯示後沿（Back porch p）
        V_ActivePix  : integer := 600;      -- 顯示時序段（Display interval q）
        V_FrontPorch : integer :=  37;      -- 顯示前沿（Front porch r）
        Vde_start    : integer :=  29;
        Vde_end      : integer := 629;
        V_unitlength : integer :=   1
        );

	 -- 外部信號定義
    port(
    	-- 輸入端口
    	rst      : in  std_logic;
    	fpga_clk : in  std_logic;
        sw       : in  std_logic_vector (1 downto 0);
    	-- 輸出端口
    	vga_hs   : out std_logic;
    	vga_vs   : out std_logic;
    	vga_r    : out std_logic_vector (3 downto 0);
    	vga_g    : out std_logic_vector (3 downto 0);
    	vga_b    : out std_logic_vector (3 downto 0)
    	);

end VGA;

architecture behavioral of VGA is

	-- 內部信號定義
    signal x_cnt        : integer range 0 to  1040;
    signal y_cnt		: integer range 0 to   666;
    signal data		    : integer range 0 to 65535;
    signal x_ball	: integer range 0 to 560;
    signal cnt	: integer range 0 to 100000000;

    signal vga_r_reg	: std_logic_vector ( 3 downto 0);	
    signal vga_g_reg	: std_logic_vector ( 3 downto 0);
    signal vga_b_reg	: std_logic_vector ( 3 downto 0);

    signal mode		:  std_logic_vector ( 1 downto 0);
    signal hsync_r		: std_logic;
    signal vsync_r		: std_logic;
    signal hsync_de		: std_logic;
    signal vsync_de		: std_logic;
    signal vga_clk		: std_logic;

begin

    -- 內部時鐘信號
    process(fpga_clk, rst)
    begin
        if rst='1' then
            vga_clk <= '0';
        elsif falling_edge(fpga_clk) then
            vga_clk <= not vga_clk;
        end if;
    end process;

    -- 水平掃描計數
    process(vga_clk)
    begin
        if rising_edge(vga_clk) then
            if rst='1' then
                x_cnt <= 1;
            elsif x_cnt=LinePeriod then
                x_cnt <= 1;
            elsif rst='0' then
                x_cnt <= x_cnt+H_unitlength;
            end if;
        end if;
    end process;

    -- 垂直掃描計數
    process(vga_clk)
    begin
        if rising_edge(vga_clk) then
            if rst='1' then
                y_cnt <= 1;
            elsif y_cnt=FramePeriod then
                y_cnt <= 1;
            elsif x_cnt=LinePeriod then
                y_cnt <= y_cnt+V_unitlength;
            end if;
        end if;
    end process;

    -- 水平掃描信號
    process(vga_clk)
    begin
        if rising_edge(vga_clk) then
            if rst='1' then
                hsync_r <= '1';
            elsif x_cnt=H_unitlength then
                hsync_r <= '0';
            elsif x_cnt=H_SyncPulse then
                hsync_r <= '1';
            end if;
        end if ;
    end process;

    process(vga_clk)
    begin
        if rising_edge(vga_clk) then
            if rst='1' then
                hsync_de <= '0';
            elsif x_cnt=Hde_start then
                hsync_de <= '1';
            elsif x_cnt=Hde_end then
                hsync_de <= '0';
            end if;
        end if ;
    end process;

    -- 垂直掃描信號
    process(vga_clk)
    begin
        if rising_edge(vga_clk) then
            if rst='1' then
                vsync_r <= '1';
            elsif y_cnt=V_unitlength then
                vsync_r <= '0';
            elsif y_cnt=V_SyncPulse then
                vsync_r <= '1';
            end if;
        end if ;
    end process;

    process(vga_clk)
    begin
        if rising_edge(vga_clk) then
            if rst='1' then
                vsync_de <= '0';
            elsif y_cnt=Vde_start then
                vsync_de <= '1';
            elsif y_cnt=Vde_end then
                vsync_de <= '0';
            end if;
        end if ;
    end process;

    -- 外部連接
    with (hsync_de and vsync_de) select
    vga_r <= vga_r_reg when '1',
             "0000" when '0';

    with (hsync_de and vsync_de) select
    vga_g <= vga_g_reg when '1',
             "0000" when '0';

    with (hsync_de and vsync_de) select
    vga_b <= vga_b_reg when '1',
             "0000" when '0';

    vga_hs <= hsync_r;
    vga_vs <= vsync_r;

    process(vga_clk, rst)
    begin
        if rst='1' then
            x_ball<=20;
            cnt<=0;
            mode<="10";
            vga_r_reg <= "0000";
            vga_g_reg <= "0000";
            vga_b_reg <= "0000";
        elsif falling_edge(vga_clk) then
        
            if cnt=40000000 then
                cnt<=0;
            elsif cnt<40000000 then
                cnt<=cnt+1;
            end if;
--            -----------------------------------------發球-----------------------------------------
            if mode="10" then
                if x_ball=20 and sw(1)='1' then
                mode<="01";
                elsif x_ball>=540 and sw(0)='1' then
                mode<="00";
                end if;
            end if;
            
--            ----------------------------球動作-----------------------------------------
            if cnt=40000000 then
                if mode="01" then
                    x_ball<=x_ball+20;
                elsif mode="00" then
                    x_ball<=x_ball-20;
                end if;
             end if;
--             -----------------------------------------打擊----------------------------------------------------------------------------------
             if sw(0)='1' and mode="01" then -----------------------------------------右打到左-----------------------------------------
                if x_ball<541 and x_ball>519 then
                    x_ball<=x_ball-20;
                    mode<="00";
                else
                    x_ball<=20;
                    mode<="10";
                end if;
             elsif sw(1)='1' and mode="00" then -----------------------------------------左打到右-----------------------------------------
                if x_ball<41 and x_ball>19 then
                    x_ball<=x_ball+20;
                    mode<="01";
                else
                    x_ball<=540;
                    mode<="10";
                end if;
             end if;
             if mode="00" and x_ball<19 then
                    x_ball<=540;
                    mode<="10";
             elsif mode="01" and x_ball>541 then
                    x_ball<=20;
                    mode<="10";
             end if;
             --------------------------------------------------------------------------------------------------------------------------------------------------------------------
             
             
            if (x_cnt>300 and x_cnt<320) and (y_cnt>100 and y_cnt<250) then-----左拍子
                vga_r_reg <= "1111";
            elsif  (x_cnt>880 and x_cnt<900) and (y_cnt>100 and y_cnt<250) then-----右拍子
                vga_b_reg <="1111";
            elsif  (x_cnt>(300+x_ball) and x_cnt<(340+x_ball)) and (y_cnt>150 and y_cnt<200) then
                vga_r_reg <="1111";
                vga_g_reg <="1111";
            elsif  (x_cnt>360 and x_cnt<400) and (y_cnt>400 and y_cnt<440) and mode="00"then
                vga_r_reg <="1111";
            elsif  (x_cnt>360 and x_cnt<400) and (y_cnt>440 and y_cnt<480) and mode="01"then
                vga_b_reg <="1111";
            elsif  (x_cnt>360 and x_cnt<400) and (y_cnt>480 and y_cnt<520) and mode="10"then
                vga_r_reg <="1111";
                vga_g_reg <="1111";
            else 
                vga_r_reg <= "0000";
                vga_g_reg <= "0000";
                vga_b_reg <= "0000";
            end if;
            
        end if;
    end process;

end behavioral;