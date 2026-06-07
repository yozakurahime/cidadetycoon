# 📑 Module Specification: cidade_tycoon_freelance

## 🎯 Purpose
Manages the freelance logistics career. It handles mission generation (Land, Sea, Air), cargo integrity monitoring, physical freight interactions (carrying boxes), and reward distribution for individual contractors.

## 📥 Inbound (Inputs)
- **Exports/Events consumed:**
    - `cidade_tycoon_core`: To fetch profile data, add XP, and notify players.
    - `cidade_tycoon_hubs`: To get coordinates for pickup and delivery points.
    - `ox_inventory`: To add/remove the `tycoon_cargo` item and check carrying capacity.
- **Config:** Uses `config/shared.lua` for mission point coordinates and reward multipliers.

## 📤 Outbound (Outputs)
- **Events triggered:**
    - `cidade_tycoon_tablet:client:updateFreelanceHUD`: Sends real-time progress to the tablet.
    - `tycoon:server:logTransaction`: Logs mission payouts to the Core ledger.
- **State Bags:** Updates `tycoonProfile.activeMission` to allow other modules (HUD) to react to mission state.

## 🌍 World & Entity Management
- **Spawns:**
    - `prop_paper_box_01`: Spawned and attached to the player during the "carrying" phase.
    - `Blips`: Dynamic mission blips (Yellow for pickup, Blue for delivery).
    - `Particles`: Green smoke VFX on vehicles carrying hazardous cargo with low integrity.
- **Deletions/Cleanup:** 
    - Automatically removes blips, props, and VFX on mission completion, failure, or resource stop.
    - Resets vehicle handling (mass) if "Heavy" cargo was being transported.

## 🛠️ Internal Logic
1. **Mission Flow:** Starts with a Hub interaction -> Pickup at Origin -> Load into Vehicle -> Drive to Destination -> Unload -> Deliver at Point.
2. **Integrity Monitoring:** A 500ms client-side thread monitors vehicle health and player damage. Impacts cause integrity loss based on multipliers (Fragile = 2x).
3. **Physical Validation:** If the `tycoon_cargo` item is removed from the inventory (dropped/lost), the server-side Event Listener cancels the mission.
4. **Distance Logic:** Interaction prompts (E to pickup) only appear when within 2.2m of designated points.
