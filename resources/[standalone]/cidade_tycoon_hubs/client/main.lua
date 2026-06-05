local config = require 'config.hubs'

local spawnedPeds = {}
local hubBlips = {}

local function DebugLog(text, ...)
    print(string.format("^3[Tycoon:Hubs]^7 %s", string.format(text, ...)))
end

local function DebugError(text, ...)
    print(string.format("^1[Tycoon-Error:Hubs]^7 %s", string.format(text, ...)))
end

local function DebugSuccess(text, ...)
    print(string.format("^2[Tycoon-Success:Hubs]^7 %s", string.format(text, ...)))
end

local function createHubBlips()
    for _, hub in ipairs(config.hubs) do
        local blip = AddBlipForCoord(hub.coords.x, hub.coords.y, hub.coords.z)
        SetBlipSprite(blip, 477) -- Sprite de Caminhão
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.9)
        SetBlipColour(blip, 27) -- Roxo (ou 83 para roxo mais vivo)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(hub.name)
        EndTextCommandSetBlipName(blip)
        table.insert(hubBlips, blip)
    end

    if config.shops then
        for _, shop in ipairs(config.shops) do
            local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
            SetBlipSprite(blip, shop.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.7)
            SetBlipColour(blip, shop.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(shop.name)
            EndTextCommandSetBlipName(blip)
            table.insert(hubBlips, blip)
        end
    end
end

local function initHubInteriors()
    -- Hub 2: Lester's Factory (La Mesa)
    -- Requesting all possible variations to ensure loading
    RequestIpl("v_lesters")
    RequestIpl("v_lesters_milo_")
    RequestIpl("v_lesters_milo_work")
    RequestIpl("v_lesters_milo_office")
    
    -- Removendo portas que bloqueiam interiores vanilla
    local doorModels = {
        `v_ilev_lester_door`,
        `v_ilev_lester_door2`,
        `v_ilev_postop_door`,
        `v_ilev_postop_door2`
    }

    CreateThread(function()
        while true do
            local pCoords = GetEntityCoords(PlayerPedId())
            
            -- Force Interior Refresh when near a Hub
            for _, hub in ipairs(config.hubs) do
                if #(pCoords - vec3(hub.coords.x, hub.coords.y, hub.coords.z)) < 60.0 then
                    local interiorId = GetInteriorAtCoords(hub.coords.x, hub.coords.y, hub.coords.z)
                    if interiorId ~= 0 then
                        PinInteriorInMemory(interiorId)
                        if not IsInteriorReady(interiorId) then
                            RefreshInterior(interiorId)
                        end
                    end
                end
            end

            -- Delete Blocking Doors
            for _, model in ipairs(doorModels) do
                local door = GetClosestObjectOfType(pCoords, 50.0, model, false, false, false)
                if DoesEntityExist(door) then
                    SetEntityAsMissionEntity(door, true, true)
                    DeleteEntity(door)
                end
            end
            Wait(3000) 
        end
    end)
end

RegisterCommand('tycoon_load_interiors', function()
    initHubInteriors()
    exports.qbx_core:Notify('Recarregando interiores Tycoon...', 'inform')
end, false)

local function spawnHubPeds()
    DebugLog("Iniciando spawn de NPCs...")
    initHubInteriors()

    for _, hub in ipairs(config.hubs) do
        local model = hub.pedModel
        
        -- Garante carregamento da área
        RequestCollisionAtCoord(hub.coords.x, hub.coords.y, hub.coords.z)
        Wait(100) -- Pequeno delay para estabilizar o mundo

        local success = lib.requestModel(model, 10000)
        if success then
            local ped = CreatePed(4, model, hub.coords.x, hub.coords.y, hub.coords.z - 1.0, hub.coords.w, false, false)
            SetEntityAsMissionEntity(ped, true, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            FreezeEntityPosition(ped, true)
            SetPedCanRagdoll(ped, false)
            SetPedDiesInWater(ped, false)
            SetEntityAsMissionEntity(ped, true, true) -- Double check
            SetModelAsNoLongerNeeded(model)

            if hub.scenario then
                TaskStartScenarioInPlace(ped, hub.scenario, 0, true)
            end

            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'tycoon_open_freelance_' .. hub.id,
                    icon = 'fa-solid fa-truck-ramp-box',
                    label = (hub.title or 'Despachante') .. ': Contratos',
                    distance = 2.5,
                    onSelect = function()
                        local playerPed = PlayerPedId()
                        local veh = GetVehiclePedIsIn(playerPed, false)
                        local mode = 'land' -- Default

                        if veh ~= 0 then
                            local class = GetVehicleClass(veh)
                            if class == 14 and hub.modes.water then
                                mode = 'water'
                            elseif (class == 15 or class == 16) and hub.modes.air then
                                mode = 'air'
                            end
                        end

                        exports.cidade_tycoon_freelance:TryStartFreelance(hub.id, mode)
                    end
                },
                {
                    name = 'tycoon_manage_company_' .. hub.id,
                    icon = 'fa-solid fa-briefcase',
                    label = (hub.title or 'Despachante') .. ': Gerenciar Empresa',
                    distance = 2.5,
                    canInteract = function()
                        local profile = LocalPlayer.state.tycoonProfile
                        return profile and profile.hasCompany and profile.companyWarehouseId == hub.id
                    end,
                    onSelect = function()
                        exports.cidade_tycoon_tablet:OpenTablet()
                        -- TODO: Direct route to business app could be added here
                    end
                }
            })
            table.insert(spawnedPeds, ped)
            DebugSuccess("Spawnado NPC Hub: " .. hub.name)
            SetModelAsNoLongerNeeded(model)
        else
            DebugError("Falha ao carregar modelo para o Hub: " .. hub.name)
        end
    end

    if config.shops then
        DebugLog("Iniciando spawn de Lojas (" .. #config.shops .. " encontradas)...")
        for _, shop in ipairs(config.shops) do
            local model = shop.pedModel
            DebugLog("Solicitando modelo Loja: " .. model)

            local success = lib.requestModel(model, 10000)
            if success then
                local ped = CreatePed(4, model, shop.coords.x, shop.coords.y, shop.coords.z - 1.0, shop.coords.w, false, false)
                SetEntityAsMissionEntity(ped, true, true)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                FreezeEntityPosition(ped, true)

                if shop.scenario then
                    TaskStartScenarioInPlace(ped, shop.scenario, 0, true)
                end

                local options = {}
                local labelPrefix = (shop.title or 'Vendedor') .. ': '

                if shop.type == 'market' then
                    table.insert(options, {
                        name = 'tycoon_open_market_' .. shop.id,
                        icon = 'fa-solid fa-car',
                        label = labelPrefix .. 'Ver Catálogo',
                        onSelect = function()
                            exports.cidade_tycoon_market:OpenVehicleMarket()
                        end
                    })
                elseif shop.type == 'autoparts' then
                    table.insert(options, {
                        name = 'tycoon_open_autoparts_' .. shop.id,
                        icon = 'fa-solid fa-gears',
                        label = labelPrefix .. 'Comprar Peças',
                        onSelect = function()
                            exports.cidade_tycoon_autoparts:OpenAutoPartsShop()
                        end
                    })
                elseif shop.type == 'cityhall' then
                    table.insert(options, {
                        name = 'tycoon_open_cityhall_' .. shop.id,
                        icon = 'fa-solid fa-building-columns',
                        label = labelPrefix .. 'Gabinete',
                        onSelect = function()
                            ExecuteCommand('cityhall')
                        end
                    })
                elseif shop.type == 'workshop' then
                    table.insert(options, {
                        name = 'tycoon_open_workshop_' .. shop.id,
                        icon = 'fa-solid fa-screwdriver-wrench',
                        label = labelPrefix .. 'Acessar Oficina',
                        onSelect = function()
                            exports.cidade_tycoon_maintenance:OpenWorkshopMenu(shop.id)
                        end
                    })
                end

                exports.ox_target:addLocalEntity(ped, options)
                table.insert(spawnedPeds, ped)
                DebugSuccess("Spawnado NPC Loja: " .. shop.name)
                SetModelAsNoLongerNeeded(model)
            else
                DebugError("Falha ao carregar modelo para a Loja: " .. shop.name)
            end
        end
    end
end

CreateThread(function()
    createHubBlips()
    spawnHubPeds()
end)

CreateThread(function()
    while true do
        local wait = 1500
        local profile = LocalPlayer.state.tycoonProfile
        
        if profile and profile.hasCompany then
            local hub = config.hubs[profile.companyWarehouseId]
            if hub and hub.productionCoords then
                local playerCoords = GetEntityCoords(PlayerPedId())
                local dist = #(playerCoords - hub.productionCoords)
                
                if dist < 20.0 then
                    wait = 0
                    DrawMarker(2, hub.productionCoords.x, hub.productionCoords.y, hub.productionCoords.z + 0.5, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.4, 0.4, 0.4, 226, 179, 90, 150, true, true, 2, false, nil, nil, false)
                    
                    if dist < 2.0 then
                        lib.showTextUI('Pressione [E] para Escritório da Empresa', { position = "right-center" })
                        if IsControlJustPressed(0, 38) then
                            exports.cidade_tycoon_tablet:OpenTablet()
                        end
                    else
                        lib.hideTextUI()
                    end
                end
            end
        end
        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    for _, blip in ipairs(hubBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end)
