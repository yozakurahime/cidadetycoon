local activeLights = {}
local activeSetWeather = {}
local insideWeatherSet = nil
local currentGuides = { show = false, grid = false, rec = false, aspect = 'none' }

-- Inicialização e sincronização inicial com o servidor
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('cidade_filmmaker_suite:server:requestLights')
    TriggerServerEvent('cidade_filmmaker_suite:server:requestSetWeather')
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(1000)
    TriggerServerEvent('cidade_filmmaker_suite:server:requestLights')
    TriggerServerEvent('cidade_filmmaker_suite:server:requestSetWeather')
end)

--------------------------------------------------------------------------------
-- 1. MÓDULO: SET LIGHTS (ILUMINAÇÃO DE SET)
--------------------------------------------------------------------------------
RegisterNetEvent('cidade_filmmaker_suite:client:syncLights', function(lightsList)
    activeLights = lightsList
end)

-- Loop otimizado para renderizar as luzes a cada frame
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        
        for id, light in pairs(activeLights) do
            local lCoords = vector3(light.x, light.y, light.z)
            local dist = #(pCoords - lCoords)
            if dist < 80.0 then
                sleep = 0
                -- DrawLightWithRange(x, y, z, r, g, b, range, intensity)
                DrawLightWithRange(light.x, light.y, light.z, light.r, light.g, light.b, light.range, light.intensity)
            end
        end
        Citizen.Wait(sleep)
    end
end)

-- Menu Contextual para Gerenciar Luzes
local function openLightsMenu()
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    
    local options = {
        {
            title = 'Criar Nova Luz',
            description = 'Posiciona uma nova luz de estúdio na sua coordenada atual',
            icon = 'lightbulb',
            onSelect = function()
                local input = lib.inputDialog('Configurar Nova Luz', {
                    { type = 'number', label = 'Alcance (Meters)', default = 15, min = 1, max = 50 },
                    { type = 'number', label = 'Intensidade', default = 10, min = 1, max = 100 },
                    { type = 'color', label = 'Cor da Luz (RGB)', default = '#FFFFFF' }
                })
                
                if not input then return end
                local range = tonumber(input[1]) or 15.0
                local intensity = tonumber(input[2]) or 10.0
                
                -- Converter Hex para RGB
                local hex = input[3]:gsub("#","")
                local r = tonumber("0x"..hex:sub(1,2)) or 255
                local g = tonumber("0x"..hex:sub(3,4)) or 255
                local b = tonumber("0x"..hex:sub(5,6)) or 255
                
                local lightId = "light_" .. math.random(1111, 9999)
                local lightData = {
                    x = pCoords.x,
                    y = pCoords.y,
                    z = pCoords.z + 1.0, -- Levemente acima da cabeça
                    r = r,
                    g = g,
                    b = b,
                    range = range + 0.0,
                    intensity = intensity + 0.0
                }
                
                TriggerServerEvent('cidade_filmmaker_suite:server:registerLight', lightId, lightData)
                lib.notify({ title = 'Set Lights', description = 'Luz criada com sucesso!', type = 'success' })
            end
        }
    }
    
    -- Listar luzes próximas para deletar
    local closeLights = false
    for id, light in pairs(activeLights) do
        local lCoords = vector3(light.x, light.y, light.z)
        local dist = #(pCoords - lCoords)
        if dist < 15.0 then
            closeLights = true
            table.insert(options, {
                title = 'Apagar Luz Próxima (' .. math.floor(dist) .. 'm)',
                description = 'ID: ' .. id .. ' | Cor: RGB('..light.r..','..light.g..','..light.b..')',
                icon = 'trash',
                onSelect = function()
                    TriggerServerEvent('cidade_filmmaker_suite:server:deleteLight', id)
                    lib.notify({ title = 'Set Lights', description = 'Luz removida!', type = 'error' })
                end
            })
        end
    end
    
    if not closeLights then
        table.insert(options, {
            title = 'Nenhuma luz próxima para gerenciar',
            disabled = true,
            icon = 'ban'
        })
    end

    lib.registerContext({
        id = 'filmmaker_lights_menu',
        title = 'Estúdio de Iluminação',
        options = options
    })
    lib.showContext('filmmaker_lights_menu')
end

RegisterNetEvent('cidade_filmmaker_suite:client:openLights', function()
    openLightsMenu()
end)

--------------------------------------------------------------------------------
-- 2. MÓDULO: CLAQUETE
--------------------------------------------------------------------------------
local function DrawText3D(x, y, z, text)
    local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(screenX, screenY)
    local factor = (string.len(text)) / 370
    DrawRect(screenX, screenY + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 75)
end

