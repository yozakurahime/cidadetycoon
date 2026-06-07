local function DebugLog(text, ...)
    print(string.format("^5[Tycoon:Server:Spawn]^7 %s", string.format(text, ...)))
end

-- Assign a player to a private routing bucket for character creation
RegisterNetEvent('cidade_tycoon_spawn:server:setPrivateBucket', function()
    local src = source
    local bucketId = src + 1000 -- Unique bucket per player
    SetPlayerRoutingBucket(src, bucketId)
    DebugLog("Jogador %d movido para bucket privado %d para criacao de personagem", src, bucketId)
end)

-- Return a player to the public routing bucket (0) after spawn
RegisterNetEvent('cidade_tycoon_spawn:server:setPublicBucket', function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
    DebugLog("Jogador %d retornado para bucket publico 0", src)
end)

-- Callback to retrieve spawn data (Last location + Hub if available)
lib.callback.register('cidade_tycoon_spawn:server:getSpawnData', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return nil end

    local spawnData = {
        lastLocation = player.PlayerData.position,
        hubLocation = nil,
        isTutorialActive = false
    }

    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if profile then
        if profile.tutorial and profile.tutorial.active then
            spawnData.isTutorialActive = true
            if profile.tutorial.currentStep == 'welcome' or profile.tutorial.currentStep == 'go_to_garage' then
                spawnData.tutorialLocation = { x = 327.56, y = -205.08, z = 53.08, w = 163.5 }
            end
        end

        -- Check if player has a company Hub
        if GetResourceState('cidade_tycoon_logistics') == 'started' then
            local company = exports.cidade_tycoon_logistics:GetCompanyData(source)
            if company and company.warehouseId then
                local hub = exports.cidade_tycoon_hubs:GetHubData(company.warehouseId)
                if hub then
                    spawnData.hubLocation = {
                        name = hub.name,
                        coords = hub.coords
                    }
                end
            end
        end
    end

    return spawnData
end)

-- Keep legacy for compatibility during transition
lib.callback.register('cidade_tycoon_spawn:server:getLastLocation', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if player and player.PlayerData.position then
        return player.PlayerData.position
    end
    return { x = -1044.3, y = -2749.88, z = 21.36, a = 326.66 }
end)
