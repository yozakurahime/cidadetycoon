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
-- WEAR TRACKING
-- (Desativado em favor do monitoramento unificado em client/wear_tear.lua)
-- ==========================================

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
            description = ('Saude: %d%% | Reparo paliativo ate 50%% | Mao de Obra NPC: $%d'):format(math.floor(sub.condition), laborFee),
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
