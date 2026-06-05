# cidade_tycoon_core

Core minimo compartilhado entre os modulos da Cidade Tycoon.

## Escopo

- helpers de framework
- helpers de dinheiro
- normalizacao de placa
- constantes de resources
- logger simples

## Nao entra aqui

- regra de negocio de freela
- regra de negocio de manutencao
- regra de negocio de concessionaria
- UIs

## Exports publicos

### Server

- `GetFrameworkPlayer(source)`
- `GetCitizenId(player)`
- `GetMoneyBalance(player, account)`
- `RemoveMoney(player, account, amount, reason)`
- `GetPreferredPaymentAccount(player, amount)`
- `IsResourceReady(resourceName)`

### Client

- `NormalizePlate(plate)`
