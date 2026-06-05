local maintenanceConfig = require 'config.maintenance'

local maintenancePeds = {}
local wearTracking = {
    activePlate = nil,
    sample = nil,
    lastFlushAt = 0,
}
local activeMechanicalEffects = {
    entity = nil,
    plate = nil,
    summary = nil,
    baseHandling = nil,
    lastRefreshAt = 0,
    lastWarningBand = nil,
    nextEngineCutAt = 0,
    nextCriticalPulseAt = 0,
}

local function notifyMaintenance(message, type)
    lib.notify({
        title = 'Central de Manutencao',
        description = message,
        type = type or 'inform',
    })
end

local function normalizePlate(plate)
    return tostring(plate or ''):gsub('%s+', ''):upper()
end

local function fmtMoney(amount)
    return ('$%s'):format(lib.math.groupdigits(math.floor((tonumber(amount) or 0) + 0.5)))
end

local function createMaintenancePed(definition)
    local model = joaat(definition.pedModel or 's_m_m_autoshop_02')
    lib.requestModel(model, 10000)

    local ped = CreatePed(0, model, definition.coords.x, definition.coords.y, definition.coords.z - 1.0, definition.coords.w or 0.0, false, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    if definition.scenario then
        TaskStartScenarioInPlace(ped, definition.scenario, 0, true)
    end

    SetModelAsNoLongerNeeded(model)
    return ped
end

local function openPartsShop(shopType)
    local shopDefinition = maintenanceConfig.shopTypes[shopType]
    if not shopDefinition or not shopDefinition.shopId then
        notifyMaintenance('Loja ainda nao configurada.', 'error')
        return
    end

    exports.ox_inventory:openInventory('shop', { type = shopDefinition.shopId })
end

local function getClosestVehicleWithinRadius(radius)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestVehicle = 0
    local closestDistance = radius + 0.01

    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle ~= 0 then
            return vehicle
        end
    end

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(vehicle) then
            local distance = #(GetEntityCoords(vehicle) - playerCoords)
            if distance < closestDistance then
                closestVehicle = vehicle
                closestDistance = distance
            end
        end
    end

    return closestVehicle
end

local function getInstallDifficulty(option)
    if option.tier >= 3 then
        return { 'medium', 'medium', 'hard' }
    elseif option.tier >= 2 then
        return { 'easy', 'medium', 'medium' }
    end

    return { 'easy', 'easy' }
end

local function getProgressLabel(mode, option)
    if mode == 'mechanic' then
        return ('A oficina esta instalando %s'):format(option.label)
    end

    return ('Instalando %s por conta propria'):format(option.label)
end

local function beginInstallFlow(workshopKey, plate, option, mode)
    local beginResponse = lib.callback.await(
        'cidade_tycoon_maintenance:server:beginWorkshopInstall',
        false,
        workshopKey,
        plate,
        option.partKey,
        mode
    )

    if not beginResponse or not beginResponse.ok then
        notifyMaintenance((beginResponse and beginResponse.message) or 'Nao foi possivel iniciar a instalacao.', 'error')
        return
    end

    local quality = 'good'
    if mode == 'mechanic' then
        quality = 'premium'
    else
        local success = lib.skillCheck(getInstallDifficulty(option), { 'w', 'a', 's', 'd' })
        quality = success and 'good' or 'poor'
        if not success then
            notifyMaintenance('A instalacao ficou abaixo do ideal, mas ainda pode funcionar.', 'warning')
        end
    end

    local progressFinished = lib.progressBar({
        duration = beginResponse.durationMs or 8000,
        label = getProgressLabel(mode, option),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'mini@repair',
            clip = mode == 'mechanic' and 'fixing_a_player' or 'fixing_a_ped',
        },
    })

    if not progressFinished then
        lib.callback.await('cidade_tycoon_maintenance:server:completeWorkshopInstall', false, beginResponse.token, {
            cancelled = true,
        })
        notifyMaintenance('Servico cancelado.', 'error')
        return
    end

    local completeResponse = lib.callback.await('cidade_tycoon_maintenance:server:completeWorkshopInstall', false, beginResponse.token, {
        quality = quality,
    })

    if not completeResponse or not completeResponse.ok then
        notifyMaintenance((completeResponse and completeResponse.message) or 'Nao foi possivel concluir a instalacao.', 'error')
        return
    end

    notifyMaintenance(completeResponse.message or 'Servico concluido com sucesso.', 'success')
