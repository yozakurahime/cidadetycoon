# Cidade Tycoon World Builder

Editor persistente de props para montar hubs, lojas e decoracoes usando modelos nativos do GTA V. O servidor valida todas as mutacoes, sincroniza os clientes incrementalmente e mantem backup do ultimo arquivo valido.

## Comandos

- `/buildmenu` abre o menu principal do editor.
- `/prop prop_toolchest_01` inicia a colocacao direta de um modelo.
- `/editprop` edita o prop salvo mais proximo.
- `/hideprop` oculta o objeto original do mapa que estiver na mira.
- `/moveentity` move a prop, NPC ou veiculo vazio que estiver na mira.
- `/entitiesmenu` gerencia entidades de outros scripts que foram reposicionadas.
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

Antes de cada gravacao, o arquivo valido atual e copiado para `data/world.json.bkp`. Se o arquivo principal estiver corrompido durante a inicializacao, o resource restaura automaticamente o backup.

`props` guarda os objetos criados pelo editor. `removals` guarda objetos vanilla do mapa que devem ser deletados localmente quando o jogador chega perto. `externalEntities` guarda reposicionamentos de props, NPCs ou veiculos vazios criados por outros scripts.

## Editar entidades de outros scripts

Use `/moveentity` ou a opcao `Mover prop/NPC existente na mira` dentro de `/buildmenu`.

O editor salva:

- tipo da entidade: `object`, `ped` ou `vehicle`;
- modelo/hash;
- coordenada original;
- nova coordenada;
- raio usado para reencontrar essa entidade quando ela nascer de novo.

Quando o jogador chega perto, o resource procura uma entidade com o mesmo modelo perto da coordenada original ou da coordenada salva e aplica a nova posicao/rotacao.

## Permissao

O servidor valida exclusivamente a ACE configurada em `shared/config.lua`:

```txt
cidade_tycoon.worldbuilder
```

Por padrao, `group.admin` e `group.god` ja receberam essa permissao em `permissions.cfg`.

## Observacoes

Esse resource nao cria MLO real. Ele funciona como um modo construcao: coloca props no mundo, edita posicao/rotacao, move props/NPCs de outros scripts, remove props salvos e esconde props existentes do mapa por modelo/coordenada/raio.

Se outro script ficar recriando a mesma entidade continuamente ou forcar a posicao dela em loop, pode haver disputa. Para NPCs e props comuns com `ox_target` anexado na entidade, o alvo costuma acompanhar porque a entidade real e movida.
