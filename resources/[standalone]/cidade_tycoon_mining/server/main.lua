local config = Config

local function DebugLog(text, ...)
    print(string.format("^3[Tycoon:Mining:Server]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- CALLBACKS
-- ==========================================
lib.callback.register('cidade_tycoon_mining:server:hasPickaxe', function(source)
    if not config.RequiredItem then return true end
    local count = exports.ox_inventory:Search(source, 'count', config.RequiredItem)
    return (count or 0) > 0
end)

-- ==========================================
-- EVENTO DE RECEBER MINÉRIO
-- ==========================================
RegisterNetEvent('cidade_tycoon_mining:server:giveOre', function(mineId, itemKey, amount, skillPassed)
    local src = source

    -- Validação de segurança: verifica se a mina existe
    local mine = nil
    for _, m in ipairs(config.Mines) do
        if m.id == mineId then
            mine = m
            break
        end
    end
    if not mine then
        DebugLog("ALERTA: Jogador %d tentou receber minério de mina inexistente: %s", src, tostring(mineId))
        return
    end

    -- Valida o drop
    local validDrop = false
    for _, d in ipairs(mine.drops) do
        if d.item == itemKey then
            validDrop = true
            break
        end
    end
    if not validDrop then
        DebugLog("ALERTA: Jogador %d tentou receber item inválido: %s na mina %s", src, tostring(itemKey), mineId)
        return
    end

    -- Range check do amount
    amount = math.max(1, math.min(amount, 20))

    -- Adiciona ao inventário
    local success = exports.ox_inventory:AddItem(src, itemKey, amount)
    if not success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Mineração',
            description = 'Inventário cheio! Libere espaço para coletar minérios.',
            type = 'error'
        })
        return
    end

    -- Concede XP se passou no skill check
    if skillPassed then
        pcall(function()
            exports.cidade_tycoon_core:AddExperience(src, config.ExperiencePerMine)
        end)
        -- Chance de quebrar a picareta
        if config.RequiredItem and math.random() < config.PickaxeBreakChance then
            exports.ox_inventory:RemoveItem(src, config.RequiredItem, 1)
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Mineração',
                description = 'Sua picareta quebrou durante a mineração!',
                type = 'error'
            })
        end
    end

    pcall(function()
        exports.cidade_tycoon_core:LogTransaction(
            src, 0, 'gathering', 'mining',
            ('Mineração: %dx %s na %s [%s]'):format(amount, itemKey, mine.label, skillPassed and 'sucesso' or 'parcial')
        )
    end)

    DebugLog("Jogador %d minerou %dx %s na mina %s", src, amount, itemKey, mineId)
end)
