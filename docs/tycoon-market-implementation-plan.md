# Cidade Tycoon - Plano de Implementação do Mercado e Garagens

## Objetivo

Transformar o design validado de mercado, frota e garagens em uma implementação
segura, incremental e auditável, priorizando o que mais impacta a cidade no lançamento.

## Estratégia Geral

Implementar em camadas:

1. dados
2. regras econômicas
3. operação/logística
4. UX e manutenção

Isso evita rebalanceamento no escuro e reduz regressões no tycoon.

## Fase 1 - Matriz de Veículos

### Meta

Criar a fonte única de verdade para balanceamento.

### Entregas

- arquivo de matriz em `docs/` ou `config/` com colunas:
  - `model`
  - `label`
  - `source` (`vanilla` ou `carros_reais`)
  - `market_layer`
  - `transport_branch`
  - `tier`
  - `price`
  - `package_capacity`
  - `insurance_class`
  - `maintenance_class`
  - `rental_enabled`
  - `financing_enabled`
  - `garage_type`
- classificação inicial dos veículos do catálogo atual
- shortlist dos 35+ veículos-chave de trabalho para o lançamento

### Prioridade

Altíssima. Sem isso, todo balanceamento seguinte vira remendo.

## Fase 2 - Reclassificação do Catálogo

### Meta

Separar claramente o que é trabalho, premium funcional e status.

### Entregas

- reclassificar `cityConfig.vehicleCatalog`
- expandir a linha de terra:
  - carro popular de entrega
  - utilitários leves
  - utilitários premium
  - vans
  - médios
  - pesados
- manter água e ar como ramos bloqueados por licença futura
- introduzir capacidade leve nos esportivos e premium
- limitar super/hyper a `1–2`

### Resultado Esperado

Catálogo grande, mas meta econômico legível.

## Fase 3 - Economia de Aquisição

### Meta

Implementar os três caminhos aprovados para frota de trabalho.

### Entregas

- compra à vista
- financiamento:
  - entrada
  - parcelas
  - trava por inadimplência
- aluguel operacional:
  - custo por período ou por uso
  - margem pior que compra própria

### Regras

- aluguel serve como ferramenta anti-travamento
- financiamento serve como ponte de tier
- compra à vista continua sendo o melhor custo total

## Fase 4 - Operação de Garagem

### Meta

Estabilizar o uso da frota no mapa com 40–48 jogadores.

### Entregas

- manter múltiplos pontos públicos terrestres
- reforçar `1 veículo ativo de trabalho por jogador`
- spawn sem warp
- fallback de vagas próximas
- recuperação de veículos `OUT` quando não estiverem no mapa
- tablet com retirada remota respeitando:
  - espaço livre
  - veículo ativo único
  - cooldown curto

### Regras

- terra: público total
- água: marinas
- ar: aeroportos/heliportos

## Fase 5 - Pressão Econômica

### Meta

Dar peso à posse do veículo sem depender de sistema completo de mecânica.

### Entregas

- classes de seguro por camada
- custo de recuperação por camada
- desgaste por uso/entrega
- campo de condição operacional do veículo ou equivalente lógico

### Regras

- trabalho degrada devagar
- premium funcional degrada mais
- super/hyper são economicamente ruins para trabalhar

## Fase 6 - UX e Clareza

### Meta

Fazer o jogador entender o sistema sem precisar decorar planilha.

### Entregas

- tablet mostrar:
  - capacidade
  - camada do veículo
  - estado
  - condição
  - seguro
  - parcela/aluguel quando existir
- concessionária mostrar:
  - categoria econômica
  - pacotes
  - tier
  - uso recomendado
- mensagens claras para:
  - ativo único
  - falta de espaço
  - recuperação
  - veículo fora

## Sequência Recomendada de Execução

1. Criar a matriz de veículos
2. Reclassificar o catálogo atual
3. Ajustar capacidades
4. Ajustar preços
5. Implementar aquisição (`compra`, `financiamento`, `aluguel`)
6. Integrar pressão econômica (`seguro`, `desgaste`, `recuperação`)
7. Refinar tablet e concessionária

## Critérios de Pronto para Lançamento

- catálogo de trabalho com 35+ veículos-chave balanceados
- importados e esportivos com papel econômico claro
- super/hyper limitados a função simbólica no transporte
- 1 veículo ativo de trabalho por jogador funcionando
- retirada via tablet e garagem estável
- custo operacional já influenciando decisão do jogador
- onboarding terrestre legível e recompensador

## Próxima Sessão Recomendada

Próxima implementação deve focar exclusivamente em:

1. gerar a matriz inicial dos veículos do catálogo atual
2. definir `package_capacity` e `market_layer`
3. propor novos `tiers` e faixas de preço

Esse recorte é o melhor ponto de entrada porque destrava todo o resto sem mexer
em UI, banco e fluxo operacional ao mesmo tempo.