RegisterNetEvent('cidade_filmmaker_suite:client:playClack', function(senderId, senderCoords, textData)
    local pPed = PlayerPedId()
    local pCoords = GetEntityCoords(pPed)
    local sCoords = vector3(senderCoords.x, senderCoords.y, senderCoords.z)
    local dist = #(pCoords - sCoords)

    -- 1. Calcular volume baseado na distância do ouvinte
    if dist < 45.0 then
        local volume = 1.0 - (dist / 45.0)
        SendNUIMessage({
            action = 'playClack',
            volume = volume
        })
    end

    -- 2. Desenhar Claquete 3D Text para todos os jogadores no set por 4 segundos
    local timeout = GetGameTimer() + 4000
    Citizen.CreateThread(function()
        while GetGameTimer() < timeout do
            local distDraw = #(GetEntityCoords(PlayerPedId()) - sCoords)
            if distDraw < 25.0 then
                DrawText3D(sCoords.x, sCoords.y, sCoords.z + 1.2, "~y~[CLAQUETE]~w~\nPROJETO: " .. textData.project .. "\nCENA: " .. textData.scene .. " | TAKE: " .. textData.take)
            end
            Citizen.Wait(0)
        end
    end)
end)

RegisterNetEvent('cidade_filmmaker_suite:client:playClaqueAnim', function(project, scene, take)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Animação da claquete
    local animDict = "amb@world_human_cop_idles@male@idle_b"
    local animName = "idle_e"
    
    lib.requestAnimDict(animDict)
    
    -- Anexar o prop da claquete
    local model = `prop_cin_board_01`
    lib.requestModel(model)
    
    local board = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
    AttachEntityToEntity(board, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, 3000, 49, 0, false, false, false)
    
    -- Espera bater a claquete na animação para sincronizar o áudio
    Citizen.Wait(1200)
    
    TriggerServerEvent('cidade_filmmaker_suite:server:playClack', GetEntityCoords(ped), {
        project = project,
        scene = scene,
        take = take
    })
    
    Citizen.Wait(1800)
    DeleteEntity(board)
end)

--------------------------------------------------------------------------------
-- 3. MÓDULO: CHROMA KEY (PAINÉIS PORTÁTEIS)
--------------------------------------------------------------------------------
local chromaProps = {}
local spawnedChromaCount = 0

-- Função para abrir o menu do Chroma Key
local function openChromaMenu()
    local options = {
        { title = 'Painel Verde Chroma', value = {r = 0, g = 255, b = 0} },
        { title = 'Painel Azul Chroma', value = {r = 0, g = 0, b = 255} },
        { title = 'Painel Preto Fosco', value = {r = 5, g = 5, b = 5} },
        { title = 'Painel Branco Puro', value = {r = 255, g = 255, b = 255} }
    }
    
    local selectOpts = {}
    for _, opt in ipairs(options) do
        table.insert(selectOpts, {
            title = opt.title,
            icon = 'square',
            onSelect = function()
                if spawnedChromaCount >= 5 then
                    lib.notify({ title = 'Chroma Key', description = 'Você atingiu o limite de 5 painéis ativos!', type = 'error' })
                    return
                end
                
                local ped = PlayerPedId()
                local heading = GetEntityHeading(ped)
                local forward = GetEntityForwardVector(ped)
                local pCoords = GetEntityCoords(ped)
                
                -- Spawnar prop na frente do jogador
                local spawnPos = pCoords + forward * 3.0
                local model = `hei_prop_heist_cardbg`
                lib.requestModel(model)
                
                local prop = CreateObject(model, spawnPos.x, spawnPos.y, spawnPos.z, true, true, true)
                SetEntityHeading(prop, heading + 180.0)
                PlaceObjectOnGroundProperly(prop)
                FreezeEntityPosition(prop, true)
                
                -- Aplicar cor customizada (nativo inexistente no GTA V — fallback seguro)
                pcall(function()
                    SetEntityColour(prop, opt.value.r, opt.value.g, opt.value.b)
                end)
                if opt.value.r == 0 and opt.value.g == 255 and opt.value.b == 0 then
                    SetObjectTextureVariation(prop, 0)
                end
                
                table.insert(chromaProps, prop)
                spawnedChromaCount = spawnedChromaCount + 1
                
                -- Adicionar interação Ox Target para manipulação
                exports.ox_target:addLocalEntity(prop, {
                    {
                        name = 'rotate_chroma',
                        icon = 'sync',
                        label = 'Girar Painel (90°)',
                        onSelect = function()
                            local currH = GetEntityHeading(prop)
                            SetEntityHeading(prop, currH + 90.0)
                        end
                    },
                    {
                        name = 'height_chroma_up',
                        icon = 'arrow-up',
                        label = 'Subir Painel',
                        onSelect = function()
                            local c = GetEntityCoords(prop)
                            SetEntityCoords(prop, c.x, c.y, c.z + 0.5, false, false, false, false)
                        end
                    },
                    {
                        name = 'height_chroma_down',
                        icon = 'arrow-down',
                        label = 'Descer Painel',
                        onSelect = function()
                            local c = GetEntityCoords(prop)
                            SetEntityCoords(prop, c.x, c.y, c.z - 0.5, false, false, false, false)
                        end
                    },
                    {
                        name = 'delete_chroma',
                        icon = 'trash',
                        label = 'Excluir Painel',
                        onSelect = function()
                            if DoesEntityExist(prop) then
                                DeleteEntity(prop)
                                spawnedChromaCount = spawnedChromaCount - 1
                            end
                            lib.notify({ title = 'Chroma Key', description = 'Painel removido!', type = 'error' })
                        end
                    }
                })
                
                lib.notify({ title = 'Chroma Key', description = 'Painel criado! Use o Alt para interagir com ele.', type = 'success' })
            end
        })
    end
    
    lib.registerContext({
        id = 'chroma_spawn_menu',
        title = 'Spawn Chroma Key',
        options = selectOpts
    })
    lib.showContext('chroma_spawn_menu')
