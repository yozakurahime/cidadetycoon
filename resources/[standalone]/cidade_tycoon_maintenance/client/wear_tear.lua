local config = require 'config/maintenance'

local isMonitoring = false
local lastCoords = nil
local lastPlate = nil

-- Telemetry buffers
local telemetry = {
    distanceKm = 0.0,
    impactScore = 0.0
}

local lastHealth = 1000.0

local function flushTelemetry(plate)
    if telemetry.distanceKm > 0.01 or telemetry.impactScore > 0 then
        -- Send to the advanced server endpoint
        lib.callback.await('cidade_tycoon_maintenance:server:processVehicleWearSample', false, plate, telemetry)

        -- Reset buffers
        telemetry = {
            distanceKm = 0.0,
            impactScore = 0.0
        }
    end
end

local function monitorVehicleStatus()
    if isMonitoring then return end
    isMonitoring = true

    -- Slower thread for Distance and Impacts
    CreateThread(function()
        while isMonitoring do
            local sampling = config.wearSampling or {}
            local intervalMs = sampling.intervalMs or 8000
            local minDistanceKm = sampling.minDistanceKm or 0.08
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)

            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                local plate = GetVehicleNumberPlateText(veh)
                local coords = GetEntityCoords(veh)
                local currentHealth = GetVehicleBodyHealth(veh)

                if lastPlate == plate and lastCoords then
                    -- Accumulate distance
                    local dist = #(coords - lastCoords) / 1000.0 -- km
                    telemetry.distanceKm = telemetry.distanceKm + dist
                    lastCoords = coords

                    -- Check Impacts (Body health drops)
                    if currentHealth < lastHealth then
                        local damage = lastHealth - currentHealth
                        telemetry.impactScore = telemetry.impactScore + damage
                    end
                    lastHealth = currentHealth

                    if telemetry.distanceKm > minDistanceKm or telemetry.impactScore > 10.0 then
                        flushTelemetry(plate)
                    end
                else
                    -- Changed vehicle or just entered
                    if lastPlate then flushTelemetry(lastPlate) end
                    lastPlate = plate
                    lastCoords = coords
                    lastHealth = currentHealth
                end
            else
                -- Exited vehicle
                if lastPlate then flushTelemetry(lastPlate) end
                lastPlate = nil
                lastCoords = nil
            end

            Wait(intervalMs)
        end
    end)
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    monitorVehicleStatus()
end)
