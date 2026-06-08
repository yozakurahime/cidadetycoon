# 📑 Module Specification: cidade_tycoon_production

## 🎯 Purpose
The advanced manufacturing layer of the Tycoon ecosystem. It allows players to transition from simple logistics to industrial production through instanced warehouses. Players can refine raw materials into high-tier legal and illegal goods.

## 📥 Inbound (Inputs)
- **Exports/Events consumed:**
    - `cidade_tycoon_core`: GetFrameworkPlayer, RemoveMoney, AddMoney.
    - `ox_inventory`: For checking raw materials and giving finished products.
    - `ox_lib`: For context menus, dialogs, and point management.

## 📤 Outbound (Outputs)
- **Exports provided:**
    - `GetPlayerCompany`: Returns company data and player role.
- **Database Tables:**
    - `tycoon_companies`: Stores company levels, experience, and products.
    - `tycoon_company_members`: Stores employee ranks and permissions.

## 🛠️ Key Logic & Mechanics
1. **Dimensions (Instancing):** Uses FiveM Routing Buckets to isolate each company within the same physical warehouse near Garage 7.
2. **Interactive Production:** No passive income. Players must engage in manual tasks/minigames inside the warehouse.
3. **Hierarchy System:** Leaders manage their team via the Tablet (Tycoon Business App), setting custom ranks and permissions.
4. **Progression:** Leveling up the company unlocks the 2nd production line (Illegal) and higher employee limits.
5. **Physical Logistics:** Produced items go to the inventory and must be transported manually, integrating with the Logistics module.
