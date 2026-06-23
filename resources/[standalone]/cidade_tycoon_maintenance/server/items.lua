-- server/items.lua

local function DebugLog(text, ...)
    print(string.format("^4[Tycoon:Server:Maintenance]^7 %s", string.format(text, ...)))
end

-- Get Parts list
local partsList = nil

CreateThread(function()
    Wait(2000)
    -- We load the parts from core
    local pcallStatus, result = pcall(function()
        local data = exports.cidade_tycoon_core:GetPartData('engine_block')
        return data ~= nil
    end)
    
    if pcallStatus and result then
        -- Core is available
        local allParts = {
            'engine_block', 'transmission_gear', 'transmission_parts', 'brake_pads', 'suspension_arm', 'suspension_kit', 'truck_tire', 'basic_repair_kit', 'advanced_repair_kit', 'mechanical_parts',
            'standard_tires', 'battery',
            'tire_street_basic', 'tire_street_sport', 'tire_rain_pro', 'tire_drift_pro', 'tire_offroad_pro', 'tire_race_premium',
            'drift_tires', 'racing_tires', 'drag_tires',
            'brake_street_basic', 'performance_brakes', 'brake_sport_kit', 'brake_race_kit', 'suspension_sport_kit', 'alignment_standard_service',
            'filter_performance', 'radiator_heavy_duty', 'ecu_sport_stage', 'turbo_street_kit', 'turbo_kit', 'supercharger_street_kit',
            'clutch_performance', 'transmission_street_kit', 'transmission_sport_kit', 'transmission_race_kit',
            'drivetrain_conversion_fwd', 'drivetrain_conversion_rwd', 'drivetrain_conversion_awd', 'traction_control',
            'performance_kit_drag', 'performance_kit_drift', 'performance_kit_race',
        }

        for _, item in ipairs(allParts) do
            exports.cidade_tycoon_core:CreateUseableItem(item, function(source, itemData)
                local src = source
                local partData = exports.cidade_tycoon_core:GetPartData(item)
                if partData then
                    TriggerClientEvent('cidade_tycoon_maintenance:client:usePart', src, item, partData)
                end
            end)
        end
        DebugLog("Registrados itens usáveis de auto peças.")
    end
end)

lib.callback.register('cidade_tycoon_maintenance:server:installPart', function(source, plate, itemName, partData)
    return { ok = false, message = 'Fluxo legado desativado. Use o Diagnostico Tycoon para reparar com kit ou trocar a peca.' }
end)

-- Legacy implementation kept disabled above to prevent old clients from bypassing the 50% kit repair rule.
local function disabledLegacyInstallPart(source, plate, itemName, partData)
    local src = source
    local item = exports.ox_inventory:GetItem(src, itemName, nil, false)
    
    if not item or item.count < 1 then
        return { ok = false, message = 'Você não tem a peça.' }
    end

    if exports.ox_inventory:RemoveItem(src, itemName, 1) then
        -- Update vehicle status
        local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
        if not status then return { ok = false, message = 'Veículo não registrado.' } end

        local repairAmount = partData.repairValue or 100.0

        if partData.category == 'engine' then
            status.engine_health = math.min(100.0, status.engine_health + repairAmount)
        elseif partData.category == 'transmission' then
            status.transmission_health = math.min(100.0, status.transmission_health + repairAmount)
        elseif partData.category == 'brakes' then
            status.brakes_health = math.min(100.0, status.brakes_health + repairAmount)
        elseif partData.category == 'suspension' then
            status.suspension_health = math.min(100.0, status.suspension_health + repairAmount)
        elseif partData.category == 'battery' then
            status.battery_health = math.min(100.0, (status.battery_health or 100.0) + repairAmount)
        elseif partData.category == 'tires' then
            status.tire_lf_health = math.min(100.0, (status.tire_lf_health or 100.0) + repairAmount)
            status.tire_rf_health = math.min(100.0, (status.tire_rf_health or 100.0) + repairAmount)
            status.tire_lr_health = math.min(100.0, (status.tire_lr_health or 100.0) + repairAmount)
            status.tire_rr_health = math.min(100.0, (status.tire_rr_health or 100.0) + repairAmount)
            status.tires_health = math.min(status.tire_lf_health, status.tire_rf_health, status.tire_lr_health, status.tire_rr_health)
        elseif partData.category == 'all' then
            status.engine_health = math.min(100.0, status.engine_health + repairAmount)
            status.transmission_health = math.min(100.0, status.transmission_health + repairAmount)
            status.brakes_health = math.min(100.0, status.brakes_health + repairAmount)
            status.suspension_health = math.min(100.0, status.suspension_health + repairAmount)
            status.battery_health = math.min(100.0, (status.battery_health or 100.0) + repairAmount)
            status.tire_lf_health = math.min(100.0, (status.tire_lf_health or 100.0) + repairAmount)
            status.tire_rf_health = math.min(100.0, (status.tire_rf_health or 100.0) + repairAmount)
            status.tire_lr_health = math.min(100.0, (status.tire_lr_health or 100.0) + repairAmount)
            status.tire_rr_health = math.min(100.0, (status.tire_rr_health or 100.0) + repairAmount)
            status.tires_health = math.min(status.tire_lf_health, status.tire_rf_health, status.tire_lr_health, status.tire_rr_health)
        end

        exports.cidade_tycoon_core:UpdateVehicleStatus(plate, status)

        -- Generate Scrap
        local scrapItem = 'mechanical_scrap'
        if partData.category == 'engine' or partData.category == 'transmission' then
            scrapItem = 'mechanical_scrap'
        elseif partData.category == 'tires' then
            scrapItem = 'rubber_scrap'
        elseif itemName:find('ecu') then
            scrapItem = 'electronic_scrap'
        end

        exports.ox_inventory:AddItem(src, scrapItem, 1)

        -- Sync state bag using unified helper (exported or global)
        if SyncVehicleStateBag then
            SyncVehicleStateBag(plate, status)
        elseif exports.cidade_tycoon_maintenance.SyncVehicleStateBag then
            exports.cidade_tycoon_maintenance:SyncVehicleStateBag(plate, status)
        end

        return { ok = true, message = 'Peça instalada com sucesso! Uma sucata foi gerada.' }
    end

    return { ok = false, message = 'Erro ao remover item.' }
end