end

RegisterNetEvent('cidade_filmmaker_suite:client:openChroma', function()
    openChromaMenu()
end)

RegisterNetEvent('cidade_filmmaker_suite:client:clearChromaProps', function()
    for _, prop in ipairs(chromaProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    chromaProps = {}
    spawnedChromaCount = 0
end)

--------------------------------------------------------------------------------
-- 4. MÓDULO: CAMERA GUIDES (SOBREPOSIÇÃO)
--------------------------------------------------------------------------------
local function updateGuidesNUI()
    SendNUIMessage({
        action = 'updateGuides',
        show = currentGuides.show,
        grid = currentGuides.grid,
        rec = currentGuides.rec,
        aspect = currentGuides.aspect
    })
end

RegisterCommand('guias', function()
    local options = {
        {
            title = 'Ativar/Desativar Guias',
            description = 'Liga ou desliga as marcações de enquadramento na tela',
            icon = currentGuides.show and 'toggle-on' or 'toggle-off',
            onSelect = function()
                currentGuides.show = not currentGuides.show
                updateGuidesNUI()
                ExecuteCommand('guias') -- Reabre o menu atualizado
            end
        },
        {
            title = 'Grade (Regra dos Terços)',
            description = 'Exibe linhas guias de proporção 3x3',
            icon = currentGuides.grid and 'check-square' or 'square',
            disabled = not currentGuides.show,
            onSelect = function()
                currentGuides.grid = not currentGuides.grid
                updateGuidesNUI()
                ExecuteCommand('guias')
            end
        },
        {
            title = 'Indicador de Gravação (REC)',
            description = 'Piscar marcador de gravação no topo da tela',
            icon = currentGuides.rec and 'check-square' or 'square',
            disabled = not currentGuides.show,
            onSelect = function()
                currentGuides.rec = not currentGuides.rec
                updateGuidesNUI()
                ExecuteCommand('guias')
            end
        },
        {
            title = 'Proporção de Tela (Aspect Ratio)',
            description = 'Atual: ' .. currentGuides.aspect:upper(),
            icon = 'video',
            disabled = not currentGuides.show,
            onSelect = function()
                local aspects = {
                    { title = 'Padrão (Sem tarjas)', value = 'none' },
                    { title = 'Cinema Anamórfico (21:9)', value = '21-9' },
                    { title = 'Redes Sociais (9:16)', value = '9-16' },
                    { title = 'Quadrado Instagram (1:1)', value = '1-1' }
                }
                local listOpts = {}
                for _, a in ipairs(aspects) do
                    table.insert(listOpts, {
                        title = a.title,
                        onSelect = function()
                            currentGuides.aspect = a.value
                            updateGuidesNUI()
                            ExecuteCommand('guias')
                        end
                    })
                end
                lib.registerContext({
                    id = 'aspect_select_menu',
                    title = 'Selecionar Proporção',
                    menu = 'filmmaker_guides_menu',
                    options = listOpts
                })
                lib.showContext('aspect_select_menu')
            end
        }
    }
    
    lib.registerContext({
        id = 'filmmaker_guides_menu',
        title = 'Guias de Câmera',
        options = options
    })
    lib.showContext('filmmaker_guides_menu')
end, false)

--------------------------------------------------------------------------------
-- 5. MÓDULO: LOCAL WEATHER (CLIMA E HORA DE SET)
--------------------------------------------------------------------------------
RegisterNetEvent('cidade_filmmaker_suite:client:syncSetWeather', function(weatherSets)
    activeSetWeather = weatherSets
end)

-- Loop que checa proximidade dos sets e pausa sincronização global se necessário
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        local currentlyInside = nil
        for id, set in pairs(activeSetWeather) do
            local sCoords = vector3(set.x, set.y, set.z)
            local dist = #(coords - sCoords)
            if dist < set.radius then
                currentlyInside = id
                break
            end
        end
        
        if currentlyInside then
            sleep = 500
            local set = activeSetWeather[currentlyInside]
            if insideWeatherSet ~= currentlyInside then
                -- Ao entrar no set, desliga o WeatherSync global
                TriggerEvent('weather:client:disableSync', true)
                insideWeatherSet = currentlyInside
                lib.notify({ title = 'Set de Gravação', description = 'Entrando em área com clima e tempo configurados para filmagem.', type = 'inform' })
            end
            
            -- Força clima e tempo locais
            SetWeatherTypeNowPersist(set.weather)
            NetworkOverrideClockTime(set.hour, 0, 0)
        else
            if insideWeatherSet then
                -- Ao sair, restabelece sincronizador global
                TriggerEvent('weather:client:disableSync', false)
                insideWeatherSet = nil
                lib.notify({ title = 'Set de Gravação', description = 'Saindo da área de gravação. Sincronização global restaurada.', type = 'inform' })
            end
        end
        
        Citizen.Wait(sleep)
    end
end)

