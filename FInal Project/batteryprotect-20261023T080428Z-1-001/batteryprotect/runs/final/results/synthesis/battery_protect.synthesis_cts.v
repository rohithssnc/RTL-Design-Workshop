module battery_protect (chg_en,
    clear,
    clk,
    dsg_en,
    occ,
    ocd,
    ov,
    rst_n,
    tick,
    uv,
    VPWR,
    VGND,
    dbn_sel,
    fault);
 output chg_en;
 input clear;
 input clk;
 output dsg_en;
 input occ;
 input ocd;
 input ov;
 input rst_n;
 input tick;
 input uv;
 input VPWR;
 input VGND;
 input [1:0] dbn_sel;
 output [3:0] fault;

 sky130_fd_sc_hd__inv_2 _094_ (.A(\u_deb_uv.cnt[4] ),
    .Y(_067_));
 sky130_fd_sc_hd__o221ai_4 _095_ (.A1(_064_),
    .A2(_065_),
    .B1(net3),
    .B2(_066_),
    .C1(_067_),
    .Y(_068_));
 sky130_fd_sc_hd__or2_1 _096_ (.A(_063_),
    .B(_068_),
    .X(_069_));
 sky130_fd_sc_hd__or3b_4 _097_ (.A(_062_),
    .B(_069_),
    .C_N(\u_deb_uv.cnt[0] ),
    .X(_070_));
 sky130_fd_sc_hd__or2_2 _098_ (.A(_061_),
    .B(_070_),
    .X(_071_));
 sky130_fd_sc_hd__inv_2 _099_ (.A(_071_),
    .Y(_072_));
 sky130_fd_sc_hd__clkbuf_2 _100_ (.A(net9),
    .X(_073_));
 sky130_fd_sc_hd__o221a_1 _101_ (.A1(\u_deb_uv.cnt[3] ),
    .A2(_072_),
    .B1(_064_),
    .B2(_071_),
    .C1(_073_),
    .X(_024_));
 sky130_fd_sc_hd__inv_2 _102_ (.A(_073_),
    .Y(_074_));
 sky130_fd_sc_hd__a211oi_2 _103_ (.A1(_061_),
    .A2(_070_),
    .B1(_074_),
    .C1(_072_),
    .Y(_023_));
 sky130_fd_sc_hd__nand2_1 _104_ (.A(net9),
    .B(_069_),
    .Y(_075_));
 sky130_fd_sc_hd__nand2_1 _105_ (.A(\u_deb_uv.cnt[0] ),
    .B(_075_),
    .Y(_076_));
 sky130_fd_sc_hd__inv_2 _106_ (.A(_076_),
    .Y(_077_));
 sky130_fd_sc_hd__o211a_1 _107_ (.A1(\u_deb_uv.cnt[1] ),
    .A2(_077_),
    .B1(_073_),
    .C1(_070_),
    .X(_022_));
 sky130_fd_sc_hd__o211a_1 _108_ (.A1(\u_deb_uv.cnt[0] ),
    .A2(_075_),
    .B1(_073_),
    .C1(_076_),
    .X(_021_));
 sky130_fd_sc_hd__clkbuf_2 _109_ (.A(net6),
    .X(_078_));
 sky130_fd_sc_hd__inv_2 _110_ (.A(_078_),
    .Y(_079_));
 sky130_fd_sc_hd__inv_2 _111_ (.A(\u_deb_ov.cnt[3] ),
    .Y(_080_));
 sky130_fd_sc_hd__inv_2 _112_ (.A(\u_deb_ov.cnt[2] ),
    .Y(_081_));
 sky130_fd_sc_hd__inv_2 _113_ (.A(\u_deb_ov.cnt[1] ),
    .Y(_082_));
 sky130_fd_sc_hd__o21a_1 _114_ (.A1(_082_),
    .A2(net2),
    .B1(_081_),
    .X(_083_));
 sky130_fd_sc_hd__inv_2 _115_ (.A(\u_deb_ov.cnt[4] ),
    .Y(_084_));
 sky130_fd_sc_hd__o221ai_4 _116_ (.A1(_080_),
    .A2(_065_),
    .B1(net3),
    .B2(_083_),
    .C1(_084_),
    .Y(_085_));
 sky130_fd_sc_hd__or2_1 _117_ (.A(_063_),
    .B(_085_),
    .X(_086_));
 sky130_fd_sc_hd__or3b_4 _118_ (.A(_082_),
    .B(_086_),
    .C_N(\u_deb_ov.cnt[0] ),
    .X(_087_));
 sky130_fd_sc_hd__or2_2 _119_ (.A(_081_),
    .B(_087_),
    .X(_088_));
 sky130_fd_sc_hd__o21a_1 _120_ (.A1(_080_),
    .A2(_088_),
    .B1(_084_),
    .X(_089_));
 sky130_fd_sc_hd__nor2_1 _121_ (.A(_079_),
    .B(_089_),
    .Y(_020_));
 sky130_fd_sc_hd__inv_2 _122_ (.A(_088_),
    .Y(_090_));
 sky130_fd_sc_hd__o221a_1 _123_ (.A1(_080_),
    .A2(_088_),
    .B1(\u_deb_ov.cnt[3] ),
    .B2(_090_),
    .C1(_078_),
    .X(_019_));
 sky130_fd_sc_hd__a211oi_2 _124_ (.A1(_081_),
    .A2(_087_),
    .B1(_079_),
    .C1(_090_),
    .Y(_018_));
 sky130_fd_sc_hd__nand2_1 _125_ (.A(net6),
    .B(_086_),
    .Y(_091_));
 sky130_fd_sc_hd__nand2_1 _126_ (.A(\u_deb_ov.cnt[0] ),
    .B(_091_),
    .Y(_092_));
 sky130_fd_sc_hd__inv_2 _127_ (.A(_092_),
    .Y(_093_));
 sky130_fd_sc_hd__o211a_1 _128_ (.A1(\u_deb_ov.cnt[1] ),
    .A2(_093_),
    .B1(_078_),
    .C1(_087_),
    .X(_017_));
 sky130_fd_sc_hd__o211a_1 _129_ (.A1(\u_deb_ov.cnt[0] ),
    .A2(_091_),
    .B1(_078_),
    .C1(_092_),
    .X(_016_));
 sky130_fd_sc_hd__buf_1 _130_ (.A(net5),
    .X(_026_));
 sky130_fd_sc_hd__inv_2 _131_ (.A(\u_deb_ocd.cnt[2] ),
    .Y(_027_));
 sky130_fd_sc_hd__inv_2 _132_ (.A(\u_deb_ocd.cnt[0] ),
    .Y(_028_));
 sky130_fd_sc_hd__inv_2 _133_ (.A(\u_deb_ocd.cnt[1] ),
    .Y(_029_));
 sky130_fd_sc_hd__o21a_1 _134_ (.A1(_028_),
    .A2(net2),
    .B1(_029_),
    .X(_030_));
 sky130_fd_sc_hd__nor2_2 _135_ (.A(\u_deb_ocd.cnt[4] ),
    .B(\u_deb_ocd.cnt[3] ),
    .Y(_031_));
 sky130_fd_sc_hd__o221ai_4 _136_ (.A1(_027_),
    .A2(_065_),
    .B1(net3),
    .B2(_030_),
    .C1(_031_),
    .Y(_032_));
 sky130_fd_sc_hd__or2_1 _137_ (.A(_063_),
    .B(_032_),
    .X(_033_));
 sky130_fd_sc_hd__and3_1 _138_ (.A(_026_),
    .B(_033_),
    .C(\u_deb_ocd.cnt[4] ),
    .X(_015_));
 sky130_fd_sc_hd__or3_4 _139_ (.A(_029_),
    .B(_028_),
    .C(_033_),
    .X(_034_));
 sky130_fd_sc_hd__or2_1 _140_ (.A(_027_),
    .B(_034_),
    .X(_035_));
 sky130_fd_sc_hd__inv_2 _141_ (.A(_035_),
    .Y(_036_));
 sky130_fd_sc_hd__o21a_1 _142_ (.A1(\u_deb_ocd.cnt[3] ),
    .A2(_036_),
    .B1(_026_),
    .X(_014_));
 sky130_fd_sc_hd__inv_2 _143_ (.A(_034_),
    .Y(_037_));
 sky130_fd_sc_hd__o211a_1 _144_ (.A1(\u_deb_ocd.cnt[2] ),
    .A2(_037_),
    .B1(_026_),
    .C1(_035_),
    .X(_013_));
 sky130_fd_sc_hd__nand2_1 _145_ (.A(net5),
    .B(_033_),
    .Y(_038_));
 sky130_fd_sc_hd__inv_2 _146_ (.A(_038_),
    .Y(_039_));
 sky130_fd_sc_hd__o21a_1 _147_ (.A1(_028_),
    .A2(_039_),
    .B1(_029_),
    .X(_040_));
 sky130_fd_sc_hd__and3b_1 _148_ (.A_N(_040_),
    .B(_034_),
    .C(_026_),
    .X(_012_));
 sky130_fd_sc_hd__o221a_1 _149_ (.A1(_028_),
    .A2(_039_),
    .B1(\u_deb_ocd.cnt[0] ),
    .B2(_038_),
    .C1(_026_),
    .X(_011_));
 sky130_fd_sc_hd__buf_1 _150_ (.A(net4),
    .X(_041_));
 sky130_fd_sc_hd__and2_1 _151_ (.A(\u_deb_occ.cnt[4] ),
    .B(_041_),
    .X(_010_));
 sky130_fd_sc_hd__inv_2 _152_ (.A(\u_deb_occ.cnt[2] ),
    .Y(_042_));
 sky130_fd_sc_hd__inv_2 _153_ (.A(\u_deb_occ.cnt[1] ),
    .Y(_043_));
 sky130_fd_sc_hd__inv_2 _154_ (.A(\u_deb_occ.cnt[0] ),
    .Y(_044_));
 sky130_fd_sc_hd__o21a_1 _155_ (.A1(_044_),
    .A2(net2),
    .B1(_043_),
    .X(_045_));
 sky130_fd_sc_hd__nor2_2 _156_ (.A(\u_deb_occ.cnt[4] ),
    .B(\u_deb_occ.cnt[3] ),
    .Y(_046_));
 sky130_fd_sc_hd__o221ai_4 _157_ (.A1(_042_),
    .A2(_065_),
    .B1(net3),
    .B2(_045_),
    .C1(_046_),
    .Y(_047_));
 sky130_fd_sc_hd__or2_1 _158_ (.A(_063_),
    .B(_047_),
    .X(_048_));
 sky130_fd_sc_hd__or3_4 _159_ (.A(_043_),
    .B(_044_),
    .C(_048_),
    .X(_049_));
 sky130_fd_sc_hd__nor2_1 _160_ (.A(_042_),
    .B(_049_),
    .Y(_050_));
 sky130_fd_sc_hd__o21a_1 _161_ (.A1(\u_deb_occ.cnt[3] ),
    .A2(_050_),
    .B1(_041_),
    .X(_009_));
 sky130_fd_sc_hd__inv_2 _162_ (.A(_049_),
    .Y(_051_));
 sky130_fd_sc_hd__o221a_1 _163_ (.A1(_042_),
    .A2(_049_),
    .B1(\u_deb_occ.cnt[2] ),
    .B2(_051_),
    .C1(_041_),
    .X(_008_));
 sky130_fd_sc_hd__nand2_1 _164_ (.A(net4),
    .B(_048_),
    .Y(_052_));
 sky130_fd_sc_hd__nand2_1 _165_ (.A(\u_deb_occ.cnt[0] ),
    .B(_052_),
    .Y(_053_));
 sky130_fd_sc_hd__inv_2 _166_ (.A(_053_),
    .Y(_054_));
 sky130_fd_sc_hd__o211a_1 _167_ (.A1(\u_deb_occ.cnt[1] ),
    .A2(_054_),
    .B1(_041_),
    .C1(_049_),
    .X(_007_));
 sky130_fd_sc_hd__o211a_1 _168_ (.A1(\u_deb_occ.cnt[0] ),
    .A2(_052_),
    .B1(_041_),
    .C1(_053_),
    .X(_006_));
 sky130_fd_sc_hd__nor4_2 _169_ (.A(net12),
    .B(net14),
    .C(_085_),
    .D(_047_),
    .Y(_000_));
 sky130_fd_sc_hd__nor4_2 _170_ (.A(net13),
    .B(net15),
    .C(_068_),
    .D(_032_),
    .Y(_001_));
 sky130_fd_sc_hd__inv_2 _171_ (.A(net1),
    .Y(_055_));
 sky130_fd_sc_hd__o21a_1 _172_ (.A1(_078_),
    .A2(_055_),
    .B1(net12),
    .X(_056_));
 sky130_fd_sc_hd__or2_1 _173_ (.A(_085_),
    .B(_056_),
    .X(_002_));
 sky130_fd_sc_hd__o21a_1 _174_ (.A1(_073_),
    .A2(_055_),
    .B1(net13),
    .X(_057_));
 sky130_fd_sc_hd__or2_1 _175_ (.A(_068_),
    .B(_057_),
    .X(_003_));
 sky130_fd_sc_hd__o21a_1 _176_ (.A1(net4),
    .A2(_055_),
    .B1(net14),
    .X(_058_));
 sky130_fd_sc_hd__or2_1 _177_ (.A(_047_),
    .B(_058_),
    .X(_004_));
 sky130_fd_sc_hd__o21a_1 _178_ (.A1(net5),
    .A2(_055_),
    .B1(net15),
    .X(_059_));
 sky130_fd_sc_hd__or2_1 _179_ (.A(_032_),
    .B(_059_),
    .X(_005_));
 sky130_fd_sc_hd__o21a_1 _180_ (.A1(_064_),
    .A2(_071_),
    .B1(_067_),
    .X(_060_));
 sky130_fd_sc_hd__nor2_1 _181_ (.A(_074_),
    .B(_060_),
    .Y(_025_));
 sky130_fd_sc_hd__inv_2 _182_ (.A(\u_deb_uv.cnt[2] ),
    .Y(_061_));
 sky130_fd_sc_hd__inv_2 _183_ (.A(\u_deb_uv.cnt[1] ),
    .Y(_062_));
 sky130_fd_sc_hd__inv_2 _184_ (.A(net8),
    .Y(_063_));
 sky130_fd_sc_hd__inv_2 _185_ (.A(\u_deb_uv.cnt[3] ),
    .Y(_064_));
 sky130_fd_sc_hd__and2_4 _186_ (.A(net3),
    .B(net2),
    .X(_065_));
 sky130_fd_sc_hd__o21a_1 _187_ (.A1(_062_),
    .A2(net2),
    .B1(_061_),
    .X(_066_));
 sky130_fd_sc_hd__dfrtp_1 _188_ (.D(_000_),
    .Q(net10),
    .RESET_B(net7),
    .CLK(clknet_1_0_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _189_ (.D(_001_),
    .Q(net11),
    .RESET_B(net16),
    .CLK(clknet_1_1_0_clk));
 sky130_fd_sc_hd__dfrtp_4 _190_ (.D(_002_),
    .Q(net12),
    .RESET_B(net16),
    .CLK(clknet_1_1_0_clk));
 sky130_fd_sc_hd__dfrtp_2 _191_ (.D(_003_),
    .Q(net13),
    .RESET_B(net16),
    .CLK(clknet_1_0_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _192_ (.D(_004_),
    .Q(net14),
    .RESET_B(net16),
    .CLK(clknet_1_0_0_clk));
 sky130_fd_sc_hd__dfrtp_4 _193_ (.D(_005_),
    .Q(net15),
    .RESET_B(net16),
    .CLK(clknet_1_1_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _194_ (.D(_006_),
    .Q(\u_deb_occ.cnt[0] ),
    .RESET_B(net16),
    .CLK(clknet_1_0_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _195_ (.D(_007_),
    .Q(\u_deb_occ.cnt[1] ),
    .RESET_B(net16),
    .CLK(clknet_1_0_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _196_ (.D(_008_),
    .Q(\u_deb_occ.cnt[2] ),
    .RESET_B(net16),
    .CLK(clknet_1_1_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _197_ (.D(_009_),
    .Q(\u_deb_occ.cnt[3] ),
    .RESET_B(net16),
    .CLK(clknet_1_0_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _198_ (.D(_010_),
    .Q(\u_deb_occ.cnt[4] ),
    .RESET_B(net16),
    .CLK(clknet_1_0_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _199_ (.D(_011_),
    .Q(\u_deb_ocd.cnt[0] ),
    .RESET_B(net16),
    .CLK(clknet_1_1_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _200_ (.D(_012_),
    .Q(\u_deb_ocd.cnt[1] ),
    .RESET_B(net16),
    .CLK(clknet_1_1_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _201_ (.D(_013_),
    .Q(\u_deb_ocd.cnt[2] ),
    .RESET_B(net16),
    .CLK(clknet_1_1_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _202_ (.D(_014_),
    .Q(\u_deb_ocd.cnt[3] ),
    .RESET_B(net16),
    .CLK(clknet_1_1_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _203_ (.D(_015_),
    .Q(\u_deb_ocd.cnt[4] ),
    .RESET_B(net16),
    .CLK(clknet_1_1_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _204_ (.D(_016_),
    .Q(\u_deb_ov.cnt[0] ),
    .RESET_B(net7),
    .CLK(clknet_1_0_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _205_ (.D(_017_),
    .Q(\u_deb_ov.cnt[1] ),
    .RESET_B(net7),
    .CLK(clknet_1_1_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _206_ (.D(_018_),
    .Q(\u_deb_ov.cnt[2] ),
    .RESET_B(net7),
    .CLK(clknet_1_1_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _207_ (.D(_019_),
    .Q(\u_deb_ov.cnt[3] ),
    .RESET_B(net7),
    .CLK(clknet_1_1_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _208_ (.D(_020_),
    .Q(\u_deb_ov.cnt[4] ),
    .RESET_B(net16),
    .CLK(clknet_1_0_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _209_ (.D(_021_),
    .Q(\u_deb_uv.cnt[0] ),
    .RESET_B(net16),
    .CLK(clknet_1_0_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _210_ (.D(_022_),
    .Q(\u_deb_uv.cnt[1] ),
    .RESET_B(net7),
    .CLK(clknet_1_0_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _211_ (.D(_023_),
    .Q(\u_deb_uv.cnt[2] ),
    .RESET_B(net7),
    .CLK(clknet_1_0_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _212_ (.D(_024_),
    .Q(\u_deb_uv.cnt[3] ),
    .RESET_B(net16),
    .CLK(clknet_1_0_0_clk));
 sky130_fd_sc_hd__dfrtp_1 _213_ (.D(_025_),
    .Q(\u_deb_uv.cnt[4] ),
    .RESET_B(net7),
    .CLK(clknet_1_0_0_clk));
 sky130_fd_sc_hd__decap_3 PHY_0 ();
 sky130_fd_sc_hd__decap_3 PHY_1 ();
 sky130_fd_sc_hd__decap_3 PHY_2 ();
 sky130_fd_sc_hd__decap_3 PHY_3 ();
 sky130_fd_sc_hd__decap_3 PHY_4 ();
 sky130_fd_sc_hd__decap_3 PHY_5 ();
 sky130_fd_sc_hd__decap_3 PHY_6 ();
 sky130_fd_sc_hd__decap_3 PHY_7 ();
 sky130_fd_sc_hd__decap_3 PHY_8 ();
 sky130_fd_sc_hd__decap_3 PHY_9 ();
 sky130_fd_sc_hd__decap_3 PHY_10 ();
 sky130_fd_sc_hd__decap_3 PHY_11 ();
 sky130_fd_sc_hd__decap_3 PHY_12 ();
 sky130_fd_sc_hd__decap_3 PHY_13 ();
 sky130_fd_sc_hd__decap_3 PHY_14 ();
 sky130_fd_sc_hd__decap_3 PHY_15 ();
 sky130_fd_sc_hd__decap_3 PHY_16 ();
 sky130_fd_sc_hd__decap_3 PHY_17 ();
 sky130_fd_sc_hd__decap_3 PHY_18 ();
 sky130_fd_sc_hd__decap_3 PHY_19 ();
 sky130_fd_sc_hd__decap_3 PHY_20 ();
 sky130_fd_sc_hd__decap_3 PHY_21 ();
 sky130_fd_sc_hd__decap_3 PHY_22 ();
 sky130_fd_sc_hd__decap_3 PHY_23 ();
 sky130_fd_sc_hd__decap_3 PHY_24 ();
 sky130_fd_sc_hd__decap_3 PHY_25 ();
 sky130_fd_sc_hd__decap_3 PHY_26 ();
 sky130_fd_sc_hd__decap_3 PHY_27 ();
 sky130_fd_sc_hd__decap_3 PHY_28 ();
 sky130_fd_sc_hd__decap_3 PHY_29 ();
 sky130_fd_sc_hd__decap_3 PHY_30 ();
 sky130_fd_sc_hd__decap_3 PHY_31 ();
 sky130_fd_sc_hd__decap_3 PHY_32 ();
 sky130_fd_sc_hd__decap_3 PHY_33 ();
 sky130_fd_sc_hd__decap_3 PHY_34 ();
 sky130_fd_sc_hd__decap_3 PHY_35 ();
 sky130_fd_sc_hd__decap_3 PHY_36 ();
 sky130_fd_sc_hd__decap_3 PHY_37 ();
 sky130_fd_sc_hd__decap_3 PHY_38 ();
 sky130_fd_sc_hd__decap_3 PHY_39 ();
 sky130_fd_sc_hd__decap_3 PHY_40 ();
 sky130_fd_sc_hd__decap_3 PHY_41 ();
 sky130_fd_sc_hd__decap_3 PHY_42 ();
 sky130_fd_sc_hd__decap_3 PHY_43 ();
 sky130_fd_sc_hd__decap_3 PHY_44 ();
 sky130_fd_sc_hd__decap_3 PHY_45 ();
 sky130_fd_sc_hd__decap_3 PHY_46 ();
 sky130_fd_sc_hd__decap_3 PHY_47 ();
 sky130_fd_sc_hd__decap_3 PHY_48 ();
 sky130_fd_sc_hd__decap_3 PHY_49 ();
 sky130_fd_sc_hd__decap_3 PHY_50 ();
 sky130_fd_sc_hd__decap_3 PHY_51 ();
 sky130_fd_sc_hd__decap_3 PHY_52 ();
 sky130_fd_sc_hd__decap_3 PHY_53 ();
 sky130_fd_sc_hd__decap_3 PHY_54 ();
 sky130_fd_sc_hd__decap_3 PHY_55 ();
 sky130_fd_sc_hd__decap_3 PHY_56 ();
 sky130_fd_sc_hd__decap_3 PHY_57 ();
 sky130_fd_sc_hd__decap_3 PHY_58 ();
 sky130_fd_sc_hd__decap_3 PHY_59 ();
 sky130_fd_sc_hd__decap_3 PHY_60 ();
 sky130_fd_sc_hd__decap_3 PHY_61 ();
 sky130_fd_sc_hd__decap_3 PHY_62 ();
 sky130_fd_sc_hd__decap_3 PHY_63 ();
 sky130_fd_sc_hd__decap_3 PHY_64 ();
 sky130_fd_sc_hd__decap_3 PHY_65 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_66 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_67 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_68 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_69 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_70 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_71 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_72 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_73 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_74 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_75 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_76 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_77 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_78 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_79 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_80 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_81 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_82 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_83 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_84 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_85 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_86 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_87 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_88 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_89 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_90 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_91 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_92 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_93 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_94 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_95 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_96 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_97 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_98 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_99 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_100 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_101 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_102 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_103 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_104 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_105 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_106 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_107 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_108 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_109 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_110 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_111 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_112 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_113 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_114 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_115 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_116 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_117 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_118 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_119 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_120 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_121 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_122 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_123 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_124 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_125 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_126 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_127 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_128 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_129 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_130 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_131 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_132 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_133 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_134 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_135 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_136 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_137 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_138 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_139 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_140 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_141 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_142 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_143 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_144 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_145 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_146 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_147 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_148 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_149 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_150 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_151 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_152 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_153 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_154 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_155 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_156 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_157 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_158 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_159 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_160 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_161 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_162 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_163 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_164 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_165 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_166 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_167 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_168 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_169 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 PHY_170 ();
 sky130_fd_sc_hd__clkbuf_1 input1 (.A(clear),
    .X(net1));
 sky130_fd_sc_hd__buf_2 input2 (.A(dbn_sel[0]),
    .X(net2));
 sky130_fd_sc_hd__buf_4 input3 (.A(dbn_sel[1]),
    .X(net3));
 sky130_fd_sc_hd__buf_1 input4 (.A(occ),
    .X(net4));
 sky130_fd_sc_hd__clkbuf_2 input5 (.A(ocd),
    .X(net5));
 sky130_fd_sc_hd__clkbuf_1 input6 (.A(ov),
    .X(net6));
 sky130_fd_sc_hd__clkbuf_4 input7 (.A(rst_n),
    .X(net7));
 sky130_fd_sc_hd__buf_1 input8 (.A(tick),
    .X(net8));
 sky130_fd_sc_hd__clkbuf_1 input9 (.A(uv),
    .X(net9));
 sky130_fd_sc_hd__buf_1 output10 (.A(net10),
    .X(chg_en));
 sky130_fd_sc_hd__buf_1 output11 (.A(net11),
    .X(dsg_en));
 sky130_fd_sc_hd__buf_1 output12 (.A(net12),
    .X(fault[0]));
 sky130_fd_sc_hd__buf_1 output13 (.A(net13),
    .X(fault[1]));
 sky130_fd_sc_hd__buf_1 output14 (.A(net14),
    .X(fault[2]));
 sky130_fd_sc_hd__buf_1 output15 (.A(net15),
    .X(fault[3]));
 sky130_fd_sc_hd__clkbuf_8 repeater16 (.A(net7),
    .X(net16));
 sky130_fd_sc_hd__clkbuf_16 clkbuf_0_clk (.A(clk),
    .X(clknet_0_clk));
 sky130_fd_sc_hd__clkbuf_1 clkbuf_1_0_0_clk (.A(clknet_0_clk),
    .X(clknet_1_0_0_clk));
 sky130_fd_sc_hd__clkbuf_1 clkbuf_1_1_0_clk (.A(clknet_0_clk),
    .X(clknet_1_1_0_clk));
endmodule
