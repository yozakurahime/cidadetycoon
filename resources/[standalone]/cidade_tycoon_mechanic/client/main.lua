local Config = require 'config'

local function notifyMechanic(message, type)
    lib.notify({
        title = 'Diagnóstico Tycoon',
        description = message,
        type = type or 'inform',
    })
    if type == 'success' then PlaySoundFrontend(-1, "PURCHASE_ACK", "HUD_LIQUIPEDIA_SOUNDSET", 1) end
end

local function hasMechanicJob()
    local playerData = exports.qbx_core:GetPlayerData()
    return playerData and playerData.job and playerData.job.name == 'mechanic'
end

local installedPartLabels = {
    engine_stock = 'Motor Original',
    transmission_stock = 'Transmissão Original',
    drivetrain_factory = 'Tração Original',
    brakes_stock = 'Freios Originais',
    suspension_stock = 'Suspensão Original',
    tire_street_basic = 'Pneus Rua Comum',
    standard_tires = 'Pneu Comum',
    truck_tire = 'Pneu Reforcado',
    alignment_standard_service = 'Alinhamento Padrao',
    no_performance_kit = 'Nenhum Kit',
}

local installCategories = {
    { key = 'engine', label = 'Motor / Performance', icon = 'gauge-high' },
    { key = 'transmission', label = 'Transmissão', icon = 'gears' },
    { key = 'drivetrain', label = 'Tração / Controle', icon = 'route' },
    { key = 'brakes', label = 'Freios', icon = 'circle-stop' },
    { key = 'suspension', label = 'Suspensão / Alinhamento', icon = 'car-burst' },
    { key = 'tires', label = 'Pneus', icon = 'circle-dot' },
    { key = 'performance_kit', label = 'Kits de Performance', icon = 'gauge' },
}

local function partLabel(itemName)
    if not itemName then return 'Original' end
    local part = exports.cidade_tycoon_core:GetPartData(itemName)
    return (part and part.label) or installedPartLabels[itemName] or itemName
end

local itemPreview = {
    -- Reparo
    engine_block = 'Reposicao: troca fisica do motor e restaura saude para 100%.',
    transmission_gear = 'Reposicao: troca fisica da transmissao e restaura saude para 100%.',
    transmission_parts = 'Reposicao: conjunto de transmissao sem bonus de tunagem.',
    brake_pads = 'Reposicao: troca fisica dos freios e restaura saude para 100%.',
    brake_street_basic = 'Tunagem: freio de rua +3% forca de frenagem. Troca restaura freios para 100%.',
    performance_brakes = 'Tunagem: freios esportivos +8% forca de frenagem. Troca restaura freios para 100%.',
    suspension_arm = 'Reposicao: troca fisica da suspensao e restaura saude para 100%.',
    suspension_kit = 'Tunagem: suspensao +3% rigidez e +0.5% tracao. Troca restaura suspensao para 100%.',
    mechanical_parts = 'Reparo: qualquer subsistema mecanico +18%.',
    basic_repair_kit = 'REPARO: restaura qualquer peca ate 50% sem troca-la. Uso geral em subsistemas.',
    advanced_repair_kit = 'TROCA: 1 kit + peca para instalar/substituir. LATARIA: restaura lataria a 100% (fora do veiculo).',
    truck_tire = 'Reposicao: pneu reforcado. Troca restaura pneu para 100%.',
    standard_tires = 'Reposicao: pneu comum. Troca restaura pneu para 100%.',
    battery = 'Eletrico: bateria de reposicao. Reparo com kit ate 50% ou troca completa para 100%.',

    -- Pneus / handling
    tire_street_basic = 'Tunagem: pneu equilibrado. Grip 1.00, chuva 0.95, off-road 0.65.',
    tire_street_sport = 'Tunagem: +4% grip seco, piora leve em chuva/off-road, desgaste +5%.',
    tire_rain_pro = 'Tunagem: +8% aderencia na chuva, desgaste -3%, grip seco quase original.',
    tire_offroad_pro = 'Tunagem: +10% off-road, desgaste -6%, grip urbano menor.',
    tire_drift_pro = 'Tunagem: drift controlado, grip seco -8%, chuva/off-road ruins.',
    tire_race_premium = 'Tunagem: +10% grip seco, alto desgaste, ruim em chuva/off-road.',
    drift_tires = 'Tunagem: drift controlado, grip seco -8%, chuva/off-road ruins.',
    racing_tires = 'Tunagem: +10% grip seco, alto desgaste, ruim em chuva/off-road.',
    drag_tires = 'Tunagem: +8% grip de arrancada, baixa chuva/off-road, desgaste +12%.',

    -- Motor / transmissao / freio / suspensao
    filter_performance = 'Tunagem: +1.5% forca inicial. Sem ganho direto de velocidade final.',
    radiator_heavy_duty = 'Tunagem: sem ganho direto de potencia. Reduz desgaste do motor.',
    ecu_sport_stage = 'Tunagem: +4.5% forca inicial e +2.5% velocidade final. Aumenta desgaste do motor.',
    turbo_street_kit = 'Tunagem: +7.5% forca inicial e +3.5% velocidade final. Exige mais manutencao.',
    turbo_kit = 'Tunagem: +8.5% forca inicial e +4% velocidade final. Exige mais manutencao.',
    supercharger_street_kit = 'Tunagem: +8.5% forca inicial e +2.5% velocidade final. Mais torque, mais desgaste.',
    clutch_performance = 'Tunagem: +6% velocidade de troca. Reduz desgaste da transmissao.',
    transmission_street_kit = 'Tunagem: +5.5% troca de marcha e +0.5% velocidade final.',
    transmission_sport_kit = 'Tunagem: +10% troca de marcha e +1.5% velocidade final.',
    transmission_race_kit = 'Tunagem: +15% troca de marcha e +2.5% velocidade final. Desgaste maior.',
    drivetrain_conversion_fwd = 'Tunagem: converte para FWD. Mais previsivel, -1% velocidade final.',
    drivetrain_conversion_rwd = 'Tunagem: converte para RWD. Mais traseiro, -2% tracao e +0.5% velocidade final.',
    drivetrain_conversion_awd = 'Tunagem: converte para AWD. +3.5% tracao, -1.5% velocidade final e mais desgaste.',
    traction_control = 'Tunagem: +4% tracao, -0.5% velocidade final e menor desgaste de pneus.',
    brake_sport_kit = 'Tunagem: +10% forca de frenagem.',
    brake_race_kit = 'Tunagem: +14% forca de frenagem, com melhor resistencia ao uso severo.',
    suspension_sport_kit = 'Tunagem: +6% forca de suspensao e +1.5% tracao.',
    alignment_standard_service = 'Tunagem: +1% suspensao e +1% tracao. Reduz desgaste dos pneus.',

    -- Kits de Performance (substituem todas as peças individuais)
    performance_kit_drag = 'KIT DRAG RACE: aceleracao +28% (INSTANTANEA), velocidade +4%, cambio ultra-rapido. TRACAO PESSIMA em curvas (-22%). So para linha reta!',
    performance_kit_drift = 'KIT DRIFT: aceleracao +10%, tracao REDUZIDA (-28%) para derrapar com controle. Suspensao macia (+12%) para angulo. So RWD.',
    performance_kit_race = 'KIT CORRIDA: aceleracao +16%, velocidade +6%, freios +16%, tracao +8%. EQUILIBRIO PROFISSIONAL para circuitos. AWD 45%.',
}

