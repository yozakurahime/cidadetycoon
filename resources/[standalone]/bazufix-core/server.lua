local permissions = {
    'bazufix-fuel',
    'bazufix-fuel.admin',
    'admin',
    'command.fueladmin',
    'command.setfuel',
}

local function isPlayerAuthorized(source, resource)
    if source == 0 then return true end

    if resource and IsPlayerAceAllowed(source, resource) then
        return true
    end

    for i = 1, #permissions do
        if IsPlayerAceAllowed(source, permissions[i]) then
            return true
        end
    end

    return false
end

exports('IsPlayerAuthorized', isPlayerAuthorized)
