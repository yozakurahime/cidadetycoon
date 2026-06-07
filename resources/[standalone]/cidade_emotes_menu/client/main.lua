local menuOpen = false
local previewPed = nil
local cachedByCategory = nil
local currentCategory = 2
local currentIndex = 1
local searchTerm = nil
local openMenu

local categories = {
    { key = 'search', label = 'Busca', source = nil },
    { key = 'emotes', label = 'Emotes', source = 'Emotes' },
    { key = 'dances', label = 'Dancas', source = 'Dances' },
    { key = 'props', label = 'Props', source = 'PropEmotes' },
    { key = 'wc2', label = 'WC 2do', source = 'White2do' },
    { key = 'wc3', label = 'WC 3ro', source = 'White3ro' },
    { key = 'wc4', label = 'WC 4ro', source = 'White4ro' },
    { key = 'wc5', label = 'WC 5to', source = 'White5to' },
    { key = 'shared', label = 'Duplas', source = 'Shared' },
    { key = 'walks', label = 'Andares', source = 'Walks' },
    { key = 'expressions', label = 'Rostos', source = 'Expressions' },
    { key = 'animals', label = 'Animais', source = 'AnimalEmotes' }
}

local function notify(description, notifyType)
    lib.notify({
        title = 'Cidade Emotes',
        description = description,
        type = notifyType or 'inform'
    })
end

local function rotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))

    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function getLabel(name, data)
    if type(data) ~= 'table' then return name end
    if type(data.AnimationOptions) == 'table' and data.AnimationOptions.Label then
        return data.AnimationOptions.Label
    end
    if type(data[3]) == 'string' then return data[3] end
    if type(data[2]) == 'string' and (not data[1] or data[1] == 'Scenario' or data[1] == 'ScenarioObject' or data[1] == 'MaleScenario') then
        return data[2]
    end
    if type(data[2]) == 'string' and type(data[1]) ~= 'string' then return data[2] end
    return name:gsub('^%l', string.upper)
end

local function getFlag(options)
    if type(options) ~= 'table' then return 1 end
    if options.EmoteMoving then return 49 end
    if options.EmoteLoop then return 1 end
    return 1
end

local function addCategory(list, category)
    local source = category.source
    if not source or not RP or type(RP[source]) ~= 'table' then return end

    for name, data in pairs(RP[source]) do
        if type(data) == 'table' then
            local options = data.AnimationOptions or {}
            list[#list + 1] = {
                name = name,
                label = getLabel(name, data),
                category = category.key,
                categoryLabel = category.label,
                dict = data[1],
                anim = data[2],
                flag = getFlag(options),
                hasProp = options.Prop ~= nil,
                shared = category.key == 'shared'
            }
        end
    end
end

local function buildLists()
    if cachedByCategory then return cachedByCategory end

    cachedByCategory = {}
    for _, category in ipairs(categories) do
        local items = {}
        if category.source then
            addCategory(items, category)
        end
        table.sort(items, function(a, b)
            return a.label:lower() < b.label:lower()
        end)
        cachedByCategory[category.key] = items
    end

    return cachedByCategory
end

