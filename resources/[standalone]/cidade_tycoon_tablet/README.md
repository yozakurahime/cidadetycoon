# cidade_tycoon_tablet

Gateway do jogador para a Cidade Tycoon.

## Escopo atual

- abertura e fechamento do tablet
- NUI do tablet
- onboarding inicial
- atalhos de rota e garagem
- integracao temporaria com callbacks legados do monolito

## Dependencias temporarias

Nesta fase o resource ainda consome exports, callbacks e eventos do monolito legado:

- exports do `cidade_transport_tycoon_infinito` para dashboard, tutorial e cancelamento
- leaderboards ainda lidas por callbacks legadas
- contratos financeiros e aluguel ainda permanecem no namespace legado

## Objetivo da fase

Extrair a UI e o fluxo de abertura do tablet sem mover ainda a logica de negocio do freela.
