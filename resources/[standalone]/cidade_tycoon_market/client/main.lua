local previewVehicle = nil
local previewCam = nil
local npcEntity = nil

local function notifyClient(message, type)
    exports.qbx_core:Notify(message, type or 'inform')
end

local function CleanupPreview()
    if DoesEntityExist(previewVehicle) then
        DeleteEntity(previewVehicle)
    end
    if previewCam then
        RenderScriptCams(false, true, 500, true, true)
        SetCamActive(previewCam, false)
        DestroyCam(previewCam, true)
        previewCam = nil
    end
    previewVehicle = nil
    FreezeEntityPosition(PlayerPedId(), false)
end

function ProcessPurchase(model)
    local result = lib.callback.await('cidade_tycoon_market:server:purchaseVehicle', false, model)
    CleanupPreview()
    if result and result.ok then
        notifyClient(result.message, 'success')
    else
        notifyClient(result and result.message or 'Falha na compra.', 'error')
        OpenVehicleMarket()
    end
end

function ProcessFinancing(model)
    local result = lib.callback.await('cidade_tycoon_market:server:purchaseVehicleFinanced', false, model, 12)
    CleanupPreview()
    if result and result.ok then
        notifyClient(result.message, 'success')
    else
        notifyClient(result and result.message or 'Falha no financiamento.', 'error')
        OpenVehicleMarket()
    end
end

function PreviewVehicleOptions(model, label, price, allowsFinancing)
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

    table.insert(options, {
        title = 'Voltar ao Catálogo',
        icon = 'arrow-rotate-left',
        onSelect = function()
            CleanupPreview()
            OpenVehicleMarket()
        end
    })

    lib.registerContext({
        id = 'tycoon_preview_options',
        title = label,
        options = options,
        onExit = function()
            CleanupPreview()
        end
    })
    lib.showContext('tycoon_preview_options')
end

local function PreviewVehicle(model, label, price, allowsFinancing)
    CleanupPreview()
    
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    -- Spawn local vehicle
    previewVehicle = CreateVehicle(hash, Config.Preview.vehicleCoords.x, Config.Preview.vehicleCoords.y, Config.Preview.vehicleCoords.z, Config.Preview.vehicleCoords.w, false, false)
    SetEntityHeading(previewVehicle, Config.Preview.vehicleCoords.w)
    FreezeEntityPosition(previewVehicle, true)
    SetEntityInvincible(previewVehicle, true)
    SetVehicleDoorsLocked(previewVehicle, 2)
    SetVehicleDirtLevel(previewVehicle, 0.0)

    -- Setup Camera
    previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    
    -- Cinematic Auto-Rotating Camera Variables
    local camAngle = 90.0
    local camRadius = 6.0
    local camHeight = 1.2

    -- Interactive Camera Thread
    CreateThread(function()
        while previewCam do
            -- Auto-rotate slowly
            camAngle = camAngle + 0.15
            if camAngle >= 360.0 then camAngle = 0.0 end

            local rad = math.rad(camAngle)
            local camX = Config.Preview.vehicleCoords.x + camRadius * math.cos(rad)
            local camY = Config.Preview.vehicleCoords.y + camRadius * math.sin(rad)
            local camZ = Config.Preview.vehicleCoords.z + camHeight

            SetCamCoord(previewCam, camX, camY, camZ)
            PointCamAtEntity(previewCam, previewVehicle, 0.0, 0.0, 0.0, true)

            Wait(0)
        end
    end)

    RenderScriptCams(true, true, 1000, true, true)
    SetCamActive(previewCam, true)

    FreezeEntityPosition(PlayerPedId(), true)

    PreviewVehicleOptions(model, label, price, allowsFinancing)
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
                    PreviewVehicle(model, data.label, data.price, data.financing)
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
        title = 'Concessionária de Frota Tycoon',
        options = marketOptions
    })
    lib.showContext('tycoon_market_menu')
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

-- ==========================================
-- NPC SPAWN
-- ==========================================
local function createDealerNpc()
    if not Config.DealerNPC then return end

    print("[Tycoon:Market] Starting createDealerNpc...")
    local modelHash = GetHashKey(Config.DealerNPC.model)
    RequestModel(modelHash)
    
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(modelHash) and GetGameTimer() < timeout do 
        Wait(100) 
    end

    if not HasModelLoaded(modelHash) then
        print("^1[Tycoon:Market] ERROR: Failed to load NPC model: " .. tostring(Config.DealerNPC.model) .. "^7")
        return
    end

    print("[Tycoon:Market] Spawning dealer ped at X: " .. Config.DealerNPC.coords.x .. " Y: " .. Config.DealerNPC.coords.y .. " Z: " .. Config.DealerNPC.coords.z)

    npcEntity = CreatePed(4, modelHash, Config.DealerNPC.coords.x, Config.DealerNPC.coords.y, Config.DealerNPC.coords.z - 1.0, Config.DealerNPC.coords.w, false, false)
    SetEntityHeading(npcEntity, Config.DealerNPC.coords.w)
    FreezeEntityPosition(npcEntity, true)
    SetEntityInvincible(npcEntity, true)
    SetBlockingOfNonTemporaryEvents(npcEntity, true)
    TaskStartScenarioInPlace(npcEntity, Config.DealerNPC.scenario, 0, true)

    exports.ox_target:addLocalEntity(npcEntity, {
        {
            name = 'tycoon_market_npc',
            icon = 'fa-solid fa-car',
            label = 'Ver Catálogo de Veículos',
            onSelect = OpenVehicleMarket,
            distance = 2.5
        }
    })

    local blip = AddBlipForCoord(Config.DealerNPC.coords.x, Config.DealerNPC.coords.y, Config.DealerNPC.coords.z)
    SetBlipSprite(blip, Config.DealerNPC.blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.DealerNPC.blip.scale)
    SetBlipColour(blip, Config.DealerNPC.blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.DealerNPC.blip.label)
    EndTextCommandSetBlipName(blip)

    SetModelAsNoLongerNeeded(modelHash)
end

CreateThread(function()
    createDealerNpc()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    CleanupPreview()
    if DoesEntityExist(npcEntity) then DeleteEntity(npcEntity) end
end)


RegisterCommand('tycoon_financings', function()
    OpenFinancingManager()
end, false)

RegisterCommand('tycoon_market', function()
    OpenVehicleMarket()
end, false)

exports('OpenVehicleMarket', OpenVehicleMarket)
