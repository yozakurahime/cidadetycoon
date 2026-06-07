# Cidade Tycoon - Onboarding e Integridade da Carga

## Objetivo

Definir um fluxo de boas-vindas para novatos dentro do tablet e consolidar a
regra de integridade da carga das missões, mantendo o onboarding leve,
persistente e alinhado ao loop real do tycoon.

## Understanding Summary

- O tutorial de boas-vindas vai abrir no `tablet` automaticamente na primeira entrada.
- O onboarding sera `guiado por acoes reais`, e nao apenas por texto.
- O fluxo validado e: `tablet -> garagem -> pegar bike -> ir ao hub -> aceitar contrato -> fazer 1 entrega curta`.
- O tom do tutorial sera `misto`: claro, rapido e com identidade da Cidade Tycoon.
- O progresso do novato precisa ser `persistente` e retomar automaticamente do passo certo.
- O jogador ficara `semi-livre`, com a cidade guiando e priorizando o proximo objetivo sem travar tudo de forma dura.
- Ao concluir, o jogador libera o modo normal, recebe `bonus pequeno + XP/rep inicial` e ganha acesso a um guia resumido no tablet.
- A integridade sera da `carga da missao inteira`, com dano por impacto e consequencias em pagamento, XP e falha somente em `0%`.

## Premissas

- O onboarding tecnico atual de `tablet + bicicleta inicial` continuara existindo.
- O recurso `cidade_transport_tycoon_infinito` continuara sendo o orquestrador do onboarding.
- O tablet/NUI atual sera reaproveitado em vez de criar uma interface paralela.
- O contrato tutorial sera uma variacao curta do fluxo real de freela terrestre.
- O sistema atual de `cargoHealth` ja existente em `company_freelance_client.lua` sera a base da nova regra de integridade.

## Assumptions

- O tutorial inicial usara a `cruiser` inicial e uma rota terrestre curta.
- Contratos normais podem ficar ocultos ou bloqueados enquanto o tutorial nao for concluido.
- O guia resumido continuara disponivel no tablet apos a conclusao.
- O bonus final sera pequeno o suficiente para orientar, nao para desequilibrar a economia.
- O sistema precisa funcionar bem com `40-48` jogadores simultaneos sem criar loops pesados adicionais.

## Open Questions

- O valor exato do bonus final ainda nao foi definido.
- O valor exato de XP/rep inicial ainda nao foi definido.
- O contrato tutorial ainda nao tem hub, rota e quantidade final de caixas escolhidos.

## Abordagens Consideradas

### Opcao 1 - Recomendada: onboarding embutido no tycoon

Transformar o onboarding em um subsistema do proprio
`cidade_transport_tycoon_infinito`, reaproveitando:

- onboarding tecnico
- tablet
- garagens
- contratos
- missoes freela

**Vantagens**

- menos duplicacao
- mais facil de manter
- validacao de progresso no servidor
- integracao natural com a integridade da carga

**Riscos**

- exige cuidado para nao misturar onboarding tecnico com onboarding pedagogico

### Opcao 2 - Script separado so para tutorial

Criar um recurso novo apenas para o tutorial.

**Vantagens**

- isolamento maior

**Desvantagens**

- duplicacao de fluxo
- manutencao mais cara
- maior risco de ficar fora de sincronia com o tycoon

### Opcao 3 - Tutorial quase todo no cliente

Resolver onboarding com foco no cliente/NUI.

**Desvantagens**

- persistencia mais fraca
- validacao mais fraca
- confiabilidade pior

## Opcao Escolhida

`Opcao 1`: onboarding embutido no `cidade_transport_tycoon_infinito`.

## Design Final

### 1. Estrutura do tutorial

O onboarding guiado tera `6 passos`:

1. `Boas-vindas no tablet`
2. `Ir ate a garagem`
3. `Retirar a bike inicial`
4. `Ir ao hub logistico`
5. `Aceitar contrato tutorial`
6. `Completar a primeira entrega`

Cada passo deve:

- ter objetivo claro
- mostrar por que aquilo importa
- marcar progresso visualmente
- persistir no servidor

