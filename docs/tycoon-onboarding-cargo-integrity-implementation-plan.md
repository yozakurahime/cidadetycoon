# Cidade Tycoon - Plano de Implementacao do Onboarding e Integridade da Carga

## Objetivo

Implementar o tutorial de boas-vindas no tablet e consolidar a integridade da
carga em etapas pequenas, sem quebrar o fluxo atual de garagem, tablet e freela.

## Estrategia Geral

Implementar em `4 fases`:

1. persistencia do tutorial
2. UX do tablet
3. contrato tutorial
4. refinamento da integridade e resultado final

## Fase 1 - Persistencia do tutorial

### Meta

Criar a base de estado do onboarding pedagogico.

### Entregas

- nova tabela de progresso do tutorial por `citizenid`
- helpers de servidor para:
  - iniciar tutorial
  - avancar passo
  - retomar estado
  - concluir tutorial
- reaproveitar o onboarding tecnico atual de `tablet + cruiser`

### Arquivos-alvo

- `resources/[standalone]/cidade_transport_tycoon_infinito/company_freelance_server.lua`

## Fase 2 - UX do tablet

### Meta

Exibir o tutorial guiado e o progresso do novato no tablet.

### Entregas

- payload do tablet com estado do tutorial
- tela/cartao de onboarding no NUI
- checklist de passos
- mensagens curtas por passo
- versao resumida do guia apos conclusao

### Arquivos-alvo

- `resources/[standalone]/cidade_transport_tycoon_infinito/company_freelance_server.lua`
- `resources/[standalone]/cidade_transport_tycoon_infinito/company_freelance_client.lua`
- `resources/[standalone]/cidade_transport_tycoon_infinito/ui/app.js`
- `resources/[standalone]/cidade_transport_tycoon_infinito/ui/index.html`
- `resources/[standalone]/cidade_transport_tycoon_infinito/ui/style.css`

## Fase 3 - Contrato tutorial

### Meta

Criar a primeira entrega guiada usando o loop real do freela.

### Entregas

- definicao de um contrato tutorial curto
- validacao de retirada da `cruiser`
- validacao de ida ao hub inicial
- aceite controlado do contrato tutorial
- conclusao com bonus pequeno e XP/rep iniciais
- bloqueio ou ocultacao de contratos normais enquanto o tutorial estiver ativo

### Arquivos-alvo

- `resources/[standalone]/cidade_transport_tycoon_infinito/company_freelance_server.lua`
- `resources/[standalone]/cidade_transport_tycoon_infinito/company_freelance_client.lua`
- possivelmente `resources/[standalone]/cidade_transport_tycoon_infinito/config/shared.lua`

## Fase 4 - Integridade da carga

### Meta

Refinar o sistema atual de `cargoHealth` para ficar mais legivel e justo.

### Entregas

- ajustar calculo de dano por impacto considerando:
  - perda de `body health`
  - perda de `engine health`
  - velocidade no momento do impacto
- reduzir punicao de encostoes leves
- manter falha apenas em `0%`
- aplicar perda de pagamento e XP conforme integridade final
- exibir resumo final de danos ao concluir a entrega

### Arquivos-alvo

- `resources/[standalone]/cidade_transport_tycoon_infinito/company_freelance_client.lua`
- `resources/[standalone]/cidade_transport_tycoon_infinito/company_freelance_server.lua`
- `resources/[standalone]/cidade_transport_tycoon_infinito/ui/app.js` se o resumo final for mostrado na NUI

## Ordem Recomendada

1. Persistencia do tutorial
2. Payload e tela no tablet
3. Contrato tutorial funcional
4. Refinamento da integridade
5. Ajuste de recompensas e resumo final

## Riscos Conhecidos

- misturar onboarding tecnico com onboarding pedagogico na mesma tabela
- deixar contratos normais escaparem antes da conclusao do tutorial
- criar feedback demais no tablet e cansar o jogador
- punir impactos leves em excesso e deixar a direcao frustrante

## Validacao Manual Recomendada

1. Criar personagem novo.
2. Confirmar recebimento de `tablet` e `cruiser`.
3. Confirmar abertura automatica do tutorial no tablet.
4. Sair no meio e reconectar; confirmar retomada do passo certo.
5. Retirar a bike e concluir o contrato tutorial.
6. Confirmar bonus final, XP/rep e liberacao do modo normal.
7. Testar colisao leve, media e forte durante a missao.
8. Confirmar reducao de pagamento/XP e falha apenas em `0%`.

