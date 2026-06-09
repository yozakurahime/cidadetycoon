local config = Config

local function DebugLog(text, ...)
    print(string.format("^2[Tycoon:Scrapyard:Server]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- EVENTO DE RECEBER MATERIAL
-- ==========================================
RegisterNetEvent('cidade_tycoon_scrapyard:server:giveMaterial', function(locationId, itemKey, amount, skillPassed, locType)
    local src = source

    -- Validação: local existe?
    local location = nil
    local sourceList = locType == 'lab' and config.Labs or config.Scrapyards
    for _, loc in ipairs(sourceList) do
        if loc.id == locationId then
            location = loc
            break
        end
    end
    if not location then
        DebugLog("ALERTA: Jogador %d tentou coletar de local inexistente: %s", src, tostring(locationId))
        return
    end

    -- Validação: item pertence ao local?
    local validDrop = false
    for _, d in ipairs(location.drops) do
        if d.item == itemKey then validDrop = true; break end
    end
    if not validDrop then
        DebugLog("ALERTA: Jogador %d tentou item inválido: %s no local %s", src, tostring(itemKey), locationId)
        return
    end

    -- Range check
    amount = math.max(1, math.min(amount, 20))

    -- Adiciona ao inventário
    local success = exports.ox_inventory:AddItem(src, itemKey, amount)
    if not success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Coleta', description = 'Inventário cheio! Libere espaço.', type = 'error'
        })
        return
    end

    -- XP
    local xpAmount = locType == 'lab' and config.ExperiencePerLab or config.ExperiencePerScavenge
    if skillPassed then
        pcall(function()
            exports.cidade_tycoon_core:AddExperience(src, xpAmount)
        end)
    end

    -- Alerta Policial (apenas laboratórios)
    if locType == 'lab' and math.random() < config.PoliceAlertChance then
        exports.qbx_core:NotifyPolice({
            coords = GetEntityCoords(GetPlayerPed(src)),
            message = config.PoliceAlertMessage,
            blip = { sprite = 432, scale = 0.8, colour = 1, time = 30000 },
        })
        TriggerClientEvent('ox_lib:notify', src, {
            title = '🚨 Alerta Policial',
            description = 'Alguém pode ter notado sua atividade... Tome cuidado!',
            type = 'error',
            duration = 8000,
        })
    end

    pcall(function()
        exports.cidade_tycoon_core:LogTransaction(
            src, 0, 'gathering', locType,
            ('Coleta: %dx %s em %s [%s]'):format(amount, itemKey, location.label, skillPassed and 'sucesso' or 'parcial')
        )
    end)

    DebugLog("Jogador %d coletou %dx %s em %s (%s)", src, amount, itemKey, locationId, locType)
end)
