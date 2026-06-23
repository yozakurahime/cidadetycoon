TycoonCore = TycoonCore or {}

local config = require 'shared.config'

local function getRecoveryCost(plate)
    local feeCfg = config.recoveryFeeConfig or { baseFee = 5000, tierMultipliers = {} }
    local vehicleRow = MySQL.single.await('SELECT vehicle FROM player_vehicles WHERE plate = ?', { plate })
    if not vehicleRow then return feeCfg.baseFee end

    local modelName = vehicleRow.vehicle
    local vehicleData = exports.cidade_tycoon_core:GetVehicleData(modelName)
    local baseFee = feeCfg.baseFee
    local multiplier = 1.0

    if vehicleData then
        multiplier = feeCfg.tierMultipliers[vehicleData.tier] or 1.0
    end

    local finalCost = math.floor(baseFee * multiplier)

    -- Insurance Check (Market Integration)
    if GetResourceState('cidade_tycoon_market') == 'started' then
        local isInsured = lib.callback.await('cidade_tycoon_market:server:checkInsurance', false, plate)
        if isInsured then
            finalCost = math.floor(finalCost * 0.3) -- 70% Discount for insured vehicles
            print(string.format("^2[Tycoon:Core]^7 Aplicado desconto de seguro para %s. Novo custo: $%d", plate, finalCost))
        end
    end

    return finalCost
end

local function getVehicleDataByHash(hash)
    return TycoonCore.GetVehicleDataByHash(hash)
end

exports('GetVehicleDataByHash', getVehicleDataByHash)
exports('GetRecoveryCost', getRecoveryCost)

