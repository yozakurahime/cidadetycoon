local function dumpTableSchema(tableName)
    local columns = MySQL.query.await(("SHOW COLUMNS FROM %s"):format(tableName))
    print(("^3--- SCHEMA DUMP: %s ---^7"):format(tableName))
    for _, col in ipairs(columns) do
        print(("- %s (%s)"):format(col.Field, col.Type))
    end
end

RegisterCommand('tycoon_dump_schema', function(source)
    dumpTableSchema('player_vehicles')
    dumpTableSchema('tycoon_players')
end, true)
