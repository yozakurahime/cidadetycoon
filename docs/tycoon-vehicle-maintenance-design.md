# Cidade Tycoon - Sistema de Desgaste, Manutencao e Oficina

## Objetivo

Definir um sistema mecanico persistente para a Cidade Tycoon, com desgaste,
pecas, instalacao em oficina, diagnostico via tablet e impacto economico real
na progressao dos jogadores.

## Understanding Summary

- A cidade vai receber um sistema de `desgaste e manutencao` de veiculos com profundidade entre `medio` e `pesado`.
- O sistema deve afetar `todos os jogadores por igual`, sem privilegiar so frota de trabalho ou so carros de luxo.
- O nucleo inicial tera `pneus`, `motor`, `freios`, `transmissao/tracao`, `suspensao` e `alinhamento`.
- As pecas serao `itens fisicos`, comprados em lojas e levados ate `oficinas oficiais`.
- O proprio jogador podera instalar o basico, mas `mecanicos` instalam mais rapido e com melhor qualidade.
- O desgaste deve reagir a `uso`, `colisoes` e `estilo de direcao`.
- O estado do veiculo deve aparecer em `tablet + mecanica`, com persistencia forte e validacao forte no servidor.

## Premissas

- O recurso `qbx_customs` pode continuar existindo para customizacao visual, enquanto este sistema cuida do estado mecanico persistente.
- O sistema sera integrado ao ecossistema atual do `cidade_transport_tycoon_infinito`, tablet e economia da cidade.
- O lancamento usara `poucas oficinas oficiais`, com peso real de RP e operacao.
- A compatibilidade sera `ampla e flexivel`, com grupos por categoria de veiculo em vez de regras muito rigidas por modelo.
- O sistema deve ser `altamente configuravel`, para evoluir por configs/tabelas e nao por hardcode espalhado.
- A persistencia desejada e `forte`: estado da peca, qualidade da instalacao, risco de falha e historico basico.

## Nao-Objetivos

- Nao criar um simulador extremo de mecanica com micropecas em excesso no primeiro lancamento.
- Nao exigir compatibilidade manual por modelo para milhares de veiculos.
- Nao depender de loops pesados permanentes em todos os veiculos do servidor.
- Nao mover a manutencao inteira para HUD; o centro da experiencia sera `tablet + oficina`.

## Decisoes Confirmadas

### Escopo do Sistema

- Profundidade: `entre 2 e 3`
- Impacto: `todos igual`
- Subsystems iniciais:
  - `pneus`
  - `motor`
  - `freios`
  - `transmissao/tracao`
  - `suspensao`
  - `alinhamento`

### Economia de Pecas

- Compra: `item fisico no inventario`
- Pecas comuns:
  - `pneus`
  - `freios`
  - `filtro`
  - `oleo`
  - `radiador`
- Pecas premium/especiais:
  - `ECU`
  - `turbo/compressor`
  - `embreagem performance`
  - `suspensao esportiva`
  - `conversao de tracao`
  - `pneus premium de corrida e drift`

### Instalacao

- Instalacao basica: `jogador + mecanico`
- Vantagem do mecanico: `tempo + qualidade`
- Instalacao propria:
  - `minigame leve + tempo de servico`
  - falha gera `perda de tempo + queda na qualidade final`
- Qualidade da instalacao afeta:
  - `durabilidade`
  - `performance`
  - `chance de falha`

### Pneus

Familias iniciais:

- `rua comum`
- `rua esportivo`
- `chuva`
- `drift`
- `off-road`
- `corrida`

Efeitos:

- `aderencia`
- `desgaste`
- `comportamento do carro`

### Motor e Drivetrain

- Motor: `pacotes por tier + pecas-chave`
- Pecas-chave:
  - `ECU`
  - `turbo/compressor`
  - `radiador`
  - `filtro`
  - `embreagem performance`
- Tracao:
  - `FWD`
  - `RWD`
  - `AWD`
- Conversao de tracao:
  - `ampla`
  - `cara, mas acessivel no mid game`

### Desgaste

Fontes:

- `uso`
- `colisao`
- `estilo de direcao`

Consequencias:

- `perda de performance`
- `risco de falha`
- `quebra/impedimento operacional`

### UX

- Estado do veiculo: `tablet + mecanica`
- Tablet mostra:
  - `condicao`
  - `alertas`
  - `pecas instaladas`
  - `recomendacoes`
  - `historico basico`

### Operacao e Estrutura

- Oficinas: `poucas e oficiais`
- Distribuicao comercial:
  - `autopecas` para pecas comuns
  - `oficinas premium` para pecas especiais
- Compatibilidade: `flexivel`
- Persistencia: `forte`
- Anti-exploit: `forte`
- Evolucao futura: `altamente configuravel`

## Abordagem Escolhida

### Recomendacao Aceita

Sistema modular persistente por veiculo, com oficinas como pontos de servico.

Cada veiculo tera um perfil mecanico persistente que guarda:

