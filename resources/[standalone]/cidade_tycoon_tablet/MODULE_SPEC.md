# 📑 Module Specification: cidade_tycoon_tablet

## 🎯 Purpose
The primary user interface for Tycoon players. It consolidates data from all modules (Logistics, Freelance, Finance, Maintenance) into a single mobile dashboard. It serves as the player's control center for accepting contracts, monitoring vehicle health, and managing their company.

## 📥 Inbound (Inputs)
- **Exports/Events consumed:**
    - `cidade_tycoon_core`: Fetches profile data, transaction history, and handles notifications.
    - `cidade_tycoon_freelance`: Retrieves active mission context.
    - `cidade_tycoon_trucklogistics`: Opens the dedicated trucking company interface.
    - `cidade_tycoon_maintenance`: Fetches upgrade data and vehicle status alerts.
    - `cidade_tycoon_market`: Retrieves active financing contracts.
- **State Bags:** Listens to `tycoonProfile` for instant UI updates.

## 📤 Outbound (Outputs)
- **Exports provided:**
    - `EnsureStarterTabletForSource(source)`: Guarantees the player has the physical tablet item.
- **NUI Messages:** Communicates with the web interface (`app.js`) to render the dashboard and apps.
- **Callbacks:** Registered with `lib.callback` for UI actions (Reset Profile, Accept Job, Pay Finance).

## 🌍 World & Entity Management
- **Spawns:**
    - `prop_cs_tablet`: Spawned and attached to the player's hand when the tablet is opened inside a vehicle.
    - **Scenarios:** Triggers `WORLD_HUMAN_STAND_MOBILE` when opening the tablet while standing.
- **Deletions/Cleanup:** 
    - Removes the tablet prop and stops animations when the UI is closed or the resource stops.

## 🛠️ Internal Logic
1. **Aggregated Dashboard:** The `getDashboardForSource` server-side function queries ALL relevant modules to build a single JSON payload for the UI.
2. **NUI Communication:** Uses `window.postNUI` (JS) and `RegisterNUICallback` (Lua) for bidirectional interaction.
3. **Clock Sync:** A background thread sends the current game time to the tablet every 10 seconds.
4. **Physical Activation:** Opening the tablet requires the physical `tablet` item in the inventory (integrated via `ox_inventory`).