local function previewText(itemName, mode, item)
    local base = itemPreview[itemName] or 'Sem preview detalhado cadastrado.'
    if mode == 'repair' and item and item.repairValue and item.repairValue > 0 then
        return ('%s | Reparo com kit: +%.1f%%, limitado a 50%%. Cada reparo aumenta o desgaste futuro da peca.'):format(base, item.repairValue)
    elseif mode == 'replace' then
        if item and item.installSlot then
            return ('%s | Troca completa: saude 100%%, bonus aplicado e desgaste normal restaurado.'):format(base)
        end
        return ('%s | Troca completa: saude 100%% e desgaste normal restaurado.'):format(base)
    end
    return base
end

local DIAG_JACK_TILT_ANGLE = 5.0
local DIAG_JACK_MIN_LIFT = 0.18

local function getWheelAverageZ(veh, wheelNames)
    local total = 0.0
    local count = 0

    for _, wheelName in ipairs(wheelNames) do
        local bone = GetEntityBoneIndexByName(veh, wheelName)
        if bone ~= -1 then
            local pos = GetWorldPositionOfEntityBone(veh, bone)
            total = total + pos.z
            count = count + 1
        end
    end

    if count == 0 then return nil end
    return total / count
end

local function applyTemporaryJackLift(veh, initialCoords, initialRot, wheelName)
    local isLeft = string.find(wheelName, "_l") ~= nil
    local liftWheels = isLeft and { 'wheel_lf', 'wheel_lr' } or { 'wheel_rf', 'wheel_rr' }
    local anchorWheels = isLeft and { 'wheel_rf', 'wheel_rr' } or { 'wheel_lf', 'wheel_lr' }
    local liftBefore = getWheelAverageZ(veh, liftWheels)
    local anchorBefore = getWheelAverageZ(veh, anchorWheels)
    local best

    for _, tilt in ipairs({ DIAG_JACK_TILT_ANGLE, -DIAG_JACK_TILT_ANGLE }) do
        SetEntityCoords(veh, initialCoords.x, initialCoords.y, initialCoords.z, false, false, false, true)
        SetEntityRotation(veh, initialRot.x, initialRot.y + tilt, initialRot.z, 2, true)
        Wait(0)

        local anchorAfter = getWheelAverageZ(veh, anchorWheels)
        local zOffset = DIAG_JACK_MIN_LIFT

        if anchorBefore and anchorAfter then
            zOffset = anchorBefore - anchorAfter
        end

        SetEntityCoords(veh, initialCoords.x, initialCoords.y, initialCoords.z + zOffset, false, false, false, true)
        Wait(0)

        local liftAfter = getWheelAverageZ(veh, liftWheels)
        local anchorFinal = getWheelAverageZ(veh, anchorWheels)
        local liftDelta = liftBefore and liftAfter and (liftAfter - liftBefore) or 0.0
        local anchorDrift = anchorBefore and anchorFinal and math.abs(anchorFinal - anchorBefore) or 0.0
        local score = liftDelta - (anchorDrift * 2.0)

        if liftDelta >= 0.02 and (not best or score > best.score) then
            best = {
                score = score,
                z = initialCoords.z + zOffset,
                roll = initialRot.y + tilt,
            }
        end
    end

    if not best then
        local fallbackTilt = isLeft and DIAG_JACK_TILT_ANGLE or -DIAG_JACK_TILT_ANGLE
        best = {
            z = initialCoords.z + DIAG_JACK_MIN_LIFT,
            roll = initialRot.y + fallbackTilt,
        }
    end

    SetEntityCoords(veh, initialCoords.x, initialCoords.y, best.z, false, false, false, true)
    SetEntityRotation(veh, initialRot.x, best.roll, initialRot.z, 2, true)
end

-- ==========================================
-- DIAGNOSTICS & INSTALLATION MENU
-- ==========================================

