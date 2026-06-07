local lastToastAt = 0

local function notifyMaintenance(message, type)
    lib.notify({
        title = 'Oficina Tycoon',
        description = message,
        type = type or 'inform',
    })
    if type == 'success' then PlaySoundFrontend(-1, "PURCHASE_ACK", "HUD_LIQUIPEDIA_SOUNDSET", 1) end
end

-- ==========================================
-- HUD & NOTIFICATIONS (User Request)
-- ==========================================

local function showMileageToast(plate, mileage)
    local now = GetGameTimer()
    if now - lastToastAt < 30000 then return end -- 30s Cooldown
    
    lastToastAt = now
    lib.notify({
        title = 'Veículo: ' .. plate,
        description = ('HODÔMETRO: %.1f KM'):format(mileage),
        type = 'inform',
        position = 'bottom-right',
        duration = 5000
    })
end

AddEventHandler('qbx_core:client:onVehicleEnter', function(veh, plate)
    local status = Entity(veh).state['tycoon:status']
    if status and status.mileage then
        showMileageToast(plate, status.mileage)
    else
        -- Fallback if state bag not ready
        lib.callback('cidade_tycoon_maintenance:server:getVehicleStatus', false, function(data)
            if data then showMileageToast(plate, data.mileage) end
        end, plate)
    end
end)

-- ==========================================
-- WEAR TRACKING (Optimized)
-- ==========================================
local wearTracking = { activePlate = nil, sample = nil, lastFlushAt = 0 }

local function resetWearTracking(plate)
    wearTracking.activePlate = plate
    wearTracking.sample = nil
    wearTracking.lastFlushAt = GetGameTimer()
end

CreateThread(function()
    while true do
        local wait = 2000
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            wait = 500
            local plate = GetVehicleNumberPlateText(veh)
            
            if wearTracking.activePlate ~= plate or not wearTracking.sample then
                wearTracking.activePlate = plate
                wearTracking.sample = { distanceKm = 0.0, lastCoords = GetEntityCoords(veh), startTime = GetGameTimer() }
                wearTracking.lastFlushAt = GetGameTimer()
            end

            local curCoords = GetEntityCoords(veh)
            local dist = #(curCoords - wearTracking.sample.lastCoords) / 1000.0
            wearTracking.sample.distanceKm = wearTracking.sample.distanceKm + dist
            wearTracking.sample.lastCoords = curCoords

            -- Flush every 1km or 60s
            if (GetGameTimer() - wearTracking.lastFlushAt > 60000) or (wearTracking.sample.distanceKm > 1.0) then
                local timeDelta = (GetGameTimer() - wearTracking.sample.startTime) / 1000
                TriggerServerEvent('cidade_tycoon_maintenance:server:flushWearSample', plate, wearTracking.sample.distanceKm, timeDelta)
                resetWearTracking(plate)
            end
        else
            if wearTracking.activePlate then resetWearTracking(nil) end
        end
        Wait(wait)
    end
end)

-- Rest of Workshop UI Logic (Simplified for Audit Consolidation)
function OpenWorkshopMenu()
    local veh = lib.getClosestVehicle(GetEntityCoords(PlayerPedId()), 5.0)
    if not veh then return end
    local plate = GetVehicleNumberPlateText(veh)
    
    local data = lib.callback.await('cidade_tycoon_maintenance:server:getWorkshopVehicleData', false, plate)
    if not data then return end

    local options = {
        {
            title = 'Reparos de Subsistemas',
            description = ('Condição Geral: %d%%'):format(math.floor(data.overallCondition)),
            onSelect = function() OpenRepairMenu(plate, data.subsystems, data.laborFee) end
        }
    }
    lib.registerContext({ id = 'tycoon_workshop', title = 'Oficina: ' .. plate, options = options })
    lib.showContext('tycoon_workshop')
end

function OpenRepairMenu(plate, subsystems, laborFee)
    local options = {}
    for key, sub in pairs(subsystems) do
        table.insert(options, {
            title = sub.label,
            description = ('Saúde: %d%% | Mão de Obra NPC: $%d'):format(math.floor(sub.condition), laborFee),
            onSelect = function()
                local res = lib.callback.await('cidade_tycoon_maintenance:server:repairSubsystem', false, plate, key)
                notifyMaintenance(res.message, res.ok and 'success' or 'error')
            end
        })
    end
    lib.registerContext({ id = 'tycoon_repairs', title = 'Reparos', menu = 'tycoon_workshop', options = options })
    lib.showContext('tycoon_repairs')
end

RegisterCommand('tycoon_workshop', OpenWorkshopMenu)
