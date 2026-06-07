# 📑 Module Specification: cidade_tycoon_production

## 🎯 Purpose
Manages the industrial manufacturing process. It allows company owners to convert raw materials into finished goods (high-end parts, luxury cargo) using timed recipes and physical interaction terminals.

## 📥 Inbound (Inputs)
- **Exports/Events consumed:**
    - `cidade_tycoon_core`: To verify profiles and process material purchase payments.
    - `cidade_tycoon_logistics`: To verify company ownership and warehouse capacity.
- **Database:** Relies on `tycoon_warehouse_inventory` for raw material stocks.

## 📤 Outbound (Outputs)
- **Callbacks:** `startProduction`, `getWarehouseInventory`, `buyMaterials`.
- **Database:** Directly updates item counts in the `tycoon_warehouse_inventory` table.

## 🌍 World & Entity Management
- **Spawns:**
    - `prop_toolchest_01`: Physical terminal spawned at the `productionCoords` of each warehouse.
    - **Visuals:** Floating "Terminal de Produção" labels.
- **Deletions/Cleanup:** Removes all spawned benches on resource stop.

## 🛠️ Internal Logic
1. **Recipe System:** Uses a time-based queue. Inputs are removed from the warehouse inventory when production starts.
2. **Cron Job:** A server-side thread runs every 30 seconds to check for completed batches and deliver output goods to the warehouse.
3. **Material Sourcing:** Owners can buy raw materials directly via the terminal using the company's vault balance (integrated with okokBanking).
4. **Integration:** Consumes "Scrap" items recycled in the `autoparts` module as cheap raw materials.
