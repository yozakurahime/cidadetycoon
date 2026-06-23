local function DebugLog(text, ...)
    print(string.format("^3[Tycoon:Server:Mechanic]^7 %s", string.format(text, ...)))
end


local function normalizePlate(plate)
    return exports.cidade_tycoon_core:NormalizePlate(plate)
end

local function getVehicleRowByPlate(plate)
    local normalizedPlate = normalizePlate(plate)
    return MySQL.single.await([[
        SELECT plate, vehicle, mods
        FROM player_vehicles
        WHERE plate = ? OR REPLACE(UPPER(plate), ' ', '') = ?
        LIMIT 1
    ]], { plate, normalizedPlate })
end

local function plateMatches(vehicle, plate)
    return normalizePlate(GetVehicleNumberPlateText(vehicle)) == normalizePlate(plate)
end
local function isVehicleElectricByPlate(plate)
    local vehicleRow = getVehicleRowByPlate(plate)
    if vehicleRow then
        return exports.cidade_tycoon_core:IsVehicleElectric(vehicleRow.vehicle)
    end

    local vehicles = GetAllVehicles()
    for _, veh in ipairs(vehicles) do
        if plateMatches(veh, plate) then
            return exports.cidade_tycoon_core:IsVehicleElectric(GetEntityModel(veh))
        end
    end
    return false
end

local KIT_REPAIR_MAX_HEALTH = 50.0
local KIT_REPAIR_FATIGUE_STEP = 0.18
local KIT_REPAIR_FATIGUE_CAP = 1.0

local repairItems = {
    engine_block = true,
    transmission_gear = true,
    transmission_parts = true,
    brake_pads = true,
    brake_street_basic = true,
    performance_brakes = true,
    suspension_arm = true,
    suspension_kit = true,
    mechanical_parts = true,
    basic_repair_kit = true,
    advanced_repair_kit = true,
    truck_tire = true,
    standard_tires = true,
    battery = true,
}

local installSlots = {
    standard_tires = 'installed_tires',
    truck_tire = 'installed_tires',
    tire_street_basic = 'installed_tires',
    tire_street_sport = 'installed_tires',
    tire_rain_pro = 'installed_tires',
    tire_drift_pro = 'installed_tires',
    tire_offroad_pro = 'installed_tires',
    tire_race_premium = 'installed_tires',
    drift_tires = 'installed_tires',
    racing_tires = 'installed_tires',
    drag_tires = 'installed_tires',
    brake_street_basic = 'installed_brakes',
    performance_brakes = 'installed_brakes',
    brake_sport_kit = 'installed_brakes',
    brake_race_kit = 'installed_brakes',
    suspension_kit = 'installed_suspension',
    suspension_sport_kit = 'installed_suspension',
    alignment_standard_service = 'installed_alignment',
    filter_performance = 'installed_engine',
    radiator_heavy_duty = 'installed_engine',
    ecu_sport_stage = 'installed_engine',
    turbo_street_kit = 'installed_engine',
    turbo_kit = 'installed_engine',
    supercharger_street_kit = 'installed_engine',
    clutch_performance = 'installed_transmission',
    transmission_street_kit = 'installed_transmission',
    transmission_sport_kit = 'installed_transmission',
    transmission_race_kit = 'installed_transmission',
    drivetrain_conversion_fwd = 'installed_drivetrain',
    drivetrain_conversion_rwd = 'installed_drivetrain',
    drivetrain_conversion_awd = 'installed_drivetrain',
    traction_control = 'installed_drivetrain',
    battery = 'installed_engine',
    -- Performance kits (ao instalar um kit, ele sobrescreve os slots individuais)
    performance_kit_drag = 'installed_performance_kit',
    performance_kit_drift = 'installed_performance_kit',
    performance_kit_race = 'installed_performance_kit',
}

local slotSubsystem = {
    installed_tires = 'tires',
    installed_brakes = 'brakes',
    installed_suspension = 'suspension',
    installed_alignment = 'suspension',
    installed_engine = 'engine',
    installed_transmission = 'transmission',
    installed_drivetrain = 'drivetrain',
    installed_performance_kit = 'performance_kit',
}

local slotHealthSubsystem = {
    installed_tires = 'tires',
    installed_brakes = 'brakes',
    installed_suspension = 'suspension',
    installed_alignment = 'suspension',
    installed_engine = 'engine',
    installed_transmission = 'transmission',
    installed_drivetrain = 'transmission',
}

