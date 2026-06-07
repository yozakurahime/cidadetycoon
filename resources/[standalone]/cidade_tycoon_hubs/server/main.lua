local config = TycoonHubs.Config

local function getHubData(hubId)
    for _, hub in ipairs(config.hubs) do
        if hub.id == hubId then
            return hub
        end
    end
    return nil
end

local function getAllHubs()
    return config.hubs
end

exports('GetHubData', getHubData)
exports('GetAllHubs', getAllHubs)

lib.callback.register('cidade_tycoon_hubs:server:getAllHubs', function(source)
    return getAllHubs()
end)
