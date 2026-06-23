--------------------------
-- Configs da Hud
--------------------------
HudConfig = HudConfig or {}

HudConfig.vida = 100 -- No FiveM nativo sem vRP, a vida útil varia de 0 a 100 (health de 100 a 200)
HudConfig.fomeSede = false -- Ativa/desativa a fome e sede da hud.
HudConfig.combustivel = true -- Ativa/desativa a exibição de combustível da hud.
HudConfig.stress = true -- Ativa/desativa a exibição de stress da hud.
HudConfig.stress_passive_relief = true -- Reduz stress lentamente quando o jogador está calmo.
HudConfig.stress_passive_interval = 60000 -- Intervalo da redução passiva, em ms.
HudConfig.stress_passive_amount = 1 -- Stress removido por intervalo passivo.
HudConfig.stress_relax_command = true -- Ativa/desativa o comando /relaxar.
HudConfig.stress_relax_amount = 15 -- Stress removido ao concluir /relaxar.
HudConfig.stress_relax_duration = 15000 -- Duração do /relaxar, em ms.
HudConfig.stress_relax_cooldown = 120 -- Cooldown server-side do /relaxar, em segundos.
HudConfig.logo = ""
HudConfig.permstaff = "admin" -- Usando ace group admin no Qbox
HudConfig.cupom = false -- A HUD cinematografica remove publicidade da tela.
-- /eat (Regenera a Fome e Sede)
-- /relaxar (Reduz stress)
-- /hud (Tira a Hud da Tela)
