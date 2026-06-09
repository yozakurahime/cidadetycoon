local config = Config
local spawnedPeds = {}
local mineCooldowns = {}

local function DebugLog(text, ...)
    print(string.format("^3[Tycoon:Mining]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- SPAWN DE NPCs NAS MINAS
-- ==========================================
local function spawnMineNPCs()
    for _, mine in ipairs(config.Mines) do
        local hash = GetHashKey(mine.pedModel)
        lib.requestModel(hash, 5000)

        local ped = CreatePed(4, hash, mine.coords.x, mine.coords.y, mine.coords.z - 1.0, mine.coords.w, false, false)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        if mine.scenario then
            TaskStartScenarioInPlace(ped, mine.scenario, 0, true)
        end
        table.insert(spawnedPeds, ped)

        -- ox_target no NPC
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'mine_ore_' .. mine.id,
                icon = 'fa-solid fa-hammer',
                label = 'Minerar em ' .. mine.label,
                onSelect = function()
                    startMining(mine)
                end,
                canInteract = function()
                    -- Verifica cooldown
                    if mineCooldowns[mine.id] and GetGameTimer() - mineCooldowns[mine.id] < config.MineCooldown then
                        return false
                    end
                    -- Verifica item necessário
                    if config.RequiredItem then
                        local hasItem = lib.callback.await('cidade_tycoon_mining:server:hasPickaxe', false)
                        return hasItem
                    end
                    return true
                end,
            }
        })
    end
    DebugLog("NPCs de mineração spawnados em %d locais.", #config.Mines)
end

-- ==========================================
-- LÓGICA DE MINERAÇÃO (Progress Bar + Minigame)
-- ==========================================
function startMining(mine)
    if mineCooldowns[mine.id] and GetGameTimer() - mineCooldowns[mine.id] < config.MineCooldown then
        lib.notify({ title = 'Mineração', description = 'Aguarde o veio de minério se recuperar...', type = 'warning' })
        return
    end

    local ped = PlayerPedId()
    local npcCoords = mine.coords

    -- Verifica distância do NPC
    if #(GetEntityCoords(ped) - npcCoords.xyz) > 3.0 then
        lib.notify({ title = 'Mineração', description = 'Chegue mais perto do encarregado da mina.', type = 'error' })
        return
    end

    -- Animação de mineração
    lib.requestAnimDict("melee@large_wpn@streamed_core", 3000)
    TaskPlayAnim(ped, "melee@large_wpn@streamed_core", "ground_attack_on_spot", 8.0, 1.0, -1, 1, 0, false, false, false)

    -- Barra de Progresso
    local completed = lib.progressBar({
        duration = config.ProgressBarDuration,
        label = 'Minerando em ' .. mine.label .. '...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = 'melee@large_wpn@streamed_core', clip = 'ground_attack_on_spot', flag = 1 },
    })

    ClearPedTasks(ped)

    if not completed then
        lib.notify({ title = 'Mineração', description = 'Mineração interrompida.', type = 'warning' })
        return
    end

    -- Minigame de Habilidade
    local skillPassed = lib.skillCheck(config.SkillCheckDifficulty, config.SkillCheckKeys)

    -- Calcular drop baseado no resultado
    local dropIndex = selectWeightedDrop(mine.drops)
    if not dropIndex then
        lib.notify({ title = 'Mineração', description = 'Nada encontrado nesse veio.', type = 'error' })
        return
    end

    local drop = mine.drops[dropIndex]
    local amount
    if skillPassed then
        amount = math.random(drop.maxAmount - 1, drop.maxAmount)
        lib.notify({
            title = '⛏️ Mineração Bem-Sucedida',
            description = ('Você extraiu %dx %s com perfeição!'):format(amount, drop.label),
            type = 'success'
        })
    else
        amount = math.random(drop.minAmount, math.floor((drop.minAmount + drop.maxAmount) / 2))
        lib.notify({
            title = '⛏️ Mineração Parcial',
            description = ('Você extraiu apenas %dx %s. Melhore sua técnica!'):format(amount, drop.label),
            type = 'inform'
        })
    end

    -- Enviar para o servidor
    TriggerServerEvent('cidade_tycoon_mining:server:giveOre', mine.id, drop.item, amount, skillPassed)

    -- Cooldown visual
    mineCooldowns[mine.id] = GetGameTimer()
end

-- ==========================================
-- SELEÇÃO PONDERADA DE DROP
-- ==========================================
function selectWeightedDrop(drops)
    local totalWeight = 0
    for _, d in ipairs(drops) do
        totalWeight = totalWeight + d.weight
    end

    local roll = math.random(1, totalWeight)
    local cumulative = 0
    for i, d in ipairs(drops) do
        cumulative = cumulative + d.weight
        if roll <= cumulative then
            return i
        end
    end
    return nil
end

-- ==========================================
-- INICIALIZAÇÃO
-- ==========================================
CreateThread(function()
    Wait(2000)
    spawnMineNPCs()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
