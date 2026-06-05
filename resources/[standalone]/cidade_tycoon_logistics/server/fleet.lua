local function getCompanyVehicles(companyId)
    return MySQL.query.await('SELECT * FROM tycoon_company_fleet WHERE company_id = ?', { companyId })
end

lib.callback.register('cidade_tycoon_logistics:server:addVehicleToFleet', function(source, plate)
    local company = exports.cidade_tycoon_logistics:GetCompanyData(source)
    if not company then return { ok = false, message = 'Empresa nao encontrada.' } end

    -- Verify if vehicle belongs to player
    local vehicle = MySQL.single.await('SELECT id FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, company.citizenid })
    if not vehicle then
        return { ok = false, message = 'Este veiculo nao pertence a voce ou sua placa e invalida.' }
    end

    -- Add to Fleet
    local success = MySQL.insert.await([[
        INSERT INTO tycoon_company_fleet (company_id, vehicle_plate, status)
        VALUES (?, ?, 'idle')
    ]], { company.id, plate })

    if success then
        return { ok = true, message = 'Veiculo integrado a frota da empresa com sucesso.' }
    end

    return { ok = false, message = 'Este veiculo ja faz parte de uma frota.' }
end)

lib.callback.register('cidade_tycoon_logistics:server:removeVehicleFromFleet', function(source, plate)
    local company = exports.cidade_tycoon_logistics:GetCompanyData(source)
    if not company then return { ok = false, message = 'Empresa nao encontrada.' } end

    local success = MySQL.update.await('DELETE FROM tycoon_company_fleet WHERE vehicle_plate = ? AND company_id = ?', { plate, company.id })
    
    if success > 0 then
        return { ok = true, message = 'Veiculo removido da frota.' }
    end

    return { ok = false, message = 'Veiculo nao encontrado na sua frota.' }
end)
