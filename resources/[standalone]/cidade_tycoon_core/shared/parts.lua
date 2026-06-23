TycoonCore = TycoonCore or {}

TycoonCore.Parts = {
    -- Reparo / reposicao
    ['engine_block'] = { label = 'Bloco do Motor', category = 'engine', price = 2500, repairValue = 40, weight = 7500 },
    ['transmission_gear'] = { label = 'Engrenagem de Transmissao', category = 'transmission', price = 1800, repairValue = 35, weight = 4000 },
    ['transmission_parts'] = { label = 'Pecas de Transmissao', category = 'transmission', price = 1200, repairValue = 30, weight = 3500 },
    ['brake_pads'] = { label = 'Pastilhas de Freio', category = 'brakes', price = 450, repairValue = 25, weight = 500 },
    ['suspension_arm'] = { label = 'Braco de Suspensao', category = 'suspension', price = 950, repairValue = 30, weight = 2000 },
    ['suspension_kit'] = { label = 'Kit de Amortecedores', category = 'suspension', price = 1300, repairValue = 35, weight = 3000 },
    ['mechanical_parts'] = { label = 'Pecas Mecanicas', category = 'all', price = 900, repairValue = 18, weight = 2500 },
    ['truck_tire'] = { label = 'Pneu Reforcado', category = 'tires', price = 6000, repairValue = 25, weight = 5000 },
    ['standard_tires'] = { label = 'Pneu Comum', category = 'tires', price = 3000, repairValue = 20, weight = 4000 },
    ['basic_repair_kit'] = { label = 'Kit de Reparo Basico', category = 'all', price = 300, repairValue = 15, weight = 1500 },
    ['advanced_repair_kit'] = { label = 'Kit de Reparo Avancado', category = 'all', price = 900, repairValue = 35, weight = 4000 },

    -- Pneus instalaveis
    ['tire_street_basic'] = { label = 'Kit Pneus Rua Comum', category = 'tires', price = 3800, repairValue = 20, weight = 5200 },
    ['tire_street_sport'] = { label = 'Kit Pneus Rua Esportivo', category = 'tires', price = 7200, repairValue = 30, weight = 5000 },
    ['tire_rain_pro'] = { label = 'Kit Pneus Chuva', category = 'tires', price = 7600, repairValue = 25, weight = 5000 },
    ['tire_drift_pro'] = { label = 'Kit Pneus Drift Premium', category = 'tires', price = 14800, repairValue = 35, weight = 4900 },
    ['tire_offroad_pro'] = { label = 'Kit Pneus Off-road', category = 'tires', price = 9800, repairValue = 35, weight = 5600 },
    ['tire_race_premium'] = { label = 'Kit Pneus Corrida Premium', category = 'tires', price = 26500, repairValue = 40, weight = 4700 },
    ['drift_tires'] = { label = 'Pneus de Drift', category = 'tires', price = 12000, repairValue = 35, weight = 4000 },
    ['racing_tires'] = { label = 'Pneus de Corrida', category = 'tires', price = 15000, repairValue = 40, weight = 4000 },
    ['drag_tires'] = { label = 'Pneus de Arrancada', category = 'tires', price = 14000, repairValue = 35, weight = 4500 },

    -- Freios instalaveis
    ['brake_street_basic'] = { label = 'Kit de Freio Rua', category = 'brakes', price = 4200, repairValue = 25, weight = 2600 },
    ['performance_brakes'] = { label = 'Freios Esportivos', category = 'brakes', price = 1800, repairValue = 35, weight = 2500 },
    ['brake_sport_kit'] = { label = 'Kit de Freio Sport', category = 'brakes', price = 2600, repairValue = 35, weight = 2700 },
    ['brake_race_kit'] = { label = 'Kit de Freio Corrida', category = 'brakes', price = 5200, repairValue = 45, weight = 2900 },

    -- Suspensao / alinhamento instalaveis
    ['suspension_sport_kit'] = { label = 'Suspensao Esportiva', category = 'suspension', price = 15800, repairValue = 40, weight = 3600 },
    ['alignment_standard_service'] = { label = 'Kit de Alinhamento', category = 'alignment', price = 1800, repairValue = 100, weight = 900 },

    -- Motor / performance instalaveis
    ['filter_performance'] = { label = 'Filtro Performance', category = 'engine', price = 3200, repairValue = 10, weight = 700 },
    ['radiator_heavy_duty'] = { label = 'Radiador Reforcado', category = 'engine', price = 6900, repairValue = 30, weight = 3200 },
    ['ecu_sport_stage'] = { label = 'ECU Sport', category = 'engine', price = 16800, repairValue = 0, weight = 1200 },
    ['turbo_street_kit'] = { label = 'Turbo Street', category = 'engine', price = 24500, repairValue = 0, weight = 6200 },
    ['turbo_kit'] = { label = 'Kit Turbo Profissional', category = 'engine', price = 32000, repairValue = 0, weight = 4800 },
    ['supercharger_street_kit'] = { label = 'Compressor Street', category = 'engine', price = 27200, repairValue = 0, weight = 6500 },

    -- Transmissao instalavel
    ['clutch_performance'] = { label = 'Embreagem Performance', category = 'transmission', price = 14200, repairValue = 30, weight = 2100 },
    ['transmission_street_kit'] = { label = 'Transmissao Street', category = 'transmission', price = 3200, repairValue = 0, weight = 3800 },
    ['transmission_sport_kit'] = { label = 'Transmissao Sport', category = 'transmission', price = 6200, repairValue = 0, weight = 3900 },
    ['transmission_race_kit'] = { label = 'Transmissao Corrida', category = 'transmission', price = 9800, repairValue = 0, weight = 4100 },
    ['drivetrain_conversion_fwd'] = { label = 'Kit Conversao FWD', category = 'transmission', price = 32000, repairValue = 0, weight = 5200 },
    ['drivetrain_conversion_rwd'] = { label = 'Kit Conversao RWD', category = 'transmission', price = 41000, repairValue = 0, weight = 6100 },
    ['drivetrain_conversion_awd'] = { label = 'Kit Conversao AWD', category = 'transmission', price = 54000, repairValue = 0, weight = 7800 },
    ['traction_control'] = { label = 'Controle de Tracao', category = 'transmission', price = 4300, repairValue = 0, weight = 1500 },

    -- Ferramentas
    ['weapon_wrench'] = { label = 'Chave Inglesa', category = 'tools', price = 800, repairValue = 0, weight = 1200 },
    ['car_jack'] = { label = 'Macaco Hidraulico', category = 'tools', price = 2500, repairValue = 0, weight = 8500 },
    ['battery'] = { label = 'Bateria Elétrica', category = 'battery', price = 4500, repairValue = 100, weight = 15000 },

    -- Performance Kits (instalação única que define a identidade do carro)
    ['performance_kit_drag'] = {
        label = 'Kit Drag Race',
        category = 'kit',
        price = 55000,
        repairValue = 0,
        weight = 12000,
        desc = 'Aceleracao extrema em linha reta. O carro fica quase inguinavel em curvas.'
    },
    ['performance_kit_drift'] = {
        label = 'Kit Drift',
        category = 'kit',
        price = 48000,
        repairValue = 0,
        weight = 10000,
        desc = 'Derrapagem controlada. Menos aderencia, mais angulo, suspensao macia para drift.'
    },
    ['performance_kit_race'] = {
        label = 'Kit Corrida',
        category = 'kit',
        price = 72000,
        repairValue = 0,
        weight = 11000,
        desc = 'Kit profissional de corrida. Equilibrio maximo entre aceleracao, frenagem e aderencia.'
    },
}

function TycoonCore.GetPartData(itemName)
    if not itemName then return nil end
    return TycoonCore.Parts[itemName:lower()]
end

return TycoonCore.Parts
