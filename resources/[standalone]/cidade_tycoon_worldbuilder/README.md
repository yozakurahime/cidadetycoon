# Cidade Tycoon World Builder

Editor persistente de props para montar hubs, lojas e decoracoes usando modelos nativos do GTA V.

## Comandos

- `/buildmenu` abre o menu principal do editor.
- `/prop prop_toolchest_01` inicia a colocacao direta de um modelo.
- `/editprop` edita o prop salvo mais proximo.
- `/hideprop` oculta o objeto original do mapa que estiver na mira.
- `/wb_reload` recarrega o arquivo salvo e sincroniza todos os jogadores.

## Controles no modo de colocacao

- Setas cima/baixo: distancia.
- Setas esquerda/direita: rotacao.
- PageUp/PageDown: altura.
- G: alterna grudar no chao.
- Enter: salva.
- Backspace: cancela.

## Persistencia

Tudo fica salvo em:

```txt
data/world.json
```

`props` guarda os objetos criados pelo editor. `removals` guarda objetos vanilla do mapa que devem ser deletados localmente quando o jogador chega perto.

## Permissao

O servidor valida a ACE:

```txt
cidade_tycoon.worldbuilder
```

Por padrao, `group.admin` e `group.god` ja receberam essa permissao em `permissions.cfg`.

## Observacoes

Esse resource nao cria MLO real. Ele funciona como um modo construcao: coloca props no mundo, edita posicao/rotacao, remove props salvos e esconde props existentes do mapa por modelo/coordenada/raio.