local subsystemRepairItems = {
    engine = { engine_block = true, filter_performance = true, radiator_heavy_duty = true, mechanical_parts = true, basic_repair_kit = true },
    transmission = { transmission_gear = true, transmission_parts = true, clutch_performance = true, mechanical_parts = true, basic_repair_kit = true },
    drivetrain = { transmission_parts = true, mechanical_parts = true, basic_repair_kit = true },
    brakes = { brake_pads = true, brake_street_basic = true, performance_brakes = true, mechanical_parts = true, basic_repair_kit = true },
    suspension = { suspension_arm = true, suspension_kit = true, mechanical_parts = true, basic_repair_kit = true },
    tires = { truck_tire = true, standard_tires = true, basic_repair_kit = true },
    tire_lf = { truck_tire = true, standard_tires = true, basic_repair_kit = true },
    tire_rf = { truck_tire = true, standard_tires = true, basic_repair_kit = true },
    tire_lr = { truck_tire = true, standard_tires = true, basic_repair_kit = true },
    tire_rr = { truck_tire = true, standard_tires = true, basic_repair_kit = true },
    battery = { battery = true, basic_repair_kit = true, advanced_repair_kit = true, mechanical_parts = true },
}

local kitRepairItems = {
    basic_repair_kit = { all = true },
    -- advanced_repair_kit is NOT for repairing parts - it's for install/replace + body repair only
    mechanical_parts = {
        engine = true,
        transmission = true,
        drivetrain = true,
        brakes = true,
        suspension = true,
        battery = true,
    },
}

local replacementItems = {
    engine = { engine_block = true },
    transmission = { transmission_gear = true, transmission_parts = true },
    brakes = { brake_pads = true },
    suspension = { suspension_arm = true },
    tires = { standard_tires = true, truck_tire = true },
    tire_lf = { standard_tires = true, truck_tire = true },
    tire_rf = { standard_tires = true, truck_tire = true },
    tire_lr = { standard_tires = true, truck_tire = true },
    tire_rr = { standard_tires = true, truck_tire = true },
    battery = { battery = true },
}

local function isTireSubsystem(subsystemKey)
    return subsystemKey == 'tires' or (subsystemKey and subsystemKey:find('tire_') == 1)
end

local function getInstallTargetSubsystem(itemName)
    local installSlot = installSlots[itemName]
    if itemName == 'battery' then
        return 'battery'
    end

    return slotSubsystem[installSlot]
end

local function itemCanInstallForSubsystem(itemName, subsystemKey)
    local installSlot = installSlots[itemName]
    local targetSub = getInstallTargetSubsystem(itemName)

    if installSlot and (subsystemKey == 'all' or targetSub == subsystemKey or (isTireSubsystem(subsystemKey) and installSlot == 'installed_tires')) then
        return true
    end

    return false
end

local function itemCanRepairSubsystem(itemName, subsystemKey)
    local allowed = kitRepairItems[itemName]
    if not allowed then return false end
    if allowed.all then return true end

    local key = subsystemKey
    if key == 'drivetrain' then
        key = 'transmission'
    elseif isTireSubsystem(key) then
        key = 'tires'
    end

    return allowed[key] == true or allowed[subsystemKey] == true
end

local function itemCanReplaceSubsystem(itemName, subsystemKey)
    if itemCanInstallForSubsystem(itemName, subsystemKey) then
        return true
    end

    return replacementItems[subsystemKey] and replacementItems[subsystemKey][itemName] == true
end

local function itemCanReplaceAnySubsystem(itemName)
    if installSlots[itemName] then return true end

    for _, items in pairs(replacementItems) do
        if items[itemName] then return true end
    end

    return false
end

local function itemMatchesSubsystem(itemName, subsystemKey)
    return itemCanInstallForSubsystem(itemName, subsystemKey) or itemCanRepairSubsystem(itemName, subsystemKey)
end

local function hasMechanicJob(src)
    local job = exports.cidade_tycoon_core:GetPlayerJob(src)
    return job and job.name == 'mechanic'
end

local function consumePart(src, itemName)
    local item = exports.ox_inventory:GetItem(src, itemName, nil, false)
    if not item or item.count < 1 then return false end
    return exports.ox_inventory:RemoveItem(src, itemName, 1)
end

-- For install/replace: requires part + advanced repair kit
local function consumePartWithKit(src, itemName)
    if not consumePart(src, itemName) then
        return false, 'Voce nao tem a peca na mochila.'
    end
    if not consumePart(src, 'advanced_repair_kit') then
        exports.ox_inventory:AddItem(src, itemName, 1)
        return false, 'Voce precisa de 1x Kit de Reparo Avancado junto com a peca.'
    end
    return true, nil
