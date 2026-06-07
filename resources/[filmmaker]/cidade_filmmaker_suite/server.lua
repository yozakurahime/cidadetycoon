local ActiveLights = {}
local ActiveSetWeather = {}

-- Helper para checar se o jogador tem permissÃ£o de filmmaker ou administrador
local function hasPermission(src)
    return IsPlayerAceAllowed(src, "filmmaker.tools") 
        or exports.qbx_core:HasGroup(src, "admin") 
        or exports.qbx_core:HasGroup(src, "god") 
        or exports.qbx_core:HasGroup(src, "filmmaker")
end

--------------------------------------------------------------------------------
-- COMANDOS COM PERMISSÃƒO (VIA OX_LIB / SERVER-SIDE)
--------------------------------------------------------------------------------
lib.addCommand('luz', {
    help = 'Abre o menu de estÃºdio de iluminaÃ§Ã£o (Filmmaker/Admin)',
}, function(source, args, raw)
    if hasPermission(source) then
        TriggerClientEvent('cidade_filmmaker_suite:client:openLights', source)
    else
        TriggerClientEvent('ox_lib:notify', source, { title = 'Sem PermissÃ£o', description = 'Apenas Filmmakers e Admins podem gerenciar luzes.', type = 'error' })
    end
end)

lib.addCommand('chroma', {
    help = 'Abre o menu de painÃ©is Chroma Key (Filmmaker/Admin)',
}, function(source, args, raw)
    if hasPermission(source) then
        TriggerClientEvent('cidade_filmmaker_suite:client:openChroma', source)
    else
        TriggerClientEvent('ox_lib:notify', source, { title = 'Sem PermissÃ£o', description = 'Apenas Filmmakers e Admins podem usar o Chroma Key.', type = 'error' })
    end
end)

lib.addCommand('setclima', {
    help = 'Abre o menu de clima local do set (Filmmaker/Admin)',
}, function(source, args, raw)
    if hasPermission(source) then
        TriggerClientEvent('cidade_filmmaker_suite:client:openWeather', source)
    else
        TriggerClientEvent('ox_lib:notify', source, { title = 'Sem PermissÃ£o', description = 'Apenas Filmmakers e Admins podem alterar o clima local.', type = 'error' })
    end
end)

lib.addCommand('claquete', {
    help = 'Bater claquete no set (Filmmaker/Admin)',
    params = {
        { name = 'projeto', type = 'string', optional = true, help = 'Nome do Filme/Projeto' },
        { name = 'cena', type = 'string', optional = true, help = 'NÃºmero da Cena' },
        { name = 'take', type = 'string', optional = true, help = 'NÃºmero do Take' }
    }
}, function(source, args, raw)
    if hasPermission(source) then
        TriggerClientEvent('cidade_filmmaker_suite:client:playClaqueAnim', source, args.projeto or "Projeto Cidade Tycoon", args.cena or "01", args.take or "01")
    else
        TriggerClientEvent('ox_lib:notify', source, { title = 'Sem PermissÃ£o', description = 'VocÃª nÃ£o pode bater claquete.', type = 'error' })
    end
end)

lib.addCommand('limparset', {
    help = 'Limpa todos os props de Chroma e luzes do servidor (Admin apenas)',
}, function(source, args, raw)
    local isAdmin = exports.qbx_core:HasGroup(source, "admin") or exports.qbx_core:HasGroup(source, "god")
    if isAdmin then
        -- Limpa luzes
        ActiveLights = {}
        TriggerClientEvent('cidade_filmmaker_suite:client:syncLights', -1, ActiveLights)
        
        -- Limpa clima
        ActiveSetWeather = {}
        TriggerClientEvent('cidade_filmmaker_suite:client:syncSetWeather', -1, ActiveSetWeather)
        
        -- Limpa props de chroma em todos os clientes
        TriggerClientEvent('cidade_filmmaker_suite:client:clearChromaProps', -1)
        
        TriggerClientEvent('ox_lib:notify', source, { title = 'Set Limpo', description = 'Todos os painÃ©is e luzes de set foram limpos globalmente.', type = 'success' })
    else
        TriggerClientEvent('ox_lib:notify', source, { title = 'Sem PermissÃ£o', description = 'Apenas Administradores podem limpar o set globalmente.', type = 'error' })
    end
end)

