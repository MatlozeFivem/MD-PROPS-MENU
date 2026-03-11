Config = {}

Config.MenuCommand = "propsmenu"
Config.MenuKey = 56 -- Key F9 (This is the control code for F9)
Config.DefaultKey = "F9" -- Default key for RegisterKeyMapping
Config.MaxPropsPerPlayer = 15 -- Nombre maximum de props qu'un joueur peut poser simultanément

Config.ColorMenuR = 0
Config.ColorMenuG = 0
Config.ColorMenuB = 0
Config.ColorMenuA = 180 -- Transparence RageUI

Config.AdminGroups = {
    ['admin'] = true,
    ['superadmin'] = true,
    ['fondateur'] = true
}

-- Categories of props
Config.Categories = {
    "Police & Sécurité",
    "EMS & Médical",
    "Chantier & Route",
    "Mécanicien",
    "Drogue & Illégal",
    "Mobilier",
    "Camping & Nature",
    "Divers",
}

-- Restrictions de métiers par Catégorie (laissez vide ou n'ajoutez pas la catégorie pour autoriser tout le monde)
-- Exemple : ["Nom de la Catégorie Exact"] = {"nom_du_job_1", "nom_du_job_2"}
Config.CategoryJobs = {
    ["Police & Sécurité"] = {"police", "sheriff"},
    ["EMS & Médical"] = {"ambulance"},
    ["Mécanicien"] = {"mechanic", "bennys"}
}

-- You can change or add props here
Config.PropsList = {
    ['Police & Sécurité'] = {
        { name = "Cône LSPD", model = "prop_roadcone02a" },
        { name = "Cône LSPD Ligne", model = "prop_roadcone02b" },
        { name = "Barrière LSPD", model = "prop_barrier_work05" },
        { name = "Barrière Police", model = "prop_police_barrier" },
        { name = "Herse 1", model = "p_ld_stinger_s" },
        { name = "Herse 2", model = "p_ld_stinger_s_01" },
        { name = "Projecteur Allumé", model = "prop_worklight_03b" },
        { name = "Projecteur Éteint", model = "prop_worklight_03a" },
        { name = "Rubalise Scène de crime", model = "prop_barrier_work06a" },
        { name = "Grosse Barrière Plastique", model = "prop_mp_barrier_02b" },
        { name = "Radar", model = "prop_cctv_pole_01a" }
    },
    ['EMS & Médical'] = {
        { name = "Brancard (Lit roulant)", model = "v_med_emptybed" },
        { name = "Sac Mortuaire", model = "prop_ld_binbag_01" },
        { name = "Sac Médical", model = "xm_prop_x17_bag_med_01a" },
        { name = "Tente Première Urgence", model = "prop_gazebo_02" },
        { name = "Kit de Secours", model = "prop_med_bag_01b" },
        { name = "Lit Hôpital", model = "v_med_bed1" },
        { name = "Chaise Roulante", model = "prop_wheelchair_01" }
    },
    ['Chantier & Route'] = {
        { name = "Cône de chantier", model = "prop_roadcone01a" },
        { name = "Cône de chantier 2", model = "prop_roadcone01c" },
        { name = "Panneau Déviation Gauche", model = "prop_consign_01b" },
        { name = "Panneau Déviation Droite", model = "prop_consign_02a" },
        { name = "Barrière Chantier", model = "prop_barrier_work01b" },
        { name = "Barrière de sécurité bois", model = "prop_barrier_work01a" },
        { name = "Bloc Béton", model = "prop_mp_barrier_01" },
        { name = "Outils Chantier", model = "prop_tool_box_01" },
        { name = "Pelle", model = "prop_tool_shovel" },
        { name = "Brouette", model = "prop_wheelbarrow01a" }
    },
    ['Mécanicien'] = {
        { name = "Boite à outils", model = "prop_tool_box_04" },
        { name = "Bidon d'Huile", model = "prop_oil_can_01" },
        { name = "Chandelle", model = "prop_car_jack_01" },
        { name = "Cric", model = "prop_carjack" },
        { name = "Pneu de voiture", model = "prop_wheel_tyre" },
        { name = "Pneu de camion", model = "prop_tyre_01" },
        { name = "Moteur (Bloc)", model = "prop_engine_hoist" }
    },
    ['Drogue & Illégal'] = {
        { name = "Table avec Weed", model = "bkr_prop_weed_table_01a" },
        { name = "Pochon de Weed", model = "p_weed_img_s" },
        { name = "Table avec Coke", model = "bkr_prop_coke_table01a" },
        { name = "Paquet de Coke", model = "prop_coke_block_01" },
        { name = "Table de Meth", model = "bkr_prop_meth_table01a" },
        { name = "Sac de Billet", model = "prop_money_bag_01" },
        { name = "Liasse de Billet", model = "prop_cash_pile_02" },
        { name = "Arme au sol (Pistolet)", model = "w_pi_pistol" },
        { name = "Arme au sol (AK)", model = "w_ar_assaultrifle" }
    },
    ['Mobilier'] = {
        { name = "Canapé Moderne", model = "p_lev_sofa_s" },
        { name = "Fauteuil", model = "p_armchair_01_s" },
        { name = "Table en bois", model = "prop_table_03b" },
        { name = "Chaise de Bureau", model = "v_ret_ps_chair" },
        { name = "Banc Public", model = "prop_bench_01a" },
        { name = "Télévision Écran Plat", model = "prop_tv_flat_01" },
        { name = "Plante Intérieur 1", model = "prop_plant_int_01a" },
        { name = "Plante Intérieur 2", model = "prop_potted_plant_05" },
        { name = "Lumière Bureau", model = "prop_lamp_01a" },
        { name = "Corbeille", model = "prop_bin_01a" }
    },
    ['Camping & Nature'] = {
        { name = "Tente", model = "prop_skid_tent_01" },
        { name = "Tente Grise", model = "prop_tent_01" },
        { name = "Feu de camp", model = "prop_beach_fire" },
        { name = "Chaise de Camping", model = "prop_chair_02" },
        { name = "Glacière", model = "prop_coolbox_01" },
        { name = "Gazebo", model = "prop_gazebo_01" },
        { name = "BBQ", model = "prop_bbq_1" }
    },
    ['Divers'] = {
        { name = "Carton (Box)", model = "prop_cardbordbox_04a" },
        { name = "Caisse en bois", model = "prop_box_wood02a_pu" },
        { name = "Sac Poubelle", model = "prop_ld_binbag_01" },
        { name = "Baffle (Boombox)", model = "prop_boombox_01" },
        { name = "Guitare", model = "prop_acc_guitar_01" },
        { name = "Parapluie", model = "p_amb_brolly_01_s" }
    }
}

-- Configuration des props avec lesquels on peut interagir (S'asseoir, S'allonger)
Config.Interactables = {
    -- Sièges et Canapés
    ["p_lev_sofa_s"] = { label = "[E] S'asseoir", type = "sit", scenario = "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER", offsetZ = 0.5 },
    ["p_armchair_01_s"] = { label = "[E] S'asseoir", type = "sit", scenario = "PROP_HUMAN_SEAT_ARMCHAIR", offsetZ = 0.5 },
    ["prop_bench_01a"] = { label = "[E] S'asseoir", type = "sit", scenario = "PROP_HUMAN_SEAT_BENCH", offsetZ = 0.5 },
    ["prop_chair_02"] = { label = "[E] S'asseoir", type = "sit", scenario = "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER", offsetZ = 0.5 },
    ["v_ret_ps_chair"] = { label = "[E] S'asseoir", type = "sit", scenario = "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER", offsetZ = 0.5 },
    ["prop_wheelchair_01"] = { label = "[E] S'asseoir", type = "sit", scenario = "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER", offsetZ = 0.5 },
    
    -- Lits et Brancards
    ["v_med_emptybed"] = { label = "[E] S'allonger", type = "lay", 
        animDict = "dead", 
        animName = "dead_a", 
        offsetPos = vector3(0.0, 0.0, 1.15), 
        offsetRot = 0.0 
    }
}