end

local function syncStatus(plate, status)
    exports.cidade_tycoon_core:UpdateVehicleStatus(plate, status)
    if exports.cidade_tycoon_maintenance.SyncVehicleStateBag then
        exports.cidade_tycoon_maintenance:SyncVehicleStateBag(plate, status)
    end
end

local function addScrap(src, partData, itemName)
    local scrapItem = 'mechanical_scrap'
    if partData.category == 'tires' then
        scrapItem = 'rubber_scrap'
    elseif itemName:find('ecu') then
        scrapItem = 'electronic_scrap'
    end
    exports.ox_inventory:AddItem(src, scrapItem, 1)
end

local function normalizeHealthSubsystem(subsystemKey)
    if subsystemKey == 'drivetrain' then
        return 'transmission'
    end

    return subsystemKey
end

local function subsystemHasHealth(status, subsystemKey)
    local healthSubsystem = normalizeHealthSubsystem(subsystemKey)
    if healthSubsystem == 'tires' then return true end
    if healthSubsystem and healthSubsystem:find('tire_') then
        return status[healthSubsystem .. '_health'] ~= nil
    end

    return healthSubsystem and status[healthSubsystem .. '_health'] ~= nil
end

local function applyRepair(status, subsystemKey, amount, maxHealth)
    maxHealth = maxHealth or 100.0
    local healthSubsystem = normalizeHealthSubsystem(subsystemKey)

    if healthSubsystem == 'tires' then
        status.tire_lf_health = math.min(maxHealth, (status.tire_lf_health or 100.0) + amount)
        status.tire_rf_health = math.min(maxHealth, (status.tire_rf_health or 100.0) + amount)
        status.tire_lr_health = math.min(maxHealth, (status.tire_lr_health or 100.0) + amount)
        status.tire_rr_health = math.min(maxHealth, (status.tire_rr_health or 100.0) + amount)
    elseif healthSubsystem and healthSubsystem:find('tire_') then
        local column = healthSubsystem .. '_health'
        status[column] = math.min(maxHealth, (status[column] or 100.0) + amount)
    else
        if not healthSubsystem then return false end
        local column = healthSubsystem .. '_health'
        if status[column] == nil then return false end
        status[column] = math.min(maxHealth, status[column] + amount)
    end

    return true
end

local function setSubsystemHealth(status, subsystemKey, health)
    local healthSubsystem = normalizeHealthSubsystem(subsystemKey)

    if healthSubsystem == 'tires' then
        status.tire_lf_health = health
        status.tire_rf_health = health
        status.tire_lr_health = health
        status.tire_rr_health = health
    elseif healthSubsystem and healthSubsystem:find('tire_') then
        local column = healthSubsystem .. '_health'
        status[column] = health
    else
        if not healthSubsystem then return false end
        local column = healthSubsystem .. '_health'
        if status[column] == nil then return false end
        status[column] = health
    end

    return true
end

local function getSubsystemHealth(status, subsystemKey)
    local healthSubsystem = normalizeHealthSubsystem(subsystemKey)

    if healthSubsystem == 'tires' then
        return math.min(
            status.tire_lf_health or 100.0,
            status.tire_rf_health or 100.0,
            status.tire_lr_health or 100.0,
            status.tire_rr_health or 100.0
        )
    elseif healthSubsystem and healthSubsystem:find('tire_') then
        return status[healthSubsystem .. '_health'] or 100.0
    end

    if not healthSubsystem then return nil end
    return status[healthSubsystem .. '_health']
end

local function ensureRepairFatigue(status)
    if type(status.repair_fatigue) ~= 'table' then
        status.repair_fatigue = {}
    end
    return status.repair_fatigue
end

local function getRepairFatigueKeys(subsystemKey)
    local healthSubsystem = normalizeHealthSubsystem(subsystemKey)
    if healthSubsystem == 'tires' then
        return { 'tire_lf', 'tire_rf', 'tire_lr', 'tire_rr' }
    elseif healthSubsystem and healthSubsystem:find('tire_') then
        return { healthSubsystem }
    end
    return { healthSubsystem }
end

