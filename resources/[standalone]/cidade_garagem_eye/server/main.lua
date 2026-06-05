local VEHICLES = exports.qbx_core:GetVehiclesByName()
local DEFAULT_RECOVERY_GARAGE = 'motelgarage'
local activeVehicles = {}

local VehicleState = {
    OUT = 0,
    GARAGED = 1,
    IMPOUNDED = 2,
}

local VehicleType = {
    CAR = 'car',
    AIR = 'air',
    SEA = 'sea',
}

local function setActiveTycoonVehicle(source, plate)
    if GetResourceState('cidade_tycoon_freelance') == 'started' then
        exports.cidade_tycoon_freelance:SetActiveVehiclePlate(source, plate)
    end
end

RegisterNetEvent('cidade_garagem_eye:server:setActiveVehicle', function(plate)
    setActiveTycoonVehicle(source, plate)
end)

local function offsetSpawnPoint(origin, forwardOffset, rightOffset)
    local heading = math.rad(origin.w or 0.0)
    local forwardX = math.cos(heading)
    local forwardY = math.sin(heading)
    local rightX = math.cos(heading - math.pi / 2)
    local rightY = math.sin(heading - math.pi / 2)

    return vec4(
        origin.x + (forwardX * forwardOffset) + (rightX * rightOffset),
        origin.y + (forwardY * forwardOffset) + (rightY * rightOffset),
        origin.z,
        origin.w
    )
end

local function findAvailableSpawnPoint(baseSpawn)
    local candidates = {
        { 0.0, 0.0 },
        { 4.0, 0.0 },
        { -4.0, 0.0 },
        { 0.0, 4.0 },
        { 0.0, -4.0 },
        { 8.0, 0.0 },
        { -8.0, 0.0 },
        { 4.0, 4.0 },
        { 4.0, -4.0 },
        { -4.0, 4.0 },
        { -4.0, -4.0 },
    }

    for i = 1, #candidates do
        local offsets = candidates[i]
        local candidate = offsetSpawnPoint(baseSpawn, offsets[1], offsets[2])
        if not lib.getClosestVehicle(candidate.xyz, 5.0, false) then
            return candidate
        end
    end
end

local function getVehicleType(modelName)
    local vehicleData = VEHICLES[modelName]
    if not vehicleData then
        return VehicleType.CAR
    end

    if vehicleData.category == 'helicopters' or vehicleData.category == 'planes' then
        return VehicleType.AIR
    elseif vehicleData.category == 'boats' then
        return VehicleType.SEA
    end

    return VehicleType.CAR
end

local function normalizeState(value)
    return tonumber(value) or value
end

local function normalizePlate(plate)
    return tostring(plate or ''):gsub('%s+', '')
end

local function isPlateSpawnedOnServer(plate)
    local normalizedPlate = normalizePlate(plate)
    if normalizedPlate == '' then
        return false
    end

    -- Check cache first
    local cachedEntity = activeVehicles[normalizedPlate]
    if cachedEntity and DoesEntityExist(cachedEntity) then
        return true
    end

    if cachedEntity then
        activeVehicles[normalizedPlate] = nil
    end

    -- Fallback loop
    local vehicles = GetAllVehicles()
    for i = 1, #vehicles do
        local entity = vehicles[i]
        if DoesEntityExist(entity) and normalizePlate(GetVehicleNumberPlateText(entity)) == normalizedPlate then
            activeVehicles[normalizedPlate] = entity
            return true
        end
    end

    return false
end

