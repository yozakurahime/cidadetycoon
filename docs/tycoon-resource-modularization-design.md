# Tycoon Resource Modularization Design

## Understanding Summary

- O objetivo e quebrar `cidade_transport_tycoon_infinito` em varios resources menores.
- A divisao deve melhorar estabilidade, organizacao e performance.
- A prioridade principal e isolamento de falha, com restart mais seguro por modulo.
- A nova arquitetura deve ser organizada por dominio de gameplay.
- Cada dominio importante deve ter sua propria NUI.
- O tablet vira um gateway do jogador, separado do dominio de trabalho.
- A migracao deve ser gradual, com compatibilidade temporaria nos pontos criticos.

## Assumptions

- Havera um `core` minimo compartilhado entre os novos resources.
- O `core` nao carregara regra de negocio de dominio.
- A cidade precisa continuar jogavel durante toda a migracao.
- O padrao de manutencao futuro deve ser legivel para qualquer dev novo no projeto.
- A arquitetura alvo deve suportar operacao confortavel para 40 a 48 jogadores.

## Non-Goals

- Nao vamos redesenhar toda a economia do tycoon nesta etapa.
- Nao vamos reescrever toda a UI da cidade de uma vez.
- Nao vamos fazer um big bang de migracao.
- Nao vamos deixar `cidade_tycoon_core` virar um novo monolito.

## Recommended Approach

Arquitetura por dominio de gameplay, com:

- `cidade_tycoon_core` para helpers e contratos minimos
- `cidade_tycoon_compat` para compatibilidade temporaria
- resources independentes por dominio
- migracao faseada e reversivel

Essa abordagem entrega isolamento real sem exigir corte total de uma vez.

## Target Resource Map

### `cidade_tycoon_core`

Responsabilidades:

- logger compartilhado
- helpers de player, citizenid, dinheiro e placas
- nomes e contratos publicos comuns
- configuracao global minima

Nao deve conter:

- logica de freela
- logica de manutencao
- logica de concessionaria
- logica institucional
- NUI

### `cidade_tycoon_tablet`

Responsabilidades:

- item do tablet
- abrir e fechar a UI
- onboarding do jogador
- dashboard agregado
- waypoints e atalhos de experiencia
- integracao com outros modulos

### `cidade_tycoon_freelance`

Responsabilidades:

- contratos e missao ativa
- freight actions
- integridade da carga
- treinamento de motorista
- tutorial operacional real

### `cidade_tycoon_maintenance`

Responsabilidades:

- oficinas
- desgaste
- pecas
- historico mecanico
- cobranca recorrente
- UI propria

### `cidade_tycoon_dealership`

Responsabilidades:

- catalogo
- showroom
- compra a vista
- financiamento
- aluguel operacional

### `cidade_tycoon_cityhall`

Responsabilidades:

- licencas
- governanca
- impostos
- servicos institucionais

### `cidade_tycoon_social`

Responsabilidades:

- rankings publicos
- avisos
- feed social da cidade

### `cidade_tycoon_events`

Responsabilidades:

- eventos logisticos
- contratos/eventos de prioridade

### `cidade_tycoon_racing`

Responsabilidades:

- corridas oficiais
- corridas privadas
- sementes/listas de corrida

### `cidade_tycoon_tools`

Responsabilidades:

- captura de imagens
- ferramentas de catalogo
- utilitarios de dev/admin

Esse modulo deve ficar fora do runtime normal da cidade.

### `cidade_tycoon_compat`

Responsabilidades:

- reexpor callbacks antigos
- reexpor eventos antigos
- reexpor exports antigos
- encaminhar chamadas para os novos modulos

Esse resource existe para amortecer a migracao e deve encolher com o tempo.

## Module Contracts

Os modulos devem se comunicar por tres superfices:

1. Exports
2. Callbacks
3. Eventos

Regra:

- exports para acoes e consultas simples
- callbacks para payloads orientados a UI
- eventos para notificacao e side effects

Evitar:

- acesso direto a tabelas internas de outro dominio
- callback gigante que devolve metade da cidade
- shared config com regra de negocio espalhada

## Critical First Cut

O primeiro corte recomendado e:

1. `cidade_tycoon_tablet`
2. `cidade_tycoon_freelance`

Motivo:

- sao o coracao operacional da cidade
- concentram onboarding
- tem alto impacto em estabilidade percebida

## Compatibility Strategy

Durante a migracao:

- manter aliases de eventos antigos
- manter aliases de callbacks antigos
- manter exports antigos nos pontos mais sensiveis
- atualizar consumidores por fase

## Decision Log

1. UI por dominio foi escolhida no lugar de uma NUI central.
   - Alternativas: NUI unica, abordagem mista.
   - Motivo: reduzir acoplamento e deixar cada fluxo mais legivel.

2. Estrutura por dominio foi escolhida no lugar de estrutura por camada tecnica.
   - Alternativas: `core/ui/data/services`, mista.
   - Motivo: combina melhor com manutencao real de FiveM e ownership por gameplay.

3. `cidade_tycoon_core` sera minimo.
   - Alternativas: quase nada compartilhado, configs apenas.
   - Motivo: precisamos reaproveitar contratos sem criar novo monolito.

4. Migracao gradual com compatibilidade temporaria foi escolhida.
   - Alternativas: corte grande, hibrida.
   - Motivo: menor risco para cidade viva.

5. Tablet vira gateway do jogador.
   - Alternativas: ficar dentro do freela.
   - Motivo: ele sera a porta de entrada para varios sistemas.

6. Manutencao e concessionaria viram modulos independentes.
   - Alternativas: manter acoplado por enquanto.
   - Motivo: ambos ja tem escopo e UI suficientes para vida propria.

7. `cityhall` e `social` devem ser separados.
   - Alternativas: um bloco institucional unico, deixar por ultimo.
   - Motivo: reduzir a gaveta de funcionalidades heterogeneas.

8. `events` e `racing` devem ser separados.
   - Alternativas: modulo unico temporario.
   - Motivo: dominios diferentes, com risco e evolucao distintos.

## Final Design

O `cidade_transport_tycoon_infinito` deve evoluir de um resource monolitico para um conjunto de resources por dominio, apoiados por um `core` minimo e uma camada temporaria de compatibilidade. A extracao comeca por `tablet` e `freelance`, depois avanca para `maintenance`, `dealership`, `cityhall`, `social`, `events`, `racing` e por fim remove tooling do runtime produtivo. Cada resource deve ter fronteiras explicitas, propria UI quando necessario, e contratos pequenos e bem documentados.
