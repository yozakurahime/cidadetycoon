local stressCooldown = {}

local function updateStress(source, delta)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local now = os.time()
    if delta > 0 and stressCooldown[source] and stressCooldown[source] >= now then return end
    if delta > 0 then stressCooldown[source] = now + 1 end

    local currentStress = tonumber(player.PlayerData.metadata.stress) or 0
    local newStress = math.max(0, math.min(100, currentStress + delta))
    player.Functions.SetMetaData('stress', newStress)
end

RegisterNetEvent('hud:server:GainStress', function(amount)
    updateStress(source, math.max(0, math.min(5, tonumber(amount) or 0)))
end)

RegisterNetEvent('hud:server:RelieveStress', function(amount)
    updateStress(source, -math.max(0, math.min(100, tonumber(amount) or 0)))
end)

AddEventHandler('playerDropped', function()
    stressCooldown[source] = nil
end)

-- Comando /eat para administradores (alimentar e saciar a sede)
RegisterCommand("eat", function(source, args, rawCommand)
    local src = source
    if src == 0 then -- Console
        return
    end

    -- Checa permissão de administrador no Qbox/QBCore
    local hasPermission = false
    if exports.qbx_core:HasPermission(src, "admin") or exports.qbx_core:HasPermission(src, "god") or IsPlayerAceAllowed(src, "command") then
        hasPermission = true
    end

    if hasPermission then
        local player = exports.qbx_core:GetPlayer(src)
        if player then
            player.Functions.SetMetaData('hunger', 100)
            player.Functions.SetMetaData('thirst', 100)
            player.Functions.SetMetaData('stress', 0)
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
