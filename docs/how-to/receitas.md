# Receitas: passo a passo das tarefas comuns

Cada receita diz **quais arquivos mexer, em que ordem e como conferir**. Antes de qualquer
uma: leia `CLAUDE.md`, o ADR do tema em `docs/adr/`, `docs/reference/arquitetura.md` e as skills
`godot-*`. No fim: testes + `/fechar-fatia` (ADR, `docs/CHANGELOG.md`, apagar item do `docs/backlog/`)
e diga em 1 linha se está "Conforme as skills".

Comandos (PowerShell, na raiz `C:\Jogos\rpg`; o Godot está em `$env:GODOT_EDITOR_PATH`):
```powershell
# Importar (depois de PNG novo ou class_name novo; ANTES de rodar ferramentas)
& $env:GODOT_EDITOR_PATH --headless --path . --import
# Rodar uma ferramenta (SEM --debug: com erro, o --debug trava no depurador)
& $env:GODOT_EDITOR_PATH --headless --path . --script res://tools/gerar_armas.gd
# Um teste (COM --debug: mostra avisos do GDScript)
& $env:GODOT_EDITOR_PATH --headless --debug --path . --script res://tests/criaturas/teste_goblin.gd
# Todos os testes + o jogo 3 s procurando erros e avisos
powershell -NoProfile -ExecutionPolicy Bypass -File tests\rodar_testes.ps1
```
Outros comandos de ferramenta (sem `--debug`):
```powershell
# Arte provisória (ladrilhos), importar e regerar a fase de teste
& $env:GODOT_EDITOR_PATH --headless --path . --script res://tools/gerar_arte_provisoria.gd
& $env:GODOT_EDITOR_PATH --headless --path . --import
& $env:GODOT_EDITOR_PATH --headless --path . --script res://tools/gerar_fase_teste.gd
# Só uma fase (sem apagar as outras, que têm marcadores postos à mão): `-- 6` grava a fase 6 (com o chefe e os pilares quebráveis)
& $env:GODOT_EDITOR_PATH --headless --path . --script res://tools/gerar_fase_teste.gd -- 6
# Remarcar o ponto e a camada da mão (depois de mudar a arte do herói); o argumento salva uma folha de revisão
& $env:GODOT_EDITOR_PATH --headless --path . --script res://tools/marcar_pontos_mao.gd -- C:/caminho/revisao.png
# Print segurando teclas (precisa de janela). Opções: inicio, equipar
& $env:GODOT_EDITOR_PATH --path . --script res://tools/capturar_tela.gd -- mover_direita 40 C:/caminho/print.png equipar
# Jogar já numa fase (aqui a 6, a do Minotauro; a 3 é a do Ankheg), sem passar pelo título
& $env:GODOT_EDITOR_PATH --path . --script res://tools/abrir_fase.gd -- 6
# Regerar as regras e os comandos do Cursor (depois de mudar skill, comando ou doc de decisões)
powershell -NoProfile -ExecutionPolicy Bypass -File tools\gerar_regras_cursor.ps1
```

---

## 1. Criatura nova (monstro do livro)

Molde simples: **Gray Ooze** (quase só kit). Molde com capacidades da ficha: **Goblin**.
Camadas em `docs/adr/criaturas.md`: kit sempre → capacidades do `.tres` → específico.

1. **Ficha** em `data/<criatura>.tres` (`CriaturaRPG`): copie uma ficha parecida e preencha
   o bloco do livro. Marque capacidades (arremesso, disparo, furtividade, sol, matilha…).
   Campo novo -> `core/dados/criatura_rpg.gd` com `@export` e padrão que não muda as outras.
2. **Arte**: siga `docs/reference/artes_prontas.md`. Tiras finais em
   `features/<criatura>/sprites/` + gerador de SpriteFrames. Não versionar `fonte_gemini/`.
3. **Script raiz** `features/<criatura>/<criatura>.gd`: use `MontagemDeCriatura` no `_ready`
   (ficha, condições, empurrão, saltador, sinais). Andar com
   `MontagemDeCriatura.velocidade_andar`. API: `signal morreu`, `definir_alvo`, `vida_atual`,
   `nome_estado`, `_ao_resolver_golpe`, `_ao_morrer`. Só então o específico (se houver).
4. **Estados** em `features/<criatura>/estados/`: base `Estado<Criatura>` + um por estado.
   Mínimo do kit: Parado, Perseguindo, Atacando, Morrendo, Caido, Pulando (+ LevandoDano nos
   minions; chefes podem só piscar).