local function addRepairFatigue(status, subsystemKey)
    local repairFatigue = ensureRepairFatigue(status)
    for _, key in ipairs(getRepairFatigueKeys(subsystemKey)) do
        if key then
            repairFatigue[key] = math.min(KIT_REPAIR_FATIGUE_CAP, (tonumber(repairFatigue[key]) or 0.0) + KIT_REPAIR_FATIGUE_STEP)
        end
    end
end

local function resetRepairFatigue(status, subsystemKey)
    local repairFatigue = ensureRepairFatigue(status)
    for _, key in ipairs(getRepairFatigueKeys(subsystemKey)) do
        if key then repairFatigue[key] = 0.0 end
    end
end

lib.callback.register('cidade_tycoon_mechanic:server:getAvailableParts', function(source, categoryKey, mode)
    local inventory = exports.ox_inventory:GetInventoryItems(source)
    if type(inventory) == 'boolean' or not inventory then return {} end

    local available = {}
    categoryKey = categoryKey or 'all'

    for slot, item in pairs(inventory) do
        if type(item) == 'table' and item.name and item.count > 0 then
            local partData = exports.cidade_tycoon_core:GetPartData(item.name)
            local include = false

            if partData then
                if mode == 'install' then
                    include = itemCanInstallForSubsystem(item.name, categoryKey)
                elseif mode == 'repair' then
                    include = repairItems[item.name] == true and (categoryKey == 'all' or itemCanRepairSubsystem(item.name, categoryKey))
                elseif mode == 'replace' then
                    include = (categoryKey == 'all' and itemCanReplaceAnySubsystem(item.name)) or itemCanReplaceSubsystem(item.name, categoryKey)
                else
                    include = partData.category == categoryKey or partData.category == 'all'
                end
            end

            if include then
                table.insert(available, {
                    name = item.name,
                    label = partData.label,
                    count = item.count,
                    repairValue = partData.repairValue or 0.0,
                    installSlot = installSlots[item.name],
                    slot = slot
                })
            end
        end
    end

    return available
end)

local function installUpgrade(src, plate, itemName)
    plate = normalizePlate(plate)
    if not hasMechanicJob(src) then return { ok = false, message = 'Apenas mecanicos podem instalar modificacoes.' } end

    local partData = exports.cidade_tycoon_core:GetPartData(itemName)
    local installSlot = installSlots[itemName]
    if not partData or not installSlot then return { ok = false, message = 'Peca nao instalavel como modificacao.' } end

    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return { ok = false, message = 'Veiculo nao registrado no sistema logistico.' } end

    local isElectric = isVehicleElectricByPlate(plate)
    if itemName == 'battery' and not isElectric then
        return { ok = false, message = 'Bateria eletrica so pode ser instalada em veiculos eletricos.' }
    end
    if isElectric and installSlot == 'installed_engine' and itemName ~= 'battery' then
        return { ok = false, message = 'Veiculo eletrico usa bateria, nao pecas de motor a combustao.' }
    end

    local ok_kit, msg_kit = consumePartWithKit(src, itemName)
    if not ok_kit then
        return { ok = false, message = msg_kit }
    end

    status[installSlot] = itemName

    if installSlot == 'installed_tires' then
        status.tire_type = itemName == 'truck_tire' and 'reinforced' or 'standard'
        status.tire_lf_health = 100.0
        status.tire_rf_health = 100.0
        status.tire_lr_health = 100.0
        status.tire_rr_health = 100.0
    elseif installSlot == 'installed_engine' then
        if isElectric then
            status.battery_health = 100.0
        else
            status.engine_health = math.max(status.engine_health or 0.0, 85.0)
        end
    elseif installSlot == 'installed_transmission' then
        status.transmission_health = math.max(status.transmission_health or 0.0, 85.0)
    elseif installSlot == 'installed_drivetrain' then
        status.transmission_health = math.max(status.transmission_health or 0.0, 85.0)
    elseif installSlot == 'installed_brakes' then
        status.brakes_health = math.max(status.brakes_health or 0.0, 85.0)
    elseif installSlot == 'installed_suspension' then
        status.suspension_health = math.max(status.suspension_health or 0.0, 85.0)
    elseif installSlot == 'installed_alignment' then
        status.suspension_health = math.max(status.suspension_health or 0.0, 75.0)
    end

    local resetSubsystem = slotHealthSubsystem[installSlot]
    if isElectric and installSlot == 'installed_engine' then
        resetSubsystem = 'battery'
    end
    resetRepairFatigue(status, resetSubsystem)

    syncStatus(plate, status)
    addScrap(src, partData, itemName)

    return { ok = true, message = ('%s instalado. Funcionamento do veiculo atualizado.'):format(partData.label) }
