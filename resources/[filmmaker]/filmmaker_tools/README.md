# Cidade Império do Transporte - Ferramentas de Set

Este recurso trabalha junto com o Rockstar Editor e o EVER, sem substituir a exportacao.

## Comandos

- `/filmhelp`: exibe os comandos disponiveis.
- `/cinehud`: liga/desliga HUD e radar para gravacao limpa.
- `/claquete Cena 1 Take 1`: mostra contagem sincronizada para todos no set.
- `/cineprop nome_do_modelo`: posiciona um objeto de cenario onde a camera aponta.
- `/cineapagar`: remove o objeto do set apontado pela camera.
- `/cinelimpar`: remove todos os objetos criados pelo set.

Durante `/cineprop`, use `ENTER` para confirmar, `BACKSPACE` para cancelar e as setas para ajustar rotacao/altura.

## Permissao

Os comandos que mudam o set exigem `filmmaker.permissao`, `admin.permissao` ou `owner.permissao`.

Administradores usam `/darfilmmaker ID` e `/tirarfilmmaker ID` com o jogador online. O cargo e separado do emprego RP do personagem.

## Menyoo no set

- `F10`: abre e fecha o Menyoo.
- `F5`: abre o Spooner Mode para montagem de cena.
- Antes de montar ou gravar, execute `setup/cliente/ativar_menyoo_para_gravar.ps1`.
- Antes de abrir o Editor de Replays ou exportar com EVER, feche o FiveM e execute `setup/cliente/desativar_menyoo_para_exportar.ps1`.

O servidor de filmagem permite ScriptHook para o Menyoo. Se a cidade voltar a operar como RP publico competitivo, desative essa permissao.


