local sharedConfig = require 'config.shared'
local ClientRuntimeState = {
    activeMission = nil,
    deliveryBlip = 0,
    boxProp = nil,
    nextInteractionAt = 0,
    lastVehicleSeenAt = 0
}

local function notifyClient(msg, type)
    exports.qbx_core:Notify(msg, type or 'inform')
end

-- ==========================================
-- PREDICTIVE CARGO VISUALS
-- ==========================================
local function toggleBoxVisual(active)
    local ped = PlayerPedId()
    if active then
        local animDict = "anim@heists@box_carry@"
        lib.requestAnimDict(animDict)
        TaskPlayAnim(ped, animDict, "idle", 8.0, -8.0, -1, 49, 0, false, false, false)
        
        local model = joaat("hei_prop_heist_box")
        lib.requestModel(model)
        ClientRuntimeState.boxProp = CreateObject(model, 0, 0, 0, false, false, false)
        AttachEntityToEntity(ClientRuntimeState.boxProp, ped, GetPedBoneIndex(ped, 60309), 0.025, 0.08, 0.255, -145.0, 290.0, 0.0, true, true, false, true, 1, true)
    else
        ClearPedTasks(ped)
        if ClientRuntimeState.boxProp then DeleteEntity(ClientRuntimeState.boxProp) end
        ClientRuntimeState.boxProp = nil
    end
end

-- ==========================================
-- INTERACTION POINTS (OX_LIB)
-- ==========================================
local currentPoints = {}
local setupMissionPoints

local function applyMissionState(state, rebuildPoints)
    if not state then return end
    local wasCarrying = ClientRuntimeState.activeMission and ClientRuntimeState.activeMission.carryingBox == true
    ClientRuntimeState.activeMission = state
    local isCarrying = state.carryingBox == true
    if wasCarrying ~= isCarrying then toggleBoxVisual(isCarrying and not IsPedInAnyVehicle(PlayerPedId(), false)) end
    TriggerEvent('cidade_tycoon_tablet:client:updateFreelanceHUD', {
        active = true,
        cargoHealth = state.cargoHealth or 100,
        totalDelivered = state.totalDelivered or 0,
        totalRequired = state.totalRequired or 1,
        phase = state.phase,
        inTrunk = state.inTrunk or 0,
        capacity = state.capacity or 0
    })
    if rebuildPoints and setupMissionPoints then setupMissionPoints() end
end

local function playChatSound(name)
    -- Sons padrão do GTA que combinam com as ações
    if name == 'pickup' then
        PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    elseif name == 'place' then
        PlaySoundFrontend(-1, "Object_Dropped_Remote", "DLC_HEISTS_BIOLAB_FINALE_SOUNDS", 1)
    elseif name == 'deliver' then
        PlaySoundFrontend(-1, "LOCAL_PLYR_CASH_COUNTER_COMPLETE", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 1)
    end
end

local function cleanupMissionPoints()
    for _, point in ipairs(currentPoints) do point:remove() end
    currentPoints = {}
    if ClientRuntimeState.deliveryBlip ~= 0 then RemoveBlip(ClientRuntimeState.deliveryBlip) end
    ClientRuntimeState.deliveryBlip = 0
end