5. **Cena** `features/<criatura>/<criatura>.tscn`: copie `gray_ooze.tscn` (simples) ou
   `goblin.tscn` (com capacidades). `collision_layer = 16`; Hurtbox 4; Hitbox máscara 8.
   **Roda sozinha (F6)**: sem alvo, fica Parada. Variante do mesmo bicho = cena herdada.
6. **Ligar no jogo**: `levels/main.gd` (`CENAS_DOS_TIPOS` / Trazer) + teste da lista.
7. **Teste** `tests/criaturas/teste_<criatura>.gd`: ficha, cena sozinha, percebe/persegue, ataca, morre.
8. `docs/adr/criaturas.md`, `CLAUDE.md` se pasta nova, `CHANGELOG` / backlog, `CREDITOS.md`.

> Capacidades (arremesso, disparo, sol, flanqueio…) pertencem à ficha/`core/`, não à feature.
> Se a capacidade ainda só existe no Goblin, reutilize o Goblin ou extraia (regra de três /
> backlog `capacidades-*`) antes de copiar o monólito.

## 2. Arma, armadura ou munição nova

**Nunca edite `data/armas/*.tres`, `data/armaduras/*.tres` ou `data/municoes/*.tres` à mão.**
1. Acrescente a linha na `TABELA` de `tools/gerar_armas.gd` (ou `tools/gerar_armaduras.gd`).
   O comentário acima da tabela explica cada coluna. Arma corpo a corpo também precisa do
   movimento na tabela `GOLPES` (poses-chave) — copie o de uma arma parecida.
2. Arte: ícone do pacote em `assets/armas/fonte_idylwild/` (ou `fonte_aereo/`), ou desenho por
   script. Se o PNG é novo: rode o gerador, `--import`, rode o gerador de novo (o 2º passo lê a
   arte importada).
3. Confira os testes `tests/combate/teste_armas.gd` / `teste_armaduras.gd` (contagens, propriedades).
4. O baú do arsenal pega tudo das pastas `data/armas`, `data/armaduras`, `data/municoes` sozinho.

## 3. Regra de D&D nova (cálculo)

1. Conta pura em `core/regras/` (função estática ou método da `Ficha`/`Combate`), sem nó.
2. Teste em `tests/regras/teste_regras_dnd.gd` (ou `tests/combate/teste_combate_dnd.gd`) com o exemplo do livro.
   Dados: fixe a semente do `RandomNumberGenerator` ou use bônus enormes (+100) para não ter
   teste que falha às vezes.
3. Só depois ligue no jogo (componente, estado ou tela).
4. Fidelidade: **PHB 2024**. Regra da casa só com ok do usuário, e anotada em `docs/adr/regras_dnd.md`.

## 4. Estado novo (herói ou criatura)

1. Arquivo em `.../estados/estado_<nome>.gd` estendendo a base (`EstadoJogador`,
   `EstadoGoblin`...). Métodos: `entrar()`, `sair()`, `processar_fisica(delta)`.
2. Troca de estado só por `trocar_para.emit(&"Nome")` (o nome é o do NÓ na cena).
3. Nó filho da `MaquinaEstados` na `.tscn` + `ext_resource` do script.
4. Física e consultas ficam no script raiz (ferramentas); o estado só decide. Sem cadeia de `if`.

## 5. Ação de entrada nova (tecla + toque)

1. `project.godot`, seção `[input]`: a ação e a tecla padrão.
2. Se o jogador pode trocar a tecla: `core/utilitarios/comandos.gd` (`ACOES` e `NOMES`).
3. No celular: um botão em `ui/controles_toque/controles_toque.gd` (tabela `BOTOES`:
   ação, texto, canto, centro, raio). O layout salvo do jogador continua valendo; o botão novo
   nasce na posição padrão.
4. `docs/adr/interface.md`, linha "Ações de input".

## 6. Tela nova (UI)

1. `ui/<tela>/tela_<nome>.tscn` + `.gd` (`class_name Tela<Nome>`), raiz Control com
   `anchors_preset = 15` (tela inteira; a largura muda no celular), tema `ui/tema_menu.tres`.
