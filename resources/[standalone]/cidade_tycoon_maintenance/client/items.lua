-- client/items.lua
local function notifyMaintenance(message, type)
    lib.notify({
        title = 'Oficina Tycoon',
        description = message,
        type = type or 'inform',
    })
end

RegisterNetEvent('cidade_tycoon_maintenance:client:usePart', function(itemName, partData)
    notifyMaintenance(('Selecione como usar %s no Diagnostico Tycoon: instalar/modificar ou reparar.'):format(partData.label), 'inform')
    TriggerEvent('cidade_tycoon_mechanic:client:openVehicleMenuFromItem')
end)
