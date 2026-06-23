-- client/tools.lua

local activeJacks = {}
local jackLockThreadActive = false
local JACK_TILT_ANGLE = 5.0
local JACK_MIN_LIFT = 0.18
local JACK_LOCK_INTERVAL = 500

local function notify(msg, type)
    lib.notify({ title = 'Ferramentas', description = msg, type = type or 'inform' })
end

local function hasMechanicJob()
    local playerData = exports.qbx_core:GetPlayerData()
    return playerData and playerData.job and playerData.job.name == 'mechanic'
end

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

local function requestEntityControl(entity, timeoutMs)
    if not entity or not DoesEntityExist(entity) then return false end
    if NetworkHasControlOfEntity(entity) then return true end

    local timeout = GetGameTimer() + (timeoutMs or 750)
    NetworkRequestControlOfEntity(entity)

    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
        Wait(0)
        NetworkRequestControlOfEntity(entity)
    end

    return NetworkHasControlOfEntity(entity)
end

local function lockVehicleForJack(veh)
    if not veh or not DoesEntityExist(veh) then return end

    requestEntityControl(veh, 250)
    SetVehicleEngineOn(veh, false, true, true)
    SetVehicleHandbrake(veh, true)
    SetEntityVelocity(veh, 0.0, 0.0, 0.0)
    FreezeEntityPosition(veh, true)
end

local function unlockVehicleFromJack(veh)
    if not veh or not DoesEntityExist(veh) then return end

    requestEntityControl(veh, 500)
    SetVehicleHandbrake(veh, false)
    SetEntityVelocity(veh, 0.0, 0.0, 0.0)
    FreezeEntityPosition(veh, false)
end

local function lockJackProp(prop)
    if not prop or not DoesEntityExist(prop) then return end

    requestEntityControl(prop, 250)
    SetEntityAsMissionEntity(prop, true, true)
    SetEntityCollision(prop, false, false)
    FreezeEntityPosition(prop, true)
end

local function deleteJackProp(prop)
    if not prop or not DoesEntityExist(prop) then return end

    requestEntityControl(prop, 500)
    FreezeEntityPosition(prop, false)
    DeleteEntity(prop)
end

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

local function applyJackLift(veh, initialCoords, initialRot, wheelName, isBike)
    if isBike then
        SetEntityCoords(veh, initialCoords.x, initialCoords.y, initialCoords.z + JACK_MIN_LIFT, false, false, false, true)
        SetEntityRotation(veh, initialRot.x, initialRot.y, initialRot.z, 2, true)
        return
    end

    local isLeft = string.find(wheelName, "_l") ~= nil
    local liftWheels = isLeft and { 'wheel_lf', 'wheel_lr' } or { 'wheel_rf', 'wheel_rr' }
    local anchorWheels = isLeft and { 'wheel_rf', 'wheel_rr' } or { 'wheel_lf', 'wheel_lr' }
    local liftBefore = getWheelAverageZ(veh, liftWheels)
    local anchorBefore = getWheelAverageZ(veh, anchorWheels)
    local best

    for _, tilt in ipairs({ JACK_TILT_ANGLE, -JACK_TILT_ANGLE }) do
        SetEntityCoords(veh, initialCoords.x, initialCoords.y, initialCoords.z, false, false, false, true)
        SetEntityRotation(veh, initialRot.x, initialRot.y + tilt, initialRot.z, 2, true)
        Wait(0)

        local anchorAfter = getWheelAverageZ(veh, anchorWheels)
        local zOffset = JACK_MIN_LIFT

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
        local fallbackTilt = isLeft and JACK_TILT_ANGLE or -JACK_TILT_ANGLE
        best = {
            z = initialCoords.z + JACK_MIN_LIFT,
            roll = initialRot.y + fallbackTilt,
        }
    end

    SetEntityCoords(veh, initialCoords.x, initialCoords.y, best.z, false, false, false, true)
    SetEntityRotation(veh, initialRot.x, best.roll, initialRot.z, 2, true)
end

local function getActiveJackForPlate(plate)
    for jackId, jackData in pairs(activeJacks) do
        if jackData.plate == plate then
            return jackId, jackData
        end
    end
    return nil, nil
end

