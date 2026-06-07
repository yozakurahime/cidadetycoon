# AGENTS.md - Tycoon Intelligence Manifest

## 🌲 Repository Architecture
This is a modular "Transport Tycoon" simulation built on the Qbox (QB-Core) framework.

### Core Resources
- `cidade_tycoon_core`: SSOT (Single Source of Truth) for profiles, database initialization, and shared exports.
- `cidade_tycoon_logistics`: Business management, company ownership, and warehouse data.
- `cidade_tycoon_freelance`: Mission runner, mission generation, and reward logic.
- `cidade_tycoon_tablet`: Central UI for all tycoon activities.
- `cidade_chat`: Minimalist, glassmorphic chat system matching the HUD.

### Support Modules
- `cidade_tycoon_market`: Vehicle dealership and financing.
- `cidade_tycoon_maintenance`: Wear & tear system and repair workshops.
- `cidade_tycoon_production`: Industrial manufacturing and scrap recycling.
- `cidade_tycoon_hubs`: Physical world interaction points (NPCs, Props).
- `cidade_hud`: Reactive UI for real-time cargo/vehicle monitoring.

## 🛠️ Standards & Conventions
- **Prefix:** All custom resources MUST be prefixed with `cidade_`.
- **Sync:** Prioritize State Bags (`tycoonProfile`) over Server Callbacks for UI updates.
- **Geography:** Use `vector3` / `vector4`. Coordinate standards follow the "Grounded" rule (all interaction points on solid ground).
- **Inventory:** Exclusively integrated with `ox_inventory` (Qbox/QB-Core native).
- **Banking:** Exclusively integrated with `okokBanking`.

## ✅ Global Audit & Optimization (Completed 2026-06-04)
The ecosystem has been hardened and optimized to Enterprise standards.

### 🛡️ Hardening Measures
- **Framework Isolation:** All QBCore/Qbox calls are bridged through `cidade_tycoon_core/server/framework.lua`.
- **Database:** Standardized on `BIGINT` for currency and rewards. Implemented transactional `pcall` wrappers.
- **Inventory:** 100% migrated to `ox_inventory`. Legacy `core_inventory` removed.
- **Performance:** Migrated HUD and Tablet sync to Reactive State Bag listeners (Zero-Loop Pattern). Increased idle waits to 2000ms.

### 📜 Decision Log Summary
- **[D1] Private State Bags:** Private data sync moved to non-replicated handlers to prevent O(N^2) traffic.
- **[D2] Damage Noise Floor:** Adjusted damage detection to ignore minor terrain bumps on bicycles.
- **[D3] Unified Exports:** Common utilities (Notify, AddMoney, Log) centralised in Core.

## 💾 State Bag Manifest (`tycoonProfile`)
- `citizenid`: Unique ID.
- `level`, `experience`: Player progression.
- `activeMission`: Current job data (nil if idle).
- `isSuspended`: Fiscal status.
- `vaultBalance`: Personal/Corporate savings linked to okokBanking.
