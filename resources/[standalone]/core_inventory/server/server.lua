local QBCore = exports['qb-core']:GetCoreObject()
Inventories = {}
Drops = {}
DynamicItems = {}
UsedItems = {}

RegisterServerEvent("core_inventory:server:loadInventory")
AddEventHandler("core_inventory:server:loadInventory", function()
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if xPlayer then
        local citizenid = xPlayer.PlayerData.citizenid
        MySQL.query("SELECT inventorysettings FROM players WHERE citizenid = ?", { citizenid }, function(result)
            if result[1] and result[1].inventorysettings then
                TriggerClientEvent("core_inventory:client:setSettings", src, json.decode(result[1].inventorysettings), Items)
            end
        end)
    end
end)