local function allSearchableEmotes()
    local lists = buildLists()
    local merged = {}

    for _, category in ipairs(categories) do
        if category.key ~= 'search' then
            for _, emote in ipairs(lists[category.key] or {}) do
                merged[#merged + 1] = emote
            end
        end
    end

    return merged
end

local function getCurrentItems()
    local lists = buildLists()
    return lists[categories[currentCategory].key] or {}
end

local function currentEmote()
    local items = getCurrentItems()
    return items[currentIndex]
end

local function sendState()
    local items = getCurrentItems()

    SendNUIMessage({
        action = menuOpen and 'open' or 'close',
        categories = categories,
        categoryIndex = currentCategory,
        items = items,
        selectedIndex = currentIndex,
        total = #items,
        searchTerm = searchTerm
    })
end

local function deletePreviewPed()
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
    end
    previewPed = nil
end

local function closeMenu()
    menuOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    deletePreviewPed()
    sendState()
end

local function ensurePreviewPed()
    if previewPed and DoesEntityExist(previewPed) then return previewPed end

    local playerPed = PlayerPedId()
    previewPed = ClonePed(playerPed, 0.0, false, true)
    SetEntityInvincible(previewPed, true)
    SetEntityCollision(previewPed, false, false)
    FreezeEntityPosition(previewPed, true)
    SetBlockingOfNonTemporaryEvents(previewPed, true)
    SetEntityAsMissionEntity(previewPed, true, true)

    return previewPed
end

local function positionPreviewPed()
    if not previewPed or not DoesEntityExist(previewPed) then return end

    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local forward = rotationToDirection(camRot)
    local right = vector3(forward.y, -forward.x, 0.0)
    local coords = camCoords + (forward * 3.15) + (right * 1.45) - vector3(0.0, 0.0, 0.38)
    local heading = GetHeadingFromVector_2d(camCoords.x - coords.x, camCoords.y - coords.y)

    SetEntityCoordsNoOffset(previewPed, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(previewPed, heading)
end

local function loadAnimDict(dict)
    if not dict or dict == '' then return false end
    RequestAnimDict(dict)

    local deadline = GetGameTimer() + 3500
    while not HasAnimDictLoaded(dict) and GetGameTimer() < deadline do
        Wait(10)
    end

    return HasAnimDictLoaded(dict)
end

local function playPreview(data)
    if type(data) ~= 'table' then return end

    local ped = ensurePreviewPed()
    if not ped or not DoesEntityExist(ped) then return end

    positionPreviewPed()
    ClearPedTasksImmediately(ped)

    if data.category == 'walks' and data.dict then
        RequestAnimSet(data.dict)
        local deadline = GetGameTimer() + 2500
        while not HasAnimSetLoaded(data.dict) and GetGameTimer() < deadline do
            Wait(10)
        end
        if HasAnimSetLoaded(data.dict) then
            SetPedMovementClipset(ped, data.dict, 0.2)
        end
        return
    end

    if data.category == 'expressions' and data.dict then
        SetFacialIdleAnimOverride(ped, data.dict, 0)
        return
    end

    if data.dict == 'Scenario' or data.dict == 'ScenarioObject' or data.dict == 'MaleScenario' then
        if data.anim then
            TaskStartScenarioInPlace(ped, data.anim, 0, true)
        end
        return
    end

    if loadAnimDict(data.dict) then
        TaskPlayAnim(ped, data.dict, data.anim or '', 4.0, 4.0, -1, data.flag or 1, 0.0, false, false, false)
    end
end

local function playSelected()
    local data = currentEmote()
    if type(data) ~= 'table' or not data.name then return end

    closeMenu()

    if data.category == 'walks' then
        ExecuteCommand(('walk %s'):format(data.name))
        return
    end

    if data.category == 'expressions' then
        ExecuteCommand(('mood %s'):format(data.name))
        return
    end

    if data.category == 'shared' then
        ExecuteCommand(('nearby %s'):format(data.name))
        return
    end

    exports['cidade_emotes']:EmoteCommandStart(data.name, 0)
end

local function applySearch(term)
    local normalized = term and term:lower():gsub('^%s+', ''):gsub('%s+$', '') or ''
    local lists = buildLists()
    local matches = {}

    searchTerm = normalized ~= '' and normalized or nil

    if searchTerm then
        for _, emote in ipairs(allSearchableEmotes()) do
            local name = emote.name:lower()
            local label = emote.label:lower()
            local category = emote.categoryLabel:lower()

            if name:find(searchTerm, 1, true) or label:find(searchTerm, 1, true) or category:find(searchTerm, 1, true) then
                matches[#matches + 1] = emote
                if #matches >= 350 then break end
            end
        end
    end

    lists.search = matches
    currentCategory = searchTerm and 1 or 2
    currentIndex = #matches > 0 and 1 or 1
    sendState()

    if #matches > 0 then
        playPreview(currentEmote())
    elseif not searchTerm then
        playPreview(currentEmote())
    else
        notify(searchTerm and 'Nenhuma animacao encontrada.' or 'Busca limpa.', searchTerm and 'error' or 'inform')
        deletePreviewPed()
    end
end

local function openSearch()
    if not menuOpen then
        openMenu()
        Wait(100)
    end

    local result = lib.inputDialog('Pesquisar animacao', {
        {
            type = 'input',
            label = 'Nome da animacao',
            placeholder = 'Ex: salute, dance, selfie...',
            default = searchTerm or '',
            required = false
        }
    })

    if not result then return end

    applySearch(result[1])
end

local function selectRelative(delta)
    if not menuOpen then return end

    local items = getCurrentItems()
    if #items == 0 then return end

    currentIndex = currentIndex + delta
    if currentIndex < 1 then currentIndex = #items end
    if currentIndex > #items then currentIndex = 1 end
    sendState()
    playPreview(currentEmote())
end

local function categoryRelative(delta)
    if not menuOpen then return end

    currentCategory = currentCategory + delta
    if currentCategory < 1 then currentCategory = #categories end
    if currentCategory > #categories then currentCategory = 1 end
    currentIndex = 1
    sendState()
    playPreview(currentEmote())
end

function openMenu()
    if menuOpen then
        closeMenu()
        return
    end

    buildLists()
    currentCategory = math.max(1, math.min(currentCategory, #categories))
    currentIndex = 1
    menuOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    sendState()
    playPreview(currentEmote())
end

RegisterCommand('emotemenu', openMenu, false)
RegisterCommand('emotesmenu', openMenu, false)
RegisterCommand('emotesfix', closeMenu, false)
RegisterCommand('emotes_up', function() selectRelative(-1) end, false)
RegisterCommand('emotes_down', function() selectRelative(1) end, false)
RegisterCommand('emotes_left', function() categoryRelative(-1) end, false)
RegisterCommand('emotes_right', function() categoryRelative(1) end, false)
RegisterCommand('emotes_play', function() if menuOpen then playSelected() end end, false)
RegisterCommand('emotes_preview', function() if menuOpen then playPreview(currentEmote()) end end, false)
RegisterCommand('emotes_close', function() if menuOpen then closeMenu() end end, false)

RegisterKeyMapping('emotemenu', 'Abrir menu de emotes Cidade Tycoon', 'keyboard', 'F3')

RegisterNUICallback('search', function(data, cb)
    applySearch(data and data.term)
    cb('ok')
end)

RegisterNUICallback('navigate', function(data, cb)
    selectRelative((data and data.delta) or 0)
    cb('ok')
end)

RegisterNUICallback('category', function(data, cb)
    categoryRelative((data and data.delta) or 0)
    cb('ok')
end)

RegisterNUICallback('play', function(_, cb)
    playSelected()
    cb('ok')
end)

RegisterNUICallback('preview', function(_, cb)
    if menuOpen then playPreview(currentEmote()) end
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb('ok')
end)

CreateThread(function()
    Wait(500)
    closeMenu()

    while true do
        if menuOpen and previewPed and DoesEntityExist(previewPed) then
            positionPreviewPed()
            Wait(0)
        else
            Wait(250)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        closeMenu()
    end
end)