### 2. Persistencia

O progresso do tutorial deve viver em uma tabela propria, separada da tabela
tecnica de onboarding.

Campos sugeridos:

- `citizenid`
- `tutorial_started_at`
- `current_step`
- `tutorial_completed_at`
- `assigned_garage`
- `assigned_hub`
- `tutorial_contract_id`
- `summary_unlocked`

Separacao de responsabilidade:

- `player_tycoon_onboarding`: entrega tecnica de `tablet + bicicleta`
- nova tabela do tutorial: progresso pedagogico do novato

### 3. Retomada

No login:

- se nunca iniciou, abre o tutorial no tablet
- se iniciou e nao concluiu, retoma o passo salvo
- se ja concluiu, nao abre automaticamente

### 4. Semi-liberdade

Enquanto o onboarding estiver ativo:

- o jogador pode circular normalmente
- o tablet e as notificacoes continuam empurrando o proximo objetivo
- a cidade pode esconder ou bloquear contratos normais para evitar dispersao

### 5. Contrato tutorial

O contrato tutorial sera uma variante curta do freela terrestre real.

Caracteristicas:

- usa a `cruiser` inicial
- rota curta
- poucas caixas
- `1` parada, ou no maximo `2`
- recompensa pequena
- XP/rep pequenos
- mensagens didaticas em cada etapa

Ensino explicito no contrato:

- colisao reduz integridade
- integridade baixa reduz resultado
- `0%` falha a missao

### 6. Integridade da carga

O sistema usara a `integridade da carga da missao inteira`.

Regras:

- pequenos toques quase nao punem
- impactos medios tiram parte visivel da integridade
- pancadas fortes tiram muito mais
- pagamento e XP caem junto com a integridade
- a missao so falha em `0%`

Faixas operacionais sugeridas:

- `100-70%`: entrega boa
- `69-30%`: entrega danificada
- `29-1%`: entrega critica
- `0%`: falha

### 7. Feedback ao jogador

Durante o tutorial e nas missoes:

- mostrar integridade atual em `%`
- avisar quando houver dano relevante
- explicar no final quanto foi perdido por dano

### 8. Guia resumido apos conclusao

Depois de concluir o tutorial, o tablet mantera um `Guia do Iniciante`
resumido com:

- retirar veiculo
- aceitar contrato
- proteger a carga
- melhorar a frota
- usar garagem e tablet

## Non-Functional Requirements

- **Performance:** reaproveitar loops de missao existentes; evitar novos loops pesados globais.
- **Escala:** precisa funcionar bem com `40-48` jogadores simultaneos.
- **Seguranca:** progresso, desbloqueios e conclusao precisam ser validados no servidor.
- **Confiabilidade:** logout/reconnect nao pode perder o passo atual.
- **Manutencao:** onboarding e integridade devem viver dentro do tycoon, sem recurso paralelo desnecessario.

## Decision Log

| Decisao | Alternativas consideradas | Resolucao |
| --- | --- | --- |
| Local do tutorial | tela separada, NPC, tablet | `tablet` |
| Estilo do tutorial | texto, checklist, guiado | `guiado por acoes reais` |
| Fluxo inicial | varios fluxos de onboarding | `tablet -> garagem -> bike -> hub -> contrato -> entrega` |
| Tom | funcional, imersivo, misto | `misto` |
| Persistencia | reiniciar, retomada parcial, retomada total | `retomar do passo salvo` |
| Liberdade do jogador | travado, semi-livre, livre | `semi-livre` |
| Pos-tutorial | sem recompensa, dinheiro, dinheiro+xp | `bonus pequeno + XP/rep` |
| Consulta posterior | nao manter, manter completa, manter resumida | `versao resumida no tablet` |
| Modelo de integridade | por missao, por caixa, misto | `por missao inteira` |
| Fonte de dano | forca, velocidade, ambos | `ambos` |
| Efeito do dano | so dinheiro, dinheiro+xp, dinheiro+xp+falha | `dinheiro + XP + falha em 0%` |
| Abordagem tecnica | embutido no tycoon, script separado, cliente | `embutido no tycoon` |

