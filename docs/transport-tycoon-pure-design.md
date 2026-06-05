# Transport Tycoon Puro - Design Validado

## Objetivo

Transformar a base Qbox em um servidor FiveM focado em transport tycoon puro.
O servidor deixa de iniciar automaticamente pacotes inteiros de resources herdados
de RP e passa a carregar apenas o nucleo necessario para progressao logistica.

## Understanding Summary

- `cidade_hud` sera o unico HUD visual do servidor.
- `qbx_hud` deixara de iniciar, mas integracoes oficiais Qbox serao preservadas.
- O jogador cria o personagem e recebe acesso imediato aos contratos pelo tablet.
- Cada personagem recebe uma unica bicicleta `cruiser` persistente na primeira entrada.
- Fome, sede e stress continuam ativos como pressao operacional.
- O servidor deve suportar mais de 100 jogadores com atualizacoes leves e previsiveis.
- Scripts tradicionais de RP serao desativados primeiro e apagados somente depois da validacao.

## Premissas

- `qbx_core`, `ox_lib`, `oxmysql`, `ox_inventory`, `ox_target`, `qbx_vehicles`,
  `qbx_garages`, `ox_fuel`, `qbx_seatbelt`, voz, aparencia e spawn permanecem.
- Telefone e corridas sao opcionais e nao podem impedir o nucleo de iniciar.
- A manutencao sera feita por uma pessoa com apoio pontual.
- A primeira fase deve ser reversivel: alterar inicializacao, nao apagar diretorios.

## Arquitetura

### Inicializacao Explicita

Remover `ensure [qbx]` e `ensure [standalone]` do `server.cfg`. Substituir por uma
lista explicita de resources mantidos. Isso impede a ativacao acidental de sistemas
de RP ao adicionar novos diretorios.

Nucleo:

- Infraestrutura: `oxmysql`, `ox_lib`, `qbx_core`, `ox_inventory`, `ox_target`.
- Jornada: `qbx_spawn`, `illenium-appearance`.
- Economia: `Renewed-Banking`.
- Transporte: `qbx_vehicles`, `qbx_garages`, `ox_fuel`, `qbx_vehiclekeys`,
  `qbx_seatbelt`.
- Interface: `cidade_hud`, `pma-voice`, `cidade_transport_tycoon_infinito`.
- Suporte: loadscreen, clima e dependencias comprovadamente necessarias.

Desativar inicialmente: `qbx_hud`, policia, hospital, crimes, drogas,
propriedades, empregos comuns e scripts auxiliares de RP sem dependencia do nucleo.

### HUD Unico

`cidade_hud` mantem seu NUI. O cliente Lua deve:

- Ler fome, sede e stress por statebags Qbox.
- Ler vida, colete, stamina e diagnosticos locais do veiculo.
- Ler voz e radio do `pma-voice`.
- Ler cinto exclusivamente de `LocalPlayer.state.seatbelt`.
- Remover a implementacao paralela de cinto existente no HUD.
- Exibir uma barra de stress junto a fome e sede.
- Enviar mensagens NUI somente quando valores relevantes mudarem.
- Usar cadencias separadas para status lentos, veiculo e voz.

### Onboarding Idempotente

No carregamento do personagem, o servidor deve:

1. Garantir exatamente um tablet no inventario.
2. Consultar uma marca persistente de onboarding por `citizenid`.
3. Criar uma unica `cruiser` via `qbx_vehicles:CreatePlayerVehicle` quando necessario.
4. Salvar a bicicleta em uma garagem publica padrao.
5. Marcar o onboarding somente apos a criacao bem-sucedida.
6. Tentar novamente no proximo login caso veiculos ou banco estejam indisponiveis.

Remover a migracao automatica que percorre todos os personagens no startup.
Nao inferir onboarding pela existencia de qualquer `cruiser`, pois uma bicicleta
comprada nao e necessariamente o kit inicial.

### Garagens Publicas Tycoon

Veiculos do tycoon devem ser acessiveis em qualquer garagem publica compativel.
As garagens publicas usam `skipGarageCheck = true`, mantendo os filtros existentes
por proprietario, estado e tipo (`car`, `air`, `sea`).

