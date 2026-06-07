local spawnedEntities = {}

local function notifyClient(message, type)
    exports.qbx_core:Notify(message, type or 'inform')
end

-- City Hall interactions
function OpenCityHallMenu()
    local dashboard = lib.callback.await('cidade_tycoon_cityhall:server:getDashboard', false)
    if not dashboard then
        notifyClient('Falha ao carregar dados da Prefeitura.', 'error')
        return
    end

    local options = {
        {
            title = 'Pagar Imposto Territorial',
            description = ('Sua taxa atual é de $%d. Streak: %d'):format(dashboard.taxAmount, dashboard.taxStreak),
            icon = 'building-columns',
            onSelect = function()
                local res = lib.callback.await('cidade_tycoon_cityhall:server:payTaxes', false)
                notifyClient(res.message, res.ok and 'success' or 'error')
            end
        }
    }

    for _, lic in ipairs(dashboard.licenses) do
        table.insert(options, {
            title = lic.label,
            description = lic.owned and 'Voce ja possui esta licença.' or ('Custo: $%d | Reputacao: %d'):format(lic.cost, lic.requiredReputation),
            icon = 'id-card',
            disabled = lic.owned or not lic.canBuy,
            onSelect = function()
                -- Animation: Sign documents
                TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_CLIPBOARD", 0, true)
                Wait(3000)
                ClearPedTasks(PlayerPedId())
                
                local res = lib.callback.await('cidade_tycoon_cityhall:server:purchaseLicense', false, lic.key)
                notifyClient(res.message, res.ok and 'success' or 'error')
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_cityhall_menu',
        title = 'Gabinete da Prefeitura Tycoon',
        options = options
    })
    lib.showContext('tycoon_cityhall_menu')
end

-- World Interaction Points
CreateThread(function()
    for key, loc in pairs(Config.Locations) do
        if loc.type == 'npc' then
            RequestModel(GetHashKey(loc.model))
            while not HasModelLoaded(GetHashKey(loc.model)) do Wait(100) end
            
            local ped = CreatePed(4, GetHashKey(loc.model), loc.coords.x, loc.coords.y, loc.coords.z - 1.0, loc.coords.w, false, false)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            table.insert(spawnedEntities, ped)

            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'cityhall_npc_' .. key,
                    icon = loc.icon,
                    label = loc.label,
                    onSelect = OpenCityHallMenu,
                    distance = 2.5
                }
            })
        elseif loc.type == 'prop' then
            local obj = CreateObject(GetHashKey(loc.model), loc.coords.x, loc.coords.y, loc.coords.z - 1.0, false, false, false)
            FreezeEntityPosition(obj, true)
            table.insert(spawnedEntities, obj)

            exports.ox_target:addLocalEntity(obj, {
                {
                    name = 'cityhall_kiosk_' .. key,
                    icon = loc.icon,
                    label = loc.label,
                    onSelect = OpenCityHallMenu,
                    distance = 2.5
                }
            })
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, entity in ipairs(spawnedEntities) do
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
end)

RegisterCommand('cityhall', function()
    OpenCityHallMenu()
end, false)