end

local function getServiceDifficulty(option)
    if option.tier >= 2 then
        return { 'easy', 'medium', 'medium' }
    end

    return { 'easy', 'easy' }
end

local function getServiceProgressLabel(mode, option)
    if mode == 'mechanic' then
        return ('A oficina esta executando %s'):format(option.label)
    end

    return ('Executando %s por conta propria'):format(option.label)
end

local function beginServiceFlow(workshopKey, plate, option, mode)
    local beginResponse = lib.callback.await(
        'cidade_tycoon_maintenance:server:beginWorkshopService',
        false,
        workshopKey,
        plate,
        option.serviceKey,
        mode
    )

    if not beginResponse or not beginResponse.ok then
        notifyMaintenance((beginResponse and beginResponse.message) or 'Nao foi possivel iniciar o servico.', 'error')
        return
    end

    local quality = 'good'
    if mode == 'mechanic' then
        quality = 'premium'
    else
        local success = lib.skillCheck(getServiceDifficulty(option), { 'w', 'a', 's', 'd' })
        quality = success and 'good' or 'poor'
        if not success then
            notifyMaintenance('O servico saiu funcional, mas sem o acabamento ideal de oficina.', 'warning')
        end
    end

    local progressFinished = lib.progressBar({
        duration = beginResponse.durationMs or 9000,
        label = getServiceProgressLabel(mode, option),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'mini@repair',
            clip = mode == 'mechanic' and 'fixing_a_player' or 'fixing_a_ped',
        },
    })

    if not progressFinished then
        lib.callback.await('cidade_tycoon_maintenance:server:completeWorkshopService', false, beginResponse.token, {
            cancelled = true,
        })
        notifyMaintenance('Servico cancelado.', 'error')
        return
    end

    local completeResponse = lib.callback.await('cidade_tycoon_maintenance:server:completeWorkshopService', false, beginResponse.token, {
        quality = quality,
    })

    if not completeResponse or not completeResponse.ok then
        notifyMaintenance((completeResponse and completeResponse.message) or 'Nao foi possivel concluir o servico.', 'error')
        return
    end

    notifyMaintenance(completeResponse.message or 'Servico concluido com sucesso.', 'success')
end

local function openInstallModeMenu(workshopKey, plate, option)
    local modeOptions = {}

    if option.selfInstallAllowed then
        modeOptions[#modeOptions + 1] = {
            title = 'Instalar por conta propria',
            description = ('Taxa do box %s. Usa minigame leve e pode resultar em qualidade menor se voce errar.'):format(fmtMoney(option.selfLaborCost or 0)),
            icon = 'fa-solid fa-screwdriver-wrench',
            onSelect = function()
                beginInstallFlow(workshopKey, plate, option, 'self')
            end,
        }
    end

    modeOptions[#modeOptions + 1] = {
        title = 'Servico da oficina oficial',
        description = ('Mao de obra %s. A oficina faz mais rapido e entrega qualidade premium.'):format(fmtMoney(option.mechanicLaborCost or 0)),
        icon = 'fa-solid fa-user-gear',
        onSelect = function()
            beginInstallFlow(workshopKey, plate, option, 'mechanic')
        end,
    }

    lib.registerContext({
        id = 'tycoon_maintenance_install_modes',
        title = option.label,
        options = modeOptions,
    })

    lib.showContext('tycoon_maintenance_install_modes')
end

