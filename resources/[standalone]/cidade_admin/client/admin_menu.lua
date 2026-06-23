-- client/admin_menu.lua
-- Admin menu interface using lib.context

local currentTarget = nil
local currentPlayers = {}

-- ==========================================
-- NOTIFY HELPER
-- ==========================================

local function notify(msg, type)
    lib.notify({ title = 'Admin', description = msg, type = type or 'inform' })
end

-- ==========================================
-- PERMISSION CHECK
-- ==========================================

local function getPermission()
    -- Client-side approximate check; real check is server-side
    local perm = LocalPlayer.state.adminPermission
    if not perm then
        -- Try to get from server
        -- For now just show menu and let server reject actions
        return 'unknown'
    end
    return perm
end

-- ==========================================
-- PLAYER LIST
-- ==========================================

local function refreshPlayerList()
    currentPlayers = lib.callback.await('cidade_admin:server:getPlayerList', false) or {}
    return currentPlayers
end

local function openPlayerActions(player)
    currentTarget = player
    local options = {
        {
            title = ('%s [%d]'):format(player.name, player.id),
            description = ('Job: %s | Ping: %dms | Perm: %s'):format(player.job, player.ping, player.permission),
            icon = 'user',
            readOnly = true,
        },
        {
            title = 'Teleportar ate mim (Bring)',
            description = 'Traz o jogador para sua localizacao.',
            icon = 'person-arrow-down-to-line',
            onSelect = function()
                lib.callback.await('cidade_admin:server:executeCommand', false, 'bring', player.id)
                notify(('Trazendo %s...'):format(player.name), 'success')
            end,
        },
        {
            title = 'Ir ate o jogador (Goto)',
            description = 'Teleporta voce ate o jogador.',
            icon = 'person-arrow-up-from-line',
            onSelect = function()
                lib.callback.await('cidade_admin:server:executeCommand', false, 'goto', player.id)
                notify(('Indo ate %s...'):format(player.name), 'success')
            end,
        },
        {
            title = 'Congelar / Descongelar',
            description = 'Alterna o estado de congelamento do jogador.',
            icon = 'snowflake',
            onSelect = function()
                lib.callback.await('cidade_admin:server:executeCommand', false, 'freeze', player.id)
                notify(('Alternando freeze de %s.'):format(player.name), 'success')
            end,
        },
        {
            title = 'Advertir (Warn)',
            description = 'Envia uma advertencia ao jogador.',
            icon = 'triangle-exclamation',
            onSelect = function()
                local input = lib.inputDialog('Advertir ' .. player.name, {
                    { type = 'input', label = 'Motivo', icon = 'message', required = true },
                })
                if input then
                    ExecuteCommand(('warn %d %s'):format(player.id, input[1]))
                end
            end,
        },
        {
            title = 'Kickar',
            description = 'Remove o jogador do servidor.',
            icon = 'user-slash',
            iconColor = 'red',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Kickar Jogador',
                    content = ('Deseja kickar **%s** (ID: %d)?'):format(player.name, player.id),
                    centered = true,
                    cancel = true,
                })
                if confirm == 'confirm' then
                    local input = lib.inputDialog('Motivo do Kick', {
                        { type = 'input', label = 'Motivo', icon = 'message', default = 'Kickado por administrador.' },
                    })
                    if input then
                        ExecuteCommand(('kick %d %s'):format(player.id, input[1]))
                    end
                end
            end,
        },
    }

    lib.registerContext({
        id = 'admin_player_actions',
        title = ('Gerenciar: %s'):format(player.name),
        menu = 'admin_player_list',
        options = options,
    })
    lib.showContext('admin_player_actions')
end

