local maxPlayers = GlobalState.MaxPlayers
local discord = require 'config.client'.discord

if not discord.enabled then return end

local function updateRichPresence(playerCount)
    SetRichPresence(('Cidade Tycoon | %s/%s online'):format(playerCount or 0, maxPlayers))
end

AddStateBagChangeHandler('PlayerCount', '', function(bagName, _, value)
    if bagName == 'global' and value then
        updateRichPresence(value)
    end
end)

SetDiscordAppId(discord.appId)
SetDiscordRichPresenceAsset(discord.largeIcon.icon)
SetDiscordRichPresenceAssetText(discord.largeIcon.text)
SetDiscordRichPresenceAssetSmall(discord.smallIcon.icon)
SetDiscordRichPresenceAssetSmallText(discord.smallIcon.text)
SetDiscordRichPresenceAction(0, discord.firstButton.text, discord.firstButton.link)
SetDiscordRichPresenceAction(1, discord.secondButton.text, discord.secondButton.link)
updateRichPresence(GlobalState.PlayerCount)