local function InstallPart(veh, plate, itemName, partLabel, categoryKey, actionMode)
    local ped = PlayerPedId()
    local vehCoords = GetEntityCoords(veh)
    local pedCoords = GetEntityCoords(ped)

    local isEnginePart = (categoryKey == 'engine' or categoryKey == 'transmission' or categoryKey == 'drivetrain' or categoryKey == 'performance_kit' or categoryKey == 'all' or categoryKey == 'battery')
    local isWheelPart = (categoryKey == 'tires' or categoryKey == 'brakes' or categoryKey == 'suspension' or string.find(categoryKey, 'tire_') == 1)
    local isInstall = actionMode == 'install'
    local isReplace = actionMode == 'replace'
    local isRepair = actionMode == 'repair'
    local progressLabel = isInstall and ('Instalando ' .. partLabel) or (isReplace and ('Trocando ' .. partLabel) or ('Reparando ' .. partLabel))

    local function loadAnimDict(dict)
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end
    end

    if isEnginePart then
        local engineBone = GetEntityBoneIndexByName(veh, 'engine')
        if engineBone ~= -1 then
            local enginePos = GetWorldPositionOfEntityBone(veh, engineBone)
            if #(pedCoords - enginePos) > 2.5 then
                notifyMechanic('Aproxime-se do capô do veículo para instalar isso.', 'error')
                return
            end
        end

        TaskTurnPedToFaceEntity(ped, veh, 1000)
        Wait(1000)
        SetVehicleEngineOn(veh, false, false, true)
        SetVehicleDoorOpen(veh, 4, false, false) -- Open hood
        
        loadAnimDict("mini@repair")
        TaskPlayAnim(ped, "mini@repair", "fixing_a_ped", 8.0, -8.0, -1, 1, 0, false, false, false)

        if lib.progressBar({
            duration = 10000,
            label = progressLabel,
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true }
        }) then
            ClearPedTasks(ped)
            SetVehicleDoorShut(veh, 4, false)
            
            local res
            if isInstall then
                res = lib.callback.await('cidade_tycoon_mechanic:server:installUpgrade', false, plate, itemName)
            elseif isReplace then
                res = lib.callback.await('cidade_tycoon_mechanic:server:replaceInstalledPart', false, plate, categoryKey, itemName)
            elseif isRepair then
                res = lib.callback.await('cidade_tycoon_mechanic:server:repairInstalledPartWithItem', false, plate, categoryKey, itemName)
            else
                res = { ok = false, message = 'Use Reparar com kit ou Trocar a peca.' }
            end
            notifyMechanic(res.message, res.ok and 'success' or 'error')
        else
            ClearPedTasks(ped)
            SetVehicleDoorShut(veh, 4, false)
            notifyMechanic('Ação cancelada.', 'error')
        end

    elseif isWheelPart then
        local wheels = {'wheel_lf', 'wheel_rf', 'wheel_lr', 'wheel_rr'}
        local closestWheel = nil
        local closestDist = 1000.0
        local wheelPos = nil

        for _, w in ipairs(wheels) do
            local bone = GetEntityBoneIndexByName(veh, w)
            if bone ~= -1 then
                local pos = GetWorldPositionOfEntityBone(veh, bone)
                local dist = #(pedCoords - pos)
                if dist < closestDist then
                    closestDist = dist
                    closestWheel = w
                    wheelPos = pos
                end
            end
        end

        if closestDist > 2.0 or not wheelPos then
            notifyMechanic('Aproxime-se de uma das rodas para instalar isso.', 'error')
            return
        end

        TaskTurnPedToFaceCoord(ped, wheelPos.x, wheelPos.y, wheelPos.z, 1000)
        Wait(1000)

        -- Elevate Vehicle & Jack Prop
        local initialZ = GetEntityCoords(veh).z
        local initialRot = GetEntityRotation(veh, 2)
        SetVehicleHandbrake(veh, true)
        SetEntityVelocity(veh, 0.0, 0.0, 0.0)
        FreezeEntityPosition(veh, true)
        
        local jackHash = GetHashKey("prop_carjack")
        RequestModel(jackHash)
        while not HasModelLoaded(jackHash) do Wait(10) end
        
        -- Calculate jack position slightly offset from wheel
        local forwardVector, rightVector, upVector, position = GetEntityMatrix(veh)
        local isLeft = string.find(closestWheel, "_l") ~= nil
        local offsetDir = isLeft and -1.0 or 1.0
        local actualRight = rightVector * offsetDir
        
        local jackPos = wheelPos + (actualRight * 0.5)

        local jackProp = CreateObject(jackHash, jackPos.x, jackPos.y, jackPos.z - 0.5, true, true, false)
        SetEntityHeading(jackProp, GetEntityHeading(veh) + (isLeft and 90.0 or -90.0))
        PlaceObjectOnGroundProperly(jackProp)
        SetEntityCollision(jackProp, false, false)
        FreezeEntityPosition(jackProp, true)
        
        -- Raise the side supported by the jack and keep the opposite side anchored.
        applyTemporaryJackLift(veh, vehCoords, initialRot, closestWheel)
        SetVehicleHandbrake(veh, true)
        SetEntityVelocity(veh, 0.0, 0.0, 0.0)
        FreezeEntityPosition(veh, true)

        loadAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
        TaskPlayAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8.0, -1, 1, 0, false, false, false)

        if lib.progressBar({
            duration = 10000,
            label = progressLabel,
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true }
        }) then
            ClearPedTasks(ped)
            
            local res
            if isInstall then
                res = lib.callback.await('cidade_tycoon_mechanic:server:installUpgrade', false, plate, itemName)
            elseif isReplace then
                res = lib.callback.await('cidade_tycoon_mechanic:server:replaceInstalledPart', false, plate, categoryKey, itemName)
            elseif isRepair then
                res = lib.callback.await('cidade_tycoon_mechanic:server:repairInstalledPartWithItem', false, plate, categoryKey, itemName)
            else
                res = { ok = false, message = 'Use Reparar com kit ou Trocar a peca.' }
            end
            notifyMechanic(res.message, res.ok and 'success' or 'error')
        else
            ClearPedTasks(ped)
            notifyMechanic('Ação cancelada.', 'error')
        end

        -- Cleanup
        SetEntityRotation(veh, initialRot.x, initialRot.y, initialRot.z, 2, true)
        SetEntityCoords(veh, vehCoords.x, vehCoords.y, initialZ, false, false, false, true)
        SetVehicleHandbrake(veh, false)
        FreezeEntityPosition(veh, false)
        if DoesEntityExist(jackProp) then
            FreezeEntityPosition(jackProp, false)
            DeleteEntity(jackProp)
        end
        SetModelAsNoLongerNeeded(jackHash)
    end
end

local function OpenPartSelectionMenu(veh, plate, categoryKey, categoryLabel, mode)
    -- Fetch available items in mechanic's inventory for this category
    -- For individual tires, we map them back to the general 'tires' category for inventory lookup
    local lookupCategory = categoryKey
    if string.find(categoryKey, 'tire_') then lookupCategory = 'tires' end

    local availableItems = lib.callback.await('cidade_tycoon_mechanic:server:getAvailableParts', false, lookupCategory, mode)

    if not availableItems or #availableItems == 0 then
        notifyMechanic('Você não possui peças aplicáveis na mochila para: ' .. categoryLabel, 'error')
        return
    end

    local options = {}
    for _, item in ipairs(availableItems) do
        local titlePrefix = mode == 'install' and 'Instalar: ' or (mode == 'replace' and 'Trocar por: ' or 'Reparar com: ')
        local description = mode == 'install'
            and ('Você tem %d na mochila. Altera o funcionamento do veículo.'):format(item.count)
            or ('Você tem %d na mochila. Recupera +%.1f%% da peça instalada.'):format(item.count, item.repairValue)

        description = ('Voce tem %d na mochila. %s'):format(item.count, previewText(item.name, mode, item))

        table.insert(options, {
            title = titlePrefix .. item.label,
            description = description,
            image = "nui://ox_inventory/web/images/" .. item.name .. ".png",
            icon = 'wrench',
            onSelect = function()
                InstallPart(veh, plate, item.name, item.label, categoryKey, mode)
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_mechanic_part_select',
        title = mode == 'install' and 'Instalar / Modificar' or (mode == 'replace' and 'Trocar Peca' or 'Reparar Peca Instalada'),
        menu = 'tycoon_mechanic_diagnosis',
        options = options
    })
    lib.showContext('tycoon_mechanic_part_select')
end