local function openPlayerList()
    local players = refreshPlayerList()
    if #players == 0 then
        notify('Nenhum jogador online.', 'error')
        return
    end

    local options = {}
    for _, p in ipairs(players) do
        local permIcon = p.permission == 'god' and '👑' or p.permission == 'admin' and '⭐' or p.permission == 'mod' and '🛡️' or ''
        options[#options + 1] = {
            title = ('[%d] %s %s'):format(p.id, p.name, permIcon),
            description = ('Job: %s | Ping: %dms'):format(p.job, p.ping),
            icon = p.permission ~= 'player' and 'crown' or 'user',
            iconColor = p.permission ~= 'player' and '#ff9f0a' or '#8e8e93',
            arrow = true,
            onSelect = function()
                openPlayerActions(p)
            end,
        }
    end

    lib.registerContext({
        id = 'admin_player_list',
        title = ('Jogadores Online (%d)'):format(#players),
        menu = 'admin_main',
        options = options,
    })
    lib.showContext('admin_player_list')
end

-- ==========================================
-- VEHICLE TOOLS
-- ==========================================

local function openVehicleTools()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    local inVehicle = veh ~= 0

    local options = {
        {
            title = 'Spawnar Veiculo',
            description = 'Digite o nome do modelo (ex: adder, faggio).',
            icon = 'car',
            onSelect = function()
                local input = lib.inputDialog('Spawnar Veiculo', {
                    { type = 'input', label = 'Modelo', description = 'Nome do modelo do veiculo.', icon = 'car', required = true },
                })
                if input then
                    ExecuteCommand(('car %s'):format(input[1]))
                end
            end,
        },
        {
            title = 'Deletar Veiculo Atual',
            description = inVehicle and 'Deleta o veiculo que voce esta.' or 'Nenhum veiculo encontrado.',
            icon = 'trash',
            disabled = not inVehicle,
            onSelect = function()
                ExecuteCommand('dv')
            end,
        },
        {
            title = 'Reparar Veiculo',
            description = inVehicle and 'Repara o veiculo que voce esta.' or 'Nenhum veiculo encontrado.',
            icon = 'wrench',
            disabled = not inVehicle,
            onSelect = function()
                ExecuteCommand('repair')
            end,
        },
    }

    lib.registerContext({
        id = 'admin_vehicle_tools',
        title = 'Ferramentas de Veiculo',
        menu = 'admin_main',
        options = options,
    })
    lib.showContext('admin_vehicle_tools')
end

-- ==========================================
-- ECONOMY TOOLS
-- ==========================================

local function openEconomyTools()
    local players = refreshPlayerList()
    local playerOptions = {}
    for _, p in ipairs(players) do
        playerOptions[#playerOptions + 1] = { value = p.id, label = ('[%d] %s'):format(p.id, p.name) }
    end

    local options = {
        {
            title = 'Dar Dinheiro',
            description = 'Adiciona dinheiro a conta de um jogador.',
            icon = 'dollar-sign',
            onSelect = function()
                local input = lib.inputDialog('Dar Dinheiro', {
                    { type = 'select', label = 'Jogador', options = playerOptions, icon = 'user' },
                    { type = 'number', label = 'Quantia', icon = 'dollar-sign', required = true, min = 1, default = 1000 },
                    { type = 'select', label = 'Conta', options = { { value = 'bank', label = 'Banco' }, { value = 'cash', label = 'Carteira' } }, default = 'bank' },
                })
                if input then
                    ExecuteCommand(('giveMoney %d %d %s'):format(input[1], input[2], input[3]))
                end
            end,
        },
        {
            title = 'Dar Item',
            description = 'Adiciona um item ao inventario de um jogador.',
            icon = 'box',
            onSelect = function()
                local input = lib.inputDialog('Dar Item', {
                    { type = 'select', label = 'Jogador', options = playerOptions, icon = 'user' },
                    { type = 'input', label = 'Item', description = 'Nome do item (ex: tablet, water).', icon = 'box', required = true },
                    { type = 'number', label = 'Quantidade', icon = 'hashtag', default = 1, min = 1 },
                })
                if input then
                    ExecuteCommand(('giveItem %d %s %d'):format(input[1], input[2], input[3] or 1))
                end
            end,
        },
        {
            title = 'Setar Job',
            description = 'Altera o cargo de um jogador.',
            icon = 'briefcase',
            onSelect = function()
                local jobs = lib.callback.await('cidade_admin:server:getJobList', false) or {}
                if #jobs == 0 then
                    notify('Nenhum job encontrado.', 'error')
                    return
                end
                local jobOptions = {}
                for _, j in ipairs(jobs) do
                    jobOptions[#jobOptions + 1] = { value = j.name, label = ('%s (%s)'):format(j.label, j.name) }
                end
                local input = lib.inputDialog('Setar Job', {
                    { type = 'select', label = 'Jogador', options = playerOptions, icon = 'user' },
                    { type = 'select', label = 'Cargo', options = jobOptions, icon = 'briefcase', searchable = true },
                    { type = 'number', label = 'Grau', icon = 'hashtag', default = 0, min = 0 },
                })
                if input then
                    ExecuteCommand(('setjob %d %s %d'):format(input[1], input[2], input[3] or 0))
                end
            end,
        },
    }

    lib.registerContext({
        id = 'admin_economy',
        title = 'Economia',
        menu = 'admin_main',
        options = options,
    })
    lib.showContext('admin_economy')
end

-- ==========================================
-- SERVER TOOLS
-- ==========================================

local function openServerTools()
    local options = {
        {
            title = 'Alterar Clima',
            description = 'Muda o clima do servidor.',
            icon = 'cloud-sun',
            onSelect = function()
                local input = lib.inputDialog('Alterar Clima', {
                    {
                        type = 'select',
                        label = 'Clima',
                        options = {
                            { value = 'EXTRASUNNY', label = 'Ensolarado' },
                            { value = 'CLEAR', label = 'Limpo' },
                            { value = 'CLOUDS', label = 'Nublado' },
                            { value = 'RAIN', label = 'Chuva' },
                            { value = 'THUNDER', label = 'Tempestade' },
                            { value = 'FOGGY', label = 'Neblina' },
                            { value = 'XMAS', label = 'Neve' },
                        },
                        icon = 'cloud',
                    },
                })
                if input then
                    ExecuteCommand(('weather %s'):format(input[1]))
                end
            end,
        },
        {
            title = 'Alterar Horario',
            description = 'Muda o horario do servidor.',
            icon = 'clock',
            onSelect = function()
                local input = lib.inputDialog('Alterar Horario', {
                    { type = 'slider', label = 'Hora', min = 0, max = 23, default = 12, icon = 'clock' },
                    { type = 'slider', label = 'Minuto', min = 0, max = 59, default = 0, icon = 'clock' },
                })
                if input then
                    ExecuteCommand(('time %d %d'):format(input[1], input[2]))
                end
            end,
        },
        {
            title = 'Anuncio Global',
            description = 'Envia uma mensagem para todos os jogadores.',
            icon = 'bullhorn',
            onSelect = function()
                local input = lib.inputDialog('Anuncio Global', {
                    { type = 'input', label = 'Mensagem', icon = 'message', required = true },
                })
                if input then
                    ExecuteCommand(('announcement %s'):format(input[1]))
                end
            end,
        },
    }

    lib.registerContext({
        id = 'admin_server',
        title = 'Servidor',
        menu = 'admin_main',
        options = options,
    })
    lib.showContext('admin_server')
end

-- ==========================================
-- TYCOON TOOLS
-- ==========================================

local function openTycoonTools()
    local players = refreshPlayerList()
    local playerOptions = {}
    for _, p in ipairs(players) do
        playerOptions[#playerOptions + 1] = { value = p.id, label = ('[%d] %s'):format(p.id, p.name) }
    end

    local options = {
        {
            title = 'Setar Nivel',
            description = 'Ajusta o nivel Tycoon de um jogador.',
            icon = 'arrow-up-from-bracket',
            iconColor = '#ff6482',
            onSelect = function()
                local input = lib.inputDialog('Setar Nivel Tycoon', {
                    { type = 'select', label = 'Jogador', options = playerOptions, icon = 'user' },
                    { type = 'slider', label = 'Nivel', min = 1, max = 100, default = 1, icon = 'hashtag' },
                })
                if input then
                    ExecuteCommand(('tycoonSetLevel %d %d'):format(input[1], input[2]))
                end
            end,
        },
        {
            title = 'Adicionar XP',
            description = 'Adiciona experiencia Tycoon a um jogador.',
            icon = 'star',
            iconColor = '#ff9f0a',
            onSelect = function()
                local input = lib.inputDialog('Adicionar XP', {
                    { type = 'select', label = 'Jogador', options = playerOptions, icon = 'user' },
                    { type = 'number', label = 'XP', icon = 'star', required = true, min = 1, default = 1000 },
                })
                if input then
                    ExecuteCommand(('tycoonGiveXP %d %d'):format(input[1], input[2]))
                end
            end,
        },
        {
            title = 'Dar Tablet',
            description = 'Garante um tablet a um jogador.',
            icon = 'tablet',
            iconColor = '#5ac8fa',
            onSelect = function()
                local input = lib.inputDialog('Dar Tablet', {
                    { type = 'select', label = 'Jogador', options = playerOptions, icon = 'user' },
                })
                if input then
                    ExecuteCommand(('giveItem %d tablet 1'):format(input[1]))
                end
            end,
        },
    }

    lib.registerContext({
        id = 'admin_tycoon',
        title = 'Tycoon',
        menu = 'admin_main',
        options = options,
    })
    lib.showContext('admin_tycoon')
end

-- ==========================================
-- GARAGE MANAGEMENT
-- ==========================================

local function openGarageTools()
    local options = {
        {
            title = 'Adicionar Garagem',
            description = 'Inicia o assistente de criacao de garagem.',
            icon = 'warehouse',
            onSelect = function()
                ExecuteCommand('addgaragem')
            end,
        },
        {
            title = 'Listar Garagens',
            description = 'Mostra todas as garagens customizadas.',
            icon = 'list',
            onSelect = function()
                ExecuteCommand('listargaragen')
            end,
        },
    }

    lib.registerContext({
        id = 'admin_garages',
        title = 'Gerenciar Garagens',
        menu = 'admin_main',
        options = options,
    })
    lib.showContext('admin_garages')
end

-- ==========================================
-- MAIN MENU
-- ==========================================

local function openAdminMenu()
    local playerData = exports.qbx_core:GetPlayerData()
    local isAdmin = playerData and (playerData.job.name == 'admin' or playerData.job.name == 'god')

    local options = {
        {
            title = 'Jogadores Online',
            description = 'Lista de jogadores e acoes.',
            icon = 'users',
            iconColor = '#5ac8fa',
            arrow = true,
            onSelect = openPlayerList,
        },
        {
            title = 'Veiculos',
            description = 'Spawnar, deletar e reparar veiculos.',
            icon = 'car',
            iconColor = '#34c759',
            arrow = true,
            onSelect = openVehicleTools,
        },
        {
            title = 'Economia',
            description = 'Dar dinheiro, itens e setar jobs.',
            icon = 'dollar-sign',
            iconColor = '#ff9f0a',
            arrow = true,
            onSelect = openEconomyTools,
        },
        {
            title = 'Servidor',
            description = 'Clima, horario e anuncios.',
            icon = 'server',
            iconColor = '#bf5af2',
            arrow = true,
            onSelect = openServerTools,
        },
        {
            title = 'Tycoon',
            description = 'Gerenciar niveis, XP e progressao.',
            icon = 'building',
            iconColor = '#ff6482',
            arrow = true,
            onSelect = openTycoonTools,
        },
        {
            title = 'Garagens',
            description = 'Adicionar e listar garagens customizadas.',
            icon = 'warehouse',
            iconColor = '#8e8e93',
            arrow = true,
            onSelect = openGarageTools,
        },
    }

    lib.registerContext({
        id = 'admin_main',
        title = 'Painel Administrativo',
        options = options,
    })
    lib.showContext('admin_main')
end

-- ==========================================
-- CLIENT-SIDE COMMAND HANDLERS
-- ==========================================

RegisterNetEvent('cidade_admin:client:spawnVehicle', function(model)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local vehicle = GetHashKey(model)
    if not IsModelInCdimage(vehicle) then
        notify(('Modelo %s nao encontrado.'):format(model), 'error')
        return
    end
    RequestModel(vehicle)
    while not HasModelLoaded(vehicle) do Wait(10) end
    local veh = CreateVehicle(vehicle, coords.x + 2.0, coords.y + 2.0, coords.z, heading, true, false)
    SetPedIntoVehicle(ped, veh, -1)
    SetModelAsNoLongerNeeded(vehicle)
    notify(('Veiculo %s spawnado.'):format(model), 'success')
end)

RegisterNetEvent('cidade_admin:client:deleteVehicle', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        veh = lib.getClosestVehicle(GetEntityCoords(ped), 5.0)
    end
    if veh and DoesEntityExist(veh) then
        DeleteEntity(veh)
        notify('Veiculo deletado.', 'success')
    end
end)

RegisterNetEvent('cidade_admin:client:repairVehicle', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        veh = lib.getClosestVehicle(GetEntityCoords(ped), 5.0)
    end
    if veh and DoesEntityExist(veh) then
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleDirtLevel(veh, 0.0)
        notify('Veiculo reparado.', 'success')
    end
end)

RegisterNetEvent('cidade_admin:client:freezePlayer', function(state)
    SetPlayerControl(PlayerId(), not state, false)
    if state then
        FreezeEntityPosition(PlayerPedId(), true)
        notify('Voce foi congelado por um administrador.', 'error')
    else
        FreezeEntityPosition(PlayerPedId(), false)
        notify('Voce foi descongelado.', 'success')
    end
end)

RegisterNetEvent('cidade_admin:client:teleport', function(x, y, z)
    SetEntityCoords(PlayerPedId(), x, y, z)
end)

RegisterNetEvent('cidade_admin:client:setWeather', function(weather)
    -- ClearOverrideWeather()
    -- ClearWeatherTypePersist()
    -- SetWeatherTypePersist(weather)
    -- SetWeatherTypeNow(weather)
    -- SetWeatherTypeNowPersist(weather)
    notify(('Clima alterado para %s.'):format(weather), 'success')
end)

RegisterNetEvent('cidade_admin:client:setTime', function(hour, minute)
    NetworkOverrideClockTime(hour, minute, 0)
    notify(('Horario alterado para %02d:%02d.'):format(hour, minute), 'success')
end)

-- ==========================================
-- COMMAND TO OPEN MENU
-- ==========================================

RegisterCommand('admin', function()
    openAdminMenu()
end, false)

RegisterCommand('painel', function()
    openAdminMenu()
end, false)

-- Key mapping
RegisterKeyMapping('admin', 'Abrir Painel Administrativo', 'keyboard', 'F7')
