-- server/commands.lua
-- Admin commands with integrated permission system

local Config = require 'shared.config'

-- ==========================================
-- PERMISSION SYSTEM
-- ==========================================

-- Cache levels for fast lookup
local permLevels = {}
for name, level in pairs(Config.Permissions) do
    permLevels[name] = level
end

---Check if a source has a given permission level
---@param source number
---@param requiredLevel string 'god'|'admin'|'mod'|'support'
---@return boolean
function HasPermission(source, requiredLevel)
    if source <= 0 then return true end -- console always allowed

    local required = permLevels[requiredLevel] or 0

    -- Check specific identifiers first (hardcoded gods)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        local special = Config.SpecialIdentifiers[id]
        if special then
            local level = permLevels[special] or 0
            if level >= required then return true end
        end
    end

    -- Check ACE groups
    if IsPlayerAceAllowed(source, 'command') then return true end

    -- Check hierarchy: god > admin > mod > support
    for _, level in ipairs({ 'god', 'admin', 'mod', 'support' }) do
        if IsPlayerAceAllowed(source, level) then
            local levelVal = permLevels[level] or 0
            if levelVal >= required then return true end
        end
    end

    -- Fallback: check qbx admin permission
    local ok, hasPerm = pcall(exports.cidade_tycoon_core.HasPermission, source, requiredLevel)
    if ok and hasPerm then return true end

    return false
end
exports('HasPermission', HasPermission)

---Get player's permission level label
---@param source number
---@return string
function GetPermissionLabel(source)
    if source <= 0 then return 'console' end
    if HasPermission(source, 'god') then return 'god' end
    if HasPermission(source, 'admin') then return 'admin' end
    if HasPermission(source, 'mod') then return 'mod' end
    if HasPermission(source, 'support') then return 'support' end
    return 'player'
end
exports('GetPermissionLabel', GetPermissionLabel)

---Notify admin of result
local function notifyAdmin(source, msg, type)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Admin',
        description = msg,
        type = type or 'inform',
    })
end

-- ==========================================
-- PLAYER MANAGEMENT COMMANDS
-- ==========================================

RegisterCommand('kick', function(source, args)
    if not HasPermission(source, 'mod') then
        notifyAdmin(source, 'Sem permissao.', 'error')
        return
    end
    local targetId = tonumber(args[1])
    if not targetId then notifyAdmin(source, 'Use: /kick <id> [motivo]', 'error') return end
    local reason = table.concat(args, ' ', 2)
    if reason == '' then reason = 'Kickado por administrador.' end
    DropPlayer(targetId, ('Voce foi kickado: %s'):format(reason))
    notifyAdmin(source, ('Jogador %d kickado: %s'):format(targetId, reason), 'success')
end, false)

RegisterCommand('warn', function(source, args)
    if not HasPermission(source, 'mod') then
        notifyAdmin(source, 'Sem permissao.', 'error')
        return
    end
    local targetId = tonumber(args[1])
    if not targetId then notifyAdmin(source, 'Use: /warn <id> [motivo]', 'error') return end
    local reason = table.concat(args, ' ', 2)
    if reason == '' then reason = 'Comportamento inadequado.' end
    TriggerClientEvent('ox_lib:notify', targetId, {
        title = 'ADVERTENCIA',
        description = ('Voce foi advertido: %s'):format(reason),
        type = 'error',
    })
    notifyAdmin(source, ('Jogador %d advertido: %s'):format(targetId, reason), 'success')
end, false)

-- Helper functions to execute player management directly with correct source context
local function bringPlayer(adminSource, targetId)
    local adminPed = GetPlayerPed(adminSource)
    local targetPed = GetPlayerPed(targetId)
    if not adminPed or adminPed == 0 or not targetPed or targetPed == 0 then
        return false, 'Jogador invalido ou offline.'
    end
    local coords = GetEntityCoords(adminPed)
    SetEntityCoords(targetPed, coords.x, coords.y, coords.z + 1.0)
    return true, ('Jogador %d trazido ate voce.'):format(targetId)
end

local function gotoPlayer(adminSource, targetId)
    local adminPed = GetPlayerPed(adminSource)
    local targetPed = GetPlayerPed(targetId)
    if not adminPed or adminPed == 0 or not targetPed or targetPed == 0 then
        return false, 'Jogador invalido ou offline.'
    end
    local targetCoords = GetEntityCoords(targetPed)
    TriggerClientEvent('cidade_admin:client:teleport', adminSource, targetCoords.x, targetCoords.y, targetCoords.z)
    return true, ('Teleportado ate %d.'):format(targetId)
end

