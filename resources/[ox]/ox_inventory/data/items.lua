return {
    ['testburger'] = {
        label = 'Test Burger',
        weight = 220,
        degrade = 60,
        client = {
            image = 'burger_chicken.png',
            status = { hunger = 200000 },
            anim = 'eating',
            prop = 'burger',
            usetime = 2500,
            export = 'ox_inventory_examples.testburger'
        },
        server = {
            export = 'ox_inventory_examples.testburger',
            test = 'what an amazingly delicious burger, amirite?'
        },
        buttons = {
            {
                label = 'Lick it',
                action = function(slot)
                    print('You licked the burger')
                end
            },
            {
                label = 'Squeeze it',
                action = function(slot)
                    print('You squeezed the burger :(')
                end
            },
            {
                label = 'What do you call a vegan burger?',
                group = 'Hamburger Puns',
                action = function(slot)
                    print('A misteak.')
                end
            },
            {
                label = 'What do frogs like to eat with their hamburgers?',
                group = 'Hamburger Puns',
                action = function(slot)
                    print('French flies.')
                end
            },
            {
                label = 'Why were the burger and fries running?',
                group = 'Hamburger Puns',
                action = function(slot)
                    print('Because they\'re fast food.')
                end
            }
        },
        consume = 0.3
    },

    ['bandage'] = {
        label = 'Bandage',
        weight = 115,
    },

    ['burger'] = {
        label = 'Burger',
        weight = 220,
        client = {
            status = { hunger = 200000 },
            anim = 'eating',
            prop = 'burger',
            usetime = 2500,
            notification = 'You ate a delicious burger'
        },
    },

    ['sprunk'] = {
        label = 'Sprunk',
        weight = 350,
        client = {
            status = { thirst = 200000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            notification = 'You quenched your thirst with a sprunk'
        }
    },

    ['parachute'] = {
        label = 'Parachute',
        weight = 8000,
        stack = false,
        client = {
            anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
            usetime = 1500
        }
    },

    ['garbage'] = {
        label = 'Garbage',
    },

    ['paperbag'] = {
        label = 'Paper Bag',
        weight = 1,
        stack = false,
        close = false,
        consume = 0
    },

    ['panties'] = {
        label = 'Knickers',
        weight = 10,
        consume = 0,
        client = {
            status = { thirst = -100000, stress = -25000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_cs_panties_02`, pos = vec3(0.03, 0.0, 0.02), rot = vec3(0.0, -13.5, -1.5) },
            usetime = 2500,
        }
    },

    ['lockpick'] = {
        label = 'Lockpick',
        weight = 160,
    },

    ['phone'] = {
        label = 'Phone',
        weight = 190,
        stack = false,
        consume = 0,
        client = {
            add = function(total)
                if total > 0 then
                    pcall(function() return exports.npwd:setPhoneDisabled(false) end)
                end
            end,

            remove = function(total)
                if total < 1 then
                    pcall(function() return exports.npwd:setPhoneDisabled(true) end)
                end
            end
        }
    },

    ['mustard'] = {
        label = 'Mustard',
        weight = 500,
        client = {
            status = { hunger = 25000, thirst = 25000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_food_mustard`, pos = vec3(0.01, 0.0, -0.07), rot = vec3(1.0, 1.0, -1.5) },
            usetime = 2500,
            notification = 'You... drank mustard'
        }
    },

    ['water'] = {
        label = 'Water',
        weight = 500,
        client = {
            status = { thirst = 200000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
            usetime = 2500,
            cancel = true,
            notification = 'You drank some refreshing water'
        }
    },

    ['armour'] = {
        label = 'Bulletproof Vest',
        weight = 3000,
        stack = false,
        client = {
            anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
            usetime = 3500
        }
    },

    ['clothing'] = {
        label = 'Clothing',
        consume = 0,
    },

    ['money'] = {
        label = 'Money',
    },

    ['black_money'] = {
        label = 'Dirty Money',
    },

    ['id_card'] = {
        label = 'Identification Card',
    },

    ['driver_license'] = {
        label = 'Drivers License',
    },

    ['weaponlicense'] = {
        label = 'Weapon License',
    },

    ['lawyerpass'] = {
        label = 'Lawyer Pass',
    },

    ['radio'] = {
        label = 'Radio',
        weight = 1000,
        allowArmed = true,
        consume = 0,
        client = {
            event = 'mm_radio:client:use'
        }
    },

    ['jammer'] = {
        label = 'Radio Jammer',
        weight = 10000,
        allowArmed = true,
        client = {
            event = 'mm_radio:client:usejammer'
        }
    },

    ['radiocell'] = {
        label = 'AAA Cells',
        weight = 1000,
        stack = true,
        allowArmed = true,
        client = {
            event = 'mm_radio:client:recharge'
        }
    },

    ['advancedlockpick'] = {
        label = 'Advanced Lockpick',
        weight = 500,
    },

    ['screwdriverset'] = {
        label = 'Screwdriver Set',
        weight = 500,
    },

    ['electronickit'] = {
        label = 'Electronic Kit',
        weight = 500,
    },

    ['cleaningkit'] = {
        label = 'Cleaning Kit',
        weight = 500,
    },

    ['repairkit'] = {
        label = 'Repair Kit',
        weight = 2500,
    },

    ['advancedrepairkit'] = {
        label = 'Advanced Repair Kit',
        weight = 4000,
    },

    ['tire_street_basic'] = {
        label = 'Kit Pneus Rua Comum',
        weight = 5200,
    },

    ['tire_street_sport'] = {
        label = 'Kit Pneus Rua Esportivo',
        weight = 5000,
    },

    ['tire_rain_pro'] = {
        label = 'Kit Pneus Chuva',
        weight = 5000,
    },

    ['tire_drift_pro'] = {
        label = 'Kit Pneus Drift Premium',
        weight = 4900,
    },

    ['tire_offroad_pro'] = {
        label = 'Kit Pneus Off-road',
        weight = 5600,
    },

    ['tire_race_premium'] = {
        label = 'Kit Pneus Corrida Premium',
        weight = 4700,
    },

    ['brake_street_basic'] = {
        label = 'Kit de Freio Rua',
        weight = 2600,
    },

    ['alignment_standard_service'] = {
        label = 'Kit de Alinhamento',
        weight = 900,
    },

    ['ecu_sport_stage'] = {
        label = 'ECU Sport',
        weight = 1200,
    },

    ['turbo_street_kit'] = {
        label = 'Turbo Street',
        weight = 6200,
    },

    ['supercharger_street_kit'] = {
        label = 'Compressor Street',
        weight = 6500,
    },

    ['radiator_heavy_duty'] = {
        label = 'Radiador Reforcado',
        weight = 3200,
    },

    ['filter_performance'] = {
        label = 'Filtro Performance',
        weight = 700,
    },

    ['clutch_performance'] = {
        label = 'Embreagem Performance',
        weight = 2100,
    },

    ['suspension_sport_kit'] = {
        label = 'Suspensao Esportiva',
        weight = 3600,
    },

    ['drivetrain_conversion_awd'] = {
        label = 'Kit Conversao AWD',
        weight = 7800,
    },

    ['diamond_ring'] = {
        label = 'Diamond',
        weight = 1500,
    },

    ['rolex'] = {
        label = 'Golden Watch',
        weight = 1500,
    },

    ['goldbar'] = {
        label = 'Gold Bar',
        weight = 1500,
    },

    ['goldchain'] = {
        label = 'Golden Chain',
        weight = 1500,
    },

    ['crack_baggy'] = {
        label = 'Crack Baggy',
        weight = 100,
    },

    ['cokebaggy'] = {
        label = 'Bag of Coke',
        weight = 100,
    },

    ['coke_brick'] = {
        label = 'Coke Brick',
        weight = 2000,
    },

    ['coke_small_brick'] = {
        label = 'Coke Package',
        weight = 1000,
    },

    ['xtcbaggy'] = {
        label = 'Bag of Ecstasy',
        weight = 100,
    },

    ['meth'] = {
        label = 'Methamphetamine',
        weight = 100,
    },

    ['oxy'] = {
        label = 'Oxycodone',
        weight = 100,
    },

    ['weed_ak47'] = {
        label = 'AK47 2g',
        weight = 200,
    },

    ['weed_ak47_seed'] = {
        label = 'AK47 Seed',
        weight = 1,
    },

    ['weed_skunk'] = {
        label = 'Skunk 2g',
        weight = 200,
    },

    ['weed_skunk_seed'] = {
        label = 'Skunk Seed',
        weight = 1,
    },

    ['weed_amnesia'] = {
        label = 'Amnesia 2g',
        weight = 200,
    },

    ['weed_amnesia_seed'] = {
        label = 'Amnesia Seed',
        weight = 1,
    },

    ['weed_og-kush'] = {
        label = 'OGKush 2g',
        weight = 200,
    },

    ['weed_og-kush_seed'] = {
        label = 'OGKush Seed',
        weight = 1,
    },

    ['weed_white-widow'] = {
        label = 'OGKush 2g',
        weight = 200,
    },

    ['weed_white-widow_seed'] = {
        label = 'White Widow Seed',
        weight = 1,
    },

    ['weed_purple-haze'] = {
        label = 'Purple Haze 2g',
        weight = 200,
    },

    ['weed_purple-haze_seed'] = {
        label = 'Purple Haze Seed',
        weight = 1,
    },

    ['weed_brick'] = {
        label = 'Weed Brick',
        weight = 2000,
    },

    ['weed_nutrition'] = {
        label = 'Plant Fertilizer',
        weight = 2000,
    },

    ['joint'] = {
        label = 'Joint',
        weight = 200,
    },

    ['rolling_paper'] = {
        label = 'Rolling Paper',
        weight = 0,
    },

    ['empty_weed_bag'] = {
        label = 'Empty Weed Bag',
        weight = 0,
    },

    ['firstaid'] = {
        label = 'First Aid',
        weight = 2500,
    },

    ['ifaks'] = {
        label = 'Individual First Aid Kit',
        weight = 2500,
    },

    ['painkillers'] = {
        label = 'Painkillers',
        weight = 400,
    },

    ['firework1'] = {
        label = '2Brothers',
        weight = 1000,
    },

    ['firework2'] = {
        label = 'Poppelers',
        weight = 1000,
    },

    ['firework3'] = {
        label = 'WipeOut',
        weight = 1000,
    },

    ['firework4'] = {
        label = 'Weeping Willow',
        weight = 1000,
    },

    ['steel'] = {
        label = 'Steel',
        weight = 100,
    },

    ['rubber'] = {
        label = 'Rubber',
        weight = 100,
    },

    ['metalscrap'] = {
        label = 'Metal Scrap',
        weight = 100,
    },

    ['iron'] = {
        label = 'Iron',
        weight = 100,
    },

    ['copper'] = {
        label = 'Copper',
        weight = 100,
    },

    ['aluminum'] = {
        label = 'Aluminium',
        weight = 100,
    },

    ['plastic'] = {
        label = 'Plastic',
        weight = 100,
    },

    ['glass'] = {
        label = 'Glass',
        weight = 100,
    },

    ['gatecrack'] = {
        label = 'Gatecrack',
        weight = 1000,
    },

    ['cryptostick'] = {
        label = 'Crypto Stick',
        weight = 100,
    },

    ['trojan_usb'] = {
        label = 'Trojan USB',
        weight = 100,
    },

    ['toaster'] = {
        label = 'Toaster',
        weight = 5000,
    },

    ['small_tv'] = {
        label = 'Small TV',
        weight = 100,
    },

    ['security_card_01'] = {
        label = 'Security Card A',
        weight = 100,
    },

    ['security_card_02'] = {
        label = 'Security Card B',
        weight = 100,
    },

    ['drill'] = {
        label = 'Drill',
        weight = 5000,
    },

    ['thermite'] = {
        label = 'Thermite',
        weight = 1000,
    },

    ['diving_gear'] = {
        label = 'Diving Gear',
        weight = 30000,
    },

    ['diving_fill'] = {
        label = 'Diving Tube',
        weight = 3000,
    },

    ['antipatharia_coral'] = {
        label = 'Antipatharia',
        weight = 1000,
    },

    ['dendrogyra_coral'] = {
        label = 'Dendrogyra',
        weight = 1000,
    },

    ['jerry_can'] = {
        label = 'Jerrycan',
        weight = 3000,
    },

    ['nitrous'] = {
        label = 'Nitrous',
        weight = 1000,
    },

    ['wine'] = {
        label = 'Wine',
        weight = 500,
    },

    ['grape'] = {
        label = 'Grape',
        weight = 10,
    },

    ['grapejuice'] = {
        label = 'Grape Juice',
        weight = 200,
    },

    ['coffee'] = {
        label = 'Coffee',
        weight = 200,
    },

    ['vodka'] = {
        label = 'Vodka',
        weight = 500,
    },

    ['whiskey'] = {
        label = 'Whiskey',
        weight = 200,
    },

    ['beer'] = {
        label = 'Beer',
        weight = 200,
    },

    ['sandwich'] = {
        label = 'Sandwich',
        weight = 200,
    },

    ['walking_stick'] = {
        label = 'Walking Stick',
        weight = 1000,
    },

    ['lighter'] = {
        label = 'Lighter',
        weight = 200,
    },

    ['binoculars'] = {
        label = 'Binoculars',
        weight = 800,
    },

    ['stickynote'] = {
        label = 'Sticky Note',
        weight = 0,
    },

    ['empty_evidence_bag'] = {
        label = 'Empty Evidence Bag',
        weight = 200,
    },

    ['filled_evidence_bag'] = {
        label = 'Filled Evidence Bag',
        weight = 200,
    },

    ['harness'] = {
        label = 'Harness',
        weight = 200,
    },

    ['tablet'] = {
        label = 'Tablet de Transportes',
        weight = 500,
        stack = false,
        close = true,
    },

    ['handcuffs'] = {
        label = 'Handcuffs',
        weight = 200,
    },

    -- TYCOON VEHICLE PARTS
    ['engine_block'] = {
        label = 'Bloco do Motor',
        weight = 7500,
    },

    ['transmission_gear'] = {
        label = 'Engrenagem de Transmissão',
        weight = 4000,
    },

    ['brake_pads'] = {
        label = 'Pastilhas de Freio',
        weight = 500,
    },

    ['suspension_arm'] = {
        label = 'Braço de Suspensão',
        weight = 2000,
    },

    ['truck_tire'] = {
        label = 'Pneu Reforçado',
        weight = 5000,
    },

    ['basic_repair_kit'] = {
        label = 'Kit de Reparo Básico',
        weight = 1500,
    },

    ['battery'] = {
        label = 'Bateria Elétrica',
        weight = 15000,
    },

    -- TYCOON SCRAP ITEMS
    ['mechanical_scrap'] = {
        label = 'Sucata Mecânica',
        weight = 2500,
    },

    ['electronic_scrap'] = {
        label = 'Sucata Eletrônica',
        weight = 1000,
    },

    ['rubber_scrap'] = {
        label = 'Sucata de Borracha',
        weight = 1500,
    },

    ['tycoon_cargo'] = {
        label = 'Carga Logística',
        weight = 1000,
        stack = true,
        close = true,
    },

    ['raw_metal'] = {
        label = 'Metal Bruto',
        weight = 1000,
    },

    ['raw_electronics'] = {
        label = 'Componentes Eletrônicos',
        weight = 200,
    },

    ['raw_rubber'] = {
        label = 'Borracha Bruta',
        weight = 1500,
    },

    -- ==========================================
    -- CIDADE TYCOON — Matérias-Primas & Produção
    -- ==========================================

    -- Mineração
    ['iron_ore'] = {
        label = 'Minério de Ferro',
        weight = 1200,
    },
    ['copper_wire'] = {
        label = 'Fio de Cobre',
        weight = 800,
    },
    ['stone'] = {
        label = 'Pedra Bruta',
        weight = 2000,
    },

    -- Ferro-Velho / Coleta
    ['raw_chemicals'] = {
        label = 'Produtos Químicos',
        weight = 1000,
    },

    -- TIER 1 — Materiais Processados
    ['steel_plate'] = {
        label = 'Chapa de Aço',
        weight = 2000,
    },
    ['aluminum_plate'] = {
        label = 'Chapa de Alumínio',
        weight = 1500,
    },
    ['copper_coil'] = {
        label = 'Bobina de Cobre',
        weight = 1200,
    },
    ['plastic_sheet'] = {
        label = 'Chapa Plástica',
        weight = 1000,
    },
    ['rubber_sheet'] = {
        label = 'Manta de Borracha',
        weight = 1500,
    },
    ['glass_pane'] = {
        label = 'Painel de Vidro',
        weight = 1200,
    },

    -- TIER 2 — Peças de Reparo
    ['mechanical_parts'] = {
        label = 'Peças Mecânicas',
        weight = 2500,
    },
    ['standard_tires'] = {
        label = 'Pneus Padrão',
        weight = 5000,
    },
    ['electronic_circuit'] = {
        label = 'Circuito Eletrônico',
        weight = 800,
    },
    ['suspension_kit'] = {
        label = 'Kit de Amortecedores',
        weight = 3000,
    },
    ['transmission_parts'] = {
        label = 'Peças de Transmissão',
        weight = 3500,
    },
    ['transmission_street_kit'] = {
        label = 'Transmissao Street',
        weight = 3800,
    },
    ['transmission_sport_kit'] = {
        label = 'Transmissao Sport',
        weight = 3900,
    },
    ['transmission_race_kit'] = {
        label = 'Transmissao Corrida',
        weight = 4100,
    },
    ['drivetrain_conversion_fwd'] = {
        label = 'Kit Conversao FWD',
        weight = 5200,
    },
    ['drivetrain_conversion_rwd'] = {
        label = 'Kit Conversao RWD',
        weight = 6100,
    },
    ['reinforced_frame'] = {
        label = 'Chassi Reforçado',
        weight = 5000,
    },

    -- TIER 3 — Performance
    ['performance_brakes'] = {
        label = 'Freios Esportivos',
        weight = 2500,
    },
    ['brake_sport_kit'] = {
        label = 'Kit de Freio Sport',
        weight = 2700,
    },
    ['brake_race_kit'] = {
        label = 'Kit de Freio Corrida',
        weight = 2900,
    },
    ['drift_tires'] = {
        label = 'Pneus de Drift',
        weight = 4000,
    },
    ['turbo_kit'] = {
        label = 'Kit Turbo',
        weight = 3500,
    },
    ['racing_tires'] = {
        label = 'Pneus de Corrida',
        weight = 4000,
    },
    ['drag_tires'] = {
        label = 'Pneus de Arrancada',
        weight = 4500,
    },
    ['traction_control'] = {
        label = 'Controle de Tração',
        weight = 1500,
    },
    ['performance_kit_drag'] = {
        label = 'Kit Drag Race',
        weight = 12000,
    },
    ['performance_kit_drift'] = {
        label = 'Kit Drift',
        weight = 10000,
    },
    ['performance_kit_race'] = {
        label = 'Kit Corrida',
        weight = 11000,
    },
    -- ILEGAL
    ['refined_powder'] = {
        label = 'Pó Refinado',
        weight = 500,
    },
    ['weapon_parts'] = {
        label = 'Peças de Arma',
        weight = 2000,
    },
    ['counterfeit_chip'] = {
        label = 'Chip Falsificado',
        weight = 300,
    },
    ['explosive_compound'] = {
        label = 'Composto Explosivo',
        weight = 1500,
    },
    ['ammo_pack'] = {
        label = 'Pacote de Munição',
        weight = 3000,
    },

    -- ESPECIAL
    ['advanced_lockpick'] = {
        label = 'Lockpick Avançado',
        weight = 500,
    },
    ['vehicle_armor'] = {
        label = 'Blindagem Veicular',
        weight = 8000,
    },
    ['advanced_repair_kit'] = {
        label = 'Kit de Reparo Avançado',
        weight = 4000,
    },
    ['car_jack'] = {
        label = 'Macaco Hidráulico',
        weight = 8500,
        description = 'Usado para levantar veículos e trocar pneus.',
        allowArmed = true,
        client = {
            image = 'macaco_hidraulico.png',
        }
    },
}
