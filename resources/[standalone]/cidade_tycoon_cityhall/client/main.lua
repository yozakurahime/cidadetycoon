local function notifyClient(message, type)
    exports.qbx_core:Notify(message, type or 'inform')
end

-- City Hall interactions
function OpenCityHallMenu()
    local dashboard = lib.callback.await('cidade_tycoon_cityhall:server:getDashboard', false)
    if not dashboard then
        notifyClient('Falha ao carregar dados da Prefeitura.', 'error')
        return
    end

    local options = {
        {
            title = 'Pagar Imposto Territorial',
            description = ('Sua taxa atual é de $%d. Streak: %d'):format(1500, dashboard.taxStreak), -- Simplified calculation display
            icon = 'building-columns',
            onSelect = function()
                local res = lib.callback.await('cidade_tycoon_cityhall:server:payTaxes', false)
                notifyClient(res.message, res.ok and 'success' or 'error')
            end
        }
    }

    for _, lic in ipairs(dashboard.licenses) do
        table.insert(options, {
            title = lic.label,
            description = lic.owned and 'Voce ja possui esta licença.' or ('Custo: $%d | Reputacao: %d'):format(lic.cost, lic.requiredReputation),
            icon = 'id-card',
            disabled = lic.owned or not lic.canBuy,
            onSelect = function()
                local res = lib.callback.await('cidade_tycoon_cityhall:server:purchaseLicense', false, lic.key)
                notifyClient(res.message, res.ok and 'success' or 'error')
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_cityhall_menu',
        title = 'Gabinete da Prefeitura Tycoon',
        options = options
    })
    lib.showContext('tycoon_cityhall_menu')
end

RegisterCommand('cityhall', function()
    OpenCityHallMenu()
end, false)
