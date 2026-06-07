# 📑 Module Specification: cidade_tycoon_core

## 🎯 Purpose
The central nervous system of the Tycoon ecosystem. It manages persistent player profiles, shared configurations, and provides a framework-agnostic bridge between Tycoon business logic and the base server framework (Qbox/QB-Core).

## 📥 Inbound (Inputs)
- **Frameworks:** Interacts with `qbx_core` or `qb-core` for player loading/unloading and economy operations.
- **Database:** Requires an active `oxmysql` connection.
- **Data:** Relies on `shared/config.lua` for skill/upgrade defaults and level formulas.

## 📤 Outbound (Outputs)
- **Exports provided:**
    - `GetPlayerProfile(source)`: Returns the full tycoon data for a player.
    - `UpdateProfileField(source, field, value)`: Updates specific persistent or volatile fields.
    - `AddExperience(source, amount)`: Handles level progression logic.
    - `GetFrameworkPlayer(source)`: Abstracted player object retrieval.
    - `NotifyPlayer(source, message, type)`: Centralized notification routing.
- **State Bags:** Replicates the `tycoonProfile` to the client for reactive UI (HUD/Tablet) updates.
- **Database:** Manages the initialization of all `tycoon_*` tables.

## 🌍 World & Entity Management
- **Spawns:** Does not spawn physical entities.
- **Deletions/Cleanup:** Clears player memory cache on disconnect via `qbx_core:server:onPlayerUnload`.

## 🛠️ Internal Logic
1. **Startup:** Runs `createTycoonTables()` to ensure the SQL schema is correct (Auto-migration).
2. **Persistence:** Uses `PlayerProfiles` table in memory for fast access, flushing changes to MySQL on specific field updates.
3. **Leveling:** Implements a cumulative XP formula ($Level * 1500$) and triggers level-up events.
4. **Tax Compliance:** Runs a 1-hour background thread to check for overdue taxes and suspend licenses (`is_suspended`).
