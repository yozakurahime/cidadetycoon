TycoonCore = TycoonCore or {}

local config = require 'shared.config'

-- ==========================================
-- CENTRALIZED MODIFIER ENGINE
-- ==========================================

local function applySkillModifiers(profile, modifierName)
    if not profile then return 1.0 end

    local isSuspended = profile.isSuspended or false
    if isSuspended then
        if modifierName == 'freelance_reward_multiplier' then return 1.0
        elseif modifierName == 'dealership_discount_percent' then return 0.0 end
    end

    -- Logistics Skill Impact
    if modifierName == 'freelance_reward_multiplier' then
        local level = profile.skills.skill_logistics or 0
        return 1.0 + (level * 0.05)
    elseif modifierName == 'race_reward_multiplier' then
        local level = profile.skills.skill_logistics or 0
        return 1.0 + (level * 0.02)

    -- Simulation Modifiers
    elseif modifierName == 'fragile_cargo_protection' then
        local level = profile.skills.skill_fragile or 0
        return 1.0 - (level * 0.10)
    elseif modifierName == 'heavy_cargo_efficiency' then
        local level = profile.skills.skill_heavy or 0
        return 1.0 - (level * 0.15)
    elseif modifierName == 'hazardous_safety_rating' then
        local level = profile.skills.skill_hazardous or 0
        return 1.0 - (level * 0.12)
    end

    return 1.0
end

local function getSkillModifier(source, modifierName)
    return applySkillModifiers(exports.cidade_tycoon_core:GetPlayerProfile(source), modifierName)
end

local function getSkillModifierForCitizen(citizenId, modifierName)
    return applySkillModifiers(exports.cidade_tycoon_core:GetProfileByCitizenId(citizenId), modifierName)
end

local function trainSkill(source, skillName)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return { ok = false, message = 'Perfil nao encontrado.' } end

    if not config.skillDefaults[skillName] then
        return { ok = false, message = 'Habilidade invalida.' }
    end

    local currentLevel = profile.skills[skillName] or 0
    if currentLevel >= config.skillTraining.maxLevel then
        return { ok = false, message = 'Habilidade ja esta no nivel maximo.' }
    end

    -- Training costs and requirements
    local cost = (currentLevel + 1) * config.skillTraining.baseCost
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)

    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < cost then
        return { ok = false, message = ('Saldo insuficiente. Custo: $%d'):format(cost) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', cost, 'tycoon-skill-training') then
        profile.skills[skillName] = currentLevel + 1
        exports.cidade_tycoon_core:UpdateSkills(source, profile.skills)

        return {
            ok = true,
            message = ('Habilidade %s treinada para o nivel %d!'):format(skillName, profile.skills[skillName]),
            level = profile.skills[skillName]
        }
    end

    return { ok = false, message = 'Falha ao processar pagamento.' }
end

exports('GetTycoonSkillModifier', getSkillModifierForCitizen)
exports('GetSkillModifier', getSkillModifier)
exports('TrainSkill', trainSkill)
