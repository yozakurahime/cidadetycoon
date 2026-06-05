-- Emotes you add in the file will automatically be added to AnimationList.lua
-- If you have multiple custom list files they MUST be added between AnimationList.lua and Emote.lua in fxmanifest.lua!
-- Don't change 'CustomDP' it is local to this file!

local CustomDP = {}

CustomDP.Expressions = {}
CustomDP.Walks = {}
CustomDP.Shared = {}
CustomDP.Dances = {}
CustomDP.AnimalEmotes = {}
CustomDP.Exits = {}
CustomDP.Emotes = {
    ["gangsign2"] = { "mp_player_int_uppergang_sign_b", "mp_player_int_gang_sign_b", "Gang Sign 2", AnimationOptions = { EmoteMoving = true, EmoteLoop = true } },
    ["lapdance3"] = { "mini@strip_club@private_dance@part3", "priv_dance_p3", "Lapdance 3", AnimationOptions = { EmoteLoop = true } },
    ["golfswing"] = { "rcmnigel1d", "swing_a_mark", "Golf Swing" },
    ["lapdance"] = { "mp_safehouse", "lap_dance_girl", "Lapdance" },
    ["sunbatheback"] = { "Scenario", "WORLD_HUMAN_SUNBATHE_BACK", "Sunbathe Back" },
    ["reaching"] = { "move_m@intimidation@cop@unarmed", "idle", "Reaching", AnimationOptions = { EmoteMoving = true, EmoteLoop = true } },
    ["t2"] = { "mp_sleep", "bind_pose_180", "T 2", AnimationOptions = { EmoteLoop = true } },
    ["eat"] = { "mp_player_inteat@burger", "mp_player_int_eat_burger", "Eat", AnimationOptions = { EmoteDuration = 3000, EmoteMoving = true } },
    ["lapdance2"] = { "mini@strip_club@private_dance@idle", "priv_dance_idle", "Lapdance 2", AnimationOptions = { EmoteLoop = true } },
    ["leafblower"] = { "MaleScenario", "WORLD_HUMAN_GARDENER_LEAF_BLOWER", "Leafblower" },
    ["hug"] = { "mp_ped_interaction", "kisses_guy_a", "Hug" },
    ["gangsign"] = { "mp_player_int_uppergang_sign_a", "mp_player_int_gang_sign_a", "Gang Sign", AnimationOptions = { EmoteMoving = true, EmoteLoop = true } },
    ["drink"] = { "mp_player_inteat@pnq", "loop", "Drink", AnimationOptions = { EmoteDuration = 2500, EmoteMoving = true } },
    ["copbeacon"] = { "MaleScenario", "WORLD_HUMAN_CAR_PARK_ATTENDANT", "Cop Beacon" },
    ["dj"] = { "anim@amb@nightclub@djs@dixon@", "dixn_dance_cntr_open_dix", "DJ", AnimationOptions = { EmoteMoving = true, EmoteLoop = true } },
    ["twerk"] = { "switch@trevor@mocks_lapdance", "001443_01_trvs_28_idle_stripper", "Twerk", AnimationOptions = { EmoteLoop = true } },
    ["t"] = { "missfam5_yoga", "a2_pose", "T", AnimationOptions = { EmoteMoving = true, EmoteLoop = true } },
    ["hug3"] = { "mp_ped_interaction", "hugs_guy_a", "Hug 3" },
    ["hug2"] = { "mp_ped_interaction", "kisses_guy_b", "Hug 2" }
}
CustomDP.PropEmotes = {
    ["brief3"] = {
        "missheistdocksprep1hold_cellphone",
        "static",
        "Brief 3",
        AnimationOptions = {
            Prop = "prop_ld_case_01",
            PropBone = 57005,
            PropPlacement = { 0.1, 0.0, 0.0, 0.0, 280.0, 53.0 },
            EmoteMoving = true,
            EmoteLoop = true
        }
    }
}

CustomDP.Walks["Gangster5"] = { "move_m@gangster@var_i" }
CustomDP.Walks["Gangster4"] = { "move_m@gangster@var_f" }
CustomDP.Walks["Hurry"] = { "move_f@hurry@a" }
CustomDP.Walks["Gangster3"] = { "move_m@gangster@var_e" }
CustomDP.Walks["Lemar"] = { "anim_group_move_lemar_alley" }
CustomDP.Walks["Gangster2"] = { "move_m@gangster@ng" }

-----------------------------------------------------------------------------------------
--| I don't think you should change the code below unless you know what you are doing |--
-----------------------------------------------------------------------------------------

-- Add the custom emotes to RPEmotes main array
for arrayName, array in pairs(CustomDP) do
    if RP[arrayName] then
        for emoteName, emoteData in pairs(array) do
            RP[arrayName][emoteName] = emoteData
        end
    end
    -- Free memory
    CustomDP[arrayName] = nil
end
-- Free memory
CustomDP = nil
