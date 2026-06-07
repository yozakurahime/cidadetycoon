# 📑 Module Specification: cidade_tycoon_logistics

## 🎯 Purpose
Manages the corporate layer of the Tycoon simulation. This includes company creation, warehouse ownership, employee recruitment, and the management of corporate fleets and job boards.

## 📥 Inbound (Inputs)
- **Exports/Events consumed:**
    - `cidade_tycoon_core`: To verify profiles, update company XP, and process large currency transactions via okokBanking.
    - `cidade_tycoon_hubs`: To link company headquarters to physical world locations.
- **Data required:** `tycoon_companies`, `tycoon_company_employees`, and `tycoon_company_fleet` database tables.

## 📤 Outbound (Outputs)
- **Exports provided:**
    - `GetCompanyData(source)`: Returns the company profile owned by the player.
    - `GetBusinessDashboardForSource(source)`: Consolidates all corporate data for the tablet.
    - `StartPlayerBulkContractForSource(...)`: Initiates a high-volume mission for company owners.
- **Callbacks:** Registered with `lib.callback` for purchasing warehouses and recruiting NPCs.

## 🌍 World & Entity Management
- **Spawns:** Does not spawn physical entities directly (delegates to `hubs` or `production`).
- **Deletions/Cleanup:** Handles the archival of completed NPC delivery contracts.

## 🛠️ Internal Logic
1. **Company Logic:** Players must purchase a physical warehouse to unlock the corporate dashboard.
2. **Bulk Contracts:** Generates missions with 10x the volume of freelance jobs, requiring multi-trip logistics.
3. **Vault System:** Integrates with `okokBanking_societies` to allow company owners to pay for upgrades and salaries from the corporate cofre.
4. **NPC Management:** (Planned) Handles a background thread for NPC employee delivery progression.
