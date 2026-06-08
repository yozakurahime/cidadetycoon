local config = Config
local spawnedPeds = {}
local inWarehouse = false

-- ==========================================
-- EFEITOS DE ISOLAMENTO (Dimenção)
-- ==========================================

local function setWorldState(isPrivate)
    if isPrivate then
        inWarehouse = true
        
        -- Efeito Visual Industrial (Apenas cor/luz)
        SetTimecycleModifier('tunnel')
        SetTimecycleModifierStrength(0.5)
        
        -- Desativa o sincronizador global de clima/tempo para esta dimensão
        TriggerEvent('qb-weathersync:client:DisableSync')
        LocalPlayer.state:set('syncWeather', false, false)
        
        -- Aplica um clima fixo uma única vez
        SetRainLevel(0.0)
        SetWeatherTypePersist('EXTRASUNNY')
        SetWeatherTypeNow('EXTRASUNNY')
        SetWeatherTypeNowPersist('EXTRASUNNY')
        NetworkOverrideClockTime(12, 0, 0)
    else
        inWarehouse = false
        
        -- Restaura filtros de cor
        ClearTimecycleModifier()
        
        -- Reativa o sincronizador global e deixa ele tomar o controle
        LocalPlayer.state:set('syncWeather', true, false)
        TriggerEvent('qb-weathersync:client:EnableSync')
    end
end

-- ==========================================
-- COMANDO DE EMERGÊNCIA (Caso a tela trave)
-- ==========================================
RegisterCommand('fixpreto', function()
    DoScreenFadeIn(500)
    setWorldState(false)
    SetNuiFocus(false, false)
    FreezeEntityPosition(PlayerPedId(), false)
    lib.notify({ title = 'Sistema', description = 'Visual e filtros restaurados com sucesso.', type = 'success' })
end)

RegisterCommand('tycoon_coords', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local output = string.format('vec4(%.2f, %.2f, %.2f, %.2f)', coords.x, coords.y, coords.z, heading)
    print(output)
    if lib then lib.setClipboard(output) end
    lib.notify({ title = 'Coordenadas Copiadas', description = output, type = 'inform' })
end)

local function safeTeleport(ped, x, y, z, h)
    RequestCollisionAtCoord(x, y, z)
    SetEntityCoords(ped, x, y, z, false, false, false, false)
    SetEntityHeading(ped, h)
    
    local timer = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(ped) do
        Wait(10)
        -- Failsafe: se demorar mais que 3 segundos para carregar o mapa, continua
        if GetGameTimer() - timer > 3000 then break end
    end
end

local function setupIndustrialPortal()
    local model = "s_m_y_dockwork_01" -- Nome do modelo seguro
    lib.requestModel(GetHashKey(model), 5000)
    
    local coords = config.Entrance.coords
    local ped = CreatePed(4, GetHashKey(model), coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    if config.Entrance.scenario then TaskStartScenarioInPlace(ped, config.Entrance.scenario, 0, true) end
    spawnedPeds[1] = ped

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'production_open_menu',
            icon = 'fa-solid fa-industry',
            label = 'Acessar Complexo Industrial',
            onSelect = function()
                openEntranceMenu()
            end
        },
        {
            name = 'production_buy_warehouse',
            icon = 'fa-solid fa-file-contract',
            label = 'Fundar Nova Indústria (R$ 500k)',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Registrar Indústria',
                    content = 'Deseja investir R$ 500.000 para fundar sua própria empresa de manufatura?',
                    centered = true,
                    cancel = true
                })
                if alert == 'confirm' then
                    local result = lib.callback.await('cidade_tycoon_production:server:createCompany', false)
                    if result and result.ok then
                        lib.notify({ title = 'Indústria', description = result.message, type = 'success' })
                    else
                        lib.notify({ title = 'Indústria', description = result and result.message or 'Erro ao registrar empresa', type = 'error' })
                    end
                end
            end
        }
    })
end

