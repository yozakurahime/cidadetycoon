# Cidade Tycoon - Plano de Implementacao do Sistema de Manutencao

## Objetivo

Transformar o design do sistema de desgaste e manutencao em um plano de
implementacao incremental, seguro e facil de validar em servidor ativo.

## Estrategia

Implementar em camadas, com cada fase adicionando valor proprio e reduzindo
risco de regressao:

- primeiro persistencia e modelo de dados
- depois fluxo de oficina e itens
- depois desgaste e balanceamento
- por fim refinamentos premium e UX completa

## Fase 1 - Fundacao de Dados

### Entregas

- criar tabelas persistentes do perfil mecanico por veiculo
- criar tabela/catalogo de pecas
- criar tabela de historico basico de servicos
- definir estrutura configuravel de:
  - categorias
  - grupos de compatibilidade
  - durabilidade
  - efeitos

### Saida esperada

- cada veiculo passa a ter um estado mecanico consultavel no servidor
- nenhuma oficina ainda; foco em estrutura

### Validacao

- criar registro ao primeiro uso do veiculo
- recarregar estado apos reconnect/restart
- verificar associacao correta com `vehicle_id` e `citizenid`

## Fase 2 - Catalogo e Economia de Pecas

### Entregas

- cadastrar pecas comuns e premium iniciais
- mapear lojas:
  - autopecas
  - oficinas premium
- integrar compra de pecas como item fisico

### Escopo inicial recomendado

- pneus
- freios
- filtro
- oleo
- radiador
- ECU
- turbo/compressor
- embreagem performance
- suspensao esportiva
- conversao de tracao

### Validacao

- compra entrega item correto
- preco configuravel
- item correto visivel no inventario

## Fase 3 - Oficinas Oficiais e Fluxo de Servico

### Entregas

- definir oficinas oficiais no mapa
- criar zonas/boxes de servico
- selecionar veiculo alvo
- instalar/remover/servicar pecas
- validar:
  - local
  - item
  - compatibilidade
  - autoria
  - tempo minimo

### Regras

- jogador instala o basico
- mecanico instala melhor e mais rapido
- servico proprio usa minigame leve

### Validacao

- impedir servico fora da oficina
- impedir uso sem item
- impedir instalacao em veiculo invalido

## Fase 4 - Qualidade de Instalacao e Historico

### Entregas

- sistema de qualidade:
  - ruim
  - boa
  - premium
- autoria do servico:
  - self
  - mechanic
- historico basico por veiculo

### Validacao

- qualidade influencia dados persistidos
- historico registra:
  - quando
  - o que
  - em qual veiculo
  - por quem

## Fase 5 - Motor de Desgaste

### Entregas

- desgaste por uso
- desgaste por colisao
- desgaste por estilo de direcao
- desgaste por terreno/tipo de pneu

### Recomendacao tecnica

- usar eventos + amostragem periodica
- focar em veiculos ocupados/ativos
- evitar simulacao pesada universal

### Validacao

- pneus errados desgastam mais em uso inadequado
- colisao forte acelera dano
- direcao agressiva aumenta degradacao

## Fase 6 - Consequencias Reais

### Entregas

- perda de performance por subsistema
- aumento de risco de falha
- estado critico com quebra operacional
- manutencao preventiva e revisao recomendada

### Validacao

- pneu ruim altera aderencia
- freio ruim altera frenagem
- motor ruim afeta potencia/temperatura
- drivetrain ruim afeta saida/tracao

## Fase 7 - Tablet e Diagnostico

### Entregas

- visao de condicao geral
- visao por subsistema
- pecas instaladas
- alertas
- recomendacoes
- historico basico

### Validacao

- tablet reflete exatamente o estado salvo no servidor
- alertas aparecem antes de quebra total

## Fase 8 - Servicos Premium

### Entregas

- conversao FWD/RWD/AWD
- pneus drift/race premium
- kits de suspensao esportiva
- balanceamento fino de ECU/turbo/embreagem

### Validacao

- servicos premium exigem item, oficina e custo adequado
- mudancas alteram comportamento e desgaste

## Fase 9 - Balanceamento e Operacao

### Entregas

- calibrar curva de desgaste
- calibrar custo de manutencao
- calibrar diferenca entre self e mechanic
- calibrar impacto economico em:
  - novato
  - mid game
  - late game

### Validacao

- sistema pesa economicamente sem travar onboarding
- oficina vira gameplay, nao punicao gratuita

## Tabelas / Configs Recomendadas

### Persistencia

- `player_vehicle_mechanical_state`
- `player_vehicle_installed_parts`
- `player_vehicle_service_history`

### Config/lookup

- `vehicle_maintenance_parts`
- `vehicle_maintenance_shops`
- `vehicle_maintenance_compatibility_groups`
- `vehicle_maintenance_wear_profiles`

## Dependencias Provaveis

- `ox_inventory` para pecas fisicas
- `ox_target` para boxes/oficinas
- `ox_lib` para UI/contextos/minigames
- `qbx_vehicles` para vinculo com frota persistida
- `cidade_transport_tycoon_infinito` para tablet/economia
- opcionalmente `qbx_customs` apenas para parte visual

## Riscos

- excesso de granularidade no primeiro corte
- custo alto de simulacao se o desgaste for mal amostrado
- instalacao premium sem diferenca perceptivel matar o valor do mecanico
- economia quebrar se pecas comuns forem caras demais cedo
- conversao de tracao ficar forte demais e destruir identidade dos veiculos

## Ordem Recomendada de Execucao

1. Fase 1 - Fundacao de dados
2. Fase 2 - Catalogo e economia
3. Fase 3 - Oficinas e servico
4. Fase 4 - Qualidade e historico
5. Fase 5 - Motor de desgaste
6. Fase 7 - Tablet e diagnostico
7. Fase 6 - Consequencias reais
8. Fase 8 - Premium
9. Fase 9 - Balanceamento

## Criterios de Pronto para Implementar

- design validado
- modelo de dados aceito
- lojas e oficinas definidas
- lista inicial de pecas aprovada
- regras de desgaste aceitas
- requisitos de persistencia e seguranca claros

