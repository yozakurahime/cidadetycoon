fx_version 'cerulean'

game 'gta5'
lua54 'yes'

white 'White Custom'
discord 'https://discord.gg/cUxnazUxqU'


dependencies {
    '/server:5848',
    '/onesync',
}

-- Remove the following lines if you would like to use the SQL keybinds. Requires oxmysql.

--#region oxmysql

-- dependency 'oxmysql'
-- server_script '@oxmysql/lib/MySQL.lua'

--#endregion oxmysql

shared_scripts {
    'config.lua',
    'Translations.lua',
    'animals.lua',
}

server_scripts {
    'printer.lua',
    'server/Server.lua',
    'server/frameworks/*.lua'
}

client_scripts {
    'NativeUI.lua',
    'client/Utils.lua',
    'client/AnimationList.lua',
    'client/AnimationListCustom.lua',
    'client/AnimationListDeado.lua',
    'client/AnimationListDeadoBridge.lua',
    'client/Binoculars.lua',
    'client/Crouch.lua',
    'client/Emote.lua',
    'client/EmoteMenu.lua',
    'client/Expressions.lua',
    'client/Keybinds.lua',
    'client/NewsCam.lua',
    'client/NoIdleCam.lua',
    'client/Pointing.lua',
    'client/Ragdoll.lua',
    'client/Syncing.lua',
    'client/Walk.lua',
    'client/frameworks/*.lua'
}


---- Loads all ytyp files for custom props to stream ---
---- You will need to add a data_file 'DLC_ITYP_REQUEST' for your own to work in game ---

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/TayMcKenzieNZ/taymckenzienz_rpemotes.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/Brummiee/brummie_props.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/BzzziProps/bzzz_props.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/CandyApple/apple_1.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/KayKayMods/kaykaymods_props.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/KnjghPizzaSlices/knjgh_pizzas.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/NattyLollipops/natty_props_lollipops.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/UltraRingCase/ultra_ringcase.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/PataMods/pata_props.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/PataMods/pata_freevalentinesday.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/babe/bebekbus.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/badge1/badge1.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/badge2/copbadge.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/BzzzFoodPack/bzzz_foodpack.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/NattyLollipops/natty_props_lollipops.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/Pride Props/lilflags_ytyp.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/Pride Props/prideprops_ytyp.ytyp'