Nao usar `garage = 'global'`: essa garagem virtual nao esta registrada no
`qbx_garages`. A retirada basica tambem nao pode depender de
`npwd_qbx_garages_plus`, pois esse modulo nao esta instalado.

### Degradacao Controlada

Dependencias essenciais geram erro claro no console e bloqueiam apenas operacoes
que nao podem ser concluidas corretamente. Dependencias opcionais ocultam ou
bloqueiam a funcionalidade correspondente com mensagem objetiva ao jogador.

## Seguranca E Confiabilidade

- O servidor decide a entrega do kit inicial.
- Eventos repetidos de login nao geram itens ou veiculos duplicados.
- A marca de onboarding e persistente e exclusiva por `citizenid`.
- HUD nao tem autoridade sobre inventario, garagem ou economia.
- Compras e recompensas continuam validadas no servidor.
- Resources ativos ficam declarados explicitamente para facilitar auditoria.

## Estrategia De Teste

- Iniciar somente resources explicitamente listados.
- Criar personagem novo: receber um tablet e uma `cruiser`.
- Reconectar: nao duplicar tablet nem bicicleta.
- Validar bicicleta e veiculos comprados em garagens publicas compativeis.
- Validar HUD com fome, sede, stress, voz, combustivel e cinto.
- Entrar e sair de veiculo sem HUD duplicado.
- Desligar telefone e corridas: tycoon basico continua utilizavel.
- Inspecionar console para dependencias ausentes e mensagens acionaveis.

## Revisao Estruturada

### Challenger

Objeções:

- `garage = 'global'` nao corresponde a uma garagem registrada.
- A bicicleta existente e entregue tambem a veteranos no startup.
- Qualquer `cruiser` existente e tratada como starter.
- `cidade_hud` duplica o cinto fornecido por `qbx_seatbelt`.

Resolucao:

- Usar garagens publicas compativeis.
- Criar marca persistente de onboarding.
- Remover migracao global e inferencia por modelo.
- Manter uma unica fonte de estado do cinto.

### Constraint Guardian

Objeções:

- `ensure [qbx]` e `ensure [standalone]` tornam a composicao imprevisivel.
- Loops e mensagens NUI redundantes prejudicam escala acima de 100 jogadores.
- Starter items atuais do core exigem telefone e documentos de RP.

Resolucao:

- Inicializacao explicita.
- Atualizacoes por mudanca e cadencias separadas.
- Revisar starter items do Qbox para o onboarding tycoon.

### User Advocate

Objeções:

- Veiculo salvo em garagem virtual pode ficar invisivel ao jogador.
- Retirada pelo tablet depende de modulo ausente.
- Falhas opcionais precisam resultar em mensagens compreensiveis.

Resolucao:

- Garagens publicas acessiveis para veiculos tycoon.
- Fluxo basico independente de NPWD.
- Degradacao controlada com aviso objetivo.

### Arbiter

Disposicao final: **APPROVED**.

As objeções foram incorporadas sem reabrir os objetivos confirmados. O design esta
pronto para planejamento de implementacao incremental.

## Decision Log

| Decisao | Alternativas consideradas | Resolucao |
| --- | --- | --- |
| HUD unico | `cidade_hud`, `qbx_hud`, hibrido | Usar `cidade_hud` |
| Escopo | Tycoon puro, cidade viva, limpeza conservadora | Tycoon puro |
| Sobrevivencia | Remover, parcial, completa | Completa |
| Escala | 48, 100, mais de 100 jogadores | Mais de 100 |
| Remocao | Apagar, arquivar, desativar primeiro | Desativar primeiro |
| Onboarding | Direto, simplificado, tutorial | Personagem, tablet e contratos |
| Bicicleta | `cruiser`, `bmx`, `scorcher` | `cruiser` |
| Inicializacao | Explicita, bloqueios posteriores, orquestrador | Explicita |
| Garagens | Publicas compativeis, central, tablet global | Publicas compativeis |