function openEntranceMenu()
    local data = lib.callback.await('cidade_tycoon_production:server:getEntranceData', false)
    if not data then return end

    local options = {}
    if #data.companies > 0 then
        for _, comp in ipairs(data.companies) do
            table.insert(options, {
                title = comp.name,
                description = ('Acessar galpão como %s'):format(comp.role == 'owner' and 'Proprietário' or comp.role),
                icon = comp.role == 'owner' and 'building' or 'briefcase',
                onSelect = function()
                    enterWarehouse(comp.id)
                end
            })
        end
    else
        table.insert(options, {
            title = 'Sem Acesso',
            description = 'Você não possui permissão para entrar em nenhum galpão.',
            icon = 'lock',
            disabled = true
        })
    end

    lib.registerContext({ id = 'production_entrance_menu', title = 'Complexo Industrial', options = options })
    lib.showContext('production_entrance_menu')
end

local spawnedMachines = {}

local function despawnCompanyMachines()
    for _, prop in pairs(spawnedMachines) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    spawnedMachines = {}
end

local function spawnCompanyMachines(level)
    despawnCompanyMachines()
    
    for i, slot in ipairs(config.MachineSlots) do
        if level >= slot.minLevel then
            local hash = GetHashKey(slot.model)
            lib.requestModel(hash, 5000)
            
            if HasModelLoaded(hash) then
                local prop = CreateObject(hash, slot.coords.x, slot.coords.y, slot.coords.z, false, false, false)
                SetEntityHeading(prop, slot.coords.w)
                FreezeEntityPosition(prop, true)
                
                -- Add ox_target
                local options = {}
                for prodId, prodData in pairs(config.Products) do
                    if prodData.type == slot.type and level >= prodData.minLevel then
                        table.insert(options, {
                            name = 'prod_machine_' .. i .. '_' .. prodId,
                            icon = 'fa-solid fa-gears',
                            label = 'Produzir: ' .. prodData.label,
                            onSelect = function()
                                TriggerEvent('cidade_tycoon_production:client:startProduction', prodId, prop)
                            end
                        })
                    end
                end
                
                exports.ox_target:addLocalEntity(prop, options)
                table.insert(spawnedMachines, prop)
            end
        end
    end
end

local exitPoint = nil

function enterWarehouse(companyId)
    local ped = PlayerPedId()
    
    DoScreenFadeOut(800)
    Wait(1000)
    
    PlaySoundFrontend(-1, "CLOSED", "MP_PROPERTIES_ELEVATOR_DOORS", 1)
    
    -- Teleporte para o Interior do Galpão (CE Warehouse)
    safeTeleport(ped, config.Interior.coords.x, config.Interior.coords.y, config.Interior.coords.z, config.Interior.coords.w)
    TriggerServerEvent('cidade_tycoon_production:server:enterWarehouse', companyId)
    
    local companyLevel = lib.callback.await('cidade_tycoon_production:server:getCompanyLevel', false, companyId)
    spawnCompanyMachines(companyLevel or 1)

    setWorldState(true)
    
    Wait(500)
    ShutdownLoadingScreen()
    DoScreenFadeIn(800)
    
    if exitPoint then exitPoint:remove() end
    exitPoint = lib.points.new({
        coords = config.Interior.exitCoords.xyz,
        distance = 2.0
    })
    
    function exitPoint:nearby()
        DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 226, 179, 90, 150, false, true, 2, false)
        if self.currentDistance < 1.5 then
            lib.showTextUI('[E] Sair do Galpão')
            if IsControlJustPressed(0, 38) then
                if exitPoint then exitPoint:remove() exitPoint = nil end
                lib.hideTextUI()
                leaveWarehouse()
            end
        else
            lib.hideTextUI()
        end
    end

    -- Thread de Barreira (Garante que só rode uma vez por entrada)
    CreateThread(function()
        local centerCoords = config.Interior.coords.xyz
        local maxDistance = 45.0 -- Raio maior para o galpão real
        while inWarehouse do
            Wait(1000)
            local pPed = PlayerPedId()
            if #(GetEntityCoords(pPed) - centerCoords) > maxDistance then
                SetEntityCoordsNoOffset(pPed, centerCoords.x, centerCoords.y, centerCoords.z, false, false, false)
                lib.notify({ title = 'Aviso de Segurança', description = 'Você não pode sair dos limites do galpão.', type = 'warning' })
            end
        end
    end)
