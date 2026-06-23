local function updateLicenses(source, licensesTable)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return false end

    profile.licenses = licensesTable
    MySQL.update.await('UPDATE tycoon_players SET licenses = ? WHERE citizenid = ?', {
        json.encode(profile.licenses),
        profile.citizenid
    })
    exports.cidade_tycoon_core:SyncPlayerState(source)

    return true
end

local function addReputation(source, amount)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return false end

    profile.reputation = profile.reputation + amount
    MySQL.update.await('UPDATE tycoon_players SET reputation = ? WHERE citizenid = ?', {
        profile.reputation,
        profile.citizenid
    })
    exports.cidade_tycoon_core:SyncPlayerState(source)

    return true, profile.reputation
end

local function setReputation(source, amount)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return false end

    profile.reputation = tonumber(amount) or 0
    MySQL.update.await('UPDATE tycoon_players SET reputation = ? WHERE citizenid = ?', {
        profile.reputation,
        profile.citizenid
    })
    exports.cidade_tycoon_core:SyncPlayerState(source)

    return true, profile.reputation
end

local function hasLicense(source, licenseName)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return false end

    return profile.licenses[licenseName] == true
end

local function updateInsurance(source, tier)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return false end

    profile.insuranceTier = tier
    MySQL.update.await('UPDATE tycoon_players SET insurance_tier = ? WHERE citizenid = ?', {
        profile.insuranceTier,
        profile.citizenid
    })
    exports.cidade_tycoon_core:SyncPlayerState(source)

    return true
end

local function getInsuranceTier(source)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    return profile and profile.insuranceTier or 0
end

exports('UpdateLicenses', updateLicenses)
exports('AddReputation', addReputation)
exports('SetReputation', setReputation)
exports('HasLicense', hasLicense)
exports('UpdateInsurance', updateInsurance)
exports('GetInsuranceTier', getInsuranceTier)