--------------------------------------------------------------------------------
-- 1. SINCRONIZAÃ‡ÃƒO DA CLAQUETE
--------------------------------------------------------------------------------
RegisterNetEvent('cidade_filmmaker_suite:server:playClack', function(coords, textData)
    local src = source
    if not hasPermission(src) then return end
    
    -- Dispara para todos os clientes prÃ³ximos tocarem o som e verem a claquete
    TriggerClientEvent('cidade_filmmaker_suite:client:playClack', -1, src, coords, textData)
end)

--------------------------------------------------------------------------------
-- 2. GERENCIAMENTO DE LUZES DO SET
--------------------------------------------------------------------------------
RegisterNetEvent('cidade_filmmaker_suite:server:requestLights', function()
    local src = source
    TriggerClientEvent('cidade_filmmaker_suite:client:syncLights', src, ActiveLights)
end)

RegisterNetEvent('cidade_filmmaker_suite:server:registerLight', function(lightId, lightData)
    local src = source
    if not hasPermission(src) then return end
    
    -- Limitar luzes ativas por jogador (mÃ¡ximo 8) para evitar lag
    local count = 0
    for _, l in pairs(ActiveLights) do
        if l.owner == src then
            count = count + 1
        end
    end
    
    if count >= 8 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Set Lights', description = 'VocÃª atingiu o limite de 8 luzes de estÃºdio!', type = 'error' })
        return
    end
    
    lightData.owner = src
    ActiveLights[lightId] = lightData
    TriggerClientEvent('cidade_filmmaker_suite:client:syncLights', -1, ActiveLights)
end)

RegisterNetEvent('cidade_filmmaker_suite:server:deleteLight', function(lightId)
    local src = source
    if not hasPermission(src) then return end
    
    if ActiveLights[lightId] then
        ActiveLights[lightId] = nil
        TriggerClientEvent('cidade_filmmaker_suite:client:syncLights', -1, ActiveLights)
    end
end)

--------------------------------------------------------------------------------
-- 3. GERENCIAMENTO DE CLIMA E HORA LOCALIZADOS
--------------------------------------------------------------------------------
RegisterNetEvent('cidade_filmmaker_suite:server:requestSetWeather', function()
    local src = source
    TriggerClientEvent('cidade_filmmaker_suite:client:syncSetWeather', src, ActiveSetWeather)
end)

RegisterNetEvent('cidade_filmmaker_suite:server:registerSetWeather', function(setId, setData)
    local src = source
    if not hasPermission(src) then return end
    
    setData.owner = src
    ActiveSetWeather[setId] = setData
    TriggerClientEvent('cidade_filmmaker_suite:client:syncSetWeather', -1, ActiveSetWeather)
end)

RegisterNetEvent('cidade_filmmaker_suite:server:deleteSetWeather', function(setId)
    local src = source
    if not hasPermission(src) then return end
    
    if ActiveSetWeather[setId] then
        ActiveSetWeather[setId] = nil
        TriggerClientEvent('cidade_filmmaker_suite:client:syncSetWeather', -1, ActiveSetWeather)
    end
end)

--------------------------------------------------------------------------------
-- LIMPEZA AUTOMÃTICA AO DESCONECTAR (PREVENÃ‡ÃƒO DE ACÃšMULO/GHOST ENTITIES)
--------------------------------------------------------------------------------
AddEventHandler('playerDropped', function(reason)
    local src = source
    local lightsChanged = false
    local weatherChanged = false
    
    -- Limpar luzes do jogador
    for id, l in pairs(ActiveLights) do
        if l.owner == src then
            ActiveLights[id] = nil
            lightsChanged = true
        end
    end
    
    -- Limpar clima do jogador
    for id, w in pairs(ActiveSetWeather) do
        if w.owner == src then
            ActiveSetWeather[id] = nil
            weatherChanged = true
        end
    end
    
    if lightsChanged then
        TriggerClientEvent('cidade_filmmaker_suite:client:syncLights', -1, ActiveLights)
    end
    
    if weatherChanged then
        TriggerClientEvent('cidade_filmmaker_suite:client:syncSetWeather', -1, ActiveSetWeather)
    end
end)

