WorldBuilder = {}

WorldBuilder.Config = {
    command = 'buildmenu',
    propCommand = 'prop',
    permissionAce = 'cidade_tycoon.worldbuilder',
    adminGroups = { 'admin', 'god' },
    maxPlacementDistance = 14.0,
    editDistance = 8.0,
    streamDistance = 220.0,
    removalScanDistance = 180.0,
    externalScanDistance = 220.0,
    removalTickMs = 2500,
    defaultRadius = 3.0,
    defaultExternalRadius = 6.0,

    presets = {
        {
            label = 'Hubs - Logistica',
            props = {
                { label = 'Palete com caixas', model = 'prop_boxpile_07d' },
                { label = 'Palete industrial', model = 'prop_pallet_01a' },
                { label = 'Carrinho de carga', model = 'prop_flattruck_01b' },
                { label = 'Caixa grande', model = 'prop_box_wood05a' },
                { label = 'Contenedor pequeno', model = 'prop_container_05a' },
                { label = 'Bancada metalica', model = 'prop_tool_bench02' },
                { label = 'Mesa de escritorio', model = 'prop_table_03' },
                { label = 'Locker industrial', model = 'p_cs_locker_01_s' },
            }
        },
        {
            label = 'Loja de Pecas',
            props = {
                { label = 'Prateleira', model = 'v_ret_gc_shelving01' },
                { label = 'Prateleira baixa', model = 'v_ret_gc_shelving02' },
                { label = 'Balcao de loja', model = 'v_ret_gc_counter' },
                { label = 'Caixa registradora', model = 'prop_till_01' },
                { label = 'Kit de ferramentas', model = 'prop_toolchest_01' },
                { label = 'Macaco hidraulico', model = 'prop_carjack' },
                { label = 'Pneu', model = 'prop_wheel_tyre' },
                { label = 'Bateria automotiva', model = 'prop_car_battery_01' },
            }
        },
        {
            label = 'Decoracao',
            props = {
                { label = 'Planta', model = 'prop_plant_int_01a' },
                { label = 'Cadeira', model = 'prop_off_chair_04' },
                { label = 'Sofa', model = 'prop_couch_lg_02' },
                { label = 'Lixeira', model = 'prop_bin_05a' },
                { label = 'Cone', model = 'prop_roadcone02a' },
                { label = 'Barreira', model = 'prop_barrier_work05' },
            }
        },
    }
}

return WorldBuilder.Config
