# cidade_tycoon_compat

Camada temporaria de compatibilidade para a modularizacao do Cidade Tycoon.

## Objetivo

Reexpor eventos, callbacks e exports antigos enquanto os modulos novos sao extraidos por fase.

## Estado atual

Nesta fase o resource sobe como esqueleto, sem aliases ativos ainda.

## Regra

Nenhum alias deve virar permanente. Cada entrada aqui precisa ser removida quando os consumidores forem migrados.
