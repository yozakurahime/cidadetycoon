# Original User Request

## Initial Request — 2026-06-04T21:13:58-03:00

O projeto consiste em realizar testes integrados em todos os sistemas modulares da Cidade Tycoon (`cidade_*`) para identificar bugs, erros de callback e falhas de comunicação entre os recursos após a migração do legado, corrigindo problemas óbvios/seguros e mapeando as conexões do sistema.

Working directory: e:\Cidade Tycoon
Integrity mode: development

## Requirements

### R1. Cobertura de Verificação Estática e de Sintaxe
Validar sintaxe de todos os arquivos de script (Lua, JS/TS) contidos nos diretórios ativos `cidade_*`.

### R2. Mapeamento de Eventos e Callbacks
Identificar e mapear todas as comunicações inter-recursos (eventos locais/rede, callbacks de servidor/cliente). Apontar discrepâncias de parâmetros ou nomes de eventos inexistentes.

### R3. Criação de Mocks para Execução Parcial
Desenvolver ou adaptar scripts de teste/mock em Node.js (ex: na pasta `scratch/`) para testar/simular execuções de fluxos de eventos importantes de forma isolada, validando o comportamento sem a necessidade de rodar o servidor FiveM completo.

### R4. Correção e Relatório de Bugs
Corrigir erros de sintaxe, imports incorretos, variáveis indefinidas ou discrepâncias óbvias de chamadas. Gerar um relatório detalhado de auditoria listando os bugs encontrados, corrigidos, e os riscos de integração persistentes.

## Acceptance Criteria

### Validação de Sintaxe
- [ ] Todos os arquivos Lua ativos em `cidade_*` são validados sem erros críticos de sintaxe.
- [ ] Todos os arquivos JS ativos em `cidade_*` passam na validação básica de sintaxe.

### Auditoria de Eventos
- [ ] Um relatório de auditoria detalhado (`audit_report.md`) contendo o mapa de callbacks e eventos inter-recursos, destacando potenciais timeouts ou quebras.

### Scripts de Mock e Simulação
- [ ] Existência e execução com sucesso de pelo menos um script de mock automatizado que simula o fluxo de eventos/callbacks críticos entre pelo menos dois recursos `cidade_*` correlacionados.

### Correções e Changelog
- [ ] Changelog detalhado de modificações aplicadas aos recursos ativos (se houver), ou justificativa técnica no relatório se nenhuma correção foi considerada segura/necessária.
