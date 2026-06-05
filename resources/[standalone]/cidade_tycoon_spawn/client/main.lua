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
        {
            label = 'Motel',
            coords = vec4(327.56, -205.08, 53.08, 163.5),
            icon = 'bed'
        },
    }
}

local isNewCharacter = false

local function safeTeleportAndDrop(spawnData)
    local ped = PlayerPedId()
    
    -- Request the server to assign public bucket if we were in private
    TriggerServerEvent('cidade_tycoon_spawn:server:setPublicBucket')
    
    -- Mover o ped para o local
    SetEntityCoords(ped, spawnData.coords.x, spawnData.coords.y, spawnData.coords.z, false, false, false, false)
    if spawnData.coords.w then
        SetEntityHeading(ped, spawnData.coords.w)
    end
    FreezeEntityPosition(ped, true)

    -- Carregar colisões rigorosamente
    RequestCollisionAtCoord(spawnData.coords.x, spawnData.coords.y, spawnData.coords.z)
    local timer = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timer do
        Wait(50)
    end

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
        title = 'Bem-vindo à Cidade',
        description = ('Você chegou em %s.'):format(spawnData.label),
        type = 'inform',
        position = 'top'
    })

    if not isNewCharacter then
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
    end
end

local function showSpawnMenu(spawnsList)
    local options = {}

    for i = 1, #spawnsList do
        local sp = spawnsList[i]
        table.insert(options, {
            title = sp.label,
            description = sp.description or 'Ponto de chegada padrão.',
            icon = sp.icon or 'location-dot',
            onSelect = function()
                safeTeleportAndDrop(sp)
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_spawn_menu',
        title = 'Selecione o Local de Chegada',
        options = options,
        canClose = false
    })

    lib.showContext('tycoon_spawn_menu')
end

RegisterNetEvent('qb-spawn:client:setupSpawns', function(cData, new, apps)
    isNewCharacter = new or false
    
    -- Start the switch to sky
    DoScreenFadeOut(500)
    Wait(500)
    
    SwitchOutPlayer(PlayerPedId(), 0, 1)
    
    while GetPlayerSwitchState() ~= 5 do
        Wait(50)
    end
    
    DoScreenFadeIn(500)

    -- If new character, we assign to private bucket
    if new then
        TriggerServerEvent('cidade_tycoon_spawn:server:setPrivateBucket')
    end

    local spawnsList = {}
    local data = lib.callback.await('cidade_tycoon_spawn:server:getSpawnData', false)

    -- 1. Tutorial Force (Priority)
    if data and data.isTutorialActive and data.tutorialLocation then
        table.insert(spawnsList, {
            label = 'Início do Onboarding (Motel)',
            description = 'O local ideal para começar sua jornada Tycoon.',
            coords = vec4(data.tutorialLocation.x, data.tutorialLocation.y, data.tutorialLocation.z, data.tutorialLocation.w or 163.5),
            icon = 'graduation-cap'
        })
    end

    -- 2. Company Hub (Secondary Priority)
    if data and data.hubLocation then
        table.insert(spawnsList, {
            label = 'Sede da Empresa',
            description = ('Sua base em %s.'):format(data.hubLocation.name),
            coords = data.hubLocation.coords,
            icon = 'building-shield'
        })
    end

    -- 3. Last Location
    if data and data.lastLocation then
        table.insert(spawnsList, {
            label = 'Última Localização',
            description = 'Volte exatamente de onde parou.',
            coords = vec4(data.lastLocation.x, data.lastLocation.y, data.lastLocation.z, data.lastLocation.w or 0.0),
            icon = 'clock-rotate-left'
        })
    end

    -- 4. Default spawns from config
    for i = 1, #config.spawns do
        table.insert(spawnsList, config.spawns[i])
    end

    showSpawnMenu(spawnsList)
end)