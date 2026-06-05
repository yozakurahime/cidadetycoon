local QBCore = exports['qb-core']:GetCoreObject()

ESX = {}

function ESX.GetPlayerFromId(source)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return nil end

    local self = {}
    self.source = source
    self.identifier = xPlayer.PlayerData.citizenid
    self.job = {
        name = xPlayer.PlayerData.job.name,
        grade = xPlayer.PlayerData.job.grade.level
    }

    function self.getIdentifier()
        return self.identifier
    end

    function self.getGroup()
        return xPlayer.PlayerData.permission or "user"
    end

    function self.getName()
        return xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
    end

    function self.showNotification(msg)
        TriggerClientEvent('QBCore:Notify', self.source, msg)
    end

    return self
end

function ESX.RegisterServerCallback(name, cb)
    QBCore.Functions.CreateCallback(name, function(source, callback, ...)
        cb(source, callback, ...)
    end)
end

function ESX.GetExtendedPlayers()
    local players = QBCore.Functions.GetPlayers()
    local xPlayers = {}
    for _, src in ipairs(players) do
        xPlayers[src] = ESX.GetPlayerFromId(src)
    end
    return xPlayers
end

-- Export to other files in the same resource
_G.ESX = ESX