local function RepairInstalledPart(veh, plate, subsystem)
    local ped = PlayerPedId()
    local categoryKey = subsystem.key
    local pedCoords = GetEntityCoords(ped)

    local isWheelPart = (categoryKey == 'tires' or categoryKey == 'brakes' or categoryKey == 'suspension' or string.find(categoryKey, 'tire_') == 1)

    local function loadAnimDict(dict)
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end
    end

    if isWheelPart then
        local wheels = {'wheel_lf', 'wheel_rf', 'wheel_lr', 'wheel_rr'}
        local closestDist = 1000.0
        local wheelPos = nil

        for _, w in ipairs(wheels) do
            local bone = GetEntityBoneIndexByName(veh, w)
            if bone ~= -1 then
                local pos = GetWorldPositionOfEntityBone(veh, bone)
                local dist = #(pedCoords - pos)
                if dist < closestDist then
                    closestDist = dist
                    wheelPos = pos
                end
            end
        end

        if closestDist > 2.0 or not wheelPos then
            notifyMechanic('Aproxime-se de uma das rodas para reparar isso.', 'error')
            return
        end

        TaskTurnPedToFaceCoord(ped, wheelPos.x, wheelPos.y, wheelPos.z, 1000)
        Wait(1000)
        loadAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
        TaskPlayAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8.0, -1, 1, 0, false, false, false)
    else
        local engineBone = GetEntityBoneIndexByName(veh, 'engine')
        if engineBone ~= -1 then
            local enginePos = GetWorldPositionOfEntityBone(veh, engineBone)
            if #(pedCoords - enginePos) > 2.5 then
                notifyMechanic('Aproxime-se do capo do veiculo para reparar isso.', 'error')
                return
            end
        end

        TaskTurnPedToFaceEntity(ped, veh, 1000)
        Wait(1000)
        SetVehicleEngineOn(veh, false, false, true)
        SetVehicleDoorOpen(veh, 4, false, false)
        loadAnimDict("mini@repair")
        TaskPlayAnim(ped, "mini@repair", "fixing_a_ped", 8.0, -8.0, -1, 1, 0, false, false, false)
    end

    if lib.progressBar({
        duration = 8000,
        label = 'Reparando ' .. subsystem.label,
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true }
    }) then
        ClearPedTasks(ped)
        SetVehicleDoorShut(veh, 4, false)
        local res = lib.callback.await('cidade_tycoon_mechanic:server:repairInstalledPart', false, plate, subsystem.key)
        notifyMechanic(res.message, res.ok and 'success' or 'error')
    else
        ClearPedTasks(ped)
        SetVehicleDoorShut(veh, 4, false)
        notifyMechanic('Reparo cancelado.', 'error')
    end
end

local function OpenRepairActionMenu(veh, plate, subsystem)
    local options = {
        {
            title = 'Reparar com kit',
            description = 'Usa kit/material da mochila. Recupera somente ate 50% e aumenta o desgaste futuro da peca.',
            icon = 'toolbox',
            onSelect = function()
                OpenPartSelectionMenu(veh, plate, subsystem.key, subsystem.label, 'repair')
            end
        },
        {
            title = 'Trocar a peca',
            description = 'Substitui por uma peca nova. Saude volta para 100%, bonus aplicado e desgaste normal restaurado.',
            icon = 'rotate-cw',
            onSelect = function()
                OpenPartSelectionMenu(veh, plate, subsystem.key, subsystem.label, 'replace')
            end
        }
    }

    lib.registerContext({
        id = 'tycoon_mechanic_repair_action',
        title = subsystem.label,
        menu = 'tycoon_mechanic_repair_installed',
        options = options
    })
    lib.showContext('tycoon_mechanic_repair_action')
end

local function OpenInstallMenu(veh, plate)
    local options = {}
    local isElectric = exports.cidade_tycoon_core:IsVehicleElectric(GetEntityModel(veh))

    for _, category in ipairs(installCategories) do
        local showCategory = true
        if isElectric and (category.key == 'engine' or category.key == 'transmission') then
            showCategory = false
        end

        if showCategory then
            table.insert(options, {
                title = category.label,
                description = 'Instalar peças novas que modificam o funcionamento.',
                icon = category.icon,
                onSelect = function()
                    OpenPartSelectionMenu(veh, plate, category.key, category.label, 'install')
                end
            })
        end
    end

    if isElectric then
        table.insert(options, {
            title = 'Bateria',
            description = 'Instalar ou substituir a Bateria Elétrica.',
            icon = 'bolt',
            onSelect = function()
                OpenPartSelectionMenu(veh, plate, 'battery', 'Bateria', 'install')
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_mechanic_install',
        title = 'Instalar / Modificar',
        menu = 'tycoon_mechanic_diagnosis',
        options = options
    })
    lib.showContext('tycoon_mechanic_install')
end

local function OpenInstalledRepairMenu(veh, plate, subsystems)
    local options = {}

    for _, sub in ipairs(subsystems) do
        table.insert(options, {
            title = sub.label .. (' - Saúde: %d%%'):format(math.floor(sub.health)),
            description = 'Kit recupera ate 50% e acelera desgaste; troca restaura 100% e desgaste normal.',
            icon = sub.icon,
            onSelect = function()
                OpenRepairActionMenu(veh, plate, sub)
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_mechanic_repair_installed',
        title = 'Reparar Peças Instaladas',
        menu = 'tycoon_mechanic_diagnosis',
        options = options
    })
    lib.showContext('tycoon_mechanic_repair_installed')
end

local function ApplyBodyworkRepair(veh)
    local engineHealth = GetVehicleEngineHealth(veh)
    local tankHealth = GetVehiclePetrolTankHealth(veh)
    local fuelLevel = GetVehicleFuelLevel(veh)
    local dirtLevel = GetVehicleDirtLevel(veh)
    local burstTires = {}

    for tireIndex = 0, 7 do
        burstTires[tireIndex] = IsVehicleTyreBurst(veh, tireIndex, false) or IsVehicleTyreBurst(veh, tireIndex, true)
    end

    SetVehicleFixed(veh)
    SetVehicleDeformationFixed(veh)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehicleDirtLevel(veh, 0.0)

    for doorIndex = 0, 7 do
        SetVehicleDoorShut(veh, doorIndex, false)
    end

    for windowIndex = 0, 7 do
        FixVehicleWindow(veh, windowIndex)
    end

    for tireIndex, wasBurst in pairs(burstTires) do
        if wasBurst then
            SetVehicleTyreBurst(veh, tireIndex, true, 1000.0)
        end
    end

    SetVehicleEngineHealth(veh, engineHealth)
    SetVehiclePetrolTankHealth(veh, tankHealth)
    SetVehicleFuelLevel(veh, fuelLevel)
    if dirtLevel > 0.0 then SetVehicleDirtLevel(veh, 0.0) end
