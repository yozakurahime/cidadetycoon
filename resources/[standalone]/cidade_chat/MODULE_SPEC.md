# 📑 Module Specification: cidade_chat

## 🎯 Purpose
A minimalist, immersive, and reactive chat system designed specifically for the Cidade Tycoon aesthetic. It replaces the default CFX chat to provide a cohesive visual experience integrated with the main HUD.

## 📥 Inbound (Inputs)
- **Exports/Events consumed:**
    - `qbx_core`: Fetches player names and permissions (admin/staff tags).
- **Events:** Listens for `chat:addMessage` and `chat:clear` for backward compatibility with other resources.

## 📤 Outbound (Outputs)
- **Events triggered:**
    - `cidade_chat:server:sendMessage`: Broadcasts player messages to the entire server.
- **Exports provided:**
    - `addMessage(target, payload)`: Allows other scripts to send formatted messages to specific players or all.

## 🌍 World & Entity Management
- **Spawns:** Does not spawn physical entities.
- **NUI:** Renders a glassmorphic chat box and input field.

## 🛠️ Internal Logic
1. **Glassmorphic UI:** Uses high-blur backgrounds and the 'Outfit' font to match `cidade_hud`.
2. **Message Lifespan:** Messages automatically fade and are removed from the DOM after 15 seconds to keep the screen clean.
3. **Compatibility Layer:** Implements a `provide 'chat'` in the manifest to satisfy dependencies from other resources while using its own custom logic.
4. **Input Handling:** Automatically handles commands (prefixed with `/`) using the native `ExecuteCommand`.
