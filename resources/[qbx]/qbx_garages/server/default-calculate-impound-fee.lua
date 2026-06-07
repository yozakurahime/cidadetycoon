---Calculates a fee based on Tycoon Core vehicle tiers.
---@param vehicleId number        -- ID of the vehicle (not used in this calculation)
---@param modelName string        -- model name used to look up vehicle data
---@return number                 -- calculated fee based on Tycoon Tier
local defaultCalculateImpoundFee = function(vehicleId, modelName)
    local recoveryFee = 1000 -- Default fallback
    
    local ok, result = pcall(function()
        return exports.cidade_tycoon_core:GetRecoveryCost(modelName)
    end)

    if ok and result then
        recoveryFee = result
    else
        -- If core fails, fallback to price-based calculation if available
        local vehicleInfo = VEHICLES[modelName]
        if vehicleInfo and vehicleInfo.price then
            recoveryFee = qbx.math.round(vehicleInfo.price * 0.05) -- Slightly higher for untracked vehicles
        end
    end

    print(string.format("^3[Tycoon:Garages]^7 Calculada taxa de recuperacao para %s: $%d", modelName, recoveryFee))

    return recoveryFee
end

return defaultCalculateImpoundFee
