# Cidade Tycoon - Resumo da Matriz Inicial de Balanceamento

## Escopo

- Catalogo base Qbox observado: `901` veiculos.
- Pack `carros_reais` observado: `164` veiculos nomeados.
- Matriz inicial gerada a partir do catalogo atual do tycoon: `167` veiculos.
- Arquivo fonte: [tycoon-vehicle-balance-matrix.csv](./tycoon-vehicle-balance-matrix.csv)

## Contagem por secao atual do catalogo

- `civilian_import`: `40`
- `hypercars_import`: `16`
- `race`: `8`
- `sports_import`: `30`
- `supercars_import`: `26`
- `suv_offroad`: `35`
- `transport_air`: `4`
- `transport_land`: `4`
- `transport_water`: `4`

## Contagem por camada economica proposta

- `core_work`: `63`
- `premium_functional`: `22`
- `status_hyper`: `16`
- `status_light`: `40`
- `status_super`: `26`

## Contagem por tier proposto

- `a1`: `1`
- `a2`: `1`
- `a3`: `1`
- `a5`: `1`
- `hx`: `16`
- `pf2`: `10`
- `pf3`: `12`
- `s0`: `2`
- `s1`: `8`
- `s2`: `22`
- `s3`: `8`
- `ss`: `26`
- `t1`: `38`
- `t2`: `12`
- `t3`: `2`
- `t4`: `1`
- `t5`: `2`
- `w1`: `1`
- `w2`: `1`
- `w3`: `1`
- `w5`: `1`

## Heuristicas usadas nesta primeira passada

- `transport_land`, `transport_water` e `transport_air` foram tratados como `core_work`.
- `civilian_import` foi tratado majoritariamente como base de `carro popular de entrega` (`t1`, 4 pacotes), com motos marcadas para revisao.
- `suv_offroad` foi dividido entre `core_work` utilitario e `premium_functional`.
- `sports_import` e `race` viraram `status_light` com faixa de `3 a 6` pacotes.
- `supercars_import` e `hypercars_import` foram limitados a carga simbolica.

## Proximas decisoes necessarias

- Revisar manualmente quais modelos de `civilian_import` realmente entram como carro popular de entrega.
- Confirmar quais SUVs/pickups serao `core_work` e quais ficam so em `premium_functional`.
- Fixar tabela de seguro, manutencao, aluguel e financiamento por classe.
- Traduzir a matriz para os arquivos de configuracao do tycoon.

## Observacao

- Esta matriz e uma primeira proposta operacional para sair do balanceamento generico. Ela ainda precisa de curadoria manual antes de virar configuracao final da cidade.
