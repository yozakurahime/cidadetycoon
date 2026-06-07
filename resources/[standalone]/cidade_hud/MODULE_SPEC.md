# 📑 Module Specification: cidade_hud

## 🎯 Purpose
A specialized, reactive UI overlay for the Tycoon career. It provides real-time monitoring of mission progress, cargo integrity, and professional driver stats without cluttering the main screen.

## 📥 Inbound (Inputs)
- **Exports/Events consumed:**
    - `cidade_tycoon_core`: Fetches profile identity (Player Name, Passport).
    - `cidade_tycoon_freelance`: Receives mission update events.
- **State Bags:** Listens reactively to `tycoonProfile` for progression data.

## 📤 Outbound (Outputs)
- **NUI Messages:**
    - `updateTycoon`: Syncs Level, XP, and Company Name.
    - `updateMission`: Syncs Cargo Health and Delivery Counter.
- **Visuals:** Glassmorphic side panel with dynamic color coding (Green/Yellow/Red).

## 🌍 World & Entity Management
- **Spawns:** Does not spawn physical entities.
- **Radar:** Automatically toggles the GTA Radar/Minimap based on vehicle state.

## 🛠️ Internal Logic
1. **Zero-Loop Architecture:** Uses `AddStateBagChangeHandler` to update progression stats, eliminating the need for periodic polling threads.
2. **Event Redirection:** Converts mission-specific events into NUI payloads for the CSS-based interface.
3. **Identity Sync:** Normalizes framework-specific names into a clean Tycoon Identity (First + Last Name).
4. **Visibility:** Handles HUD-off commands to allow cinematic gameplay/recordings.