local function openServiceModeMenu(workshopKey, plate, option)
    local modeOptions = {}

    if option.selfAllowed then
        modeOptions[#modeOptions + 1] = {
            title = 'Fazer por conta propria',
            description = ('Taxa do box %s. Resolve o servico no box com minigame leve e eficiencia menor.'):format(fmtMoney(option.selfLaborCost or 0)),
            icon = 'fa-solid fa-toolbox',
            onSelect = function()
                beginServiceFlow(workshopKey, plate, option, 'self')
            end,
        }
    end

    modeOptions[#modeOptions + 1] = {
        title = 'Equipe da oficina oficial',
        description = ('Mao de obra %s. Mais rapido, mais limpo e com resultado melhor para o veiculo.'):format(fmtMoney(option.mechanicLaborCost or 0)),
        icon = 'fa-solid fa-user-gear',
        onSelect = function()
            beginServiceFlow(workshopKey, plate, option, 'mechanic')
        end,
    }

    lib.registerContext({
        id = 'tycoon_maintenance_service_modes',
        title = option.label,
        options = modeOptions,
    })

    lib.showContext('tycoon_maintenance_service_modes')
end

local function buildSubsystemOptions(profile)
    local options = {
        {
            title = ('%s | %s'):format(profile.nextServiceRecommendation or 'Revisao em dia', profile.drivetrain and string.upper(profile.drivetrain) or 'RWD'),
            description = ('Condicao geral %s%% | Servico %s%% | Quilometragem %.0f km')
                :format(profile.overallCondition or 100, profile.serviceScore or 100, profile.odometerKm or 0),
            icon = 'fa-solid fa-chart-line',
            disabled = true,
        }
    }

    for subsystemKey, subsystem in pairs(profile.subsystems or {}) do
        options[#options + 1] = {
            title = ('%s | %s%%'):format(subsystem.label or subsystemKey, math.floor((subsystem.condition or 100) + 0.5)),
            description = ('Peca atual: %s | Instalacao: %s')
                :format(subsystem.partLabel or subsystem.partKey or 'Padrao', subsystem.installationQuality or 'good'),
            icon = 'fa-solid fa-gauge-high',
            disabled = true,
        }
    end

    return options
end

local function openWorkshopMenu(workshopKey)
    local vehicle = getClosestVehicleWithinRadius(6.0)
    if vehicle == 0 then
        notifyMaintenance('Aproxime um veiculo seu da oficina para inspecionar ou instalar pecas.', 'error')
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate or plate == '' then
        notifyMaintenance('Nao foi possivel identificar a placa do veiculo.', 'error')
        return
    end

    local response = lib.callback.await('cidade_tycoon_maintenance:server:getWorkshopVehicleData', false, workshopKey, plate)
    if not response or not response.ok then
        notifyMaintenance((response and response.message) or 'Nao foi possivel abrir a oficina para esse veiculo.', 'error')
        return
    end

    local mechanicsOnline = response.mechanicsOnline or 0
    local options = buildSubsystemOptions(response.profile or {})
    
    -- Status Header
    if mechanicsOnline > 0 then
        options[#options + 1] = {
            title = 'Equipe de Mecânicos Online',
            description = 'Existem profissionais na cidade. Procure um para serviços complexos ou descontos.',
            icon = 'fa-solid fa-users-gear',
            iconColor = '#4caf50',
            disabled = true,
        }
    else
        options[#options + 1] = {
            title = 'Modo Assistência NPC Ativo',
            description = 'Nenhum mecânico de plantão. O gerente da oficina pode realizar os serviços por uma taxa extra.',
            icon = 'fa-solid fa-robot',
            iconColor = '#ff9800',
            disabled = true,
        }
    end

    -- SECTION: MECHANICAL REPAIR
    options[#options + 1] = {
        title = 'Reparos Mecânicos',
        description = 'Consertar motor, freios, pneus e suspensão.',
        icon = 'fa-solid fa-screwdriver-wrench',
        onSelect = function()
            OpenMechanicalRepairMenu(plate, response.profile.subsystems)
        end
    }

    -- SECTION: PERFORMANCE UPGRADES
    options[#options + 1] = {
        title = 'Performance & Upgrades',
        description = 'Melhorar motor, turbo, freios e transmissão.',
        icon = 'fa-solid fa-gauge-high',
        onSelect = function()
            ExecuteCommand('tycoon_upgrades') -- Assuming this exists or we create it
        end
    }

    -- SECTION: AESTHETIC CUSTOMS
    options[#options + 1] = {
        title = 'Customização Estética',
        description = 'Cores, rodas, neon e acessórios.',
        icon = 'fa-solid fa-palette',
        onSelect = function()
            exports.cidade_tycoon_customs:OpenAestheticMenu()
        end
    }

    lib.registerContext({
        id = 'tycoon_maintenance_workshop_menu',
        title = ('Oficina Tycoon - %s'):format(plate),
        options = options,
    })

    lib.showContext('tycoon_maintenance_workshop_menu')
