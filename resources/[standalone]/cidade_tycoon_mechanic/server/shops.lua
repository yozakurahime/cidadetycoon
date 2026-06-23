-- server/shops.lua

local jsonFile = 'server/shops_config.json'

local defaultShops = {
    ['mechanic_1'] = {
        label = 'Oficina Aeroporto',
        npc = { x = -1148.9711, y = -1999.9376, z = 13.1803, h = 128.4388, model = 's_m_y_xmech_01' },
        custom_spots = {
            { x = -1154.26, y = -2007.82, z = 13.18 },
            { x = -1158.07, y = -2011.66, z = 13.18 },
            { x = -1140.68, y = -1999.07, z = 13.18 }
        },
        warehouse_spot = { x = -1152.0, y = -2001.0, z = 13.18 }
    },
    ['mechanic_2'] = {
        label = 'Oficina Burton',
        npc = { x = -346.9582, y = -133.9218, z = 39.0096, h = 246.4790, model = 's_m_y_xmech_02' },
        custom_spots = {
            { x = -340.5, y = -138.5, z = 39.0 },
            { x = -343.8, y = -145.2, z = 39.0 },
            { x = -350.2, y = -136.8, z = 39.0 }
        },
        warehouse_spot = { x = -345.5, y = -139.0, z = 39.0 }
    }
}

local currentShops = {}

local function updateGlobalStates()
    local customSpots = {}
    local warehouseSpots = {}
    local npcSpots = {}

    for shopId, data in pairs(currentShops) do
        if data.custom_spots then
            for _, spot in ipairs(data.custom_spots) do
                table.insert(customSpots, { x = spot.x, y = spot.y, z = spot.z })
            end
        end
        if data.warehouse_spot then
            table.insert(warehouseSpots, {
                shopId = shopId,
                coords = data.warehouse_spot
            })
        end
        if data.npc then
            table.insert(npcSpots, {
                shopId = shopId,
                label = data.label,
                coords = data.npc
            })
        end
    end

    GlobalState['tycoon:customs_spots'] = customSpots
    GlobalState['tycoon:warehouse_spots'] = warehouseSpots
    GlobalState['tycoon:mechanic_npcs'] = npcSpots
end

local function loadShops()
    local content = LoadResourceFile(GetCurrentResourceName(), jsonFile)
    if content then
        local success, parsed = pcall(json.decode, content)
        if success and parsed then
            currentShops = parsed
        else
            currentShops = defaultShops
        end
    else
        currentShops = defaultShops
        SaveResourceFile(GetCurrentResourceName(), jsonFile, json.encode(defaultShops, { indent = true }), -1)
    end
    updateGlobalStates()
end

local function saveShops()
    SaveResourceFile(GetCurrentResourceName(), jsonFile, json.encode(currentShops, { indent = true }), -1)
    updateGlobalStates()
end

CreateThread(function()
    Wait(500)
    loadShops()
end)

lib.callback.register('cidade_tycoon_mechanic:server:updateShopSpot', function(source, shopId, spotType, index, coords)
    local src = source
    local job = exports.cidade_tycoon_core:GetPlayerJob(src)
    if not job then return { ok = false } end

    -- Check job and boss status
    if job.name ~= 'mechanic' or not job.isboss then
        return { ok = false, message = 'Apenas o dono/líder da oficina pode gerenciar os pontos.' }
    end

    if not currentShops[shopId] then
        return { ok = false, message = 'Oficina não registrada.' }
    end

    if spotType == 'custom' then
        if not currentShops[shopId].custom_spots then
            currentShops[shopId].custom_spots = {}
        end
        currentShops[shopId].custom_spots[index] = { x = coords.x, y = coords.y, z = coords.z }
    elseif spotType == 'warehouse' then
        currentShops[shopId].warehouse_spot = { x = coords.x, y = coords.y, z = coords.z }
    elseif spotType == 'npc' then
        currentShops[shopId].npc = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            h = coords.w or 0.0,
            model = currentShops[shopId].npc.model or 's_m_y_xmech_01'
        }
    end

    saveShops()
    return { ok = true, message = 'Ponto de oficina atualizado com sucesso!' }
end)
