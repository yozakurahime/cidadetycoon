local function notifyClient(message, type)
    exports.qbx_core:Notify(message, type or 'inform')
end

-- Market Client Logic
function OpenVehicleMarket()
    local vehicleMatrix = exports.cidade_tycoon_core:GetVehicleMatrix()
    local marketOptions = {}

    -- Filter vehicles that are allowed for purchase/financing and have a tier
    for model, data in pairs(vehicleMatrix) do
        if data.price > 0 and data.tier > 0 then
            table.insert(marketOptions, {
                title = data.label,
                description = ('Tier %d | Preço: $%d | Capacidade: %d caixas'):format(data.tier, data.price, data.capacity or 0),
                icon = (data.branch == 'air') and 'plane' or (data.branch == 'water' and 'ship' or 'car'),
                onSelect = function()
                    OpenPurchaseOptions(model, data.label, data.price, data.financing)
                end
            })
        end
    end

    -- Sort by Tier then Price
    table.sort(marketOptions, function(a, b)
        return a.title < b.title -- Simple alphabetical for now
    end)

    lib.registerContext({
        id = 'tycoon_market_menu',
        title = 'Concessionaria de Frota Tycoon',
        options = marketOptions
    })
    lib.showContext('tycoon_market_menu')
end

function OpenPurchaseOptions(model, label, price, allowsFinancing)
    local downPayment = math.floor(price * 1.15 * 0.20) -- 20% of (Price + Interest)
    local installment = math.floor((price * 1.15 - downPayment) / 12)

    local options = {
        {
            title = 'Compra à Vista',
            description = ('Pague $%d agora e leve o veículo.'):format(price),
            icon = 'money-bill-1',
            onSelect = function()
                ProcessPurchase(model)
            end
        }
    }

    if allowsFinancing then
        table.insert(options, {
            title = 'Financiamento Tycoon',
            description = ('Entrada de $%d + 12x de $%d (Juros inclusos)'):format(downPayment, installment),
            icon = 'credit-card',
            onSelect = function()
                ProcessFinancing(model)
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_purchase_options',
        title = label,
        menu = 'tycoon_market_menu',
        options = options
    })
    lib.showContext('tycoon_purchase_options')
end

function ProcessPurchase(model)
    local result = lib.callback.await('cidade_tycoon_market:server:purchaseVehicle', false, model)
    if result and result.ok then
        notifyClient(result.message, 'success')
    else
        notifyClient(result and result.message or 'Falha na compra.', 'error')
    end
end

function ProcessFinancing(model)
    local result = lib.callback.await('cidade_tycoon_market:server:purchaseVehicleFinanced', false, model, 12)
    if result and result.ok then
        notifyClient(result.message, 'success')
    else
        notifyClient(result and result.message or 'Falha no financiamento.', 'error')
    end
end

function OpenFinancingManager()
    local financings = lib.callback.await('cidade_tycoon_market:server:getPlayerFinancings', false)
    if not financings or #financings == 0 then
        notifyClient('Voce nao possui financiamentos ativos.', 'inform')
        return
    end

    local options = {}
    for _, fin in ipairs(financings) do
        table.insert(options, {
            title = ('%s (Placa: %s)'):format(fin.vehicle_model:upper(), fin.plate),
            description = ('Parcela %d/%d: $%d | Total Pago: $%d/%d'):format(
                fin.installments_paid + 1, fin.total_installments, fin.installment_amount, fin.amount_paid, fin.total_price
            ),
            icon = 'calendar-check',
            onSelect = function()
                local res = lib.callback.await('cidade_tycoon_market:server:payInstallment', false, fin.id)
                notifyClient(res.message, res.ok and 'success' or 'error')
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_financing_manager',
        title = 'Meus Financiamentos',
        options = options
    })
    lib.showContext('tycoon_financing_manager')
end

RegisterCommand('tycoon_financings', function()
    OpenFinancingManager()
end, false)

RegisterCommand('tycoon_market', function()
    OpenVehicleMarket()
end, false)

exports('OpenVehicleMarket', OpenVehicleMarket)