-- Menu para criar set de clima
local function openWeatherSetMenu()
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    
    local options = {
        {
            title = 'Criar Set de Clima Local',
            description = 'Define o clima e horário num raio delimitado nesta coordenada',
            icon = 'cloud-sun',
            onSelect = function()
                local input = lib.inputDialog('Configurar Set de Clima', {
                    { type = 'select', label = 'Clima Desejado', default = 'EXTRASUNNY', options = {
                        { value = 'EXTRASUNNY', label = 'Ensolarado' },
                        { value = 'CLEAR', label = 'Limpo' },
                        { value = 'CLOUDS', label = 'Nublado' },
                        { value = 'FOGGY', label = 'Neblina' },
                        { value = 'RAIN', label = 'Chuvoso' },
                        { value = 'THUNDER', label = 'Tempestade' },
                        { value = 'XMAS', label = 'Nevando' }
                    }},
                    { type = 'number', label = 'Hora do Set (0-23)', default = 12, min = 0, max = 23 },
                    { type = 'number', label = 'Raio de Cobertura (Meters)', default = 80, min = 10, max = 300 }
                })
                
                if not input then return end
                local weather = input[1]
                local hour = tonumber(input[2]) or 12
                local radius = tonumber(input[3]) or 80.0
                
                local setId = "set_" .. math.random(1111, 9999)
                local setData = {
                    x = pCoords.x,
                    y = pCoords.y,
                    z = pCoords.z,
                    weather = weather,
                    hour = hour,
                    radius = radius + 0.0
                }
                
                TriggerServerEvent('cidade_filmmaker_suite:server:registerSetWeather', setId, setData)
                lib.notify({ title = 'Set Weather', description = 'Set de clima registrado com sucesso!', type = 'success' })
            end
        }
    }
    
    -- Listar sets próximos para deletar
    local closeSets = false
    for id, set in pairs(activeSetWeather) do
        local sCoords = vector3(set.x, set.y, set.z)
        local dist = #(pCoords - sCoords)
        if dist < 30.0 then
            closeSets = true
            table.insert(options, {
                title = 'Remover Set Próximo (' .. math.floor(dist) .. 'm)',
                description = 'Clima: '..set.weather..' | Hora: '..set.hour..'h | Raio: '..set.radius..'m',
                icon = 'trash',
                onSelect = function()
                    TriggerServerEvent('cidade_filmmaker_suite:server:deleteSetWeather', id)
                    lib.notify({ title = 'Set Weather', description = 'Set de clima removido!', type = 'error' })
                end
            })
        end
    end
    
    if not closeSets then
        table.insert(options, {
            title = 'Nenhum set de clima próximo para gerenciar',
            disabled = true,
            icon = 'ban'
        })
    end

    lib.registerContext({
        id = 'filmmaker_weather_menu',
        title = 'Sincronizador de Clima Local',
        options = options
    })
    lib.showContext('filmmaker_weather_menu')
end

RegisterNetEvent('cidade_filmmaker_suite:client:openWeather', function()
    openWeatherSetMenu()
end)
