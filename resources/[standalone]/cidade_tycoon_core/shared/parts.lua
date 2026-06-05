TycoonCore = TycoonCore or {}

TycoonCore.Parts = {
    ['engine_block'] = { label = 'Bloco do Motor', category = 'engine', price = 2500, repairValue = 40, weight = 7500 }, -- 7.5kg
    ['transmission_gear'] = { label = 'Engrenagem de Transmissão', category = 'transmission', price = 1800, repairValue = 35, weight = 4000 }, -- 4kg
    ['brake_pads'] = { label = 'Pastilhas de Freio', category = 'brakes', price = 450, repairValue = 25, weight = 500 }, -- 0.5kg
    ['suspension_arm'] = { label = 'Braço de Suspensão', category = 'suspension', price = 950, repairValue = 30, weight = 2000 }, -- 2kg
    ['truck_tire'] = { label = 'Pneu Reforçado', category = 'tires', price = 600, repairValue = 25, weight = 5000 }, -- 5kg
    ['basic_repair_kit'] = { label = 'Kit de Reparo Básico', category = 'all', price = 300, repairValue = 15, weight = 1500 }, -- 1.5kg
}

function TycoonCore.GetPartData(itemName)
    return TycoonCore.Parts[itemName:lower()]
end

return TycoonCore.Parts