end

lib.callback.register('cidade_tycoon_mechanic:server:installUpgrade', function(source, plate, itemName)
    if not exports.cidade_tycoon_core:CheckRateLimit(source, 'mechanic_install', 3000) then
        return { ok = false, message = 'Aguarde antes de instalar outra peca.' }
    end
    return installUpgrade(source, plate, itemName)
end)

local function repairInstalledPart(src, plate, subsystemKey)
    plate = normalizePlate(plate)
    if not hasMechanicJob(src) then return { ok = false, message = 'Apenas mecanicos podem reparar subsistemas internos.' } end

    return { ok = false, message = 'Use Reparar com kit ou Trocar a peca. Reparo interno sem item foi desativado.' }
end

local function repairInstalledPartWithItem(src, plate, subsystemKey, itemName)
    plate = normalizePlate(plate)
    if not hasMechanicJob(src) then return { ok = false, message = 'Apenas mecanicos podem reparar subsistemas internos.' } end

    local partData = exports.cidade_tycoon_core:GetPartData(itemName)
    if not partData then return { ok = false, message = 'Item invalido para reparo.' } end
    if not itemCanRepairSubsystem(itemName, subsystemKey) then
        return { ok = false, message = 'Este item nao repara esse subsistema.' }
    end

    local repairAmount = tonumber(partData.repairValue) or 0.0
    if repairAmount <= 0 then
        return { ok = false, message = 'Este item nao possui valor de reparo.' }
    end

    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return { ok = false, message = 'Veiculo nao registrado no sistema logistico.' } end
    if not subsystemHasHealth(status, subsystemKey) then
        return { ok = false, message = 'Subsistema invalido.' }
    end

    local currentHealth = getSubsystemHealth(status, subsystemKey)
    if currentHealth and currentHealth >= KIT_REPAIR_MAX_HEALTH then
        return { ok = false, message = ('Esta peca ja esta com %.0f%% ou mais. Use Trocar a peca para restaurar 100%%.'):format(KIT_REPAIR_MAX_HEALTH) }
    end

    if not consumePart(src, itemName) then
        return { ok = false, message = 'Voce nao tem o item na mochila.' }
    end

    if not applyRepair(status, subsystemKey, repairAmount, KIT_REPAIR_MAX_HEALTH) then
        return { ok = false, message = 'Subsistema invalido.' }
    end

    addRepairFatigue(status, subsystemKey)
    syncStatus(plate, status)
    addScrap(src, partData, itemName)

    return { ok = true, message = ('%s usado. %s reparado ate no maximo 50%%. Esta peca agora desgasta mais rapido.'):format(partData.label, subsystemKey) }
end

lib.callback.register('cidade_tycoon_mechanic:server:repairInstalledPart', function(source, plate, subsystemKey)
    if not exports.cidade_tycoon_core:CheckRateLimit(source, 'mechanic_repair_' .. plate, 4000) then
        return { ok = false, message = 'Aguarde antes de reparar novamente.' }
    end
    return repairInstalledPart(source, plate, subsystemKey)
end)

lib.callback.register('cidade_tycoon_mechanic:server:repairInstalledPartWithItem', function(source, plate, subsystemKey, itemName)
    if not exports.cidade_tycoon_core:CheckRateLimit(source, 'mechanic_repair_item_' .. plate, 4000) then
        return { ok = false, message = 'Aguarde antes de reparar novamente.' }
    end
    return repairInstalledPartWithItem(source, plate, subsystemKey, itemName)
end)