local function restoreVehicleFromJack(jackData)
    local veh = jackData.veh

    if veh and DoesEntityExist(veh) then
        requestEntityControl(veh, 500)
        FreezeEntityPosition(veh, true)
        SetEntityVelocity(veh, 0.0, 0.0, 0.0)
        SetEntityRotation(veh, jackData.rot.x, jackData.rot.y, jackData.rot.z, 2, true)
        SetEntityCoords(veh, jackData.coords.x, jackData.coords.y, jackData.coords.z, false, false, false, true)
        unlockVehicleFromJack(veh)
    end

    deleteJackProp(jackData.prop)
end

local function ensureJackLockThread()
    if jackLockThreadActive then return end

    jackLockThreadActive = true
    CreateThread(function()
        while next(activeJacks) do
            for jackId, jackData in pairs(activeJacks) do
                if not jackData.veh or not DoesEntityExist(jackData.veh) then
                    deleteJackProp(jackData.prop)
                    activeJacks[jackId] = nil
                else
                    lockVehicleForJack(jackData.veh)
                    lockJackProp(jackData.prop)
                end
            end

            Wait(JACK_LOCK_INTERVAL)
        end

        jackLockThreadActive = false
    end)
end

local function getClosestWheel(veh, coords)
    local isBike = IsThisModelABike(GetEntityModel(veh))
    local wheels = isBike and {'wheel_f', 'wheel_r'} or {'wheel_lf', 'wheel_rf', 'wheel_lr', 'wheel_rr'}
    local closestWheel = nil
    local closestDist = 1000.0
    local wheelPos = nil
    local wheelId = -1

    local wheelIdMap = {
        ['wheel_lf'] = 0,
        ['wheel_rf'] = 1,
        ['wheel_lr'] = 4,
        ['wheel_rr'] = 5,
        ['wheel_f'] = 0,
        ['wheel_r'] = 1,
    }

    for _, w in ipairs(wheels) do
        local bone = GetEntityBoneIndexByName(veh, w)
        if bone ~= -1 then
            local pos = GetWorldPositionOfEntityBone(veh, bone)
            local dist = #(coords - pos)
            if dist < closestDist then
                closestDist = dist
                closestWheel = w
                wheelPos = pos
                wheelId = wheelIdMap[w]
            end
        end
    end
    return closestWheel, closestDist, wheelPos, wheelId
end

