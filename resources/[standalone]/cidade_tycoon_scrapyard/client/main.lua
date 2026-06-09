local config = Config
local spawnedPeds = {}
local scrapCooldowns = {}

local function DebugLog(text, ...)
    print(string.format("^2[Tycoon:Scrapyard]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- SELEÇÃO PONDERADA DE DROP
-- ==========================================
local function selectWeightedDrop(drops)
    local totalWeight = 0
    for _, d in ipairs(drops) do
        totalWeight = totalWeight + d.weight
    end
    local roll = math.random(1, totalWeight)
    local cumulative = 0
    for i, d in ipairs(drops) do
        cumulative = cumulative + d.weight
        if roll <= cumulative then return i end
    end
    return nil
end

-- ==========================================
-- SPAWN DE NPCs (Ferro-Velho)
-- ==========================================
local function spawnScrapyardNPCs()
    for _, yard in ipairs(config.Scrapyards) do
        local hash = GetHashKey(yard.pedModel)
        lib.requestModel(hash, 5000)
        local ped = CreatePed(4, hash, yard.coords.x, yard.coords.y, yard.coords.z - 1.0, yard.coords.w, false, false)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        if yard.scenario then TaskStartScenarioInPlace(ped, yard.scenario, 0, true) end
        table.insert(spawnedPeds, ped)

        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'scavenge_' .. yard.id,
                icon = 'fa-solid fa-recycle',
                label = 'Vasculhar ' .. yard.label,
                onSelect = function() startScavenging(yard, 'scrapyard') end,
                canInteract = function()
                    if scrapCooldowns[yard.id] and GetGameTimer() - scrapCooldowns[yard.id] < config.ScrapCooldown then
                        return false
                    end
                    return true
                end,
            }
        })
    end
end

-- ==========================================
-- SPAWN DE NPCs (Laboratórios Clandestinos)
-- ==========================================
local function spawnLabNPCs()
    for _, lab in ipairs(config.Labs) do
        local hash = GetHashKey(lab.pedModel)
        lib.requestModel(hash, 5000)
        local ped = CreatePed(4, hash, lab.coords.x, lab.coords.y, lab.coords.z - 1.0, lab.coords.w, false, false)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        if lab.scenario then TaskStartScenarioInPlace(ped, lab.scenario, 0, true) end
        table.insert(spawnedPeds, ped)

        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'lab_collect_' .. lab.id,
                icon = 'fa-solid fa-flask',
                label = 'Coletar em ' .. lab.label,
                onSelect = function() startScavenging(lab, 'lab') end,
                canInteract = function()
                    if scrapCooldowns[lab.id] and GetGameTimer() - scrapCooldowns[lab.id] < config.LabCooldown then
                        return false
                    end
                    return true
                end,
            }
        })
    end
end

-- ==========================================
-- LÓGICA DE COLETA (Compartilhada)
-- ==========================================
function startScavenging(location, locType)
    local cooldownMs = locType == 'lab' and config.LabCooldown or config.ScrapCooldown

    if scrapCooldowns[location.id] and GetGameTimer() - scrapCooldowns[location.id] < cooldownMs then
        lib.notify({ title = 'Coleta', description = config.CooldownMessage, type = 'warning' })
        return
    end

    local ped = PlayerPedId()
    if #(GetEntityCoords(ped) - location.coords.xyz) > 3.0 then
        lib.notify({ title = 'Coleta', description = 'Chegue mais perto do ponto de coleta.', type = 'error' })
        return
    end

    -- Animação de vasculhar
    lib.requestAnimDict("amb@world_human_bum_wash@male@high@base", 3000)
    TaskPlayAnim(ped, "amb@world_human_bum_wash@male@high@base", "base", 8.0, 1.0, -1, 1, 0, false, false, false)

    -- Barra de progresso
    local completed = lib.progressBar({
        duration = config.ProgressBarDuration,
        label = (locType == 'lab' and 'Coletando químicos em ' or 'Vasculhando ') .. location.label .. '...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = 'amb@world_human_bum_wash@male@high@base', clip = 'base', flag = 1 },
    })

    ClearPedTasks(ped)

    if not completed then
        lib.notify({ title = 'Coleta', description = 'Coleta interrompida.', type = 'warning' })
        return
    end

    -- Minigame
    local skillPassed = lib.skillCheck(config.SkillCheckDifficulty, config.SkillCheckKeys)

    -- Calcular drop
    local dropIndex = selectWeightedDrop(location.drops)
    if not dropIndex then
        lib.notify({ title = 'Coleta', description = 'Nada útil encontrado.', type = 'error' })
        return
    end

    local drop = location.drops[dropIndex]
    local amount
    if skillPassed then
        amount = math.random(drop.maxAmount - 1, drop.maxAmount)
        lib.notify({
            title = '✅ Coleta Bem-Sucedida',
            description = ('Você encontrou %dx %s.'):format(amount, drop.label),
            type = 'success'
        })
    else
        amount = math.random(drop.minAmount, math.floor((drop.minAmount + drop.maxAmount) / 2))
        lib.notify({
            title = '⚠️ Coleta Parcial',
            description = ('Você encontrou apenas %dx %s.'):format(amount, drop.label),
            type = 'inform'
        })
    end

    -- Enviar para o servidor
    TriggerServerEvent('cidade_tycoon_scrapyard:server:giveMaterial', location.id, drop.item, amount, skillPassed, locType)

    scrapCooldowns[location.id] = GetGameTimer()
end

-- ==========================================
-- INICIALIZAÇÃO
-- ==========================================
CreateThread(function()
    Wait(2000)
    spawnScrapyardNPCs()
    spawnLabNPCs()
    DebugLog("NPCs de coleta spawnados: %d ferros-velho + %d laboratórios.", #config.Scrapyards, #config.Labs)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
