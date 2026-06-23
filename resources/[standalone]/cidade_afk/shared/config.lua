-- shared/config.lua
-- Configuracao do sistema AFK

local Config = {}

-- Tempos em segundos
Config.AFK = {
    -- Primeiro aviso de inatividade (aparece notificacao)
    warningTime = 240,          -- 4 minutos

    -- Entra em modo AFK (passivo + animacao)
    afkTime = 300,              -- 5 minutos

    -- Kick por AFK prolongado
    kickTime = 1800,            -- 30 minutos

    -- Aviso de kick (quanto tempo antes do kick)
    kickWarningTime = 60,       -- 1 minuto antes de kickar

    -- Tempo que o veiculo precisa estar parado para detectar AFK
    vehicleStopSeconds = 8,     -- 8 segundos parado

    -- Cooldown de combate ao retornar do AFK (segundos)
    combatCooldown = 120,       -- 2 minutos

    -- Verificar a cada X ms
    checkInterval = 1000,       -- 1 segundo

    -- Ignorar grupos (admin/mod nao sao kickados)
    ignoreGroups = {
        ['mod'] = true,
        ['admin'] = true,
        ['god'] = true,
    },
}

-- Controles considerados como "input ativo" (além de movimento)
Config.ActiveControls = {
    18, 22, 23, 24, 25,        -- Pular, entrar/sair, acelerar
    37, 38,                     -- Atirar, mirar
    44,                         -- Cover
    47,                         -- Handbrake
    56, 57,                     -- Acelerar/frear veiculo
    71, 72,                     -- Setas
    73, 74,                     -- X, Z
    75, 76,                     -- Alt, Shift
    86, 87, 88,                 -- W A S D alternativos
    140, 141, 142,              -- Mouse wheel
    172, 173, 174, 175,         -- Setas direcionais
    201, 202, 203,              -- R, F, Q
    204, 205, 206,              -- E, T, Tab
    209, 210, 211,              -- Caps, Shift, Ctrl
    237, 238, 239, 240, 241,    -- Teclas do volante
    257, 258, 259, 260, 261,    -- WASD
    263, 264,                   -- Espaco, Shift
    288,                        -- H (buzina)
    329,                        -- R para reabastecer
}

return Config