setupMissionPoints = function()
    cleanupMissionPoints()
    local m = ClientRuntimeState.activeMission
    if not m then return end

    -- 1. Origin Hub Point (Só aparece se o jogador ainda tiver caixas para buscar e não estiver com uma na mão)
    local hub = sharedConfig.hubs[m.hubId]
    if m.phase == 'pickup' and hub and m.collectedFromOrigin < m.totalRequired and not m.carryingBox then
        local originPoint = lib.points.new({
            coords = vec3(hub.coords.x, hub.coords.y, hub.coords.z),
            distance = 15.0
        })

        function originPoint:nearby()
            local ped = PlayerPedId()
            local isInVeh = IsPedInAnyVehicle(ped, false)
            
            DrawMarker(2, self.coords.x, self.coords.y, self.coords.z + 0.5, 0, 0, 0, 180.0, 0, 0, 0.5, 0.5, 0.5, 241, 229, 66, 150, true, true, 2, false)
            
            if self.currentDistance < 2.0 then
                if isInVeh then
                    lib.showTextUI('Saia do veículo para coletar a carga')
                else
                    lib.showTextUI(('[E] Coletar Carga (%d/%d)'):format(m.collectedFromOrigin + 1, m.totalRequired))
                    if IsControlJustPressed(0, 38) then
                        local res = lib.callback.await('cidade_tycoon_freelance:server:freightAction', false, m.missionId, 'pickup_origin')
                        if res.ok then
                            applyMissionState(res.state, true)
                            playChatSound('pickup')
                            notifyClient('Carga coletada! Leve até o veículo.', 'success')
                            setupMissionPoints() -- Remove o ponto de coleta até guardar no carro
                        end
                    end
                end
            else
                lib.hideTextUI()
            end
        end
        table.insert(currentPoints, originPoint)

        ClientRuntimeState.deliveryBlip = AddBlipForCoord(hub.coords.x, hub.coords.y, hub.coords.z)
        SetBlipSprite(ClientRuntimeState.deliveryBlip, 478)
        SetBlipColour(ClientRuntimeState.deliveryBlip, 5)
        SetBlipRoute(ClientRuntimeState.deliveryBlip, true)
    end

    -- 2. Delivery Destination Point (Baseado no Ponto Atual definido pelo servidor)
    if m.phase == 'delivery' and m.deliveryPoints and m.currentPointIndex then
        local currentPoint = m.deliveryPoints[m.currentPointIndex]
        if currentPoint and currentPoint.delivered < currentPoint.required then
            local destPoint = lib.points.new({
                coords = vec3(currentPoint.coords.x, currentPoint.coords.y, currentPoint.coords.z),
                distance = 30.0
            })

            function destPoint:nearby()
                DrawMarker(1, self.coords.x, self.coords.y, self.coords.z - 1.0, 0, 0, 0, 0, 0, 0, 2.5, 2.5, 1.0, 44, 204, 138, 150, false, true, 2, false)
                if self.currentDistance < 2.5 then
                    if m.carryingBox then
                        lib.showTextUI(('[E] Entregar Caixa (%d/%d neste local)'):format(currentPoint.delivered + 1, currentPoint.required))
                        if IsControlJustPressed(0, 38) and not ClientRuntimeState.isActionBusy then
                            ClientRuntimeState.isActionBusy = true
                            CreateThread(function()
                                if lib.progressBar({ duration = 2000, label = 'Entregando...', disable = { move = true, car = true } }) then
                                    local res = lib.callback.await('cidade_tycoon_freelance:server:freightAction', false, m.missionId, 'deliver_box')
                                    if res.ok then
                                        applyMissionState(res.state, true)
                                        playChatSound('deliver')
                                        
                                        if res.state.completed then
                                            TriggerServerEvent('cidade_tycoon_freelance:server:completeFreelanceMission', m.missionId)
                                            lib.hideTextUI()
                                            cleanupMissionPoints()
                                            ClientRuntimeState.activeMission = nil
                                            TriggerEvent('cidade_tycoon_tablet:client:hideFreelanceHUD')
                                        else
                                            notifyClient('Entrega registrada! Verifique seu GPS.', 'success')
                                            setupMissionPoints() -- Atualiza blip para o próximo ponto se necessário
                                        end
                                    end
                                end
                                ClientRuntimeState.isActionBusy = false
                            end)
                        end
                    elseif m.inTrunk > 0 then
                        lib.showTextUI('Use o Olho (ALT) no veículo para retirar a carga')
                    elseif m.collectedFromOrigin < m.totalRequired then
                        lib.showTextUI('Volte ao Porto para coletar mais caixas!')
                    else
                        lib.hideTextUI()
                    end
                else
                    lib.hideTextUI()
                end
            end
            
            function destPoint:onExit()
                lib.hideTextUI()
            end
            table.insert(currentPoints, destPoint)
            
            -- Blip: Sempre aponta para o ponto atual
            ClientRuntimeState.deliveryBlip = AddBlipForCoord(currentPoint.coords.x, currentPoint.coords.y, currentPoint.coords.z)
            SetBlipSprite(ClientRuntimeState.deliveryBlip, 1)
            SetBlipColour(ClientRuntimeState.deliveryBlip, 5)
            SetBlipRoute(ClientRuntimeState.deliveryBlip, true)
        end
    end
end

RegisterNetEvent('cidade_tycoon_freelance:client:syncMission', function(mission)
    applyMissionState(mission, true)
end)