local function replaceInstalledPart(src, plate, subsystemKey, itemName)
    plate = normalizePlate(plate)
    if not hasMechanicJob(src) then return { ok = false, message = 'Apenas mecanicos podem trocar pecas internas.' } end

    local partData = exports.cidade_tycoon_core:GetPartData(itemName)
    if not partData then return { ok = false, message = 'Item invalido para troca.' } end
    if not itemCanReplaceSubsystem(itemName, subsystemKey) then
        return { ok = false, message = 'Esta peca nao pode substituir esse subsistema.' }
    end

    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return { ok = false, message = 'Veiculo nao registrado no sistema logistico.' } end

    local isElectric = isVehicleElectricByPlate(plate)
    if itemName == 'battery' and not isElectric then
        return { ok = false, message = 'Bateria eletrica so pode substituir subsistema de veiculo eletrico.' }
    end
    local ok_kit, msg_kit = consumePartWithKit(src, itemName)
    if not ok_kit then
        return { ok = false, message = msg_kit }
    end

    local installSlot = installSlots[itemName]
    local resetSubsystem = subsystemKey
    if installSlot then
        status[installSlot] = itemName

        if installSlot == 'installed_tires' then
            status.tire_type = itemName == 'truck_tire' and 'reinforced' or 'standard'
            setSubsystemHealth(status, 'tires', 100.0)
            resetSubsystem = 'tires'
        else
            local targetHealthSub = slotHealthSubsystem[installSlot]
            if isElectric and installSlot == 'installed_engine' then
                targetHealthSub = 'battery'
            end
            setSubsystemHealth(status, targetHealthSub, 100.0)
            resetSubsystem = targetHealthSub
        end
    else
        if not setSubsystemHealth(status, subsystemKey, 100.0) then
            return { ok = false, message = 'Subsistema invalido.' }
        end
    end

    resetRepairFatigue(status, resetSubsystem)
    syncStatus(plate, status)
    addScrap(src, partData, itemName)

    local bonusText = installSlot and ' Bonus da peca aplicado.' or ' Peca substituida sem bonus de tunagem.'
    return { ok = true, message = ('%s trocado. Saude restaurada para 100%%.%s'):format(partData.label, bonusText) }
end

lib.callback.register('cidade_tycoon_mechanic:server:replaceInstalledPart', function(source, plate, subsystemKey, itemName)
    if not exports.cidade_tycoon_core:CheckRateLimit(source, 'mechanic_replace_' .. plate, 4000) then
        return { ok = false, message = 'Aguarde antes de trocar outra peca.' }
    end
    return replaceInstalledPart(source, plate, subsystemKey, itemName)
end)

lib.callback.register('cidade_tycoon_mechanic:server:repairBody', function(source, plate)
    plate = normalizePlate(plate)
    local src = source
    if not hasMechanicJob(src) then return { ok = false, message = 'Apenas mecanicos podem reparar lataria.' } end

    if not consumePart(src, 'basic_repair_kit') then
        return { ok = false, message = 'Voce precisa de um Kit de Reparo Basico para a lataria.' }
    end

    local row = getVehicleRowByPlate(plate)
    if row then
        local props = {}
        if row.mods and row.mods ~= '' then
            local ok, decoded = pcall(json.decode, row.mods)
            if ok and type(decoded) == 'table' then props = decoded end
        end
        props.plate = props.plate or plate
        props.bodyHealth = 1000.0
        MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE plate = ?', { json.encode(props), row.plate or plate })
    end

    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if status then
        status.body_health = 100.0
        syncStatus(plate, status)
    end

    exports.ox_inventory:AddItem(src, 'mechanical_scrap', 1)
    return { ok = true, message = 'Lataria reparada. Uma sucata foi gerada.' }
end)

lib.callback.register('cidade_tycoon_mechanic:server:installPart', function(source, plate, itemName, targetCategory)
    plate = normalizePlate(plate)
    if not exports.cidade_tycoon_core:CheckRateLimit(source, 'mechanic_install_' .. plate, 3000) then
        return { ok = false, message = 'Aguarde antes de instalar outra peca.' }
    end
    if isTireSubsystem(targetCategory) and (itemName == 'standard_tires' or itemName == 'truck_tire') then
        local partData = exports.cidade_tycoon_core:GetPartData(itemName)
        if not partData then return { ok = false, message = 'Item invalido.' } end
        if not itemMatchesSubsystem(itemName, targetCategory) then
            return { ok = false, message = 'Esta peca nao pode substituir esse pneu.' }
        end

        local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
        if not status then return { ok = false, message = 'Veiculo nao registrado no sistema logistico.' } end
        if not consumePart(source, itemName) then
            return { ok = false, message = 'Voce nao tem a peca na mochila.' }
        end

        if not setSubsystemHealth(status, targetCategory, 100.0) then
            return { ok = false, message = 'Pneu invalido.' }
        end

        status.tire_type = itemName == 'truck_tire' and 'reinforced' or 'standard'
        resetRepairFatigue(status, targetCategory)
        syncStatus(plate, status)
        addScrap(source, partData, itemName)

        return { ok = true, message = ('%s instalado. Pneu restaurado para 100%%.'):format(partData.label) }
    end

    if installSlots[itemName] then
        return installUpgrade(source, plate, itemName)
    end
    return repairInstalledPart(source, plate, targetCategory)
end)