end

function OpenMechanicalRepairMenu(plate, subsystems)
    local options = {}
    
    for key, sub in pairs(subsystems) do
        options[#options + 1] = {
            title = ('Reparar %s'):format(sub.label),
            description = ('Saúde Atual: %d%%'):format(math.floor(sub.condition)),
            icon = 'fa-solid fa-wrench',
            onSelect = function()
                OpenPartsSelectionForSubsystem(plate, key, sub.label)
            end
        }
    end

    -- NPC FULL SERVICE OPTION (Fallback)
    options[#options + 1] = {
        title = 'Serviço Completo NPC',
        description = 'O NPC providencia a peça e a mão de obra ($ 2.500 + Valor da Peça).',
        icon = 'fa-solid fa-hand-holding-dollar',
        onSelect = function()
            OpenNPCPurchaseRepairMenu(plate, subsystems)
        end
    }

    lib.registerContext({
        id = 'tycoon_mechanical_repair',
        title = 'Reparos de Subsistemas',
        menu = 'tycoon_maintenance_workshop_menu',
        options = options
    })
    lib.showContext('tycoon_mechanical_repair')
end

function OpenNPCPurchaseRepairMenu(plate, subsystems)
    local options = {}
    local parts = {
        { name = 'engine_block', label = 'Bloco do Motor', category = 'engine' },
        { name = 'transmission_gear', label = 'Transmissão', category = 'transmission' },
        { name = 'brake_pads', label = 'Freios', category = 'brakes' },
        { name = 'suspension_arm', label = 'Suspensão', category = 'suspension' },
        { name = 'truck_tire', label = 'Pneus', category = 'tires' },
    }

    for _, part in ipairs(parts) do
        options[#options + 1] = {
            title = ('Comprar e Instalar %s'):format(part.label),
            description = 'O NPC usará peças próprias. Taxa premium aplicada.',
            onSelect = function()
                local res = lib.callback.await('cidade_tycoon_maintenance:server:purchaseAndRepairNPC', false, plate, part.name)
                if res.ok then
                    ExecuteServiceTimer(part.label, function()
                        notifyMaintenance(res.message, 'success')
                        ExecuteCommand('tycoon_workshop_refresh')
                    end)
                else
                    notifyMaintenance(res.message, 'error')
                end
            end
        }
    end

    lib.registerContext({
        id = 'tycoon_npc_full_service',
        title = 'Serviços do Gerente NPC',
        menu = 'tycoon_mechanical_repair',
        options = options
    })
    lib.showContext('tycoon_npc_full_service')
end

