# cidade_tycoon_freelance

Modulo de freela, contratos e tutorial operacional da Cidade Tycoon.

## Escopo atual

- namespace proprio para callbacks e exports do freela
- cancelamento operacional
- tutorial operacional
- dashboard de motorista
- inicio de freela e freight actions pelo namespace novo
- conclusao e falha de missao pelo namespace novo
- ponte temporaria para a implementacao legada no monolito

## Pendente nesta fase

- contratos corporativos ainda nao possuem backend migrado; o modulo responde com erro explicito para esse fluxo

## Objetivo desta fase

Separar a superficie publica do freela do `cidade_transport_tycoon_infinito` sem mover ainda toda a logica de missao e HUD.
