TycoonCore = TycoonCore or {}

local function normalizePlate(plate)
    return tostring(plate or ''):gsub('%s+', ''):upper()
end

TycoonCore.NormalizePlate = normalizePlate

return {
    normalizePlate = normalizePlate,
}