RegisterNetEvent('cidade_tycoon_mechanic:client:useCarJack', function()
    print("[Tycoon:Mechanic] Client received useCarJack event.")
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local veh = lib.getClosestVehicle(coords, 3.0)

    if not veh then
        print("[Tycoon:Mechanic] No vehicle found within 3.0 meters.")
        notify('Nenhum veiculo proximo.', 'error')
        return
    end

    local isBike = IsThisModelABike(GetEntityModel(veh))

    local wheelName, dist, wheelPos, wheelId = getClosestWheel(veh, coords)
    print("[Tycoon:Mechanic] Closest wheel found: " .. tostring(wheelName) .. " at distance: " .. tostring(dist))

    if dist > 2.0 or not wheelPos then
        notify('Aproxime-se de uma das rodas para usar o macaco.', 'error')
        return
    end

    local plate = GetVehicleNumberPlateText(veh)
    local jackId = plate .. "_" .. wheelName
    local existingJackId = getActiveJackForPlate(plate)

    if existingJackId and existingJackId ~= jackId then
        notify('Ja existe um macaco instalado neste veiculo. Remova antes de mudar de roda.', 'error')
        return
    end

    if activeJacks[jackId] then
        -- Lower the car and remove jack
        local jackData = activeJacks[jackId]

        TaskTurnPedToFaceCoord(ped, wheelPos.x, wheelPos.y, wheelPos.z, 1000)
        Wait(1000)

        loadAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
        TaskPlayAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8.0, -1, 1, 0, false, false, false)

        if lib.progressBar({
            duration = 3000,
            label = 'Removendo macaco...',
            useWhileDead = false,
            canCancel = false,
            disable = { car = true, move = true, combat = true }
        }) then
            ClearPedTasks(ped)
            restoreVehicleFromJack(jackData)
            activeJacks[jackId] = nil
            lib.callback.await('cidade_tycoon_mechanic:server:releaseCarJack', false, plate)
            notify('Macaco removido.', 'success')
        end
    else
        -- Raise the car
        TaskTurnPedToFaceCoord(ped, wheelPos.x, wheelPos.y, wheelPos.z, 1000)
        Wait(1000)

        loadAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
        TaskPlayAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8.0, -1, 1, 0, false, false, false)

        if lib.progressBar({
            duration = 5000,
            label = 'Posicionando macaco...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true }
        }) then
            ClearPedTasks(ped)

            local vehCoords = GetEntityCoords(veh)
            local initialRot = GetEntityRotation(veh, 2)
            local lockRes = lib.callback.await('cidade_tycoon_mechanic:server:tryLockCarJack', false, plate, wheelName)

            if not lockRes or not lockRes.ok then
                notify((lockRes and lockRes.message) or 'Nao foi possivel reservar este veiculo para o macaco.', 'error')
                return
            end

            if not requestEntityControl(veh, 1000) then
                lib.callback.await('cidade_tycoon_mechanic:server:releaseCarJack', false, plate)
                notify('Nao foi possivel travar este veiculo agora.', 'error')
                return
            end

            lockVehicleForJack(veh)

            local jackHash = GetHashKey("prop_carjack")
            RequestModel(jackHash)
            while not HasModelLoaded(jackHash) do Wait(10) end

            local isLeft = string.find(wheelName, "_l") ~= nil
            local offsetDir = isLeft and -1.0 or 1.0

            local forwardVector, rightVector, upVector, position = GetEntityMatrix(veh)
            local actualRight = rightVector * offsetDir

            local jackPos = wheelPos
            if not isBike then
                jackPos = wheelPos + (actualRight * 0.5)
            else
                jackPos = wheelPos + (rightVector * 0.5) -- Just put it to the side for bikes
            end

            local jackProp = CreateObject(jackHash, jackPos.x, jackPos.y, jackPos.z - 0.5, true, true, false)
            if not DoesEntityExist(jackProp) then
                unlockVehicleFromJack(veh)
                lib.callback.await('cidade_tycoon_mechanic:server:releaseCarJack', false, plate)
                SetModelAsNoLongerNeeded(jackHash)
                notify('Nao foi possivel criar o macaco hidraulico.', 'error')
                return
            end

            SetEntityHeading(jackProp, GetEntityHeading(veh) + (isLeft and 90.0 or -90.0))
            PlaceObjectOnGroundProperly(jackProp)
            lockJackProp(jackProp)

            applyJackLift(veh, vehCoords, initialRot, wheelName, isBike)
            lockVehicleForJack(veh)
            SetModelAsNoLongerNeeded(jackHash)

            activeJacks[jackId] = {
                prop = jackProp,
                veh = veh,
                plate = plate,
                wheelName = wheelName,
                rot = initialRot,
                coords = vehCoords,
            }
            ensureJackLockThread()
            notify('Veiculo levantado.', 'success')
        else
            ClearPedTasks(ped)
        end
    end
end)

local function ExecuteTireRepair(veh, wheelId, wheelPos, duration, plate, actionType, item, wheelName)
    local ped = PlayerPedId()
    TaskTurnPedToFaceCoord(ped, wheelPos.x, wheelPos.y, wheelPos.z, 1000)
    Wait(1000)

    loadAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
    TaskPlayAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8.0, -1, 1, 0, false, false, false)

    local labelText = actionType == 'install' and ('Instalando ' .. item.label) or 'Remendando Pneu...'

    if lib.progressBar({
        duration = duration,
        label = labelText,
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true }
    }) then
        ClearPedTasks(ped)

        -- Fix visual puncture if burst
        if IsVehicleTyreBurst(veh, wheelId, false) then
            SetVehicleTyreFixed(veh, wheelId)
        end

        -- Mapping bike wheels to generic front/rear tire status or specific if core supports it
        local tireKey = wheelName:gsub("wheel_", "tire_")
        if wheelName == 'wheel_f' then tireKey = 'tire_lf' end -- Fallback mapping for bikes
        if wheelName == 'wheel_r' then tireKey = 'tire_lr' end

        if actionType == 'install' then
            local res = lib.callback.await('cidade_tycoon_mechanic:server:installPart', false, plate, item.name, tireKey)
            notify(res.message, res.ok and 'success' or 'error')
        else
            local res = lib.callback.await('cidade_tycoon_mechanic:server:fixVehicleEmergency', false, plate, tireKey)
            notify(res.message, res.ok and 'success' or 'error')
        end
    else
        ClearPedTasks(ped)
        notify('Acao cancelada.', 'error')
    end
