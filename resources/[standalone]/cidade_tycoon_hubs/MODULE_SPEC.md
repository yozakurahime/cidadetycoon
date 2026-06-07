# 📑 Module Specification: cidade_tycoon_hubs

## 🎯 Purpose
The world-building module for Tycoon. It populates the map with physical headquarters, dispatchers (NPCs), and blips. It acts as the physical entry point for both freelance and corporate players.

## 📥 Inbound (Inputs)
- **Exports/Events consumed:**
    - `cidade_tycoon_freelance`: Triggers mission menus on NPC interaction.
    - `cidade_tycoon_logistics`: Triggers company management menus.
- **Config:** Relies on `config/hubs.lua` for coordinates (PostOP, The Foundry, Grapeseed Shed).

## 📤 Outbound (Outputs)
- **Exports provided:**
    - `GetAllHubs()`: Returns the list of all active headquarters for the tablet.
- **Targeting:** Integrates with `ox_target` to provide interaction menus on NPCs.

## 🌍 World & Entity Management
- **Spawns:**
    - **NPCs:** Spawns distinct dispatcher models at all 7 hubs.
    - **Blips:** Hub markers on the map (Sprite 473 - Logistics).
    - **IPLs:** Requests vanilla interiors (`v_lesters`, `v_postop`) to ensure world accessibility.
- **Deletions/Cleanup:** 
    - Removes all NPCs and blips on resource stop.
    - **Door Removal:** Dynamically deletes blocking physical doors to vanilla interiors.

## 🛠️ Internal Logic
1. **Grounded Spawning:** Implements a collision-aware waiting sequence to prevent NPCs from falling through the floor during area loading.
2. **Aggressive Loading:** Uses `PinInteriorInMemory` and a proximity-based `RefreshInterior` loop to ensure floors and furniture are rendered at all times.
3. **Menu Routing:** NPC interactions dynamically detect if the player is a Freelancer or a Company Owner and show the appropriate contract menu.
