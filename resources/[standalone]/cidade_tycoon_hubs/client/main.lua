local config = TycoonHubs.Config

local spawnedHubEntities = { peds = {}, doors = {} }
local hubPoints = {}
local interiorCache = {}

local function DebugLog(text, ...)
    print(string.format("^3[Tycoon:Hubs]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- WORLD STABILIZATION (Optimized Logic)
-- ==========================================

local function stabilizeInterior(coords)
    local interiorId = GetInteriorAtCoords(coords.x, coords.y, coords.z)
    if interiorId ~= 0 then
        if not interiorCache[interiorId] then
            PinInteriorInMemory(interiorId)
            -- Refresh only once when discovered
            if not IsInteriorReady(interiorId) then
                RefreshInterior(interiorId)
            end
            interiorCache[interiorId] = true
            DebugLog("Interior %d estabilizado.", interiorId)
        end
    end
end

-- Door management moved out of per-frame for stability
local function manageDoors(coords)
    local doorModels = {
        GetHashKey("v_ilev_lester_door"),
        GetHashKey("v_ilev_lester_door2"),
        GetHashKey("v_ilev_postop_door"),
        GetHashKey("v_ilev_postop_door2")
    }

    for _, model in ipairs(doorModels) do
        local door = GetClosestObjectOfType(coords.x, coords.y, coords.z, 25.0, model, false, false, false)
        if DoesEntityExist(door) then
            -- Set to open state and disable collision/visibility
            SetEntityHeading(door, 90.0) 
            FreezeEntityPosition(door, true)
            SetEntityCollision(door, false, false)
            SetEntityAlpha(door, 0, false)
        end
    end
end

-- ==========================================
-- UNIFIED HUB POINTS (ox_lib)
-- ==========================================

local function setupHubManager()
    -- Global IPL Requests
    RequestIpl("v_postop")
    RequestIpl("v_lesters")
    RequestIpl("v_lesters_milo_")

    for _, hub in ipairs(config.hubs) do
        local hubPoint = lib.points.new({
            coords = vec3(hub.coords.x, hub.coords.y, hub.coords.z),
            distance = 250.0 
        })

        -- IDEMPOTENT NPC SPAWN & INITIAL STABILIZATION
        function hubPoint:onEnter()
            -- Stabilize area as soon as we approach
            stabilizeInterior(self.coords)
            manageDoors(self.coords)

            if not spawnedHubEntities.peds[hub.id] then
                local model = hub.pedModel
                if type(model) == "string" then model = GetHashKey(model) end
                
                if IsModelValid(model) then
                    RequestModel(model)
                    local timer = GetGameTimer()
                    while not HasModelLoaded(model) and (GetGameTimer() - timer) < 5000 do
                        Wait(10)
                    end

                    if HasModelLoaded(model) then
                        local ped = CreatePed(4, model, hub.coords.x, hub.coords.y, hub.coords.z - 1.0, hub.coords.w, false, false)
                        SetEntityInvincible(ped, true)
                        SetBlockingOfNonTemporaryEvents(ped, true)
                        FreezeEntityPosition(ped, true)
                        if hub.scenario then TaskStartScenarioInPlace(ped, hub.scenario, 0, true) end
                        
                        exports.ox_target:addLocalEntity(ped, {
                            {
                                name = 'tycoon_hub_contracts_' .. hub.id,
                                icon = 'fa-solid fa-truck-ramp-box',
                                label = 'Contratos Rápidos (Freelance)',
                                onSelect = function()
                                    exports.cidade_tycoon_freelance:TryStartFreelance(hub.id, 'land')
                                end
                            },
                            {
                                name = 'tycoon_hub_purchase_' .. hub.id,
                                icon = 'fa-solid fa-building-circle-check',
                                label = 'Adquirir Sede/Galpão (R$ ' .. hub.purchasePrice .. ')',
                                canInteract = function()
                                    local profile = LocalPlayer.state.tycoonProfile
                                    return not profile or not profile.hasCompany
                                end,
                                onSelect = function()
                                    CreateThread(function()
                                        local alert = lib.alertDialog({
                                            header = 'Adquirir Sede',
                                            content = ('Deseja adquirir o galpão "%s" como sua sede logística por R$ %s?'):format(hub.name, hub.purchasePrice),
                                            centered = true,
                                            cancel = true,
                                            labels = { confirm = 'Confirmar', cancel = 'Cancelar' }
                                        })
                                        if alert == 'confirm' then
                                            local result = lib.callback.await('cidade_tycoon_tablet:server:purchaseCompany', false, hub.id)
                                            if result and result.ok then
                                                exports.qbx_core:Notify(result.message, 'success')
                                            else
                                                exports.qbx_core:Notify(result and result.message or 'Erro ao comprar galpão', 'error')
                                            end
                                        end
                                    end)
                                end
                            },
                            {
                                name = 'tycoon_hub_terminal_' .. hub.id,
                                icon = 'fa-solid fa-tablet-screen-button',
                                label = 'Acessar Terminal (Tablet)',
                                onSelect = function()
                                    exports.cidade_tycoon_tablet:OpenTablet()
                                end
                            }
                        })
                        spawnedHubEntities.peds[hub.id] = ped
                    end
                else
                    DebugLog("^1Erro: Modelo de Ped inválido no Hub %d: %s^7", hub.id, tostring(hub.pedModel))
                end
            end
        end

        function hubPoint:nearby()
            local dist = self.currentDistance
            
            -- Visual Markers only (no heavy logic here)
            if dist < 15.0 then
                DrawMarker(2, hub.coords.x, hub.coords.y, hub.coords.z + 1.2, 0, 0, 0, 180.0, 0, 0, 0.3, 0.3, 0.3, 241, 229, 66, 150, true, true, 2, false)
                
                local profile = LocalPlayer.state.tycoonProfile
                if profile and profile.hasCompany and profile.companyWarehouseId == hub.id then
                    if hub.productionCoords then
                        local prodCoords = vec3(hub.productionCoords.x, hub.productionCoords.y, hub.productionCoords.z)
                        local officeDist = #(GetEntityCoords(PlayerPedId()) - prodCoords)
                        if officeDist < 10.0 then
                            DrawMarker(1, prodCoords.x, prodCoords.y, prodCoords.z - 1.0, 0, 0, 0, 0, 0, 0, 1.2, 1.2, 0.5, 226, 179, 90, 100, false, true, 2, false)
                            if officeDist < 1.5 then
                                if not lib.isTextUIOpen() then lib.showTextUI('[E] Escritório da Empresa') end
                                if IsControlJustPressed(0, 38) then
                                    exports.cidade_tycoon_tablet:OpenTablet()
                                end
                            else
                                if lib.isTextUIOpen() then lib.hideTextUI() end
                            end
                        end
                    end
                end
            end
        end

        function hubPoint:onExit()
            if spawnedHubEntities.peds[hub.id] then
                DeleteEntity(spawnedHubEntities.peds[hub.id])
                spawnedHubEntities.peds[hub.id] = nil
            end
        end

        table.insert(hubPoints, hubPoint)
    end
end

-- ==========================================
-- BLIPS & INITIALIZATION
-- ==========================================

local function createBlips()
    for _, hub in ipairs(config.hubs) do
        local blip = AddBlipForCoord(hub.coords.x, hub.coords.y, hub.coords.z)
        SetBlipSprite(blip, 477)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 27)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(hub.name)
        EndTextCommandSetBlipName(blip)
    end
end

CreateThread(function()
    createBlips()
    setupHubManager()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in pairs(spawnedHubEntities.peds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)

exports('GetAllHubs', function()
    return config.hubs
end)