end

function leaveWarehouse()
    local ped = PlayerPedId()
    
    -- Muda o inWarehouse antes do teleporte para a barreira não puxar de volta
    inWarehouse = false
    
    DoScreenFadeOut(500)
    Wait(600)
    
    PlaySoundFrontend(-1, "OPENED", "MP_PROPERTIES_ELEVATOR_DOORS", 1)
    
    -- Teleporte seguro para a rua
    safeTeleport(ped, config.Entrance.coords.x, config.Entrance.coords.y, config.Entrance.coords.z, config.Entrance.coords.w)
    TriggerServerEvent('cidade_tycoon_production:server:leaveWarehouse')
    
    -- Remove isolamento visual
    setWorldState(false)
    despawnCompanyMachines()
    
    Wait(500)
    ShutdownLoadingScreen()
    DoScreenFadeIn(500)
end

-- ==========================================
-- PRODUÇÃO ATIVA (MINIGAMES)
-- ==========================================

RegisterNetEvent('cidade_tycoon_production:client:startProduction', function(prodId, prop)
    local prodData = config.Products[prodId]
    if not prodData then return end
    
    local ped = PlayerPedId()

    -- Verifica se tem os materiais no inventário
    local hasItems = lib.callback.await('cidade_tycoon_production:server:checkItems', false, prodData.requirements)
    if not hasItems then
        lib.notify({ title = 'Produção Falhou', description = 'Você não possui os materiais necessários.', type = 'error' })
        return
    end

    -- Vira para a máquina e inicia animação
    TaskTurnPedToFaceEntity(ped, prop, -1)
    Wait(1000)
    
    -- Animação varia de acordo com o tipo de item (legal = ferramentas, ilegal = quimicos)
    local animScenario = prodData.type == 'illegal' and "PROP_HUMAN_BUM_BIN" or "WORLD_HUMAN_WELDING"
    TaskStartScenarioInPlace(ped, animScenario, 0, true)

    -- Barra de progresso para simular o tempo de processamento
    if lib.progressBar({
        duration = prodData.processTime or 15000,
        label = 'Processando: ' .. prodData.label,
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true }
    }) then
        -- Se terminou a barra, faz um Skill Check
        local success = lib.skillCheck({'easy', 'easy', 'medium'}, {'w', 'a', 's', 'd'})
        
        ClearPedTasks(ped)
        
        if success then
            TriggerServerEvent('cidade_tycoon_production:server:finishProduction', prodId, true)
            lib.notify({ title = 'Sucesso', description = 'Produto fabricado com perfeição.', type = 'success' })
        else
            TriggerServerEvent('cidade_tycoon_production:server:finishProduction', prodId, false)
            lib.notify({ title = 'Falha', description = 'Você errou no processo e perdeu alguns materiais.', type = 'error' })
        end
    else
        -- Cancelado
        ClearPedTasks(ped)
        lib.notify({ title = 'Cancelado', description = 'Processo de manufatura interrompido.', type = 'warning' })
    end
end)

CreateThread(function()
    setupIndustrialPortal()
end)

CreateThread(function()
    local blip = AddBlipForCoord(config.Entrance.coords.x, config.Entrance.coords.y, config.Entrance.coords.z)
    SetBlipSprite(blip, 365)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Complexo Industrial")
    EndTextCommandSetBlipName(blip)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    setWorldState(false)
    DoScreenFadeIn(100) -- Failsafe
    despawnCompanyMachines()
    for _, ped in pairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)