local function buildSpawnModelCandidates(playerVehicle)
    local candidates = {}

    if type(playerVehicle.modelName) == 'string' and playerVehicle.modelName ~= '' then
        candidates[#candidates + 1] = playerVehicle.modelName
    end

    local propsModel = playerVehicle.props and playerVehicle.props.model or nil
    if propsModel ~= nil then
        local exists = false
        for i = 1, #candidates do
            if candidates[i] == propsModel then
                exists = true
                break
            end
        end

        if not exists then
            candidates[#candidates + 1] = propsModel
        end
    end

    return candidates
end

local function getGarageConfig(garageName, accessPointIndex)
    local garages = exports.qbx_garages:GetGarages()
    local garage = garages and garages[garageName]
    local accessPoint = garage and garage.accessPoints and garage.accessPoints[accessPointIndex]
    return garage, accessPoint
end

local function isPublicGarage(garage)
    return garage and not garage.groups and garage.type ~= 'depot'
end

local function getPlayerVehiclesByCitizenId(citizenId)
    local vehicles = exports.qbx_vehicles:GetPlayerVehicles({
        citizenid = citizenId
    }) or {}

    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if not vehicle.plate or vehicle.plate == '' then
            local rawPlate = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE id = ?', { vehicle.id })
            if rawPlate then
                vehicle.plate = rawPlate
                if not vehicle.props then vehicle.props = {} end
                vehicle.props.plate = rawPlate
            end
        end
    end

    return vehicles
end

local function shouldListVehicle(vehicle, garageName, garage)
    local state = normalizeState(vehicle.state)
    local plate = vehicle.props and vehicle.props.plate or vehicle.plate
    local canRecover = state == VehicleState.OUT
    local sameGarage = tostring(vehicle.garage or '') == garageName
    local canUsePublicGarage = isPublicGarage(garage) and (state == VehicleState.GARAGED or state == VehicleState.IMPOUNDED or canRecover)
    local canUsePrivateGarage = (not isPublicGarage(garage)) and sameGarage and (state == VehicleState.GARAGED or state == VehicleState.IMPOUNDED or canRecover)

    if getVehicleType(vehicle.modelName) ~= (garage.vehicleType or VehicleType.CAR) then
        return false
    end

    if not canUsePublicGarage and not canUsePrivateGarage then
        return false
    end

    vehicle.state = state
    vehicle.canRecover = canRecover
    return true
end

local function moveVehicleToGarage(vehicleId, garageName)
    return exports.qbx_garages:SetVehicleGarage(vehicleId, garageName)
end

local function getPlayerSpawnOrigin(source)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    return offsetSpawnPoint(vec4(coords.x, coords.y, coords.z, heading), 6.0, 0.0)
end

local function spawnOwnedVehicle(source, vehicleId, garageName, accessPointIndex, mode)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then
        return { ok = false, message = 'Jogador nao encontrado.' }
    end

    local garage, accessPoint = getGarageConfig(garageName, accessPointIndex)
    if not garage or not accessPoint then
        return { ok = false, message = 'Ponto de retirada da garagem nao encontrado.' }
    end

    if garage.vehicleType ~= VehicleType.CAR then
        return { ok = false, message = 'Esse ponto de garagem nao opera veiculos terrestres.' }
    end

    local isTabletRequest = mode == 'tablet'
    local ped = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(ped)

    if isTabletRequest then
        if GetVehiclePedIsIn(ped, false) ~= 0 then
            return { ok = false, message = 'Saia do veiculo antes de usar o tablet para retirar outro.' }
        end
        if #(playerCoords.xy - accessPoint.coords.xy) > 15.0 then
            return { ok = false, message = 'Voce esta muito distante dessa garagem para retirar o veiculo.' }
        end
    else
        if #(playerCoords.xy - accessPoint.coords.xy) > 8.0 then
            return { ok = false, message = 'Chegue mais perto do atendente desta garagem.' }
        end
    end

    local playerVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
    if not playerVehicle or playerVehicle.citizenid ~= player.PlayerData.citizenid then
        return { ok = false, message = 'Esse veiculo nao pertence a voce.' }
    end

    if not playerVehicle.plate or playerVehicle.plate == '' then
        local rawPlate = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE id = ?', { vehicleId })
        if rawPlate then
            playerVehicle.plate = rawPlate
            if not playerVehicle.props then playerVehicle.props = {} end
            playerVehicle.props.plate = rawPlate
        end
    end

    if getVehicleType(playerVehicle.modelName) ~= VehicleType.CAR then
        return { ok = false, message = 'Esse veiculo nao pode ser retirado em garagem terrestre.' }
    end

    playerVehicle.state = normalizeState(playerVehicle.state)
    local vehiclePlate = playerVehicle.props and playerVehicle.props.plate or playerVehicle.plate

    if playerVehicle.state == VehicleState.OUT then
        if isPlateSpawnedOnServer(vehiclePlate) then
            return { ok = false, message = 'Esse veiculo ja esta fora no mapa.' }
        end

        local recovered = moveVehicleToGarage(vehicleId, garageName)
        if not recovered then
            return { ok = false, message = 'Nao foi possivel recuperar esse veiculo para esta garagem.' }
        end

        playerVehicle.state = VehicleState.GARAGED
        playerVehicle.garage = garageName
    end

    if playerVehicle.garage ~= garageName or playerVehicle.state == VehicleState.IMPOUNDED then
        local moved = moveVehicleToGarage(vehicleId, garageName)
        if moved then
            playerVehicle.garage = garageName
            playerVehicle.state = VehicleState.GARAGED
        end
    end

    if playerVehicle.state ~= VehicleState.GARAGED and playerVehicle.state ~= VehicleState.IMPOUNDED then
        return { ok = false, message = 'Esse veiculo nao esta disponivel para retirada.' }
    end

    local spawnOrigin = isTabletRequest and getPlayerSpawnOrigin(source) or (accessPoint.spawn or accessPoint.coords)
    local spawnCoords = findAvailableSpawnPoint(spawnOrigin)
    if not spawnCoords then
        return { ok = false, message = 'A vaga de spawn esta ocupada por outro veiculo. Por favor, libere a area.' }
    end

    playerVehicle.props = playerVehicle.props or {}
    playerVehicle.props.lockState = 1

    local spawnModels = buildSpawnModelCandidates(playerVehicle)
    if not spawnModels[1] then
        return { ok = false, message = 'Esse veiculo nao possui modelo valido para retirada.' }
    end

    local netId, veh
    for i = 1, #spawnModels do
        local spawnModel = spawnModels[i]
        local spawnOk, spawnedNetId, spawnedVeh = pcall(function()
            return qbx.spawnVehicle({
                spawnSource = spawnCoords,
                model = spawnModel,
                props = playerVehicle.props,
                warp = false
            })
        end)

        if spawnOk and spawnedNetId and spawnedVeh then
            netId = spawnedNetId
            veh = spawnedVeh
            local normPlate = normalizePlate(playerVehicle.props.plate or playerVehicle.plate)
            if normPlate ~= '' then
                activeVehicles[normPlate] = spawnedVeh
            end
            break
        end

        print(('[cidade_garagem_eye] Tentativa de spawn falhou | vehicleId=%s | garage=%s | model=%s | spawnOk=%s | netId=%s | veh=%s'):format(
            tostring(vehicleId),
            tostring(garageName),
            tostring(spawnModel),
            tostring(spawnOk),
            tostring(spawnedNetId),
            tostring(spawnedVeh)
        ))
    end

    if not netId or not veh then
        return { ok = false, message = 'Falha ao criar o veiculo na vaga de retirada.' }
    end

    if GetResourceState('qbx_vehiclekeys') == 'started' then
        TriggerEvent('qb-vehiclekeys:server:setVehLockState', netId, 2)
    else
        SetVehicleDoorsLocked(veh, 2)
    end

    TriggerClientEvent('vehiclekeys:client:SetOwner', source, playerVehicle.props.plate)
    Entity(veh).state:set('vehicleid', vehicleId, false)

    local saved = exports.qbx_vehicles:SaveVehicle(veh, {
        state = VehicleState.OUT,
        depotPrice = 0,
        garage = garageName,
        props = playerVehicle.props
    })

    if not saved then
        return { ok = false, message = 'O veiculo apareceu, mas falhou ao salvar o novo estado.' }
    end

    setActiveTycoonVehicle(source, playerVehicle.props.plate)
    if GetResourceState('cidade_tycoon_freelance') == 'started' then
        pcall(function()
            exports.cidade_tycoon_freelance:HandleTutorialVehicleRetrieved(
                source,
                playerVehicle.modelName,
                garageName
            )
        end)
    end

    return {
        ok = true,
        netId = netId,
        plate = playerVehicle.props.plate,
        message = 'Veiculo retirado com sucesso.'
    }
end

lib.callback.register('cidade_garagem_eye:server:getGarageVehicles', function(source, garageName)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {} end

    local garage = getGarageConfig(garageName, 1)
    if not garage then return {} end

    local vehicles = getPlayerVehiclesByCitizenId(player.PlayerData.citizenid)
    local filtered = {}
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if shouldListVehicle(vehicle, garageName, garage) then
            -- Tycoon Enrichment: Matrix Data
            local tycoonData = exports.cidade_tycoon_core:GetVehicleData(vehicle.vehicle)
            if tycoonData then
                vehicle.tycoon = {
                    tier = tycoonData.tier,
                    capacity = tycoonData.capacity,
                    label = tycoonData.label,
                    category = tycoonData.category
                }
            end

            -- Tycoon Enrichment: Maintenance Status
            local status = MySQL.single.await('SELECT * FROM tycoon_vehicle_status WHERE plate = ?', { vehicle.plate })
            if status then
                vehicle.maintenance = status
            else
                vehicle.maintenance = {
                    engine_health = 100.0,
                    brakes_health = 100.0,
                    tires_health = 100.0,
                    mileage = 0.0
                }
            end

            filtered[#filtered + 1] = vehicle
        end
    end

    return filtered
end)

lib.callback.register('cidade_garagem_eye:server:getPlayerVehicles', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {} end

    return getPlayerVehiclesByCitizenId(player.PlayerData.citizenid)
end)

lib.callback.register('cidade_garagem_eye:server:getPlayerVehiclesDebug', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {} end

    local vehicles = getPlayerVehiclesByCitizenId(player.PlayerData.citizenid)
    local debugRows = {}
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        debugRows[#debugRows + 1] = {
            id = vehicle.id,
            modelName = vehicle.modelName,
            plate = vehicle.props and vehicle.props.plate or '',
            garage = vehicle.garage,
            state = normalizeState(vehicle.state),
            depotPrice = vehicle.depotPrice,
            type = getVehicleType(vehicle.modelName),
        }
    end

    return {
        citizenid = player.PlayerData.citizenid,
        vehicles = debugRows,
    }
end)

lib.callback.register('cidade_garagem_eye:server:recoverOutVehicles', function(source, targetGarage)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then
        return { ok = false, message = 'Jogador nao encontrado.' }
    end

    local garageName = targetGarage or DEFAULT_RECOVERY_GARAGE
    local vehicles = getPlayerVehiclesByCitizenId(player.PlayerData.citizenid)

    local recovered = 0
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        vehicle.state = normalizeState(vehicle.state)
        if vehicle.state == VehicleState.OUT and not isPlateSpawnedOnServer(vehicle.props and vehicle.props.plate or vehicle.plate) then
            local success = moveVehicleToGarage(vehicle.id, garageName)
            if success then
                recovered = recovered + 1
            end
        end
    end

    if recovered == 0 then
        return { ok = false, message = 'Nenhum veiculo recuperavel foi encontrado.' }
    end

    return {
        ok = true,
        message = ('%d veiculo(s) foram devolvidos para a garagem %s.'):format(recovered, garageName)
    }
end)

lib.callback.register('cidade_garagem_eye:server:spawnVehicle', function(source, vehicleId, garageName, accessPointIndex)
    local ok, result = xpcall(function()
        return spawnOwnedVehicle(source, vehicleId, garageName, accessPointIndex, 'garage')
    end, function(err)
        local message = debug.traceback(err, 2)
        print(('[cidade_garagem_eye] Erro ao retirar no NPC | source=%s | vehicleId=%s | garage=%s | accessPoint=%s\n%s'):format(
            tostring(source),
            tostring(vehicleId),
            tostring(garageName),
            tostring(accessPointIndex),
            tostring(message)
        ))
        return message
    end)

    if not ok then
        return { ok = false, message = 'A retirada falhou internamente.' }
    end

    return result
end)

lib.callback.register('cidade_garagem_eye:server:spawnVehicleFromTablet', function(source, vehicleId, garageName, accessPointIndex)
    local ok, result = xpcall(function()
        return spawnOwnedVehicle(source, vehicleId, garageName, accessPointIndex, 'tablet')
    end, function(err)
        local message = debug.traceback(err, 2)
        print(('[cidade_garagem_eye] Erro ao retirar no tablet | source=%s | vehicleId=%s | garage=%s | accessPoint=%s\n%s'):format(
            tostring(source),
            tostring(vehicleId),
            tostring(garageName),
            tostring(accessPointIndex),
            tostring(message)
        ))
        return message
    end)

    if not ok then
        return { ok = false, message = 'A retirada pelo tablet falhou internamente.' }
    end

    return result
end)

local function forceRecoverVehicle(source, vehicleId, garageName)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then
        return { ok = false, message = 'Jogador nao encontrado.' }
    end

    local playerVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
    if not playerVehicle or playerVehicle.citizenid ~= player.PlayerData.citizenid then
        return { ok = false, message = 'Esse veiculo nao pertence a voce.' }
    end

    if not playerVehicle.plate or playerVehicle.plate == '' then
        local rawPlate = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE id = ?', { vehicleId })
        if rawPlate then
            playerVehicle.plate = rawPlate
            if not playerVehicle.props then playerVehicle.props = {} end
            playerVehicle.props.plate = rawPlate
        end
    end

    local plate = playerVehicle.props and playerVehicle.props.plate or playerVehicle.plate
    local normalizedPlate = normalizePlate(plate)

    -- Localizar a entidade fisica do veiculo (cache + fallback)
    local vehicleEntity = activeVehicles[normalizedPlate]
    if vehicleEntity and not DoesEntityExist(vehicleEntity) then
        vehicleEntity = nil
        activeVehicles[normalizedPlate] = nil
    end

    if not vehicleEntity then
        local allVehicles = GetAllVehicles()
        for i = 1, #allVehicles do
            local entity = allVehicles[i]
            if DoesEntityExist(entity) and normalizePlate(GetVehicleNumberPlateText(entity)) == normalizedPlate then
                vehicleEntity = entity
                break
            end
        end
    end

    -- Se a entidade fisica existe, aplicar validacoes anti-exploit
    if vehicleEntity and DoesEntityExist(vehicleEntity) then
        -- 1. Verificar ocupantes (anti-griefing: nao deletar carro com gente dentro)
        local seatCheckOk, maxSeats = pcall(GetVehicleMaxNumberOfPassengers, vehicleEntity)
        if seatCheckOk and maxSeats then
            for seat = -1, maxSeats - 1 do
                local ped = GetPedInVehicleSeat(vehicleEntity, seat)
                if ped ~= 0 and DoesEntityExist(ped) then
                    return { ok = false, message = 'Nao e possivel rebocar o veiculo enquanto ele estiver ocupado por alguem.' }
                end
            end
        end

        -- 2. Verificar velocidade (anti-combat: nao deletar veiculos em movimento)
        local velOk, velocity = pcall(GetEntityVelocity, vehicleEntity)
        if velOk and velocity then
            local speed = math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z)
            if speed > 1.0 then
                return { ok = false, message = 'Nao e possivel rebocar o veiculo enquanto ele estiver em movimento.' }
            end
        end

        -- 3. Salvar danos atuais antes de deletar (previne reparo gratuito)
        pcall(function()
            local savedProps = playerVehicle.props or {}
            local okEng, eng = pcall(GetVehicleEngineHealth, vehicleEntity)
            local okBody, body = pcall(GetVehicleBodyHealth, vehicleEntity)
            if okEng and eng then savedProps.engineHealth = eng end
            if okBody and body then savedProps.bodyHealth = body end

            exports.qbx_vehicles:SaveVehicle(vehicleEntity, {
                state = VehicleState.OUT,
                garage = playerVehicle.garage or garageName,
                props = savedProps
            })
        end)

        -- 4. Deletar a entidade fisica
        DeleteEntity(vehicleEntity)
        activeVehicles[normalizedPlate] = nil

        -- 5. Confirmar que a entidade foi realmente destruida (aguardar ate 1 segundo)
        local deleteTimeout = GetGameTimer() + 1000
        while DoesEntityExist(vehicleEntity) do
            Wait(100)
            if GetGameTimer() > deleteTimeout then
                print(('[cidade_garagem_eye] WARN: Timeout na delecao da entidade | plate=%s'):format(normalizedPlate))
                break
            end
        end

        -- 6. Fallback: limpar duplicatas orfas com a mesma placa
        local allVehicles = GetAllVehicles()
        for i = 1, #allVehicles do
            local entity = allVehicles[i]
            if DoesEntityExist(entity) and normalizePlate(GetVehicleNumberPlateText(entity)) == normalizedPlate then
                DeleteEntity(entity)
            end
        end
    end

    -- Forcar a garagem e o estado no banco (somente apos delecion ou se nao havia entidade)
    local success, err = exports.qbx_garages:SetVehicleGarage(vehicleId, garageName)
    if success then
        return { ok = true, message = 'Veiculo rebocado para a garagem com sucesso.' }
    else
        local errMsg = err and err.message or 'Nao foi possivel devolver o veiculo para a garagem.'
        print(('[cidade_garagem_eye] ERRO SetVehicleGarage | vehicleId=%s | garage=%s | err=%s'):format(
            tostring(vehicleId), tostring(garageName), tostring(errMsg)
        ))
        return { ok = false, message = errMsg }
    end
end

lib.callback.register('cidade_garagem_eye:server:forceRecoverVehicle', function(source, vehicleId, garageName)
    local ok, result = xpcall(function()
        return forceRecoverVehicle(source, vehicleId, garageName)
    end, function(err)
        local message = debug.traceback(err, 2)
        print(('[cidade_garagem_eye] Erro no reboque | source=%s | vehicleId=%s | garage=%s\n%s'):format(
            tostring(source),
            tostring(vehicleId),
            tostring(garageName),
            tostring(message)
        ))
        return message
    end)

    if not ok then
        return { ok = false, message = 'O reboque falhou internamente. Verifique o console do servidor.' }
    end

    return result
end)