local function freezePlayer(adminSource, targetId, state)
    local targetPed = GetPlayerPed(targetId)
    if not targetPed or targetPed == 0 then
        return false, 'Jogador invalido ou offline.'
    end
    TriggerClientEvent('cidade_admin:client:freezePlayer', targetId, state)
    local msg = state and ('Jogador %d congelado.'):format(targetId) or ('Jogador %d descongelado.'):format(targetId)
    return true, msg
end

RegisterCommand('freeze', function(source, args)
    if not HasPermission(source, 'mod') then return end
    local targetId = tonumber(args[1])
    if not targetId then notifyAdmin(source, 'Use: /freeze <id>', 'error') return end
    local ok, msg = freezePlayer(source, targetId, true)
    notifyAdmin(source, msg, ok and 'success' or 'error')
end, false)

RegisterCommand('unfreeze', function(source, args)
    if not HasPermission(source, 'mod') then return end
    local targetId = tonumber(args[1])
    if not targetId then notifyAdmin(source, 'Use: /unfreeze <id>', 'error') return end
    local ok, msg = freezePlayer(source, targetId, false)
    notifyAdmin(source, msg, ok and 'success' or 'error')
end, false)

RegisterCommand('bring', function(source, args)
    if not HasPermission(source, 'mod') then return end
    local targetId = tonumber(args[1])
    if not targetId then notifyAdmin(source, 'Use: /bring <id>', 'error') return end
    local ok, msg = bringPlayer(source, targetId)
    notifyAdmin(source, msg, ok and 'success' or 'error')
end, false)

RegisterCommand('goto', function(source, args)
    if not HasPermission(source, 'mod') then return end
    local targetId = tonumber(args[1])
    if not targetId then notifyAdmin(source, 'Use: /goto <id>', 'error') return end
    local ok, msg = gotoPlayer(source, targetId)
    notifyAdmin(source, msg, ok and 'success' or 'error')
end, false)

