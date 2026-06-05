
-- EDIT DEFAULT METADATA FOR CERTAIN ITEMS


local QBCore = exports['qb-core']:GetCoreObject()

function defaultMetadata(source, itemData, currentMetadata)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return currentMetadata end
    
    local info = currentMetadata

    if itemData['name'] == 'idcard' then
        info.firstname = Player.PlayerData.charinfo.firstname
        info.lastname = Player.PlayerData.charinfo.lastname
        info.dob = Player.PlayerData.charinfo.birthdate
        info.sex = Player.PlayerData.charinfo.gender
        info.height = "180" -- Standard height if not in charinfo
    end      

    return info
end