-- ==========================================
-- MISSION MONITOR (Damage & Logic)
-- ==========================================
CreateThread(function()
    while true do
        local wait = 2000
        if ClientRuntimeState.activeMission then
            wait = 500
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                local mission = ClientRuntimeState.activeMission
                if mission.carryingBox and not ClientRuntimeState.isActionBusy then
                    ClientRuntimeState.isActionBusy = true
                    toggleBoxVisual(false)
                    local netId = NetworkGetNetworkIdFromEntity(veh)
                    local res = lib.callback.await('cidade_tycoon_freelance:server:freightAction', false, mission.missionId, 'load_vehicle', netId)
                    if res.ok then
                        applyMissionState(res.state, true)
                        notifyClient(('Caixa guardada automaticamente (%d/%d).'):format(res.state.inTrunk, res.state.capacity), 'success')
                    else
                        TaskLeaveVehicle(ped, veh, 16)
                        notifyClient('Nao e possivel entrar no veiculo carregando esta caixa.', 'error')
                        CreateThread(function()
                            local timeout = GetGameTimer() + 3000
                            while IsPedInAnyVehicle(ped, false) and GetGameTimer() < timeout do Wait(100) end
                            if ClientRuntimeState.activeMission and ClientRuntimeState.activeMission.carryingBox then
                                toggleBoxVisual(true)
                            end
                        end)
                    end
                    ClientRuntimeState.isActionBusy = false
                end
                local speed = GetEntitySpeed(veh) * 3.6
                if speed > 40.0 then
                    -- Sample health and apply weighted damage
                    local health = GetVehicleBodyHealth(veh)
                    -- Simplified for audit: major speed drops or health loss trigger integrity loss
                end
            end
        end
        Wait(wait)
    end
end)

-- Exports
exports('TryStartFreelance', function(hubId, mode)
    local res = lib.callback.await('cidade_tycoon_freelance:server:startFreelanceMission', false, hubId, mode, nil, 'comum')
    if res.ok then
        applyMissionState(res.mission, true)
        notifyClient('Missão Iniciada!', 'success')
    else
        notifyClient(res.message, 'error')
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    cleanupMissionPoints()
    toggleBoxVisual(false)
    TriggerEvent('cidade_tycoon_tablet:client:hideFreelanceHUD')
end)

-- ==========================================
-- VEHICLE INTERACTION (OX_TARGET)
-- ==========================================
CreateThread(function()
    exports.ox_target:addGlobalVehicle({
        {
            name = 'tycoon_freelance_load',
            icon = 'fa-solid fa-box-open',
            label = 'Guardar Carga',
            distance = 2.5,
            canInteract = function(entity, distance, coords, name, bone)
                local m = ClientRuntimeState.activeMission
                if not m then return false end
                -- Deve estar carregando caixa, ter espaço no porta-malas e o porta-malas do carro deve estar perto
                if not m.carryingBox or m.inTrunk >= m.capacity or IsPedInAnyVehicle(PlayerPedId(), false) then return false end
                local netId = NetworkGetNetworkIdFromEntity(entity)
                return not m.vehicleNetId or m.vehicleNetId == netId
            end,
            onSelect = function(data)
                local m = ClientRuntimeState.activeMission
                if not m then return end
                if lib.progressBar({ duration = 1500, label = 'Guardando carga...', disable = { move = true, car = true } }) then
                    local netId = NetworkGetNetworkIdFromEntity(data.entity)
                    local res = lib.callback.await('cidade_tycoon_freelance:server:freightAction', false, m.missionId, 'load_vehicle', netId)
                    if res.ok then
                        applyMissionState(res.state, true)
                        playChatSound('place')
                        notifyClient('Carga guardada no veículo.', 'success')
                        setupMissionPoints() -- Atualiza caso precise mostrar o local de destino
                    else
                        notifyClient('Não foi possível guardar a carga.', 'error')
                    end
                end
            end
        },
        {
            name = 'tycoon_freelance_unload',
            icon = 'fa-solid fa-box',
            label = 'Retirar Carga',
            distance = 2.5,
            canInteract = function(entity, distance, coords, name, bone)
                local m = ClientRuntimeState.activeMission
                if not m then return false end
                -- Não pode estar com caixa na mão e deve ter carga no porta-malas
                if m.phase ~= 'delivery' or m.carryingBox or m.inTrunk <= 0 or IsPedInAnyVehicle(PlayerPedId(), false) then return false end
                local netId = NetworkGetNetworkIdFromEntity(entity)
                return not m.vehicleNetId or m.vehicleNetId == netId
            end,
            onSelect = function(data)
                local m = ClientRuntimeState.activeMission
                if not m then return end
                if lib.progressBar({ duration = 1500, label = 'Retirando carga...', disable = { move = true, car = true } }) then
                    local netId = NetworkGetNetworkIdFromEntity(data.entity)
                    local res = lib.callback.await('cidade_tycoon_freelance:server:freightAction', false, m.missionId, 'unload_vehicle', netId)
                    if res.ok then
                        applyMissionState(res.state, true)
                        playChatSound('place')
                        notifyClient('Carga retirada do veículo.', 'success')
                    else
                        notifyClient('Não foi possível retirar a carga.', 'error')
                    end
                end
            end
        }
    })
end)