RegisterCommand('setjob', function(source, args)
    if not HasPermission(source, 'admin') then return end
    local targetId = tonumber(args[1])
    local job = args[2]
    local grade = tonumber(args[3]) or 0

    if not targetId then
        notifyAdmin(source, 'Use: /setjob <id> <job> [grade]', 'error')
        notifyAdmin(source, 'Digite /listjobs para ver os cargos disponiveis.', 'inform')
        return
    end

    if not job then
        -- Show list of available jobs
        local jobs = require '@qbx_core.shared.jobs'
        local jobList = {}
        for name, data in pairs(jobs) do
            table.insert(jobList, ('%s - %s'):format(name, data.label))
        end
        table.sort(jobList)
        notifyAdmin(source, ('Cargos disponiveis (%d):'):format(#jobList), 'inform')
        -- Send in batches of 5 to avoid chat spam
        for i = 1, #jobList, 5 do
            local batch = {}
            for j = i, math.min(i + 4, #jobList) do
                table.insert(batch, jobList[j])
            end
            TriggerClientEvent('chat:addMessage', source, {
                args = { 'Sistema', table.concat(batch, '\n') }
            })
        end
        return
    end

    if GetResourceState('qbx_core') == 'started' then
        exports.qbx_core:SetJob(targetId, job, grade)
        notifyAdmin(source, ('Job de %d alterado para %s (grau %d).'):format(targetId, job, grade), 'success')
    end
end, false)

-- ==========================================
-- VEHICLE COMMANDS
-- ==========================================

RegisterCommand('car', function(source, args)
    if not HasPermission(source, 'mod') then return end
    local model = args[1]
    if not model then notifyAdmin(source, 'Use: /car <modelo>', 'error') return end
    TriggerClientEvent('cidade_admin:client:spawnVehicle', source, model)
end, false)

RegisterCommand('dv', function(source)
    if not HasPermission(source, 'mod') then return end
    TriggerClientEvent('cidade_admin:client:deleteVehicle', source)
end, false)

RegisterCommand('repair', function(source)
    if not HasPermission(source, 'mod') then return end
    TriggerClientEvent('cidade_admin:client:repairVehicle', source)
end, false)

RegisterCommand('fix', function(source)
    if not HasPermission(source, 'mod') then return end
    TriggerClientEvent('cidade_admin:client:repairVehicle', source)
end, false)

-- ==========================================
-- ECONOMY COMMANDS
-- ==========================================

RegisterCommand('giveMoney', function(source, args)
    if not HasPermission(source, 'admin') then return end
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    local account = args[3] or 'bank'
    if not targetId or not amount then
        notifyAdmin(source, 'Use: /giveMoney <id> <quantia> [bank|cash]', 'error')
        return
    end
    if exports.cidade_tycoon_core:AddMoney(targetId, account, amount, 'admin-give') then
        notifyAdmin(source, ('$%d adicionado a conta %s de %d.'):format(amount, account, targetId), 'success')
    end
end, false)

RegisterCommand('giveItem', function(source, args)
    if not HasPermission(source, 'admin') then return end
    local targetId = tonumber(args[1])
    local item = args[2]
    local amount = tonumber(args[3]) or 1
    if not targetId or not item then
        notifyAdmin(source, 'Use: /giveItem <id> <item> [quantidade]', 'error')
        return
    end
    if exports.ox_inventory:AddItem(targetId, item, amount) then
        notifyAdmin(source, ('%d x %s adicionado a %d.'):format(amount, item, targetId), 'success')
    end
end, false)

-- ==========================================
-- SERVER COMMANDS
-- ==========================================

RegisterCommand('weather', function(source, args)
    if not HasPermission(source, 'admin') then return end
    local weatherType = args[1]
    if not weatherType then
        notifyAdmin(source, 'Use: /weather <tipo> (EXTRASUNNY, CLEAR, RAIN, THUNDER, FOGGY, XMAS)', 'error')
        return
    end
    TriggerClientEvent('cidade_admin:client:setWeather', -1, weatherType:upper())
    notifyAdmin(source, ('Clima alterado para %s.'):format(weatherType:upper()), 'success')
end, false)

RegisterCommand('time', function(source, args)
    if not HasPermission(source, 'admin') then return end
    local hour = tonumber(args[1])
    local minute = tonumber(args[2]) or 0
    if not hour or hour < 0 or hour > 23 then
        notifyAdmin(source, 'Use: /time <hora> [minuto]', 'error')
        return
    end
    TriggerClientEvent('cidade_admin:client:setTime', -1, hour, minute)
    notifyAdmin(source, ('Horario alterado para %02d:%02d.'):format(hour, minute), 'success')
end, false)

RegisterCommand('announcement', function(source, args)
    if not HasPermission(source, 'admin') then return end
    local msg = table.concat(args, ' ')
    if msg == '' then notifyAdmin(source, 'Use: /announcement <mensagem>', 'error') return end
    TriggerClientEvent('ox_lib:notify', -1, {
        title = 'ANUNCIO',
        description = msg,
        type = 'inform',
        duration = 10000,
    })
end, false)

-- ==========================================
-- TYCOON COMMANDS
-- ==========================================

RegisterCommand('tycoonSetLevel', function(source, args)
    if not HasPermission(source, 'admin') then return end
    local targetId = tonumber(args[1])
    local level = tonumber(args[2])
    if not targetId or not level then
        notifyAdmin(source, 'Use: /tycoonSetLevel <id> <nivel>', 'error')
        return
    end
    if exports.cidade_tycoon_core:SetLevel(targetId, level) then
        notifyAdmin(source, ('Nivel Tycoon de %d definido para %d.'):format(targetId, level), 'success')
    else
        notifyAdmin(source, 'Falha ao definir nivel do jogador.', 'error')
    end
end, false)

RegisterCommand('tycoonGiveXP', function(source, args)
    if not HasPermission(source, 'admin') then return end
    local targetId = tonumber(args[1])
    local xp = tonumber(args[2])
    if not targetId or not xp then
        notifyAdmin(source, 'Use: /tycoonGiveXP <id> <xp>', 'error')
        return
    end
    if exports.cidade_tycoon_core:AddExperience(targetId, xp) then
        notifyAdmin(source, ('%d XP adicionado a %d.'):format(xp, targetId), 'success')
    end
end, false)

RegisterCommand('tycoonSetRep', function(source, args)
    if not HasPermission(source, 'admin') then return end
    local targetId = tonumber(args[1])
    local rep = tonumber(args[2])
    if not targetId or not rep then
        notifyAdmin(source, 'Use: /tycoonSetRep <id> <reputacao>', 'error')
        return
    end
    if exports.cidade_tycoon_core:SetReputation(targetId, rep) then
        notifyAdmin(source, ('Reputacao Tycoon de %d definida para %d.'):format(targetId, rep), 'success')
    else
        notifyAdmin(source, 'Falha ao definir reputacao do jogador.', 'error')
    end
end, false)

RegisterCommand('tycoonReset', function(source, args)
    if not HasPermission(source, 'god') then return end
    local targetId = tonumber(args[1])
    if not targetId then
        notifyAdmin(source, 'Use: /tycoonReset <id>', 'error')
        return
    end
    if exports.cidade_tycoon_core:ResetProfile(targetId) then
        notifyAdmin(source, ('Perfil Tycoon de %d foi resetado para os valores iniciais.'):format(targetId), 'success')
    else
        notifyAdmin(source, 'Falha ao resetar perfil do jogador.', 'error')
    end
end, false)

RegisterCommand('tycoonSetSkill', function(source, args)
    if not HasPermission(source, 'admin') then return end
    local targetId = tonumber(args[1])
    local skillName = args[2]
    local level = tonumber(args[3])
    if not targetId or not skillName or not level then
        notifyAdmin(source, 'Use: /tycoonSetSkill <id> <nome_skill> <nivel>', 'error')
        return
    end
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(targetId)
    if not profile then
        notifyAdmin(source, 'Jogador nao encontrado.', 'error')
        return
    end
    local coreConfig = exports.cidade_tycoon_core:GetCoreConfig()
    if not coreConfig.SkillDefaults[skillName] then
        notifyAdmin(source, 'Habilidade invalida.', 'error')
        return
    end
    profile.skills[skillName] = level
    if exports.cidade_tycoon_core:UpdateSkills(targetId, profile.skills) then
        notifyAdmin(source, ('Habilidade %s de %d definida para nivel %d.'):format(skillName, targetId, level), 'success')
    else
        notifyAdmin(source, 'Falha ao atualizar habilidade.', 'error')
    end
end, false)

-- ==========================================
-- PLAYER LIST (for menu)
-- ==========================================

lib.callback.register('cidade_admin:server:getPlayerList', function(source)
    if not HasPermission(source, 'support') then return {} end
    local players = {}
    local playerList = GetPlayers()
    for _, src in ipairs(playerList) do
        local srcNum = tonumber(src)
        local ped = GetPlayerPed(srcNum)
        local coords = GetEntityCoords(ped)
        local name = GetPlayerName(srcNum)
        local perm = GetPermissionLabel(srcNum)
        local job = nil
        local ok, j = pcall(exports.cidade_tycoon_core.GetPlayerJob, srcNum)
        if ok and j then job = j.name end

        table.insert(players, {
            id = srcNum,
            name = name,
            permission = perm,
            job = job or 'none',
            ping = GetPlayerPing(srcNum),
            coords = { x = math.floor(coords.x), y = math.floor(coords.y), z = math.floor(coords.z) },
        })
    end
    table.sort(players, function(a, b) return a.id < b.id end)
    return players
end)

lib.callback.register('cidade_admin:server:checkPermission', function(source)
    return HasPermission(source, 'support')
end)

lib.callback.register('cidade_admin:server:executeCommand', function(source, command, target)
    if not HasPermission(source, 'mod') then return { ok = false } end
    local ok, msg
    if command == 'bring' and target then
        ok, msg = bringPlayer(source, target)
    elseif command == 'goto' and target then
        ok, msg = gotoPlayer(source, target)
    elseif command == 'freeze' and target then
        ok, msg = freezePlayer(source, target, true)
    elseif command == 'unfreeze' and target then
        ok, msg = freezePlayer(source, target, false)
    elseif command == 'kick' and target then
        ExecuteCommand(('kick %d'):format(target))
        ok = true
    end
    if msg then
        notifyAdmin(source, msg, ok and 'success' or 'error')
    end
    return { ok = ok or false }
end)

-- ==========================================
-- LISTJOBS COMMAND
-- ==========================================

RegisterCommand('listjobs', function(source)
    if not HasPermission(source, 'admin') then
        notifyAdmin(source, 'Sem permissao.', 'error')
        return
    end
    local jobs = require '@qbx_core.shared.jobs'
    local jobList = {}
    for name, data in pairs(jobs) do
        local grades = {}
        for gId, gData in pairs(data.grades) do
            grades[#grades + 1] = ('  [%d] %s%s'):format(gId, gData.name, gData.isboss and ' (boss)' or '')
        end
        table.insert(jobList, ('%s - %s'):format(name, data.label))
        table.sort(grades)
        for _, line in ipairs(grades) do
            table.insert(jobList, line)
        end
    end
    table.sort(jobList)
    TriggerClientEvent('chat:addMessage', source, {
        args = { 'Sistema', ('Cargos disponiveis (%d):'):format(#jobs) }
    })
    for i = 1, #jobList, 8 do
        local batch = {}
        for j = i, math.min(i + 7, #jobList) do
            table.insert(batch, jobList[j])
        end
        TriggerClientEvent('chat:addMessage', source, {
            args = { 'Jobs', table.concat(batch, '\n') }
        })
    end
end, false)

-- ==========================================
-- JOB LIST FOR ADMIN MENU
-- ==========================================

lib.callback.register('cidade_admin:server:getJobList', function(source)
    if not HasPermission(source, 'admin') then return {} end
    local jobs = require '@qbx_core.shared.jobs'
    local list = {}
    for name, data in pairs(jobs) do
        local grades = {}
        for gradeId, gradeData in pairs(data.grades) do
            grades[#grades + 1] = {
                id = gradeId,
                name = gradeData.name,
                isboss = gradeData.isboss or false,
            }
        end
        table.sort(grades, function(a, b) return a.id < b.id end)
        list[#list + 1] = {
            name = name,
            label = data.label,
            grades = grades,
        }
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end)
