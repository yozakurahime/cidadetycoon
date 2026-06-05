TycoonCore = TycoonCore or {}

local config = require 'shared.config'
local QBCore = nil
pcall(function()
    QBCore = exports['qb-core']:GetCoreObject()
end)

local function getFrameworkPlayer(source)
    if GetResourceState('qbx_core') == 'started' then
        local player = exports.qbx_core:GetPlayer(source)
        if player then
            return player
        end
    end

    if QBCore and QBCore.Functions and QBCore.Functions.GetPlayer then
        return QBCore.Functions.GetPlayer(source)
    end

    return nil
end

local function getCitizenId(player)
    if not player or not player.PlayerData then
        return nil
    end

    return player.PlayerData.citizenid
end

local function getMoneyBalance(player, account)
    if player and player.Functions and player.Functions.GetMoney then
        return player.Functions.GetMoney(account) or 0
    end

    return 0
end

local function removeMoney(player, account, amount, reason)
    if not player or not player.Functions or not player.Functions.RemoveMoney then
        return false
    end

    return player.Functions.RemoveMoney(account, amount, reason)
end

local function getPreferredPaymentAccount(player, amount)
    local bank = getMoneyBalance(player, 'bank')
    if bank >= amount then
        return 'bank'
    end

    local cash = getMoneyBalance(player, 'cash')
    if cash >= amount then
        return 'cash'
    end

    return nil
end

local function isResourceReady(resourceName)
    return GetResourceState(resourceName) == 'started'
end

TycoonCore.Framework = {
    getFrameworkPlayer = getFrameworkPlayer,
    getCitizenId = getCitizenId,
    getMoneyBalance = getMoneyBalance,
    removeMoney = removeMoney,
    getPreferredPaymentAccount = getPreferredPaymentAccount,
    isResourceReady = isResourceReady,
}

local function getCoreConfig()
    return config
end

exports('GetFrameworkPlayer', getFrameworkPlayer)
exports('GetCitizenId', getCitizenId)
exports('GetMoneyBalance', getMoneyBalance)
exports('RemoveMoney', removeMoney)
exports('GetPreferredPaymentAccount', getPreferredPaymentAccount)
exports('IsResourceReady', isResourceReady)
exports('GetCoreConfig', getCoreConfig)
