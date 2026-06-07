local config = {
    spawns = {
        {
            label = 'Praça Principal (Legion)',
            coords = vec4(195.17, -933.77, 29.7, 144.5),
            icon = 'city'
        },
        {
            label = 'Paleto Bay',
            coords = vec4(80.35, 6424.12, 31.67, 45.5),
            icon = 'tree'
        },
    }
}

local isNewCharacter = false

local function safeTeleportAndDrop(spawnData)
    local ped = PlayerPedId()
    
    -- Cinematic Start: Audio & Visual
    DoScreenFadeOut(500)
    Wait(500)
    
    -- "Airplane/Travel" Sound Effect
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    PlaySoundFrontend(-1, "Flight_Military_Pass_By", "DLC_HEISTS_BIOLAB_FINALE_SOUNDS", 1)

    -- Request the server to assign public bucket
    TriggerServerEvent('cidade_tycoon_spawn:server:setPublicBucket')
    
    -- Mover o ped para o local
    SetEntityCoords(ped, spawnData.coords.x, spawnData.coords.y, spawnData.coords.z, false, false, false, false)
    if spawnData.coords.w then
        SetEntityHeading(ped, spawnData.coords.w)
    end
    FreezeEntityPosition(ped, true)

    -- Force Collisions
    RequestCollisionAtCoord(spawnData.coords.x, spawnData.coords.y, spawnData.coords.z)
    local timer = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timer do
        Wait(50)
    end

    DoScreenFadeIn(1000)
    
    -- Trigger the drop (GTA Style)
    SwitchInPlayer(ped)
    
    -- Wait for the drop to finish
    while GetPlayerSwitchState() ~= 12 do
        Wait(50)
    end

    FreezeEntityPosition(ped, false)
    DisplayRadar(true)
    
    -- Cinematic arrival effects
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
    lib.notify({
        title = 'Transport Tycoon',
        description = ('Bem-vindo! Você chegou em %s.'):format(spawnData.label),
        type = 'inform',
        position = 'top'
    })

    if not isNewCharacter then
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
    end
end

local function showSpawnMenu(spawnsList)
    -- Aggressive Blur Background for "Elite" feel
    SetTimecycleModifier('hud_def_blur')
    SetTimecycleModifierStrength(2.0)

    local options = {}
    for i = 1, #spawnsList do
        local sp = spawnsList[i]
        table.insert(options, {
            title = sp.label,
            description = sp.description or 'Ponto de chegada padrão.',
            icon = sp.icon or 'location-dot',
            onSelect = function()
                SetTimecycleModifier('default')
                safeTeleportAndDrop(sp)
            end
        })
    end

    -- ox_lib context is usually right-aligned, but we style it heavily
    lib.registerContext({
        id = 'tycoon_spawn_menu',
        title = 'DESTINO DE CHEGADA',
        options = options,
        canClose = false
    })

    lib.showContext('tycoon_spawn_menu')
end

RegisterNetEvent('qb-spawn:client:setupSpawns', function(cData, new, apps)
    isNewCharacter = new or false
    local ped = PlayerPedId()
    
    -- SKY TRANSITION
    DoScreenFadeOut(500)
    Wait(500)
    
    SwitchOutPlayer(ped, 0, 1)
    while GetPlayerSwitchState() ~= 5 do Wait(50) end
    
    -- If NEW CHARACTER: Force Motel and SKIP Menu (Rule #1)
    if isNewCharacter then
        local motelSpawn = {
            label = 'Início da Jornada (Motel)',
            coords = vec4(327.56, -205.08, 53.08, 163.5)
        }
        TriggerServerEvent('cidade_tycoon_spawn:server:setPrivateBucket')
        Wait(1000)
        safeTeleportAndDrop(motelSpawn)
        return
    end

    -- RETURNING PLAYER: Show Menu
    local data = lib.callback.await('cidade_tycoon_spawn:server:getSpawnData', false)
    local spawnsList = {}

    -- 1. Company Hub
    if data and data.hubLocation then
        table.insert(spawnsList, {
            label = 'Sede da Sua Empresa',
            description = ('Sua base operacional em %s.'):format(data.hubLocation.name),
            coords = data.hubLocation.coords,
            icon = 'building-shield'
        })
    end

    -- 2. Last Location
    if data and data.lastLocation then
        table.insert(spawnsList, {
            label = 'Última Localização',
            description = 'Retorne de onde parou.',
            coords = vec4(data.lastLocation.x, data.lastLocation.y, data.lastLocation.z, data.lastLocation.w or 0.0),
            icon = 'clock-rotate-left'
        })
    end

    -- 3. Defaults
    for i = 1, #config.spawns do
        table.insert(spawnsList, config.spawns[i])
    end

    showSpawnMenu(spawnsList)
    DoScreenFadeIn(500)
end)
