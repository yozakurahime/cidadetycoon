TycoonCore = TycoonCore or {}

local config = require 'shared.config'
local QBCore = nil
local ResourceStates = {}

-- ==========================================
-- FRAMEWORK INITIALIZATION
-- ==========================================
local function isResourceReady(resourceName)
    if ResourceStates[resourceName] ~= nil then return ResourceStates[resourceName] end
    ResourceStates[resourceName] = GetResourceState(resourceName) == 'started'
    return ResourceStates[resourceName]
end

AddEventHandler('onResourceStart', function(resourceName)
    ResourceStates[resourceName] = true
end)

AddEventHandler('onResourceStop', function(resourceName)
    ResourceStates[resourceName] = false
end)

local function initFramework()
    if isResourceReady('qbx_core') then
        -- Qbox is preferred
        return true
    end

    if isResourceReady('qb-core') then
        pcall(function()
            QBCore = exports['qb-core']:GetCoreObject()
        end)
        return QBCore ~= nil
    end

    return false
end

-- ==========================================
-- PLAYER WRAPPERS
-- ==========================================
local function getFrameworkPlayer(source)
    if not source or source <= 0 then return nil end

    if isResourceReady('qbx_core') then
        return exports.qbx_core:GetPlayer(source)
    end

    if QBCore then
        return QBCore.Functions.GetPlayer(source)
    end

    return nil
end

local function getCitizenId(player)
    if not player then return nil end
    
    -- Handle raw source being passed
    if type(player) == 'number' then
        player = getFrameworkPlayer(player)
    end

    if not player or not player.PlayerData then return nil end
    return player.PlayerData.citizenid
end

local function getSource(player)
    if type(player) == 'number' then return player end
    if type(player) == 'table' then
        if player.PlayerData and player.PlayerData.source then
            return player.PlayerData.source
        elseif player.source then
            return player.source
        end
    end
    return nil
end

-- ==========================================
-- ECONOMY WRAPPERS
-- ==========================================
local function getMoneyBalance(player, account)
    local src = getSource(player)
    if not src then return 0 end

    if isResourceReady('qbx_core') then
        return exports.qbx_core:GetMoney(src, account or 'bank') or 0
    end

    local qbPlayer = getFrameworkPlayer(src)
    if qbPlayer and qbPlayer.Functions then
        return qbPlayer.Functions.GetMoney(account or 'bank') or 0
    end
    return 0
end

local function removeMoney(player, account, amount, reason)
    local src = getSource(player)
    if not src then return false end

    if isResourceReady('qbx_core') then
        return exports.qbx_core:RemoveMoney(src, account or 'bank', amount, reason or 'tycoon-transaction')
    end

    local qbPlayer = getFrameworkPlayer(src)
    if qbPlayer and qbPlayer.Functions then
        local success = false
        pcall(function()
            success = qbPlayer.Functions.RemoveMoney(account or 'bank', amount, reason or 'tycoon-transaction')
        end)
        return success
    end
    return false
end

local function addMoney(player, account, amount, reason)
    local src = getSource(player)
    if not src then return false end

    if isResourceReady('qbx_core') then
        exports.qbx_core:AddMoney(src, account or 'bank', amount, reason or 'tycoon-transaction')
        return true
    end

    local qbPlayer = getFrameworkPlayer(src)
    if qbPlayer and qbPlayer.Functions then
        pcall(function()
            qbPlayer.Functions.AddMoney(account or 'bank', amount, reason or 'tycoon-transaction')
        end)
        return true
    end
    return false
end

-- ==========================================
-- NOTIFICATION WRAPPERS
-- ==========================================
local function notifyPlayer(source, message, notifyType)
    if isResourceReady('ox_lib') then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Transport Tycoon',
            description = message,
            type = notifyType or 'inform'
        })
    else
        -- Fallback to QB-Core notification
        TriggerClientEvent('QBCore:Notify', source, message, notifyType or 'primary')
    end
end


-- ==========================================
-- UTILS
-- ==========================================

-- Initialization
initFramework()

local function ensureStarterItem(source, itemName, amount)
    if isResourceReady('ox_inventory') then
        local item = exports.ox_inventory:GetItem(source, itemName, nil, false)
        if not item or item.count == 0 then
            exports.ox_inventory:AddItem(source, itemName, amount or 1)
            print(("^2[Tycoon:Core]^7 Item '%s' concedido ao jogador %d"):format(itemName, source))
        end
        return true
    end
    return false
end

local function createUseableItem(itemName, cb)
    if isResourceReady('qbx_core') then
        exports.qbx_core:CreateUseableItem(itemName, cb)
    elseif QBCore then
        QBCore.Functions.CreateUseableItem(itemName, cb)
    end
end

local function hasPermission(source, permission)
    if isResourceReady('qbx_core') then
        return exports.qbx_core:HasPermission(source, permission)
    elseif QBCore then
        return QBCore.Functions.HasPermission(source, permission)
    end
    return false
end

-- Exports
exports('GetFrameworkPlayer', getFrameworkPlayer)
exports('GetCitizenId', getCitizenId)
exports('GetMoneyBalance', getMoneyBalance)
exports('RemoveMoney', removeMoney)
exports('AddMoney', addMoney)
exports('NotifyPlayer', notifyPlayer)
exports('IsResourceReady', isResourceReady)
exports('EnsureStarterItem', ensureStarterItem)
exports('CreateUseableItem', createUseableItem)
exports('HasPermission', hasPermission)
exports('GetCoreConfig', function() return config end)

-- Add missing server exports used by other modules
exports('GetCoreConfig', function()
    return config
end)

exports('NormalizePlate', function(plate)
    local plates = require 'shared.plates'
    return plates.normalizePlate(plate)
end)

exports('GetVehicleData', function(model)
    if not model then return nil end
    local modelStr = tostring(model):lower()
    local vehicles = nil
    pcall(function()
        vehicles = require 'shared.vehicles'
    end)
    if vehicles and type(vehicles) == 'table' then
        return vehicles[modelStr]
    end
    if TycoonCore and TycoonCore.VehicleMatrix then
        return TycoonCore.VehicleMatrix[modelStr]
    end
    return nil
end)

exports('GetVehicleDataByHash', function(hash)
    if not hash then return nil end
    local hashNum = tonumber(hash) or joaat(tostring(hash))
    local vehicles = nil
    pcall(function()
        vehicles = require 'shared.vehicles'
    end)
    if TycoonCore and TycoonCore.GetVehicleDataByHash then
        return TycoonCore.GetVehicleDataByHash(hashNum)
    end
    return nil
end)

