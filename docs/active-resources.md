# Resources Ativos - Transport Tycoon

## Regra Operacional

O `server.cfg` usa uma lista explicita. Nao substituir por `ensure [qbx]`,
`ensure [standalone]` ou `ensure [ox]`, pois isso reativa sistemas tradicionais
de RP e dificulta a auditoria.

O limite configurado e `sv_maxclients 48`, respeitando a chave atual. A
arquitetura continua preparada para aumentar esse valor quando a assinatura for
atualizada.

## Nucleo Ativo

| Area | Resources |
| --- | --- |
| FiveM base | `mapmanager`, `chat`, `spawnmanager`, `sessionmanager`, `hardcap`, `baseevents` |
| Infraestrutura | `oxmysql`, `ox_lib`, `qbx_core`, `ox_target`, `ox_inventory`, `ox_fuel` |
| Jornada | `qbx_spawn`, `illenium-appearance` |
| Economia | `Renewed-Banking` |
| Transporte | `qbx_vehicles`, `qbx_garages`, `qbx_vehiclekeys`, `qbx_seatbelt`, `qbx_smallresources`, `qbx_carwash`, `qbx_customs` |
| Tycoon | `cidade_tycoon_core`, `cidade_tycoon_compat`, `cidade_tycoon_freelance`, `cidade_tycoon_maintenance`, `cidade_tycoon_market`, `cidade_tycoon_tablet`, `cidade_transport_tycoon_infinito`, `qbx_lapraces` |
| Interface | `cidade_hud`, `pma-voice`, `qbx_radialmenu`, `qbx_scoreboard`, `qbx_chat_theme` |
| Servicos base | `qbx_density`, `qbx_idcard`, `qbx_adminmenu` |
| Mundo | `Renewed-Weathersync`, `bob74_ipl`, `loadscreen` |

## Desativados Nesta Fase

Os diretorios continuam em `resources` para permitir rollback, mas nao iniciam.

- HUD antigo: `qbx_hud`.
- Prefeitura tradicional: `qbx_cityhall`.
- RP policial e medico: `qbx_police`, `qbx_ambulancejob`, `qbx_medical`.
- Crimes e drogas: `qbx_bankrobbery`, `qbx_houserobbery`, `qbx_storerobbery`,
  `qbx_truckrobbery`, `qbx_drugs`, `qbx_weed`, `qbx_jewelery`.
- Propriedades, vendas e gestao tradicional: `qbx_properties`, `qbx_management`,
  `qbx_vehicleshop`, `qbx_vehiclesales`.
- Empregos comuns: `qbx_busjob`, `qbx_garbagejob`, `qbx_mechanicjob`,
  `qbx_newsjob`, `qbx_recyclejob`, `qbx_taxijob`, `qbx_towjob`,
  `qbx_truckerjob`, `qbx_vineyard`.
- Telefone: `npwd`, `qbx_npwd`, `[npwd-apps]`.

## Onboarding

- `qbx_core` nao entrega telefone ou documentos automaticamente.
- `cidade_transport_tycoon_infinito` garante exatamente um `tablet`.
- Na primeira entrada de cada `citizenid`, o tycoon registra uma `cruiser`
  persistente em `motelgarage`.
- Garagens publicas exibem veiculos compativeis do jogador independentemente do
  ultimo estacionamento. Garagens restritas e depositos preservam os filtros.

## Validacao Manual Recomendada

1. Reiniciar o servidor e observar erros de dependencias no console.
2. Criar um personagem novo e confirmar um tablet e uma `cruiser`.
3. Reconectar e confirmar que nao existem duplicatas.
4. Retirar e guardar a bicicleta em duas garagens publicas diferentes.
5. Confirmar HUD unico com fome, sede, stress, voz, combustivel e cinto.
6. Validar que telefone ausente nao impede contratos basicos.
