# 📑 Module Specification: cidade_tycoon_autoparts

## 🎯 Purpose
Manages the physical marketplace for vehicle components and the industrial recycling station. It replaces generic menus with immersive, shelf-based interactions within warehouse interiors.

## 📥 Inbound (Inputs)
- **Exports/Events consumed:**
    - `cidade_tycoon_core`: To fetch part data (price, category), log transactions, and remove money.
    - `cidade_tycoon_logistics`: To verify company ownership for scrap recycling.
    - `ox_inventory`: To add purchased parts and remove scrap items.
- **Config:** Uses `config/shared.lua` from the logistics module for warehouse coordinates and part definitions.

## 📤 Outbound (Outputs)
- **Callbacks:** 
    - `purchasePart`: Server-side logic for buying components.
    - `recycleScrap`: Server-side logic for converting scrap into warehouse materials.
- **Database:** Directly updates the `tycoon_warehouse_inventory` table during recycling.

## 🌍 World & Entity Management
- **Spawns:**
    - `prop_table_03`: Physical shelf for Mechanical components.
    - `prop_table_03b`: Physical shelf for Maintenance consumables.
    - `prop_ld_bin_01`: Physical bin for Scrap recycling.
    - **Visuals:** 3D Text Labels above each prop (e.g., "Componentes Pesados").
- **Deletions/Cleanup:** 
    - Deletes all spawned props when the resource stops.

## 🛠️ Internal Logic
1. **Physical Shelving:** Props are spawned at `productionCoords` with specific offsets. `ox_target` is attached directly to the entities.
2. **Economic Loop:** Converts `mechanical_scrap`, `electronic_scrap`, and `rubber_scrap` (generated during repairs) into raw materials for the company's production lines.
3. **Proximity Performance:** Markers and 3D labels are only rendered when the player is within 15.0m of the Hub, using a 1500ms idle wait.