end

local function RepairBodywork(veh, plate)
    local ped = PlayerPedId()

    local function loadAnimDict(dict)
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end
    end

    TaskTurnPedToFaceEntity(ped, veh, 1000)
    Wait(1000)
    loadAnimDict("mini@repair")
    TaskPlayAnim(ped, "mini@repair", "fixing_a_ped", 8.0, -8.0, -1, 1, 0, false, false, false)

    if lib.progressBar({
        duration = 12000,
        label = 'Reparando lataria...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true }
    }) then
        ClearPedTasks(ped)
        local res = lib.callback.await('cidade_tycoon_mechanic:server:repairBody', false, plate)
        if res.ok then
            ApplyBodyworkRepair(veh)
        end
        notifyMechanic(res.message, res.ok and 'success' or 'error')
    else
        ClearPedTasks(ped)
        notifyMechanic('Reparo de lataria cancelado.', 'error')
    end
end

local function OpenDiagnosisMenu(veh)
    local plate = GetVehicleNumberPlateText(veh)
    if not plate then return end

    local status = lib.callback.await('cidade_tycoon_maintenance:server:getVehicleStatus', false, plate)
    if not status then 
        notifyMechanic('Veículo não registrado no sistema logístico.', 'error')
        return 
    end

    local isElectric = exports.cidade_tycoon_core:IsVehicleElectric(GetEntityModel(veh))
    local installedPartsDesc
    if isElectric then
        installedPartsDesc = ('Bateria: %s | Tração: %s | Freios: %s | Suspensão: %s | Alinhamento: %s | Pneus: %s | Kit: %s'):format(
            partLabel(status.installed_engine or 'battery'),
            partLabel(status.installed_drivetrain or 'drivetrain_factory'),
            partLabel(status.installed_brakes),
            partLabel(status.installed_suspension),
            partLabel(status.installed_alignment or 'alignment_standard_service'),
            partLabel(status.installed_tires),
            partLabel(status.installed_performance_kit or 'no_performance_kit')
        )
    else
        installedPartsDesc = ('Motor: %s | Transmissão: %s | Tração: %s | Freios: %s | Suspensão: %s | Alinhamento: %s | Pneus: %s | Kit: %s'):format(
            partLabel(status.installed_engine),
            partLabel(status.installed_transmission),
            partLabel(status.installed_drivetrain or 'drivetrain_factory'),
            partLabel(status.installed_brakes),
            partLabel(status.installed_suspension),
            partLabel(status.installed_alignment or 'alignment_standard_service'),
            partLabel(status.installed_tires),
            partLabel(status.installed_performance_kit or 'no_performance_kit')
        )
    end

    local options = {
        {
            title = ('Hodômetro: %.1f km'):format(status.mileage),
            description = 'Quilometragem total do veículo.',
            icon = 'road',
            readOnly = true
        },
        {
            title = 'Instalar / Modificar Peças',
            description = 'Peças novas que alteram desempenho, tração, freio, suspensão ou pneus.',
            icon = 'screwdriver-wrench',
            disabled = not hasMechanicJob(),
            onSelect = function()
                OpenInstallMenu(veh, plate)
            end
        },
        {
            title = 'Reparar Peças Instaladas',
            description = 'Reparar com kit ate 50% ou trocar a peca para voltar 100%.',
            icon = 'wrench',
            disabled = not hasMechanicJob(),
            onSelect = function()
                OpenInstalledRepairMenu(veh, plate, status.subsystems)
            end
        },
        {
            title = 'Reparar Lataria',
            description = 'Repara deformação, sujeira e body health com Kit de Reparo Básico.',
            icon = 'spray-can-sparkles',
            disabled = not hasMechanicJob(),
            onSelect = function()
                RepairBodywork(veh, plate)
            end
        },
        {
            title = 'Peças instaladas',
            description = installedPartsDesc,
            icon = 'clipboard-check',
            readOnly = true
        }
    }

    local healthColors = {
        { limit = 25, color = 'red' },
        { limit = 50, color = 'orange' },
        { limit = 75, color = 'yellow' },
        { limit = 100, color = 'green' }
    }

    local function getHealthColor(h)
        for _, c in ipairs(healthColors) do
            if h <= c.limit then return c.color end
        end
        return 'green'
    end

    local function getHealthState(h)
        if h <= 15 then return 'Falha iminente' end
        if h <= 40 then return 'Critico' end
        if h <= 70 then return 'Atencao' end
        return 'Saudavel'
    end
    
    for _, sub in ipairs(status.subsystems) do
        local hColor = getHealthColor(sub.health)
        local kmText = sub.kmRemaining and ('~' .. sub.kmRemaining .. ' km restantes') or 'Sem estimativa de km'
        local fatigueText = ''
        if sub.repairFatigue and sub.repairFatigue > 0 then
            fatigueText = (' | Desgaste +%d%%'):format(math.floor(sub.repairFatigue * 100))
        end
        
        table.insert(options, {
            title = sub.label .. (' - Saude: %d%%'):format(math.floor(sub.health)),
            description = getHealthState(sub.health) .. ' | ' .. kmText .. fatigueText,
            icon = sub.icon,
            iconColor = hColor,
            readOnly = true
        })
    end

    lib.registerContext({
        id = 'tycoon_mechanic_diagnosis',
        title = 'Diagnóstico: ' .. plate,
        options = options
    })
    lib.showContext('tycoon_mechanic_diagnosis')
end

RegisterNetEvent('cidade_tycoon_mechanic:client:openVehicleMenuFromItem', function()
    local veh = lib.getClosestVehicle(GetEntityCoords(PlayerPedId()), 5.0)
    if not veh then
        notifyMechanic('Nenhum veículo próximo.', 'error')
        return
    end
    OpenDiagnosisMenu(veh)
end)

-- ==========================================
-- DYNAMIC WORKSHOP MANAGEMENT & BLIPS
-- ==========================================

local spawnedNPCs = {}
local spawnedBlips = {}
local spawnedWarehouses = {}

