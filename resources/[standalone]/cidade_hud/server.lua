local stressCooldown = {}
local relaxCooldown = {}

local function updateStress(source, delta)
    local now = os.time()
    if delta > 0 and stressCooldown[source] and stressCooldown[source] >= now then return end
    if delta > 0 then stressCooldown[source] = now + 1 end

    local currentStress = tonumber(exports.cidade_tycoon_core:GetPlayerMeta(source, 'stress')) or 0
    local newStress = math.max(0, math.min(100, currentStress + delta))
    exports.cidade_tycoon_core:SetPlayerMeta(source, 'stress', newStress)
end

RegisterNetEvent('hud:server:GainStress', function(amount)
    updateStress(source, math.max(0, math.min(5, tonumber(amount) or 0)))
end)

RegisterNetEvent('hud:server:RelieveStress', function(amount)
    updateStress(source, -math.max(0, math.min(100, tonumber(amount) or 0)))
end)

RegisterNetEvent('hud:server:RequestStressRelief', function(amount)
    local src = source
    if not HudConfig.stress_relax_command then return end

    local now = os.time()
    local cooldownUntil = relaxCooldown[src] or 0
    if cooldownUntil > now then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Stress',
            description = ('Aguarde %ss para relaxar novamente.'):format(cooldownUntil - now),
            type = 'error'
        })
        return
    end

    relaxCooldown[src] = now + (HudConfig.stress_relax_cooldown or 120)
    updateStress(src, -math.max(0, math.min(100, tonumber(amount) or HudConfig.stress_relax_amount or 15)))

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Stress',
        description = 'Você se sente mais relaxado.',
        type = 'success'
    })
end)

AddEventHandler('playerDropped', function()
    stressCooldown[source] = nil
    relaxCooldown[source] = nil
end)

-- Comando /eat para administradores (alimentar e saciar a sede)
RegisterCommand("eat", function(source, args, rawCommand)
    local src = source
    if src == 0 then -- Console
        return
    end

    -- Checa permissão de administrador via Core Bridge
    local hasPermission = false
    if exports.cidade_tycoon_core:HasPermission(src, "admin") or exports.cidade_tycoon_core:HasPermission(src, "god") or IsPlayerAceAllowed(src, "command") then
        hasPermission = true
    end

    if hasPermission then
        exports.cidade_tycoon_core:SetPlayerMeta(src, 'hunger', 100)
        exports.cidade_tycoon_core:SetPlayerMeta(src, 'thirst', 100)
        exports.cidade_tycoon_core:SetPlayerMeta(src, 'stress', 0)
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Sucesso',
                description = 'Você saciou sua fome, sede e stress!',
                type = 'success'
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Negado',
            description = 'Você não tem permissão para usar este comando.',
            type = 'error'
        })
    end
end, false)
