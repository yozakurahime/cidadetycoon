-- client/garage_admin.lua
-- Admin commands for managing garages dynamically

local isPositioning = false
local positioningStep = 0 -- 0=idle, 1=accessPoint, 2=spawnPoint
local pendingGarage = {}
local positioningThread = nil

local function notify(msg, type)
    lib.notify({ title = 'Garage Admin', description = msg, type = type or 'inform' })
end

local function cancelPositioning()
    isPositioning = false
    positioningStep = 0
    pendingGarage = {}
    if positioningThread then
        positioningThread = nil
    end
    lib.hideTextUI()
    PlaySoundFrontend(-1, "CANCEL", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
end

local function confirmPosition(stepName)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local vec = vector4(coords.x, coords.y, coords.z, heading)

    if positioningStep == 1 then
        pendingGarage.accessCoords = vec
        notify(('Ponto de acesso salvo! Agora va ate o local de SPAWN do veiculo e pressione E.'):format(stepName), 'success')
        positioningStep = 2
        lib.showTextUI('[E] Confirmar Ponto de SPAWN | [BACKSPACE] Cancelar', {
            position = "right-center",
            icon = "car-side",
        })
    elseif positioningStep == 2 then
        pendingGarage.spawnCoords = vec
        notify('Ponto de spawn salvo!', 'success')
        -- Open config dialog
        openGarageConfigDialog()
    end
end

local function openGarageConfigDialog()
    isPositioning = false
    positioningStep = 0
    lib.hideTextUI()

    local input = lib.inputDialog('Configurar Nova Garagem', {
        {
            type = 'input',
            label = 'Nome da Garagem',
            description = 'Nome que aparecera no mapa e menus.',
            icon = 'signature',
            required = true,
            max = 40,
        },
        {
            type = 'select',
            label = 'Tipo de Veiculo',
            description = 'Que tipo de veiculo esta garagem aceita.',
            icon = 'car',
            options = {
                { value = 'car', label = 'Carro' },
                { value = 'air', label = 'Aereo' },
                { value = 'sea', label = 'Nautico' },
            },
            default = 'car',
        },
        {
            type = 'input',
            label = 'Restricao de Grupo (opcional)',
            description = 'Ex: police, mechanic, ballas. Deixe vazio para publico.',
            icon = 'user-lock',
            max = 30,
        },
        {
            type = 'checkbox',
            label = 'Mostrar no mapa',
            description = 'Exibir um blip no mapa para esta garagem.',
        },
    })

    if not input then
        cancelPositioning()
        notify('Criacao de garagem cancelada.', 'error')
        return
    end

    local label = input[1]
    local vehicleType = input[2]
    local groups = input[3] or ''
    local blipVisible = input[4]

    if not label or label == '' then
        notify('Nome da garagem e obrigatorio.', 'error')
        return
    end

    local data = {
        label = label,
        accessCoords = pendingGarage.accessCoords,
        spawnCoords = pendingGarage.spawnCoords,
        vehicleType = vehicleType or 'car',
        groups = (groups and groups ~= '') and groups or nil,
        blipVisible = (blipVisible == true),
    }

    local res = lib.callback.await('cidade_garagem_eye:server:addGarage', false, data)
    if res and res.ok then
        notify(res.message, 'success')
        PlaySoundFrontend(-1, "PURCHASE_ACK", "HUD_LIQUIPEDIA_SOUNDSET", 1)
    else
        notify(res and res.message or 'Falha ao criar garagem.', 'error')
    end

    pendingGarage = {}
end

-- ==========================================
-- COMMANDS
-- ==========================================

-- /addgarage - Starts the garage positioning wizard
RegisterCommand('addgaragem', function()
    if isPositioning then
        notify('Voce ja esta posicionando uma garagem! Use BACKSPACE para cancelar.', 'error')
        return
    end

    isPositioning = true
    positioningStep = 1
    pendingGarage = {}

    notify('Modo de criacao de garagem ativado!', 'inform')
    notify('Passo 1: Va ate o local de ACESSO (onde o NPC ficara) e pressione E.', 'inform')

    lib.showTextUI('[E] Confirmar Ponto de ACESSO | [BACKSPACE] Cancelar', {
        position = "right-center",
        icon = "warehouse",
    })

    positioningThread = CreateThread(function()
        while isPositioning do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            -- Draw green marker under player
            DrawMarker(1, coords.x, coords.y, coords.z - 0.98,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.5, 1.5, 0.5,
                0, 255, 0, 120,
                false, false, 2, false, nil, nil, false
            )

            -- Confirm (E)
            if IsControlJustPressed(0, 38) then
                confirmPosition()
            end

            -- Cancel (BACKSPACE)
            if IsControlJustPressed(0, 177) then
                cancelPositioning()
                notify('Posicionamento de garagem cancelado.', 'inform')
                break
            end

            Wait(0)
        end
    end)
end, false)

-- /listargaragen - List all custom garages
RegisterCommand('listargaragen', function()
    local garages = lib.callback.await('cidade_garagem_eye:server:listGarages', false)
    if not garages or #garages == 0 then
        notify('Nenhuma garagem customizada encontrada.', 'inform')
        return
    end

    local lines = {}
    for _, g in ipairs(garages) do
        local blipStatus = g.hasBlip and '🟢 No mapa' or '🔴 Oculta'
        lines[#lines + 1] = ('%s | %s | Grupo: %s | %s'):format(g.label, g.name, g.groups or 'publico', blipStatus)
    end

    lib.alertDialog({
        header = ('Garagens Customizadas (%d)'):format(#garages),
        content = table.concat(lines, '\n'),
        centered = true,
        cancel = false,
    })
end, false)

-- /delgaragem [name] - Remove a custom garage
RegisterCommand('delgaragem', function(_, args)
    local name = args[1]
    if not name then
        notify('Use: /delgaragem <nome_da_garagem>', 'error')
        -- Show available garages
        local garages = lib.callback.await('cidade_garagem_eye:server:listGarages', false)
        if garages and #garages > 0 then
            local names = {}
            for _, g in ipairs(garages) do
                names[#names + 1] = g.name
            }
            notify(('Garagens disponiveis: %s'):format(table.concat(names, ', ')), 'inform')
        end
        return
    end

    local confirm = lib.alertDialog({
        header = 'Remover Garagem',
        content = ('Deseja remover a garagem **%s**? (Efetivo apos restart do servidor)'):format(name),
        centered = true,
        cancel = true,
    })

    if confirm ~= 'confirm' then return end

    local res = lib.callback.await('cidade_garagem_eye:server:removeGarage', false, name)
    notify(res.message, res.ok and 'success' or 'error')
end, false)

-- /editgaragem [name] - Edit a garage's config
RegisterCommand('editgaragem', function(_, args)
    local name = args[1]
    if not name then
        notify('Use: /editgaragem <nome_da_garagem>', 'error')
        return
    end

    local garages = lib.callback.await('cidade_garagem_eye:server:listGarages', false)
    local found = nil
    for _, g in ipairs(garages) do
        if g.name == name then
            found = g
            break
        end
    end

    if not found then
        notify('Garagem nao encontrada: ' .. name, 'error')
        return
    end

    local input = lib.inputDialog(('Editar: %s'):format(found.label), {
        {
            type = 'input',
            label = 'Nome',
            description = 'Nome da garagem',
            icon = 'signature',
            default = found.label,
        },
        {
            type = 'select',
            label = 'Tipo de Veiculo',
            icon = 'car',
            options = {
                { value = 'car', label = 'Carro' },
                { value = 'air', label = 'Aereo' },
                { value = 'sea', label = 'Nautico' },
            },
            default = found.vehicleType or 'car',
        },
        {
            type = 'input',
            label = 'Grupo (opcional)',
            description = 'Ex: police. Deixe vazio para publico.',
            icon = 'user-lock',
            default = found.groups ~= 'publico' and found.groups or '',
        },
        {
            type = 'checkbox',
            label = 'Mostrar no mapa',
            default = found.hasBlip,
        },
    })

    if not input then return end

    local updates = {
        label = input[1],
        vehicleType = input[2] or 'car',
        groups = input[3] or '',
        blipVisible = input[4] == true,
    }

    local res = lib.callback.await('cidade_garagem_eye:server:updateGarage', false, name, updates)
    notify(res.message, res.ok and 'success' or 'error')
end, false)

-- Help command
RegisterCommand('garagemadmin', function()
    notify('Comandos: /addgaragem, /editgaragem <nome>, /delgaragem <nome>, /listargaragen', 'inform')
end, false)