local function cleanupShops()
    for _, npc in ipairs(spawnedNPCs) do
        if DoesEntityExist(npc) then DeleteEntity(npc) end
    end
    spawnedNPCs = {}

    for _, blip in ipairs(spawnedBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    spawnedBlips = {}

    for _, zoneId in pairs(spawnedWarehouses) do
        exports.ox_target:removeZone(zoneId)
    end
    spawnedWarehouses = {}
end

local isPositioning = false

local function startPositioningSpot(shopId, spotType, index, label)
    if isPositioning then
        lib.notify({
            title = 'Gerenciamento',
            description = 'Você já está posicionando um ponto!',
            type = 'error'
        })
        return
    end

    isPositioning = true
    lib.hideContext() -- Close the menu

    lib.showTextUI(('[E] Confirmar Ponto (%s) | [BACKSPACE] Cancelar'):format(label), {
        position = "right-center",
        icon = "location-crosshairs",
        style = {
            backgroundColor = '#1C1C1E',
            color = '#FFFFFF'
        }
    })

    CreateThread(function()
        while isPositioning do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            -- Premium semi-transparent green marker under player's feet to show the exact point center
            DrawMarker(1, coords.x, coords.y, coords.z - 0.98, 
                0.0, 0.0, 0.0, 
                0.0, 0.0, 0.0, 
                1.5, 1.5, 0.5, 
                0, 255, 0, 120, 
                false, false, 2, false, nil, nil, false
            )

            -- Confirm (E)
            if IsControlJustPressed(0, 38) then
                isPositioning = false
                lib.hideTextUI()
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)

                local heading = GetEntityHeading(ped)
                local coordsVec = vec4(coords.x, coords.y, coords.z, heading)

                local res = lib.callback.await('cidade_tycoon_mechanic:server:updateShopSpot', false, shopId, spotType, index, coordsVec)
                if res and res.ok then
                    lib.notify({
                        title = 'Gerenciamento',
                        description = res.message or 'Ponto de oficina atualizado!',
                        type = 'success'
                    })
                else
                    lib.notify({
                        title = 'Gerenciamento',
                        description = (res and res.message) or 'Falha ao atualizar ponto.',
                        type = 'error'
                    })
                end
                break
            end

            -- Cancel (BACKSPACE)
            if IsControlJustPressed(0, 177) then
                isPositioning = false
                lib.hideTextUI()
                PlaySoundFrontend(-1, "CANCEL", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                lib.notify({
                    title = 'Gerenciamento',
                    description = 'Ação de posicionamento cancelada.',
                    type = 'inform'
                })
                break
            end

            Wait(0)
        end
    end)
end

function OpenManagementMenu(shopId)
    local playerData = exports.qbx_core:GetPlayerData()
    local isBoss = playerData and playerData.job and playerData.job.name == 'mechanic' and playerData.job.isboss

    local options = {}

    if isBoss then
        table.insert(options, {
            title = 'Definir Ponto de Customização 1',
            description = 'Posicionar local de customização 1.',
            icon = 'location-dot',
            onSelect = function()
                startPositioningSpot(shopId, 'custom', 1, 'Customização 1')
            end
        })
        table.insert(options, {
            title = 'Definir Ponto de Customização 2',
            description = 'Posicionar local de customização 2.',
            icon = 'location-dot',
            onSelect = function()
                startPositioningSpot(shopId, 'custom', 2, 'Customização 2')
            end
        })
        table.insert(options, {
            title = 'Definir Ponto de Customização 3',
            description = 'Posicionar local de customização 3.',
            icon = 'location-dot',
            onSelect = function()
                startPositioningSpot(shopId, 'custom', 3, 'Customização 3')
            end
        })
        table.insert(options, {
            title = 'Definir Ponto do Almoxarifado',
            description = 'Posicionar ponto de estoque (Almoxarifado).',
            icon = 'boxes-stacked',
            onSelect = function()
                startPositioningSpot(shopId, 'warehouse', nil, 'Almoxarifado')
            end
        })
        table.insert(options, {
            title = 'Definir Ponto do NPC Gerente',
            description = 'Posicionar nova base do NPC Gerente.',
            icon = 'user-tie',
            onSelect = function()
                startPositioningSpot(shopId, 'npc', nil, 'NPC Gerente')
            end
        })
    else
        table.insert(options, {
            title = 'Gerenciar Oficina',
            description = 'Apenas o dono/líder da oficina pode gerenciar estes pontos.',
            icon = 'ban',
            readOnly = true
        })
    end

    lib.registerContext({
        id = 'tycoon_mechanic_management_' .. shopId,
        title = 'Gerenciamento: ' .. shopId,
        options = options
    })
    lib.showContext('tycoon_mechanic_management_' .. shopId)
end

local function refreshShops()
    cleanupShops()

    local npcList = GlobalState['tycoon:mechanic_npcs'] or {}
    local warehouseList = GlobalState['tycoon:warehouse_spots'] or {}

    -- Spawn Boss NPCs and Blips
    for _, npcData in ipairs(npcList) do
        -- Blip
        local blip = AddBlipForCoord(npcData.coords.x, npcData.coords.y, npcData.coords.z)
        SetBlipSprite(blip, 446) -- Mechanic/Wrench
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 5) -- Yellow
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Oficina Tycoon: " .. npcData.label)
        EndTextCommandSetBlipName(blip)
        table.insert(spawnedBlips, blip)

        -- NPC Entity
        local modelHash = GetHashKey(npcData.coords.model or 's_m_y_xmech_01')
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do Wait(10) end

        local npc = CreatePed(4, modelHash, npcData.coords.x, npcData.coords.y, npcData.coords.z - 1.0, npcData.coords.h or 0.0, false, false)
        FreezeEntityPosition(npc, true)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        TaskStartScenarioInPlace(npc, "WORLD_HUMAN_CLIPBOARD", 0, true)

        exports.ox_target:addLocalEntity(npc, {
            {
                name = 'tycoon_mechanic_manager_' .. npcData.shopId,
                icon = 'fa-solid fa-user-gear',
                label = 'Gerenciar Oficina (' .. npcData.label .. ')',
                onSelect = function()
                    OpenManagementMenu(npcData.shopId)
                end,
                distance = 2.5
            }
        })

        table.insert(spawnedNPCs, npc)
        SetModelAsNoLongerNeeded(modelHash)
    end

    -- Spawn Warehouse (Almoxarifado) Spheres
    for _, whData in ipairs(warehouseList) do
        local zoneId = exports.ox_target:addSphereZone({
            coords = vec3(whData.coords.x, whData.coords.y, whData.coords.z),
            radius = 1.5,
            debug = false,
            options = {
                {
                    name = 'tycoon_mechanic_warehouse_' .. whData.shopId,
                    icon = 'fa-solid fa-boxes-stacked',
                    label = 'Almoxarifado (Mecânicos)',
                    onSelect = function()
                        OpenWholesaleMain()
                    end,
                    distance = 2.0
                }
            }
        })
        table.insert(spawnedWarehouses, zoneId)
    end
end

