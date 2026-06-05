# Tycoon Resource Modularization Implementation Plan

## Objective

Dividir `cidade_transport_tycoon_infinito` em varios resources menores, com risco baixo e rollback simples por fase.

## Guiding Rules

- migracao gradual
- compatibilidade temporaria obrigatoria nos fluxos criticos
- cada fase termina com cidade subindo
- sem mover dois dominios criticos ao mesmo tempo
- `cidade_tycoon_core` deve continuar pequeno

## Phase 0 - Contracts and Skeleton

### Deliverables

- criar `resources/[standalone]/cidade_tycoon_core`
- criar `resources/[standalone]/cidade_tycoon_compat`
- definir naming oficial dos novos resources
- centralizar helpers minimos hoje espalhados
- documentar exports/callbacks/eventos publicos

### Expected Files

- `cidade_tycoon_core/fxmanifest.lua`
- `cidade_tycoon_core/shared/*.lua`
- `cidade_tycoon_core/server/*.lua`
- `cidade_tycoon_compat/fxmanifest.lua`
- `cidade_tycoon_compat/client/*.lua`
- `cidade_tycoon_compat/server/*.lua`

### Key Work

- mover `shared_logger.lua`
- padronizar helper de player/citizenid
- padronizar helper de dinheiro
- padronizar helper de `normalizePlate`
- criar toggles de compatibilidade

## Phase 1 - Extract Tablet Gateway

### Deliverables

- criar `cidade_tycoon_tablet`
- mover abertura/fechamento da UI
- mover item de tablet
- mover onboarding state e retomada
- manter dashboard consumindo dados antigos via compat

### Source Areas

- `resources/[standalone]/cidade_transport_tycoon_infinito/company_freelance_client.lua`
- `resources/[standalone]/cidade_transport_tycoon_infinito/company_freelance_server.lua`
- `resources/[standalone]/cidade_transport_tycoon_infinito/ui/*`

### Compatibility

- manter `transport_tycoon_infinito:client:openTablet`
- manter `transport_tycoon_infinito:server:getTabletDashboard`
- encaminhar tudo para `cidade_tycoon_tablet`

### Exit Criteria

- tablet abre normalmente
- onboarding continua funcionando
- NUI passa a pertencer ao novo resource
- resource antigo continua aceitando os contratos antigos de chamada

## Phase 2 - Extract Freelance

### Deliverables

- criar `cidade_tycoon_freelance`
- mover contratos, missao ativa, freight actions
- mover integridade da carga
- mover treinamento de motorista
- mover tutorial operacional

### Source Areas

- `company_freelance_client.lua`
- `company_freelance_server.lua`
- partes de `config/shared.lua` ligadas ao freela

### Compatibility

- aliases de callbacks e eventos antigos
- exports antigos passam a delegar para o novo modulo

### Exit Criteria

- contrato tutorial funciona
- missoes normais funcionam
- tablet consome o novo modulo
- cancelamento, falha e conclusao continuam operando

## Phase 3 - Extract Maintenance

### Deliverables

- criar `cidade_tycoon_maintenance`
- mover oficinas, desgaste, cobranca recorrente, ferramentas de oficina
- mover UI propria de manutencao
- manter tablet consumindo snapshots via export/callback

### Source Areas

- `maintenance_client.lua`
- `maintenance_server.lua`
- `config/maintenance.lua`

### Exit Criteria

- oficinas funcionam isoladamente
- desgaste continua persistindo
- tablet segue recebendo resumo mecanico

## Phase 4 - Extract Dealership

### Deliverables

- criar `cidade_tycoon_dealership`
- mover showroom, catalogo, compra, financiamento e aluguel
- mover UI de concessionaria

### Source Areas

- partes de `city_hubs_client.lua`
- partes de `city_hubs_server.lua`
- imagens/catalogo que forem realmente de producao

### Exit Criteria

- catalogo abre no novo resource
- compra funciona
- contratos financeiros continuam integrados ao tablet

## Phase 5 - Extract City Hall and Social

### Deliverables

- criar `cidade_tycoon_cityhall`
- criar `cidade_tycoon_social`
- separar licencas/governanca de rankings/feed/avisos

### Exit Criteria

- cada bloco sobe sozinho
- city hall nao carrega logica social
- rankings/feed nao dependem do city hall para existir

## Phase 6 - Extract Events and Racing

### Deliverables

- criar `cidade_tycoon_events`
- criar `cidade_tycoon_racing`
- mover listas, seeds e fluxos competitivos para seus dominios corretos

### Exit Criteria

- eventos logisticos independentes
- corridas independentes
- UIs e callbacks separados

## Phase 7 - Remove Tooling From Runtime

### Deliverables

- criar `cidade_tycoon_tools`
- mover captura de imagens e utilitarios de catalogo
- remover essas partes do boot normal da cidade

### Exit Criteria

- producao sobe sem tooling
- tooling continua disponivel manualmente para administracao

## Cross-Cutting Tasks

### Documentation

Cada novo resource deve ganhar:

- `README.md`
- lista de exports publicos
- lista de callbacks publicos
- lista de eventos emitidos e consumidos
- dependencias explicitas

### Logging

- prefixar logs por dominio
- padronizar formato para debug de runtime

### Config Cleanup

- tirar configs de dominio do monolito
- manter so o minimo compartilhado no `core`

### Server Boot

- atualizar `server.cfg` por fase
- manter rollback facil comentando/alternando ensures

## Risks

1. `core` crescer demais.
   - Mitigacao: revisar cada helper antes de mover.

2. compat layer virar permanente.
   - Mitigacao: marcar aliases por fase e remover assim que consumidores forem migrados.

3. UI quebrar por separar dashboard cedo demais.
   - Mitigacao: extrair `tablet gateway` antes de cortar dados de dominio.

4. dominio antigo continuar com responsabilidade oculta.
   - Mitigacao: checklist de ownership por fase.

## First Implementation Slice Recommended

Comecar por:

1. `cidade_tycoon_core`
2. `cidade_tycoon_compat`
3. `cidade_tycoon_tablet`

Esse trio prepara terreno sem mexer de uma vez na logica mais sensivel das missoes.
