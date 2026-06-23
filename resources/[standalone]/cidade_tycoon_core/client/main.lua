TycoonCore = TycoonCore or {}

local plates = require 'shared.plates'
local config = require 'shared.config'

local electricHashes = {}
for name, _ in pairs(config.ElectricVehicles or {}) do
    electricHashes[GetHashKey(name)] = true
end

local function isVehicleElectric(model)
    if not model then return false end
    if type(model) == 'number' then
        return electricHashes[model] or false
    elseif type(model) == 'string' then
        local modelLower = model:lower()
        if config.ElectricVehicles[modelLower] then return true end
        return electricHashes[GetHashKey(modelLower)] or false
    end
    return false
end

exports('NormalizePlate', function(plate)
    return plates.normalizePlate(plate)
end)

exports('IsVehicleElectric', isVehicleElectric)

exports('GetCoreConfig', function()
    return config
end)

exports('GetCityConfig', function()
    return TycoonCore.City
end)

exports('GetPartData', function(itemName)
    return TycoonCore.GetPartData(itemName)
end)

exports('GetVehicleMatrix', function()
    return TycoonCore.VehicleMatrix
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

RegisterNetEvent('cidade_tycoon_core:client:printDiag', function(columns)
    print("^3[Tycoon:DB_Diag] Estrutura da tabela player_vehicles no F8:^7")
    for _, line in ipairs(columns) do
        print(line)
    end
end)