-- Monitor Global State for Dynamic Updates
AddStateBagChangeHandler('tycoon:mechanic_npcs', 'global', function(bagName, key, value, _reserved, replicated)
    refreshShops()
end)

AddStateBagChangeHandler('tycoon:warehouse_spots', 'global', function(bagName, key, value, _reserved, replicated)
    refreshShops()
end)

-- Initialize dynamic shops and register target interactions
CreateThread(function()
    -- Wait until player is fully logged in and data is initialized
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end

    -- Wait for the server to populate GlobalStates and replicate them
    local retries = 0
    while GlobalState['tycoon:mechanic_npcs'] == nil and retries < 50 do
        Wait(200)
        retries = retries + 1
    end

    refreshShops()

    exports.ox_target:addGlobalVehicle({
        {
            name = 'tycoon_mechanic_diag',
            icon = 'fa-solid fa-clipboard-list',
            label = 'Diagnóstico Tycoon',
            distance = 2.5,
            canInteract = function(entity, distance, coords, name, bone)
                return true -- Anyone can diagnose
            end,
            onSelect = function(data)
                OpenDiagnosisMenu(data.entity)
            end
        },
        {
            name = 'tycoon_mechanic_wrench',
            icon = 'fa-solid fa-wrench',
            label = 'Reparar com Chave',
            distance = 2.5,
            canInteract = function(entity, distance, coords, name, bone)
                return GetSelectedPedWeapon(PlayerPedId()) == GetHashKey("WEAPON_WRENCH")
            end,
            onSelect = function(data)
                TriggerEvent('cidade_tycoon_mechanic:client:useWrenchTarget', data.entity, data.coords)
            end
        }
    })
end)

-- ==========================================
-- WHOLESALE SUPPLIER NPC (ALMOXARIFADO)
-- ==========================================

local function PurchaseWholesale(itemName, partLabel)
    local input = lib.inputDialog('Comprar ' .. partLabel, {
        {
            type = 'number',
            label = 'Quantidade',
            description = 'Compra em atacado para a oficina.',
            icon = 'hashtag',
            default = 1,
            min = 1,
            max = 50
        }
    })

    if not input then return end
    local amount = input[1]

    local res = lib.callback.await('cidade_tycoon_mechanic:server:purchaseWholesale', false, itemName, amount)
    notifyMechanic(res.message, res.ok and 'success' or 'error')
end

local function OpenWholesaleCategory(category)
    local options = {}

    for _, itemName in ipairs(category.items) do
        local part = exports.cidade_tycoon_core:GetPartData(itemName)
        if part then
            local discountedPrice = math.floor(part.price * Config.WholesaleDiscount)
            table.insert(options, {
                title = part.label,
                description = ('Preço Atacado: $%d (Normal: $%d)'):format(discountedPrice, part.price),
                image = "nui://ox_inventory/web/images/" .. itemName .. ".png",
                icon = 'box',
                onSelect = function()
                    PurchaseWholesale(itemName, part.label)
                end
            })
        end
    end

    lib.registerContext({
        id = 'tycoon_wholesale_category_' .. category.id,
        title = category.title,
        menu = 'tycoon_wholesale_main',
        options = options
    })
    lib.showContext('tycoon_wholesale_category_' .. category.id)
end

function OpenWholesaleMain()
    if not hasMechanicJob() then
        notifyMechanic('Você não tem crachá para acessar o almoxarifado.', 'error')
        return
    end

    local options = {}

    for _, cat in ipairs(Config.WholesaleCategories) do
        table.insert(options, {
            title = cat.title,
            icon = cat.icon,
            onSelect = function()
                OpenWholesaleCategory(cat)
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_wholesale_main',
        title = 'Almoxarifado Mecânico',
        options = options
    })
    lib.showContext('tycoon_wholesale_main')
end

local wholesaleCart = {}
local OpenWholesaleCategoryV2

local function GetWholesaleCartTotals()
    local totalItems = 0
    local totalPrice = 0

    for _, entry in pairs(wholesaleCart) do
        totalItems = totalItems + entry.amount
        totalPrice = totalPrice + (entry.unitPrice * entry.amount)
    end

    return totalItems, totalPrice
end

local function GetWholesaleOrder()
    local order = {}
    for itemName, entry in pairs(wholesaleCart) do
        order[#order + 1] = {
            name = itemName,
            amount = entry.amount
        }
    end
    return order
end

local function OpenWholesaleCart()
    local totalItems, totalPrice = GetWholesaleCartTotals()
    local options = {}

    if totalItems <= 0 then
        options[#options + 1] = {
            title = 'Carrinho vazio',
            description = 'Adicione itens em qualquer categoria do almoxarifado.',
            icon = 'shopping-cart',
            readOnly = true
        }
    else
        options[#options + 1] = {
            title = ('Finalizar compra - %d itens'):format(totalItems),
            description = ('$%d total no banco'):format(totalPrice),
            icon = 'credit-card',
            onSelect = function()
                local res = lib.callback.await('cidade_tycoon_mechanic:server:purchaseWholesaleCart', false, GetWholesaleOrder())
                notifyMechanic(res.message, res.ok and 'success' or 'error')
                if res.ok then
                    wholesaleCart = {}
                    Wait(100)
                    OpenWholesaleMain()
                else
                    Wait(100)
                    OpenWholesaleCart()
                end
            end
        }

        options[#options + 1] = {
            title = 'Limpar carrinho',
            description = 'Remove todos os itens selecionados.',
            icon = 'trash',
            onSelect = function()
                wholesaleCart = {}
                OpenWholesaleMain()
            end
        }

        for itemName, entry in pairs(wholesaleCart) do
            options[#options + 1] = {
                title = ('%s x%d'):format(entry.label, entry.amount),
                description = ('$%d cada | $%d subtotal'):format(entry.unitPrice, entry.unitPrice * entry.amount),
                image = "nui://ox_inventory/web/images/" .. itemName .. ".png",
                icon = 'box',
                onSelect = function()
                    wholesaleCart[itemName] = nil
                    OpenWholesaleCart()
                end
            }
        end
    end

    lib.registerContext({
        id = 'tycoon_wholesale_cart',
        title = 'Carrinho do Almoxarifado',
        menu = 'tycoon_wholesale_main',
        options = options
    })
    lib.showContext('tycoon_wholesale_cart')
end

