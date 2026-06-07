local sharedConfig = require 'config/shared'
local activePoints = {}

local function notifyRacing(msg, type)
    lib.notify({ title = 'Eventos Tycoon', description = msg, type = type or 'inform' })
end

-- ==========================================
-- PASSIVE ZONE PROTECTION (Guardian Rule)
-- ==========================================
local function togglePassiveProtection(active)
    local ped = PlayerPedId()
    if active then
        NetworkSetFriendlyFireOption(false)
        SetCanPedEquipAllWeapons(ped, false)
        notifyRacing('Você entrou na ZONA DE PAZ (Entrega Protegida). Armas bloqueadas.', 'inform')
    else
        NetworkSetFriendlyFireOption(true)
        SetCanPedEquipAllWeapons(ped, true)
        notifyRacing('Você saiu da ZONA DE PAZ.', 'inform')
    end
end

-- ==========================================
-- GLOBAL EVENT HANDLER
-- ==========================================

RegisterNetEvent('cidade_tycoon_racing:client:startGlobalEvent', function(data)
    -- data: eventId, checkpoint, radius, label
    local point = lib.points.new({
        coords = vec3(data.checkpoint.x, data.checkpoint.y, data.checkpoint.z),
        distance = sharedConfig.Events.passiveRadius + 50.0
    })

    local blip = AddBlipForCoord(data.checkpoint.x, data.checkpoint.y, data.checkpoint.z)
    SetBlipSprite(blip, 478)
    SetBlipColour(blip, 5)
    SetBlipRoute(blip, true)
    SetBlipDisplay(blip, 2)
    SetBlipAsShortRange(blip, false)

    function point:onEnter()
        togglePassiveProtection(true)
    end

    function point:onExit()
        togglePassiveProtection(false)
    end

    function point:nearby()
        if self.currentDistance < 25.0 then
            DrawMarker(1, self.coords.x, self.coords.y, self.coords.z - 1.0, 0, 0, 0, 0, 0, 0, 4.0, 4.0, 1.5, 241, 229, 66, 180, false, true, 2, false)
            if self.currentDistance < 4.0 then
                lib.showTextUI('[E] Entregar Carga de Prioridade')
                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent('cidade_tycoon_racing:server:attemptPriorityDelivery', data.eventId)
                end
            else
                lib.hideTextUI()
            end
        end
    end

    activePoints[data.eventId] = { point = point, blip = blip }
    notifyRacing('CARGA DE ALTA PRIORIDADE DETECTADA: ' .. data.label, 'warning')
end)

RegisterNetEvent('cidade_tycoon_racing:client:stopGlobalEvent', function(data)
    if activePoints[data.eventId] then
        activePoints[data.eventId].point:remove()
        RemoveBlip(activePoints[data.eventId].blip)
        activePoints[data.eventId] = nil
        togglePassiveProtection(false)
        lib.hideTextUI()
    end
end)