- pecas instaladas
- condicao dos subsistemas
- qualidade da instalacao
- desgaste acumulado
- risco de falha
- alertas
- historico basico

Essa abordagem foi escolhida porque:

- preserva profundidade sem exagerar o escopo
- encaixa bem no RP de oficina
- conversa com a economia aspiracional da cidade
- e facil de rebalancear por config
- permite evoluir por fases sem reescrever tudo

## Arquitetura Recomendada

### 1. Catalogo de Pecas

Camada dirigida por dados para definir:

- `key`
- `label`
- `category`
- `tier`
- `rarity`
- `shop_type`
- `price`
- `install_time_seconds`
- `self_install_allowed`
- `base_durability`
- `compatibility_group`
- `effect_profile`

Categorias iniciais:

- `tire`
- `engine_package`
- `ecu`
- `turbo`
- `supercharger`
- `radiator`
- `filter`
- `clutch`
- `brake_kit`
- `suspension_kit`
- `alignment_service`
- `drivetrain_conversion`

### 2. Perfil Mecanico do Veiculo

Cada veiculo persistido ganha um chassi mecanico com campos como:

- `vehicle_id`
- `citizenid`
- `overall_condition`
- `service_score`
- `odometer_km`
- `last_service_at`
- `next_service_recommendation`
- `alerts`

Subsistemas:

- `tires`
- `engine`
- `brakes`
- `drivetrain`
- `suspension`
- `alignment`

Cada subsistema guarda:

- `part_key`
- `condition`
- `installation_quality`
- `wear_rate_modifier`
- `failure_risk`
- `last_installed_at`
- `installed_by`
- `installed_by_role`

### 3. Motor de Desgaste

O motor de desgaste calcula deterioracao com base em:

- quilometragem
- carga/uso operacional
- alta rotacao
- freadas fortes
- derrapagem
- tracao inadequada
- tipo de pneu vs terreno
- impacto/colisao
- qualidade da peca
- qualidade da instalacao

### 4. Fluxo de Oficina

Fluxo base:

1. Jogador compra item fisico.
2. Leva o item para oficina oficial.
3. Seleciona o veiculo alvo.
4. O servidor valida:
   - item
   - local
   - compatibilidade
   - veiculo
   - tempo minimo
   - autoria
5. O servico roda com tempo e minigame.
6. O resultado final grava a peca e a qualidade.

### 5. Camada de UX

Tablet:

- visao de dono e gestor
- condicao
- alertas
- pecas
- recomendacoes
- historico

Oficina:

- tela de servico
- diagnostico
- pecas disponiveis
- tempo
- custo
- qualidade prevista

## Regras de Desgaste

### Pneus

Afetam:

- curva
- frenagem
- estabilidade
- derrapagem
- desgaste em terreno inadequado

### Motor

Afeta:

- potencia
- aquecimento
- confiabilidade
- chance de falha

### Freios

Afetam:

- resposta
- distancia de frenagem
- consistencia sob uso forte

### Drivetrain / Tracao

Afeta:

- saida
- transferencia de potencia
- comportamento em chuva/off-road
- chance de falha sob carga

### Suspensao

Afeta:

- estabilidade
- comportamento em terreno ruim
- controle em velocidade

### Alinhamento

Afeta:

- carro puxando para lado
- desgaste acelerado de pneus
- eficiencia geral da tocada

## Regras de Profissao

### Jogador Comum

- pode instalar o basico
- precisa item fisico
- precisa estar em oficina oficial
- usa minigame leve
- leva mais tempo
- tem qualidade menos consistente

### Mecanico

- instala mais rapido
- instala com melhor qualidade media
- reduz chance de servico ruim
- pode operar servicos premium com melhor eficiencia

## Lojas e Mercado

### Autopecas

Venda de:

- pneus comuns
- freios
- filtro
- oleo
- radiador

### Oficinas Premium

Venda/instalacao de:

- ECU
- turbo/compressor
- embreagem performance
- suspensao esportiva
- pneus drift/race premium
- conversao de tracao

## Performance, Persistencia e Seguranca

### Performance

Recomendacao:

- usar desgaste por `eventos + janelas de amostragem`
- focar em veiculos ativos e relevantes
- evitar loop pesado permanente em todos os carros do servidor

### Persistencia

Salvar:

- estado mecanico atual
- pecas instaladas
- condicao
- qualidade
- risco de falha
- km
- historico basico

Nao salvar no lancamento:

- telemetria infinita por evento de direcao

### Seguranca

Validacoes no servidor:

- compra
- posse do item
- veiculo alvo
- local
- compatibilidade
- tempo minimo
- autoria do servico

## Recommendation

O melhor caminho e implementar esse sistema em fases:

1. persistencia mecanica por veiculo
2. catalogo/config de pecas
3. autopecas e oficinas oficiais
4. fluxo de instalacao basica
5. desgaste por uso/impacto/conducao
6. diagnostico via tablet
7. servicos premium e conversao de tracao

