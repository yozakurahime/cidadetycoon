local realCarModels = {
    '09tahoe', '15tahoe', '16challenger', '16charger', '17civict', '180sx', '2020ss', '488', '650s', '675lt',
    '718caymans', '720s', '760li04', '80b4', '84rx7k', '99viper', 'aaq4', 'agerars', 'amdbx', 'amggtrr20',
    'ap2', 'ast', 'audquattros', 'bbentayga', 'bolide', 'c6320', 'c7', 'cam8tun', 'camrs17', 'cats', 'cesc21',
    'cgt', 'cgts', 'chr20', 'corvettec5z06', 'cp9a', 'czr1', 'dawnonyx', 'demon', 'dragekcivick', 'dragfd',
    'e34', 'e400', 'esprit02', 'f150', 'f15078', 'f430s', 'f812', 'fc3s', 'fct', 'fgt', 'fk8', 'fpacehm',
    'fto', 'fxxk', 'g65', 'gl63', 'golfgti7', 'gs350', 'gsxr19', 'gt17', 'gtr', 'gtr96', 'gtrc', 'honcrx91',
    'huracanst', 'is350mod', 'it18', 'jeep2012', 'jeepreneg', 'katana', 'laferrari', 'lambose', 'levante',
    'lp670sv', 'lp700r', 'lrrr', 'lykan', 'm2', 'm3e36', 'm3e92', 'm3f80', 'm4f82', 'm6f13', 'maj350', 'maj935',
    'majfd', 'mbc63', 'mcst', 'miata3', 'mig', 'mk2100', 'models', 'mp412c', 'mustang50th', 'na1', 'na6', 'nis15',
    'nissantitan17', 'ns350', 'nzp', 'p90d', 'pcs18', 'pm19', 'q820', 'r820', 'r8ppi', 'raid', 'ram2500',
    'raptor2017', 'rcf', 'rculi', 'regalia', 'regera', 'rrevoque', 'rrphantom', 'rrst', 'rs6', 'rs72020',
    'rsvr16', 's14', 's500w222', 's8d2', 'safari97', 'senna', 'skyline', 'sl500', 'sq72016', 'srt4', 'srt8',
    'stingray', 'subisti08', 'subwrx', 'svj63', 'svx', 'tahoe21', 'taycan', 'teslapd', 'teslax', 'tltypes',
    'tmodel', 'toysupmk4', 'tr22', 'trhawk', 'trx', 'ttrs', 'urus', 'v250', 'veneno', 'vxr', 'wildtrak', 'wmfenyr',
    'wraith', 'xc90', 'yfe458i1', 'yfe458i2', 'yfe458s1', 'yfe458s2', 'yfef12a', 'yfef12t', 'z32', 'z419'
}

local realCarHashes = {}
for i = 1, #realCarModels do
    realCarHashes[joaat(realCarModels[i])] = true
end

local trackedVehicle
local trackedStartTime

local function resetTracking()
    trackedVehicle = nil
    trackedStartTime = nil
end

local function playerHasAccess(vehicle)
    local ok, hasKeys = pcall(function()
        return exports.qbx_vehiclekeys:HasKeys(vehicle)
    end)

    if ok and hasKeys then
        return true
    end

    local owner = Entity(vehicle).state.owner
    local citizenId = QBX and QBX.PlayerData and QBX.PlayerData.citizenid
    return owner ~= nil and citizenId ~= nil and owner == citizenId
end

local function isTrackedRealCar(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    local model = GetEntityModel(vehicle)
    if not realCarHashes[model] then
        return false
    end

    if IsThisModelABike(model) or IsThisModelAQuadbike(model) or IsThisModelABicycle(model) then
        return false
    end

    return true
end

local function isCloseEnoughToDriverDoor(ped, vehicle)
    local doorBone = GetEntityBoneIndexByName(vehicle, 'door_dside_f')
    if doorBone == -1 then
        return #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) < 5.0
    end

    local doorCoords = GetWorldPositionOfEntityBone(vehicle, doorBone)
    return #(GetEntityCoords(ped) - doorCoords) < 4.0
end

CreateThread(function()
    while true do
        local waitTime = 500
        local ped = PlayerPedId()

        if LocalPlayer.state.isLoggedIn and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped, false) then
            local tryingVehicle = GetVehiclePedIsTryingToEnter(ped)
            if tryingVehicle ~= 0 and GetSeatPedIsTryingToEnter(ped) == -1 and isTrackedRealCar(tryingVehicle) then
                if trackedVehicle ~= tryingVehicle then
                    trackedVehicle = tryingVehicle
                    trackedStartTime = GetGameTimer()
                end

                waitTime = 0
            elseif trackedVehicle and DoesEntityExist(trackedVehicle) then
                waitTime = 0
            else
                resetTracking()
            end

            if trackedVehicle and trackedStartTime and (GetGameTimer() - trackedStartTime) >= 1800 then
                local vehicle = trackedVehicle
                resetTracking()

                if isTrackedRealCar(vehicle)
                    and GetPedInVehicleSeat(vehicle, -1) == 0
                    and GetVehicleDoorLockStatus(vehicle) ~= 2
                    and isCloseEnoughToDriverDoor(ped, vehicle)
                    and playerHasAccess(vehicle) then
                    TaskWarpPedIntoVehicle(ped, vehicle, -1)
                end
            end
        else
            resetTracking()
        end

        Wait(waitTime)
    end
end)
