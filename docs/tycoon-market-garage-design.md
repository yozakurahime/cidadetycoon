# Cidade Tycoon - Mercado, Frota e Garagens

## Objetivo

Definir a economia de veículos, progressão logística e comportamento das garagens
para o lançamento da Cidade Tycoon com foco em operação aspiracional, onboarding
forte e fluxo estável para 40 a 48 jogadores simultâneos.

## Understanding Summary

- A economia da cidade será `aspiracional`: progressão mais lenta e objetivos de médio/longo prazo.
- O jogador começa obrigatoriamente no ramo `terra`.
- A progressão principal do ramo terra será `bike -> carro popular de entrega -> utilitário leve -> caminhão`.
- Importados e esportivos não serão a espinha dorsal da economia, mas participarão como `carga leve premium`.
- Veículos `super` e `hyper` poderão carregar apenas `1 a 2` pacotes, mais por RP do que por eficiência.
- Garagens terrestres funcionarão como rede pública multi-ponto.
- O tablet poderá retirar veículo em qualquer lugar com espaço disponível.
- Cada jogador terá `1 veículo ativo de trabalho`.
- Aquisição de frota de trabalho terá `compra à vista`, `financiamento` e `aluguel operacional`.
- Haverá `manutenção por uso`, com sistema mais completo de mecânicas em etapa futura.

## Premissas

- O catálogo base atual contém `901` veículos no `qbx_core/shared/vehicles.lua`.
- O pack `carros_reais` contém `164` veículos nomeados.
- O recurso `cidade_transport_tycoon_infinito` já possui catálogo dividido entre:
  - frota de transporte (`terra`, `água`, `ar`)
  - carros de corrida
  - importados comuns
  - SUVs/pickups
  - esportivos
  - superesportivos
  - hiperesportivos
- O sistema de garagem já suporta múltiplos pontos públicos para terra.
- O pack `carros_reais` precisa estar ativo no boot para que os addons realmente spawnen.

## Estado Atual Observado

### Catálogo de Transporte

Hoje a parte econômica de transporte ainda está curta:

- `terra`: `bison`, `mule`, `pounder`, `barracks`
- `água`: `dinghy`, `marquis`, `tug`, `suntrap`
- `ar`: `maverick`, `frogger`, `swift`, `cargobob`

Em contrapartida, o mercado pessoal/status já é muito maior e usa boa parte do
`carros_reais`.

### Capacidades já configuradas

Capacidades hoje definidas em `config/shared.lua`:

- `cruiser`, `bmx`, `tribike`, `scorcher`: `1`
- `bison`: `3`
- `mule`: `5`
- `pounder`: `10`
- `barracks`: `12`
- pickups/SUVs selecionadas: `2 a 4`
- água: `2 a 12`
- ar: `2 a 8`

Fora dessas entradas, o fallback atual ainda é genérico e precisa ser substituído
por curadoria mais fina.

## Decisões Confirmadas

### Economia

- Economia do lançamento: `aspiracional`
- Importados/esportivos: `status com função leve`
- Início obrigatório: `terra`
- Expansão posterior: `licenças` para `água` e `ar`

### Progressão de Terra

Escada econômica aprovada:

- `bike`: `1`
- `carro popular de entrega`: `4`
- `utilitário leve`: `6 a 8`
- `utilitário premium / van forte`: `8 a 10`
- `caminhão médio`: `12`
- `pesado`: `16 a 20`

### Camada Status

- esportivos, sedãs esportivos e SUVs premium: `3 a 6`
- super e hyper: `1 a 2`

Regras:

- status nunca deve vencer a frota profissional em `custo por pacote`
- frota de trabalho continua sendo a melhor ferramenta econômica
- carros de status continuam úteis para RP, estilo e mobilidade

### Garagens

- múltiplos pontos públicos de garagem terrestre
- retirada presencial via NPC e retirada remota via tablet
- tablet pode retirar em qualquer lugar com espaço
- recuperação de veículos `OUT` quando não estiverem mais no mapa
- `1 veículo ativo de trabalho por jogador`
- spawn sempre sem warp

### Aquisição e Pressão Econômica

- compra à vista
- financiamento
- aluguel operacional
- manutenção por uso
- seguro e custos de recuperação no lançamento
- sistema mais profundo de mecânicas em fase posterior

## Arquitetura de Mercado Recomendada

### Camada 1 - Frota de Trabalho

Veículos cujo objetivo principal é produzir receita:

- bike
- carro popular de entrega
- pickups utilitárias
- vans
- caminhões médios
- pesados
- água
- ar

Essa camada deve sempre ser a melhor em:

- custo por pacote
- retorno por entrega
- resiliência operacional

### Camada 2 - Premium Funcional

Veículos bonitos que ainda podem participar do transporte leve:

- SUVs premium
- wagons
- sedãs fortes
- pickups lifestyle

Essa camada existe para:

- criar variedade por tier
- valorizar o pack `carros_reais`
- oferecer fantasia de “empresa de luxo”

Sem atropelar os utilitários profissionais.

### Camada 3 - Prestígio

Veículos de status puro ou quase puro:

- esportivos fortes
- superesportivos
- hiperesportivos

Função:

- coleção
- roleplay
- imagem da empresa
- deslocamento pessoal

## Curva de Preço Recomendada

### Trabalho

- `bike`: inicial/grátis
- `tier 1`: `18k–45k`
- `tier 2`: `55k–110k`
- `tier 3`: `110k–220k`
- `tier 4`: `220k–420k`
- `tier 5`: `450k–900k`

### Premium Funcional

- faixa sugerida: `45k–300k`
- sempre com custo operacional pior que frota profissional equivalente

### Super e Hyper

- `900k–5M+`
- preço majoritariamente orientado a prestígio

## Regras Operacionais Recomendadas

- Um único veículo ativo de trabalho por jogador
- Tablet pode retirar em qualquer lugar com espaço livre
- Garagens físicas continuam úteis para guarda, RP e organização do mapa
- Veículos de trabalho podem operar pela malha pública terrestre
- Água só em marinas
- Ar só em aeroportos/heliportos
- Spawn deve buscar vagas alternativas próximas antes de falhar

## Não-Objetivos do Lançamento

- Balancear os 1065 veículos (`901 + 164`) um por um manualmente em uma única passada
- Criar sistema completo de oficina/mecânica já no dia 1
- Dar função logística pesada a super e hyper
- Exigir realismo rígido de garagem por ponto para veículos terrestres

## Riscos

- Se muitos importados ganharem capacidade alta demais, o meta de trabalho se dissolve.
- Se o aluguel for barato demais, a compra perde relevância.
- Se o financiamento for leve demais, o crescimento aspiracional desaparece.
- Se o tablet não respeitar espaço livre e ativo único, a cidade vira caos operacional em horário cheio.

## Recommendation

O melhor caminho para iniciar a implementação é transformar o catálogo atual em
uma `matriz de balanceamento` e, a partir dela, reclassificar veículos em:

- `work`
- `premium_functional`
- `status_light`
- `status_super_hyper`

Essa matriz deve virar a fonte de verdade para:

- preço
- pacotes
- tier
- ramo
- seguro
- aluguel
- financiamento
- regras de garagem
