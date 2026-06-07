# 📑 Module Specification: cidade_tycoon_maintenance

## 🎯 Purpose
Handles vehicle health, mechanical wear & tear, and specialized repair workshops. It ensures that vehicles are not immortal and require constant logistical and financial upkeep based on usage patterns.

## 📥 Inbound (Inputs)
- **Exports/Events consumed:**
    - `cidade_tycoon_core`: To fetch part data, vehicle status, and process repair payments.
    - `ox_inventory`: To search for and remove repair parts from the player's inventory.
- **Config:** Relies on `config/maintenance.lua` for workshop locations and wear multipliers.

## 📤 Outbound (Outputs)
- **Exports provided:**
    - `GetUpgradeDashboardForSource(source)`: Returns the performance upgrade state for the tablet.
- **Database:** Updates `tycoon_vehicle_status` with mileage and subsystem health.
- **Callbacks:** `getWorkshopVehicleData`, `repairSubsystem`, `purchaseAndRepairNPC`.

## 🌍 World & Entity Management
- **Spawns:**
    - **NPCs:** Spawns workshop managers at each office/garage.
    - **Blips:** Yellow/Gold workshop blips on the map.
- **Deletions/Cleanup:** Removes peds and blips on resource stop.

## 🛠️ Internal Logic
1. **Wear Tracking:** A 500ms client thread monitors speed, braking intensity, RPM, and off-road travel. It accumulates "Wear Samples".
2. **Data Flushing:** Samples are flushed to the server every 2km or 60 seconds to update the database.
3. **Subsystem Repair:** Repairs are granular (Engine, Transmission, Brakes, Suspension, Tires). Each requires a physical item from the `ox_inventory`.
4. **Scrap Cycle:** Repairing a part generates "Scrap" items, which are then used in the `cidade_tycoon_production` module.
