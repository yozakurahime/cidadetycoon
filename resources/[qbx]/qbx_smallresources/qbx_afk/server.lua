local config = lib.loadJson('qbx_afk.config')

local loggedInPlayers = {}
local checkUser = {}

local function updateCheckUser(source)
    local permissions = exports.qbx_core:GetPermission(source)

    for k in pairs(permissions) do
        if config.ignoreGroupsForAFK[k] then
            checkUser[source] = false
            return
        end
    end

    checkUser[source] = true
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    loggedInPlayers[source] = true
    updateCheckUser(source)
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    loggedInPlayers[source] = false
    checkUser[source] = false
    Player(source).state:set('isAFK', false, true)
end)

AddEventHandler('QBCore:Server:OnPermissionUpdate', function(source)
    updateCheckUser(source)
end)

-- Sincronização de Estado AFK (Usado para Modo Pacífico e Visual)
RegisterNetEvent('qbx_afk:server:setAFK', function(isAFK)
    local src = source
    Player(src).state:set('isAFK', isAFK, true)
end)