end

RegisterNetEvent('cidade_tycoon_mechanic:client:useWrenchTarget', function(veh, coords)
    local ped = PlayerPedId()
    local isMechanic = hasMechanicJob()
    local plate = GetVehicleNumberPlateText(veh)

    -- Check if near a wheel
    local wheelName, dist, wheelPos, wheelId = getClosestWheel(veh, coords)
    if dist <= 2.0 and wheelPos then
        local jackId = plate .. "_" .. wheelName
        if not activeJacks[jackId] then
            notify('Voce precisa levantar o carro neste ponto com o macaco hidraulico antes de usar a chave.', 'error')
            return
        end

        local duration = isMechanic and 8000 or 25000

        -- Fetch available tires
        local availableTires = lib.callback.await('cidade_tycoon_mechanic:server:getAvailableParts', false, 'tires')

        local options = {
            {
                title = 'Remendo de Emergencia',
                description = 'Tapa o furo do pneu temporariamente.',
                icon = 'bandage',
                onSelect = function()
                    ExecuteTireRepair(veh, wheelId, wheelPos, duration, plate, 'emergency', nil, wheelName)
                end
            }
        }

        if availableTires and #availableTires > 0 then
            for _, item in ipairs(availableTires) do
                if item.name == 'standard_tires' or item.name == 'truck_tire' then
                    table.insert(options, {
                        title = 'Instalar: ' .. item.label,
                        description = ('Voce tem %d na mochila. (+%.1f%% Saude)'):format(item.count, item.repairValue),
                        image = "nui://ox_inventory/web/images/" .. item.name .. ".png",
                        icon = 'wrench',
                        onSelect = function()
                            ExecuteTireRepair(veh, wheelId, wheelPos, duration, plate, 'install', item, wheelName)
                        end
                    })
                end
            end
        end

        lib.registerContext({
            id = 'wrench_tire_menu',
            title = 'Manutencao: ' .. (IsThisModelABike(GetEntityModel(veh)) and "Roda de Moto" or "Pneu"),
            options = options
        })
        lib.showContext('wrench_tire_menu')
        return
    end

    -- Check Engine fallback (for emergencies)
    local engineBone = GetEntityBoneIndexByName(veh, 'engine')
    if engineBone ~= -1 then
        local enginePos = GetWorldPositionOfEntityBone(veh, engineBone)
        if #(coords - enginePos) <= 2.0 then
            if not isMechanic then
                TaskTurnPedToFaceEntity(ped, veh, 1000)
                Wait(1000)
                SetVehicleEngineOn(veh, false, false, true)
                SetVehicleDoorOpen(veh, 4, false, false)

                loadAnimDict("mini@repair")
                TaskPlayAnim(ped, "mini@repair", "fixing_a_ped", 8.0, -8.0, -1, 1, 0, false, false, false)

                if lib.progressBar({
                    duration = 20000,
                    label = 'Reparo de Emergencia (Motor)...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { car = true, move = true, combat = true }
                }) then
                    ClearPedTasks(ped)
                    SetVehicleDoorShut(veh, 4, false)
                    SetVehicleEngineHealth(veh, 500.0)
                    local res = lib.callback.await('cidade_tycoon_mechanic:server:fixVehicleEmergency', false, plate, 'engine')
                    notify(res.message, res.ok and 'success' or 'error')
                else
                    ClearPedTasks(ped)
                    SetVehicleDoorShut(veh, 4, false)
                end
            else
                notify('Como mecanico, use o menu de diagnostico [Olho] para consertos no motor.', 'inform')
            end
            return
        end
    end

    notify('Mire no motor ou em uma roda levantada.', 'error')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end

    for jackId, jackData in pairs(activeJacks) do
        restoreVehicleFromJack(jackData)
        if jackData.plate then
            TriggerServerEvent('cidade_tycoon_mechanic:server:releaseCarJack', jackData.plate)
        end
        activeJacks[jackId] = nil
    end
end)