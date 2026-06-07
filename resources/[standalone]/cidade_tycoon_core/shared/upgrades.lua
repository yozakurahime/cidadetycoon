TycoonCore = TycoonCore or {}

TycoonCore.Upgrades = {
    fleet_tier = {
        displayName = 'Fleet Tier',
        baseCost = 25000,
        growthMultiplier = 1.85,
        maxLevel = 12,
    },
    capacity_boost = {
        displayName = 'Capacity Boost',
        baseCost = 18000,
        growthMultiplier = 1.75,
        maxLevel = 12,
    },
    efficiency_tuning = {
        displayName = 'Efficiency Tuning',
        baseCost = 32000,
        growthMultiplier = 2.0,
        maxLevel = 5,
    },
    vehicle_performance = {
        displayName = 'Performance do Veiculo',
        baseCost = 20000,
        growthMultiplier = 1.8,
        maxLevel = 5,
    },
    vehicle_handling = {
        displayName = 'Suspensao e Controle',
        baseCost = 15000,
        growthMultiplier = 1.7,
        maxLevel = 5,
    },
    cargo_capacity = {
        displayName = 'Expansao de Carga',
        baseCost = 25000,
        growthMultiplier = 2.0,
        maxLevel = 5,
    }
}

function TycoonCore.CalculateUpgradeCost(upgradeKey, currentLevel)
    local def = TycoonCore.Upgrades[upgradeKey]
    if not def then return 0 end
    local rawValue = def.baseCost * (def.growthMultiplier ^ currentLevel)
    return math.floor(rawValue + 0.5)
end

function TycoonCore.FormatUpgradeEffects(upgradeState)
    return {
        fleetTier = 1 + (upgradeState.fleet_tier or 0),
        capacityMultiplier = 1.0 + ((upgradeState.capacity_boost or 0) * 0.15),
        taxReductionPercent = math.min(5, upgradeState.efficiency_tuning or 0),
        performanceBoost = (upgradeState.vehicle_performance or 0) * 10,
        handlingBoost = (upgradeState.vehicle_handling or 0) * 3,
        extraCargo = (upgradeState.cargo_capacity or 0),
    }
end

return TycoonCore.Upgrades