2. A tela **não conhece o herói**: emite `abrir_pedido` (ou outro "pedido") e tem `abrir(dados)`.
3. Pausa: `process_mode = ALWAYS` na tela; quem abre pausa a árvore.
4. Instância em `levels/main.tscn` dentro de `Interface`; ligação em `main.gd`.
   Lembre de bloquear a abertura junto com as outras (`_em_tela_de_pausa`, inventário, baú,
   comandos, edição do toque).
5. Toque: botões grandes o bastante para o dedo (mín. ~24 px na tela de 360).

## 7. Teste novo

- `tests/<tema>/teste_<assunto>.gd` (combate, criaturas, heroi, ui, campanha, regras), `extends TesteBase`, `_initialize` -> `_rodar.call_deferred()`.
- `_checar(condicao, "descrição em português")` imprime `ok`/`ERRO`; no fim **`_terminar("resumo")`**
  (imprime `PASSOU`/`FALHOU` e `quit` 0/1). Só `quit(_falhas)` sem `PASSOU` é falha no runner.
  O `rodar_testes.ps1` pega todo `teste_*.gd`, imprime `>> OK`/`>> FALHOU` por arquivo e lista as falhas no fim.
- Cena principal sem título: `main.mostrar_inicio = false` antes de `add_child`.
- Espere quadros de física (`await physics_frame`) para a física andar. Botão Pular, ataque
  etc. agem no quadro SEGUINTE (buffer).
- Toque: `root.push_input(evento, true)` com `InputEventScreenTouch`/`ScreenDrag`.
- Não suje os arquivos do jogador em `user://`: guarde e devolva (ver `tests/ui/teste_toque.gd`).
- O herói pode cair durante o teste: dê vida alta (`HealthComponent.configurar(999)`).

## 8. Print para conferir o visual

Precisa de janela (sem `--headless`). Script em pasta temporária, por exemplo:
```gdscript
extends SceneTree
func _initialize() -> void:
	_rodar.call_deferred()
func _rodar() -> void:
	var cena: Main = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	for i in 30: await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	quit()
```
`& $env:GODOT_EDITOR_PATH --path . --resolution 1280x720 --script <script> -- <saida.png>`
(`--resolution 2400x1080` simula celular largo). Há também `tools/capturar_tela.gd`.

## 9. Armadilhas conhecidas

- **Pipeline Gemini/SpriteCook intermediário**: PNGs brutos e pastas `fonte_gemini/` ficam
  fora do repositório; no jogo só entram as tiras finais e o `.tres` de SpriteFrames.
- **`class_name` novo**: rode `--import` antes de qualquer ferramenta ou teste que use a classe.
- **Ferramenta com `--debug`** trava no depurador se houver erro: rode ferramentas sem `--debug`.
- **Aviso também é falha**: o `rodar_testes.ps1` reprova `WARNING` (ex.: `await` desnecessário,
  sinal sem uso, variável sem uso).
- **Propriedade de outro script em variável tipada `Control`/`Node`**: o GDScript reclama na
  análise; use `controle.set(&"nome", valor)` ou tipe com a classe certa.
- **Ordem do `_ready`**: filhos ficam prontos antes do pai; opções carregadas na `main` ainda
  não existem no `_ready` das telas (atualize ao abrir).
- **Script `.ps1` com acento**: salve em UTF-8 **com BOM**, ou o PowerShell 5.1 estraga os acentos.
- **`.tscn` à mão**: só mudanças pequenas (um nó, um `ext_resource`). Estruturas grandes por
  script gerador ou no editor.
- **Commit**: um por fatia, em português, só com o ok do usuário; nunca force-push.

## Receita: um talento novo (efeito no golpe)
1. Dados: uma linha em `tools/gerar_compendio.gd` (id, nome do livro, texto) e os atributos em `ATRIBUTOS_DO_TALENTO`; rode o gerador.
2. Id: uma constante `TALENTO_*` em `Ficha` (o id do `TalentoRPG`, em `StringName`).
3. Efeito: uma classe em `core/regras/efeitos/efeitos_de_talento.gd` que estende `EfeitoDeGolpe` e sobrescreve só o que usa; `Ficha._juntar_efeitos_de_talento` a coloca no golpe. O `id` do efeito serve à recarga de uma vez por rodada (`por_rodada`).
4. Estado no herói (botão, doses, tempo): uma classe pura em `features/jogador/talentos/`, com teste em `tests/heroi/teste_regras_do_heroi.gd`.
5. Teste do efeito em `tests/` (`extends TesteBase`) e uma linha em `TALENTOS_FUNCIONANDO` do gerador quando o jogador já puder escolher.