function ExecuteServiceTimer(label, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    -- Visual Immersion
    if veh ~= 0 then
        FreezeEntityPosition(veh, true)
        SetVehicleDoorOpen(veh, 4, false, false) -- Hood
    end

    local success = lib.progressBar({
        duration = 10000,
        label = ('Realizando serviço: %s'):format(label),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_player' }
    })

    if veh ~= 0 then
        FreezeEntityPosition(veh, false)
        SetVehicleDoorShut(veh, 4, false)
    end

    if success then cb() end
end

function OpenPartsSelectionForSubsystem(plate, subsystemKey, label)
    local parts = exports.ox_inventory:Search('slots', {
        'engine_block', 'transmission_gear', 'brake_pads', 'suspension_arm', 'truck_tire', 'basic_repair_kit'
    })

    local options = {}
    local found = false

    for _, slot in pairs(parts) do
        local partData = exports.cidade_tycoon_core:GetPartData(slot.name)
        if partData and (partData.category == subsystemKey or partData.category == 'all') then
            found = true
            table.insert(options, {
                title = ('Usar %s'):format(partData.label),
                description = ('Recupera %d%% de integridade.'):format(partData.repairValue),
                icon = 'fa-solid fa-box',
                onSelect = function()
                    local res = lib.callback.await('cidade_tycoon_maintenance:server:repairSubsystem', false, plate, slot.name)
                    notifyMaintenance(res.message, res.ok and 'success' or 'error')
                    if res.ok then ExecuteCommand('tycoon_workshop_refresh') end -- Trigger refresh
                end
            })
        end
    end

    if not found then
        options[#options + 1] = {
            title = 'Nenhuma peça compatível',
            description = 'Você precisa comprar peças na loja de auto peças.',
            icon = 'fa-solid fa-circle-exclamation',
            disabled = true
        }
    end

    lib.registerContext({
        id = 'tycoon_part_selection',
        title = ('Peças para %s'):format(label),
        menu = 'tycoon_mechanical_repair',
        options = options
    })
    lib.showContext('tycoon_part_selection')
end

local function resetWearTracking(plate)
    wearTracking.activePlate = plate or nil
    wearTracking.sample = nil
    wearTracking.lastFlushAt = GetGameTimer()
end

local function ensureWearSample(plate, vehicle)
    local currentPlate = tostring(plate or '')
    if wearTracking.activePlate ~= currentPlate or not wearTracking.sample then
        wearTracking.activePlate = currentPlate
        wearTracking.sample = {
            startCoords = GetEntityCoords(vehicle),
            lastCoords = GetEntityCoords(vehicle),
            lastSpeedKmh = GetEntitySpeed(vehicle) * 3.6,
            lastEngineHealth = GetVehicleEngineHealth(vehicle),
            lastBodyHealth = GetVehicleBodyHealth(vehicle),
            distanceKm = 0.0,
            harshBrakes = 0,
            offroadSeconds = 0.0,
            slideSeconds = 0.0,
            highRpmSeconds = 0.0,
            impactScore = 0.0,
            speedAccumulator = 0.0,
            speedSamples = 0,
        }
        wearTracking.lastFlushAt = GetGameTimer()
    end

    return wearTracking.sample
end

local function collectWearFrame(sample, vehicle, deltaSeconds)
    local currentCoords = GetEntityCoords(vehicle)
    local currentSpeedKmh = GetEntitySpeed(vehicle) * 3.6
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local distanceKm = #(currentCoords - sample.lastCoords) / 1000.0
    local speedDrop = math.max(0.0, sample.lastSpeedKmh - currentSpeedKmh)
    local bodyLoss = math.max(0.0, sample.lastBodyHealth - bodyHealth)
    local engineLoss = math.max(0.0, sample.lastEngineHealth - engineHealth)
    local lateralSlip = math.abs(GetEntitySpeedVector(vehicle, true).x)
    local onRoad = IsPointOnRoad(currentCoords.x, currentCoords.y, currentCoords.z, vehicle)

    sample.distanceKm = sample.distanceKm + distanceKm
    sample.speedAccumulator = sample.speedAccumulator + currentSpeedKmh
    sample.speedSamples = sample.speedSamples + 1

    if sample.lastSpeedKmh > 70.0 and speedDrop > 28.0 then
        sample.harshBrakes = sample.harshBrakes + 1
    end

    if currentSpeedKmh > 65.0 and GetVehicleCurrentRpm(vehicle) > 0.82 then
        sample.highRpmSeconds = sample.highRpmSeconds + deltaSeconds
    end

    if currentSpeedKmh > 35.0 and lateralSlip > 3.1 then
        sample.slideSeconds = sample.slideSeconds + deltaSeconds
    end

    if currentSpeedKmh > 25.0 and not onRoad and not IsEntityInAir(vehicle) then
        sample.offroadSeconds = sample.offroadSeconds + deltaSeconds
    end

    if bodyLoss > 2.0 or engineLoss > 2.0 then
        sample.impactScore = sample.impactScore + ((bodyLoss * 0.08) + (engineLoss * 0.06) + (math.max(sample.lastSpeedKmh, currentSpeedKmh) * 0.015))
    end

    sample.lastCoords = currentCoords
    sample.lastSpeedKmh = currentSpeedKmh
    sample.lastEngineHealth = engineHealth
    sample.lastBodyHealth = bodyHealth
end

local function shouldFlushWearSample(sample)
    if not sample then
        return false
    end

    local sampling = maintenanceConfig.wearSampling or {}
    local intervalMs = tonumber(sampling.intervalMs) or 8000
    local minDistanceKm = tonumber(sampling.minDistanceKm) or 0.08
    local elapsed = GetGameTimer() - (wearTracking.lastFlushAt or 0)

    if sample.impactScore >= 8.0 then
        return true
    end

    if elapsed < intervalMs then
        return false
    end

    if sample.distanceKm >= minDistanceKm then
        return true
    end

    if sample.harshBrakes > 0 or sample.offroadSeconds > 0.0 or sample.slideSeconds > 0.0 or sample.highRpmSeconds > 0.0 then
        return true
    end

    return false
end

local function flushWearSample(plate)
    local sample = wearTracking.sample
    if not sample then
        return
    end

    local payload = {
        distanceKm = sample.distanceKm,
        harshBrakes = sample.harshBrakes,
        offroadSeconds = sample.offroadSeconds,
        slideSeconds = sample.slideSeconds,
        highRpmSeconds = sample.highRpmSeconds,
        impactScore = sample.impactScore,
        avgSpeedKmh = sample.speedSamples > 0 and (sample.speedAccumulator / sample.speedSamples) or 0.0,
    }

    local response = lib.callback.await('cidade_tycoon_maintenance:server:processVehicleWearSample', false, plate, payload)
    if response and response.ok then
        activeMechanicalEffects.summary = response.summary or activeMechanicalEffects.summary
        activeMechanicalEffects.lastRefreshAt = GetGameTimer()
        maybeWarnMechanicalState(activeMechanicalEffects.summary)
    end

    if response and response.ok and response.messages then
        for i = 1, #response.messages do
            notifyMaintenance(response.messages[i], i == #response.messages and 'warning' or 'inform')
        end
    end

    resetWearTracking(plate)
end

local function getSubsystemCondition(summary, subsystemKey)
    local installedParts = summary and summary.installedParts or {}
    local subsystem = installedParts[subsystemKey]
    return tonumber(subsystem and subsystem.condition) or 100.0
end

local function interpolateConditionFactor(condition, minFactor)
    local normalized = math.max(0.0, math.min(100.0, tonumber(condition) or 100.0))
    if normalized >= 70.0 then
        return 1.0
    end

    local progress = normalized / 70.0
    return minFactor + ((1.0 - minFactor) * progress)
end

local function captureBaseHandling(vehicle)
    return {
        tractionCurveMax = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax'),
        tractionCurveMin = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMin'),
        brakeForce = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce'),
        steeringLock = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSteeringLock'),
        suspensionForce = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionForce'),
    }
end

local function restoreMechanicalEffects(vehicle)
    local base = activeMechanicalEffects.baseHandling
    if vehicle ~= 0 and DoesEntityExist(vehicle) and base then
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax', base.tractionCurveMax)
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMin', base.tractionCurveMin)
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce', base.brakeForce)
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSteeringLock', base.steeringLock)
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionForce', base.suspensionForce)
        SetVehicleEngineTorqueMultiplier(vehicle, 1.0)
        SetVehicleReduceGrip(vehicle, false)
    end

    activeMechanicalEffects.entity = nil
    activeMechanicalEffects.plate = nil
    activeMechanicalEffects.baseHandling = nil
    activeMechanicalEffects.summary = nil
    activeMechanicalEffects.lastWarningBand = nil
    activeMechanicalEffects.lastRefreshAt = 0
    activeMechanicalEffects.nextEngineCutAt = 0
    activeMechanicalEffects.nextCriticalPulseAt = 0
end

local function determineOverallBand(summary)
    local condition = tonumber(summary and summary.overallCondition) or 100.0
    if condition <= 15.0 then
        return 'failure'
    elseif condition <= 40.0 then
        return 'critical'
    elseif condition <= 70.0 then
        return 'warning'
    end

    return 'healthy'
end

local function maybeWarnMechanicalState(summary)
    if not summary then
        return
    end

    local band = determineOverallBand(summary)
    if activeMechanicalEffects.lastWarningBand == band or band == 'healthy' then
        activeMechanicalEffects.lastWarningBand = band
        return
    end

    activeMechanicalEffects.lastWarningBand = band

    if band == 'warning' then
        notifyMaintenance('Seu veiculo ja sente desgaste. Vale passar na oficina antes de apertar mais o uso.', 'warning')
    elseif band == 'critical' then
        notifyMaintenance('Estado mecanico critico: o carro perdeu desempenho e precisa de manutencao urgente.', 'error')
    elseif band == 'failure' then
        notifyMaintenance('Estado mecanico extremo: o veiculo esta quase falhando em operacao.', 'error')
    end
end

local function refreshCurrentVehicleSummary(plate)
    local summary = lib.callback.await('cidade_tycoon_maintenance:server:getVehicleMaintenanceByPlate', false, plate)
    activeMechanicalEffects.summary = summary
    activeMechanicalEffects.lastRefreshAt = GetGameTimer()
    maybeWarnMechanicalState(summary)
end

local function getMaintenanceClassMultiplier(vehicle)
    local model = GetEntityModel(vehicle)
    local vehData = exports.cidade_tycoon_core:GetVehicleDataByHash(model)
    local mClass = vehData and vehData.maintenanceClass or 'standard'
    
    local multipliers = {
        light_work = 1.0,
        utility_work = 1.1,
        commercial = 1.25,
        heavy_duty = 1.5,
        light_sport = 1.2,
        sport = 1.4,
        exotic = 1.8,
        hyper = 2.5
    }
    
    return multipliers[mClass] or 1.0
end

local function applyMechanicalEffects(vehicle, plate)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end

    local normalizedPlate = normalizePlate(plate)
    local classMult = getMaintenanceClassMultiplier(vehicle)
    
    if activeMechanicalEffects.entity and activeMechanicalEffects.entity ~= vehicle then
        restoreMechanicalEffects(activeMechanicalEffects.entity)
    end
    -- ... (rest of implementation would use classMult in interpolateConditionFactor)
end

local function setupAutoPartsCounter(definition)
    local ped = createMaintenancePed(definition)
    maintenancePeds[#maintenancePeds + 1] = ped

    exports.ox_target:addLocalEntity(ped, {
        {
            name = ('tycoon_maintenance_autoparts_%s'):format(definition.key),
            label = 'Comprar pecas comuns',
            icon = 'fa-solid fa-boxes-stacked',
            distance = definition.interactionDistance or 2.2,
            onSelect = function()
                openPartsShop('autoparts')
            end,
        }
    })
end

local function setupWorkshop(definition)
    local ped = createMaintenancePed(definition)
    maintenancePeds[#maintenancePeds + 1] = ped

    exports.ox_target:addLocalEntity(ped, {
        {
            name = ('tycoon_maintenance_premium_%s'):format(definition.key),
            label = 'Comprar pecas premium',
            icon = 'fa-solid fa-gem',
            distance = definition.interactionDistance or 2.5,
            onSelect = function()
                openPartsShop('premium_shop')
            end,
        },
        {
            name = ('tycoon_maintenance_autoparts_workshop_%s'):format(definition.key),
            label = 'Comprar pecas comuns',
            icon = 'fa-solid fa-store',
            distance = definition.interactionDistance or 2.5,
            onSelect = function()
                openPartsShop('autoparts')
            end,
        },
        {
            name = ('tycoon_maintenance_service_%s'):format(definition.key),
            label = 'Inspecionar e instalar no veiculo proximo',
            icon = 'fa-solid fa-screwdriver-wrench',
            distance = definition.interactionDistance or 2.5,
            onSelect = function()
                openWorkshopMenu(definition.key)
            end,
        }
    })
end

local function initializeMaintenanceWorld()
    -- NPCs de auto peças migrados para cidade_tycoon_hubs para evitar duplicidade
    -- Mantemos a função vazia para não quebrar referências internas se houver
    print("^3[Tycoon:Maintenance]^7 Ignorando spawn de NPCs (Migrado para Hubs).")
end

CreateThread(function()
    Wait(2500)
    initializeMaintenanceWorld()
end)

CreateThread(function()
    local tickSeconds = 1.5
    local tickMs = math.floor(tickSeconds * 1000)

    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                local plate = GetVehicleNumberPlateText(vehicle)
                if plate and plate ~= '' then
                    local sample = ensureWearSample(plate, vehicle)
                    collectWearFrame(sample, vehicle, tickSeconds)

                    if shouldFlushWearSample(sample) then
                        flushWearSample(plate)
                    end
                else
                    resetWearTracking(nil)
                end
            else
                if wearTracking.activePlate and wearTracking.sample and wearTracking.sample.distanceKm > 0.0 then
                    flushWearSample(wearTracking.activePlate)
                else
                    resetWearTracking(nil)
                end
            end
        else
            if wearTracking.activePlate and wearTracking.sample and (
                wearTracking.sample.distanceKm > 0.0
                or wearTracking.sample.impactScore > 0.0
                or wearTracking.sample.harshBrakes > 0
            ) then
                flushWearSample(wearTracking.activePlate)
            else
                resetWearTracking(nil)
            end
        end

        Wait(tickMs)
    end
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                local plate = GetVehicleNumberPlateText(vehicle)
                if plate and plate ~= '' then
                    applyMechanicalEffects(vehicle, plate)
                end
            else
                restoreMechanicalEffects(activeMechanicalEffects.entity or 0)
            end
        else
            restoreMechanicalEffects(activeMechanicalEffects.entity or 0)
        end

        Wait(2000)
    end
end)

function OpenWorkshopMenu(workshopKey)
    openWorkshopMenu(workshopKey or 'main_workshop')
end

exports('OpenWorkshopMenu', OpenWorkshopMenu)

RegisterCommand('tycoon_workshop', function()
    OpenWorkshopMenu('main_workshop')
end, false)

RegisterCommand('tycoon_workshop_refresh', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        local plate = GetVehicleNumberPlateText(vehicle)
        if plate then refreshCurrentVehicleSummary(normalizePlate(plate)) end
    end
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        restoreMechanicalEffects(vehicle)
    end

    for i = 1, #maintenancePeds do
        if DoesEntityExist(maintenancePeds[i]) then
            exports.ox_target:removeLocalEntity(maintenancePeds[i])
            DeleteEntity(maintenancePeds[i])
        end
    end
end)
