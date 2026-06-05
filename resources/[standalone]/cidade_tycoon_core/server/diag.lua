CreateThread(function()
    Wait(5000)
    print("^3[Tycoon:Diagnostic]^7 Checking Database Structure...")
    
    local playerVehicles = MySQL.query.await("DESCRIBE player_vehicles")
    if playerVehicles then
        print("^2[Tycoon:Diagnostic]^7 Table 'player_vehicles' structure:")
        for _, col in ipairs(playerVehicles) do
            print(string.format("  - %s (%s) | Null: %s | Key: %s", col.Field, col.Type, col.Null, col.Key))
        end
    else
        print("^1[Tycoon:Diagnostic]^7 Could not find table 'player_vehicles'!")
    end

    local tycoonCompanies = MySQL.query.await("SHOW TABLES LIKE 'tycoon_companies'")
    if tycoonCompanies and #tycoonCompanies > 0 then
        print("^2[Tycoon:Diagnostic]^7 Table 'tycoon_companies' exists.")
    else
        print("^1[Tycoon:Diagnostic]^7 Table 'tycoon_companies' does NOT exist yet!")
    end
end)