local function AddWholesaleToCart(itemName, partLabel, unitPrice, category)
    local input = lib.inputDialog('Adicionar ' .. partLabel, {
        {
            type = 'number',
            label = 'Quantidade',
            description = 'Quantidade para adicionar ao carrinho.',
            icon = 'hashtag',
            default = 1,
            min = 1,
            max = 100
        }
    })

    if not input then return end
    local amount = math.floor(tonumber(input[1]) or 0)
    if amount <= 0 then return end

    local current = wholesaleCart[itemName]
    wholesaleCart[itemName] = {
        label = partLabel,
        unitPrice = unitPrice,
        amount = (current and current.amount or 0) + amount
    }

    notifyMechanic(('Adicionado: %d x %s'):format(amount, partLabel), 'success')
    Wait(100)
    if category and OpenWholesaleCategoryV2 then
        OpenWholesaleCategoryV2(category)
    else
        OpenWholesaleCart()
    end
end

local function PurchaseWholesaleNow(itemName, partLabel, category)
    local input = lib.inputDialog('Comprar ' .. partLabel, {
        {
            type = 'number',
            label = 'Quantidade',
            description = 'Compra imediata em atacado.',
            icon = 'hashtag',
            default = 1,
            min = 1,
            max = 50
        }
    })

    if not input then return end
    local amount = input[1]

    local res = lib.callback.await('cidade_tycoon_mechanic:server:purchaseWholesale', false, itemName, amount)
    notifyMechanic(res.message, res.ok and 'success' or 'error')
    Wait(100)
    if category and OpenWholesaleCategoryV2 then
        OpenWholesaleCategoryV2(category)
    end
end

local function OpenWholesaleItemActions(category, itemName, part, discountedPrice)
    local inCart = wholesaleCart[itemName] and wholesaleCart[itemName].amount or 0
    local options = {
        {
            title = 'Adicionar ao carrinho',
            description = inCart > 0 and ('Ja no carrinho: ' .. inCart) or 'Escolha a quantidade e continue comprando.',
            icon = 'shopping-cart',
            onSelect = function()
                AddWholesaleToCart(itemName, part.label, discountedPrice, category)
            end
        },
        {
            title = 'Comprar agora',
            description = 'Compra apenas este item e volta para a categoria.',
            icon = 'credit-card',
            onSelect = function()
                PurchaseWholesaleNow(itemName, part.label, category)
            end
        }
    }

    lib.registerContext({
        id = 'tycoon_wholesale_item_' .. itemName,
        title = part.label,
        menu = 'tycoon_wholesale_category_v2_' .. category.id,
        options = options
    })
    lib.showContext('tycoon_wholesale_item_' .. itemName)
end

OpenWholesaleCategoryV2 = function(category)
    local totalItems, totalPrice = GetWholesaleCartTotals()
    local options = {
        {
            title = ('Carrinho: %d itens'):format(totalItems),
            description = ('$%d total selecionado'):format(totalPrice),
            icon = 'shopping-cart',
            onSelect = OpenWholesaleCart
        }
    }

    for _, itemName in ipairs(category.items) do
        local part = exports.cidade_tycoon_core:GetPartData(itemName)
        if part then
            local discountedPrice = math.floor(part.price * Config.WholesaleDiscount)
            local inCart = wholesaleCart[itemName] and wholesaleCart[itemName].amount or 0
            local cartText = inCart > 0 and (' | Carrinho: ' .. inCart) or ''
            options[#options + 1] = {
                title = part.label,
                description = ('Atacado: $%d | Normal: $%d%s'):format(discountedPrice, part.price, cartText),
                image = "nui://ox_inventory/web/images/" .. itemName .. ".png",
                icon = 'box',
                onSelect = function()
                    OpenWholesaleItemActions(category, itemName, part, discountedPrice)
                end
            }
        end
    end

    lib.registerContext({
        id = 'tycoon_wholesale_category_v2_' .. category.id,
        title = category.title,
        menu = 'tycoon_wholesale_main',
        options = options
    })
    lib.showContext('tycoon_wholesale_category_v2_' .. category.id)
end

function OpenWholesaleMain()
    if not hasMechanicJob() then
        notifyMechanic('Voce nao tem cracha para acessar o almoxarifado.', 'error')
        return
    end

    local totalItems, totalPrice = GetWholesaleCartTotals()
    local options = {
        {
            title = ('Carrinho: %d itens'):format(totalItems),
            description = ('$%d total selecionado'):format(totalPrice),
            icon = 'shopping-cart',
            onSelect = OpenWholesaleCart
        }
    }

    for _, cat in ipairs(Config.WholesaleCategories) do
        options[#options + 1] = {
            title = cat.title,
            icon = cat.icon,
            onSelect = function()
                OpenWholesaleCategoryV2(cat)
            end
        }
    end

    lib.registerContext({
        id = 'tycoon_wholesale_main',
        title = 'Almoxarifado Mecanico',
        options = options
    })
    lib.showContext('tycoon_wholesale_main')
end

-- Thread to draw subtle markers for mechanics when they are near their shop
CreateThread(function()
    while true do
        local wait = 1000
        
        if hasMechanicJob() then
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)
            
            local npcList = GlobalState['tycoon:mechanic_npcs'] or {}
            local customSpots = GlobalState['tycoon:customs_spots'] or {}
            local warehouseList = GlobalState['tycoon:warehouse_spots'] or {}
            
            local nearShop = false
            
            -- Check if player is near any mechanic shop NPC to enable drawing
            for _, npcData in ipairs(npcList) do
                local dist = #(pCoords - vec3(npcData.coords.x, npcData.coords.y, npcData.coords.z))
                if dist < 40.0 then
                    nearShop = true
                    break
                end
            end
            
            if nearShop then
                wait = 0 -- Run every frame to draw markers smoothly
                
                -- Draw customization spots (subtle yellow/gold circle)
                for _, coords in ipairs(customSpots) do
                    local dist = #(pCoords - vec3(coords.x, coords.y, coords.z))
                    if dist < 25.0 then
                        DrawMarker(1, coords.x, coords.y, coords.z - 0.98,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            2.0, 2.0, 0.05, -- Diameter 2.0m, thickness 0.05m
                            255, 191, 0, 50, -- Yellow/Gold with low opacity (50)
                            false, false, 2, false, nil, nil, false
                        )
                    end
                end
                
                -- Draw warehouse spots (subtle cyan circle)
                for _, whData in ipairs(warehouseList) do
                    local dist = #(pCoords - vec3(whData.coords.x, whData.coords.y, whData.coords.z))
                    if dist < 25.0 then
                        DrawMarker(1, whData.coords.x, whData.coords.y, whData.coords.z - 0.98,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            1.5, 1.5, 0.05, -- Diameter 1.5m, thickness 0.05m
                            0, 191, 255, 50, -- Cyan with low opacity (50)
                            false, false, 2, false, nil, nil, false
                        )
                    end
                end
            end
        end
        
        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    cleanupShops()
end)
