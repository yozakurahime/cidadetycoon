TycoonCore = TycoonCore or {}

local plates = require 'shared.plates'

exports('NormalizePlate', function(plate)
    return plates.normalizePlate(plate)
end)

exports('GetCityConfig', function()
    return TycoonCore.City
end)

exports('GetPartData', function(itemName)
    return TycoonCore.GetPartData(itemName)
end)

-- Debug/Safety: Force Clear NUI Focus
RegisterCommand('tycoon_clear_focus', function()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    lib.hideContext()
    lib.hideTextUI()
    exports.qbx_core:Notify('Foco da interface limpo com sucesso.', 'inform')
end, false)

-- Register key mapping for quick fix
RegisterKeyMapping('tycoon_clear_focus', 'Limpar Foco da Interface (Unstick)', 'keyboard', 'F10')
