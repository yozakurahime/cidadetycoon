local config = TycoonHubs.Config

local spawnedHubEntities = { peds = {}, doors = {} }
local hubPoints = {}
local interiorCache = {}

local function DebugLog(text, ...)
    print(string.format("^3[Tycoon:Hubs]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- WORLD STABILIZATION (Elite Logic)
-- ==========================================

local function stabilizeInterior(coords)
    local interiorId = GetInteriorAtCoords(coords.x, coords.y, coords.z)
    if interiorId ~= 0 then
        if not interiorCache[interiorId] then
            PinInteriorInMemory(interiorId)
            interiorCache[interiorId] = true
            DebugLog("Interior %d fixado na memória.", interiorId)
        end
        
        if not IsInteriorReady(interiorId) then
            RefreshInterior(interiorId)
        end
    end
end

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
            -- Instead of deleting (desync risk), we control them
            SetEntityHeading(door, 90.0) -- Open state
            FreezeEntityPosition(door, true)
            SetEntityCollision(door, false, false) -- No collision
            SetEntityAlpha(door, 0, false) -- Invisible but exists
        end
    end
end

-- ==========================================
-- UNIFIED HUB POINTS (ox_lib)
-- ==========================================

local function setupHubManager()
    -- 1. Global IPL Requests
    RequestIpl("v_postop")
    RequestIpl("v_lesters")
    RequestIpl("v_lesters_milo_")

    for _, hub in ipairs(config.hubs) do
        local hubPoint = lib.points.new({
            coords = vec3(hub.coords.x, hub.coords.y, hub.coords.z),
            distance = 250.0 -- Wide predictive range
        })

        -- IDEMPOTENT NPC SPAWN
        function hubPoint:onEnter()
            if not spawnedHubEntities.peds[hub.id] then
                local success = lib.requestModel(hub.pedModel, 5000)
                if success then
                    local ped = CreatePed(4, hub.pedModel, hub.coords.x, hub.coords.y, hub.coords.z - 1.0, hub.coords.w, false, false)
                    SetEntityInvincible(ped, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    FreezeEntityPosition(ped, true)
                    if hub.scenario then TaskStartScenarioInPlace(ped, hub.scenario, 0, true) end
                    
                    exports.ox_target:addLocalEntity(ped, {
                        {
                            name = 'tycoon_hub_contracts_' .. hub.id,
                            icon = 'fa-solid fa-truck-ramp-box',
                            label = (hub.title or 'Despachante') .. ': Contratos',
                            onSelect = function()
                                exports.cidade_tycoon_freelance:TryStartFreelance(hub.id, 'land')
                            end
                        }
                    })
                    spawnedHubEntities.peds[hub.id] = ped
                end
            end
        end

        function hubPoint:nearby()
            local dist = self.currentDistance
            local pCoords = self.coords

            -- 1. Stabilization (Throttled)
            if dist < 100.0 then
                stabilizeInterior(pCoords)
                manageDoors(pCoords)
            end

            -- 2. Visual Markers (Markers requested by user)
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
                                lib.showTextUI('[E] Escritório da Empresa')
                                if IsControlJustPressed(0, 38) then
                                    exports.cidade_tycoon_tablet:OpenTablet()
                                end
                            else
                                lib.hideTextUI()
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
