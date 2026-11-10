# CLAUDE.md: Guia do projeto "rpg"

Este arquivo guia qualquer IA (Claude, Codex, Cursor etc.) que trabalhe neste projeto. Ele é
**curto de propósito**: só o que vale para toda tarefa. Os detalhes estão em `docs/` (índice abaixo).
**Atualize o documento do tema sempre que uma decisão mudar.** O `AGENTS.md` aponta para cá.

## Visão do jogo
- **"DnD in a Piece"**: ação e plataforma 2D lateral (side-scroller) com regras de **D&D 5e (PHB 2024)**. Herói Guerreiro.
- Jogo **original**: inspirado na sensação de jogos de ação lateral (ritmo rápido, controle justo), sem copiar personagens, fases, nomes ou visual de nenhum jogo existente.
- **Arte:** pixel art. Herói gerado no SpriteCook; armas, armaduras e monstros de pacotes CC0; o resto provisório por script.
- **Plataforma:** PC (Windows) e Android (celular deitado). Teclado no PC, toque no celular.

## Sobre o usuário
- Já fez "um pouco" de jogo. Explique as decisões em linguagem simples, sem esconder o porquê.
- Comunicação em **português**.
- Toda resposta termina com: (1) o que foi feito, (2) como testar (passos exatos), (3) o que se sugere em seguida.
- Decisões: pergunte com **3 opções**, a recomendada primeiro.

## Onde está cada coisa (Diátaxis — ver `docs/README.md`)
| Documento | Conteúdo |
|---|---|
| `docs/adr/*.md` | **Explanation:** decisões por tema (base, herói, regras D&D, armas, criaturas, interface, áudio). |
| `docs/how-to/receitas.md` | **How-to:** criatura, arma, regra, estado, ação, tela, teste, print; armadilhas. |
| `docs/reference/arquitetura.md` | **Reference:** mapa do sistema (camadas, main, golpe, persistência). |
| `docs/reference/artes_prontas.md` | Arte de terceiros (licença, como usar). |
| `docs/reference/exportar_android.md` | SDK/JDK e comando do APK. |
| `docs/reference/talentos.md` | Talentos/antecedentes: ligados vs em espera. |
| `docs/backlog/` | **O que falta** (1 arquivo = 1 pendência + YAML). Fonte do `/proxima-fatia`. |
| `docs/CHANGELOG.md` | O que já foi feito (append-only). |
| `docs/spritecook/` | Prompts vivos do SpriteCook. |

## Decisões que valem para tudo
| Decisão | Escolha |
|---|---|
| Motor | Godot 4.7.2, GDScript, GL Compatibility. |
| Tela | 640x360, `viewport` + escala inteira + `aspect = expand`; filtro Nearest; ladrilho 32x32; herói ~73 px. |
| Regras | D&D 5e **PHB 2024**, números do livro. Regras da casa só com ok do usuário (lista em `docs/adr/regras_dnd.md`). |
| Escala | 5 pés = 32 px; 1 rodada = 1,5 s; velocidade e ritmo de ataque vêm da ficha (`EscalaDnd`). |
| Dados | Números em Resources (`data/`). Armas, armaduras e munição são **gerados**: edite a TABELA do gerador, não os `.tres`. |
| Entrada | O código de jogo só lê ações do InputMap; teclado e toque apertam as mesmas ações. |
| Arquitetura | Componentes + máquina de estados; feature não importa feature; UI não conhece o herói; `levels/main.gd` monta tudo. |

## Skills do projeto (`.claude/skills/`)
**Carregue as skills de godot-* relevantes antes de qualquer mudança de código.**

| Skill | Quando usar |
|---|---|
| `godot-estrutura-pastas` | Criar, mover ou referenciar arquivos. `core/`, `features/<nome>/`, `levels/`, `ui/`, `data/`, `assets/`, `tests/`; feature não importa feature. |
| `godot-cenas-e-sinais` | Criar ou mudar cenas e ligações. Cena roda sozinha (F6), "call down, signal up", sem `get_parent()` para mexer no pai. |
| `godot-componentes-e-dados` | Montar entidades e definir números. Componentes, Resources `.tres` em `data/`, regras em `RefCounted`. |
| `godot-maquina-de-estados` | Comportamento do jogador e dos inimigos. Um estado por comportamento, sem cadeia de `if`. |
| `godot-estilo-gdscript` | Todo `.gd`. Tipagem, nomes, funções curtas, sem números mágicos, regra de três, autoload só com justificativa. |
| `revisar-codigo` | Revisão e a checagem no fim de cada tarefa. |

Regras de uso:
- Ao terminar cada tarefa, faça a checagem contra as skills usadas e diga em **1 linha**: `Conforme as skills` ou quais regras foram violadas e por quê.
- Se o usuário pedir algo que quebre uma regra, **avise e explique o impacto antes**; só quebre se ele confirmar.
- Se uma regra precisar mudar, **proponha a alteração na skill e espere o ok**. Nunca desvie da skill em silêncio.

## Comandos e agentes
- **Comandos** (`.claude/commands/`; no Cursor, `.cursor/commands/`, gerados pelo mesmo script):
  `/testar` (roda tudo e resume), `/proxima-fatia` (3 opções a partir de `docs/backlog/`),
  `/fechar-fatia` (checklist de fim de fatia), `/nova-criatura` (receita 1 com a ficha do livro).
- **Agentes** (`.claude/agents/`): `testador` (roda os testes e devolve só o que falhou),
  `revisor-godot` (revisão só de leitura contra as skills).
- **Cursor:** as skills, os comandos e as regras por tema ficam em `.cursor/` e são **gerados** por
  `tools/gerar_regras_cursor.ps1` (fonte da verdade = `.claude/` e `docs/`). **Mudou uma skill ou um
  comando? Rode o script.** Escritas à mão: `projeto`, `arquitetura`, `receitas`, `testes`,
  `ferramentas-e-dados`, `artes-prontas`. MCP do Godot: `.mcp.json` e a cópia
  `.cursor/mcp.json` (mude os dois juntos).

## Estrutura de pastas
Regras na skill `godot-estrutura-pastas`. Hoje:
```
core/estados/            Estado, MaquinaEstados (genéricos)
core/componentes/        Hitbox, Hurtbox, Defesa, Health, TextoFlutuante, Condicoes
core/regras/efeitos/     EfeitoDeGolpe e EfeitosDeTalento (um efeito de talento por classe, que o Golpe carrega)
core/regras/base/        Dado, Atributos, EscalaDnd, TiposDano, CompraDePontos, Pericia, Proficiencias
core/regras/combate/     Combate, Golpe, Equipamento, Inventario, ItemAleatorio
core/regras/criaturas/   MontagemDeCriatura, Disparo/Arremesso/Tatica/Investida/Furtividade/FugaAgil/Matilha/Voo…
core/regras/mundo/       Ficha, Salvamento, Missao, Loja, Saque
core/dados/              Item, Arma, Municao, PoseGolpe, Armadura, ClasseRPG, CriaturaRPG, PacoteInicial,
                         AntecedenteRPG, TalentoRPG, EntradaCompendio
core/utilitarios/        ToqueDuplo, DesenhoArma, Recursos, Comandos, OpcoesToque
features/jogador/        herói: jogador, stats, animação, câmera, ataque, escudo, arma de trás, estados/, sprites/
features/jogador/talentos/ regras puras dos talentos do herói (recargas, Sorte, dados de vida, veneno, defesa, Investida)
features/gray_ooze/      Gray Ooze: cena, estados/, sprites/
features/goblin/         Goblin Minion e Goblin Warrior: cenas, adaga, flecha, estados/, sprites/
features/ankheg/        Ankheg (chefe da fase 3): cena, estados/, sprites/
features/minotauro/      Minotauro de Baphomet (chefe da fase 6): cena, estados/, sprites/
features/wight/          Corpo Seco / Wight (chefe da fase 9): cena, estados/, sprites/
features/quimera/        Quimera (chefe final da fase 10): cena, estados/, sprites/
features/bloco_quebravel/ bloco de pedra que o Minotauro quebra (grupo "quebravel")
features/loja/           lojista no início da fase (NPC)
features/boneco_treino/  boneco de treino
features/bau/            baú do arsenal (E)
features/arremesso/      arma arremessada / projétil do herói
core/projeteis/          Flecha e ProjetilArremesso compartilhados (Goblin, Wight…)
levels/                  main.tscn/.gd (cena principal), fase.gd, fase_1..10.tscn, sons/musica
ui/                      titulo, criacao_personagem, hud, inventario, bau, loja, comandos, derrota,
                         controles_toque, bestiario, habilidades, pausa, compendio (+ a regra `Compendio`), talento;
                         tema_menu.tres; resumo_item.gd
data/                    jogador_padrao, ataque_desarmado, classe_guerreiro, gray_ooze, goblin_*, ankheg,
                         minotauro, wight, quimera, armas/, armaduras/, municoes/, itens/, pacotes/,
                         antecedentes/, talentos/, bestiario/
assets/                  tiles/, armas/, armaduras/, efeitos/, shaders/; CREDITOS.md
tools/                   geradores (armas, armaduras, criaturas, fase, pose, mão), capturar_tela,
                         ferramentas_pixel, gerar_regras_cursor.ps1
tests/                   apoio + rodar_testes.ps1; teste_*.gd em combate/, criaturas/, heroi/, ui/, campanha/, regras/
docs/                    README (Diátaxis), adr/, how-to/, reference/, backlog/, CHANGELOG.md, spritecook/
.claude/                 skills/, commands/, agents/
.cursor/                 rules/, commands/ (gerados do .claude e docs), mcp.json
```

## Convenções
- Os detalhes de estilo estão na skill `godot-estilo-gdscript`; abaixo ficam só os específicos do projeto.
- **Arquivos e funções:** `snake_case`. **Classes e nós:** `PascalCase`.
- **Comentários e nomes do jogo em português.** Termos do Godot ficam em inglês.
- Balanceamento em Resources (`data/`); ajustes só visuais podem ficar em `@export` do componente.
- Edite `.tscn` à mão só em mudanças pequenas e seguras. Estruturas grandes: script gerador, MCP do Godot ou editor.
- Nada de addons ou arquitetura complexa sem aprovação do usuário. Decisões grandes (combate, inimigos, save/load): proponha opções com prós e contras.

## Como trabalhar
- Uma fatia pequena por vez, escolhida em `docs/backlog/`. Ao terminar: o que mudou, como testar, próxima fatia sugerida. Não começar a próxima sem "ok".
- Teste você mesmo (rodar headless, ler log, testes, prints). Pergunte ao usuário só o que é de sensação (pulo, corrida, câmera, visual), com perguntas específicas.
- Ao fechar uma fatia (`/fechar-fatia`): testes passando, doc do tema atualizado, `docs/CHANGELOG.md` e `docs/backlog/` atualizados, checagem das skills.
- Um commit por fatia concluída, mensagem clara em português, só com o ok do usuário.
- **Nunca** apagar arquivos do usuário nem fazer force-push. Se der muito errado, voltar ao último commit.

## Ferramentas disponíveis para a IA
- **MCP do Godot** (`godot`): rodar o projeto, ler o output de debug, criar cenas e nós.
- **Plugin GDScript LSP** (`gdscript@claude-code-gdscript`): diagnósticos em `.gd`. Usa `GODOT_EDITOR_PATH`.
- **SpriteCook** (plugin): gera sprites e animações. **Gasta créditos**: avise o custo antes.
  - Preços: personagem base = 12; 1ª animação da rodada = 20, cada extra na mesma rodada = 14; preparo de pose (walk/run) = 12.
  - O herói é o asset `b484dd94-...` (perspectiva *platformer*). Gere novas animações **a partir dele**.
  - Todo asset gerado vai para o `spritecook-assets.json` (asset_id + sha12).
  - Chamadas longas podem estourar o tempo mesmo dando certo: use `wait_seconds = 0` e acompanhe pelo `run_id`, ou confira com `list_animation_outputs` antes de repetir.

## Como rodar e testar
O Godot está em `GODOT_EDITOR_PATH`
(`C:\Users\lucas\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`).
```powershell
& $env:GODOT_EDITOR_PATH --editor --path C:\Jogos\rpg          # abrir o editor
& $env:GODOT_EDITOR_PATH --path C:\Jogos\rpg                   # jogar
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --import   # depois de PNG ou class_name novo
# Todos os testes + o jogo 3 s procurando erros E avisos (aviso reprova):
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Jogos\rpg\tests\rodar_testes.ps1
# Um teste (com --debug para ver avisos):
& $env:GODOT_EDITOR_PATH --headless --debug --path C:\Jogos\rpg --script res://tests/heroi/teste_jogador.gd
```
Ferramentas de `tools/` rodam **sem `--debug`** (com erro, o `--debug` trava no depurador). Mais
comandos (fase, ponto da mão, prints) e armadilhas em `docs/how-to/receitas.md`.

## Estado atual
Últimas fatias (lista completa em `docs/CHANGELOG.md`; o que falta em `docs/backlog/`):
- Campanha de **10 fases** em 4 temas (Floresta, Ruínas, Subterrâneo, Covil): encontros, portas com cota, missões, ouro/drops, loja e vitória na fase 10 (Covil).
- Chefes: Ankheg (3), Minotauro (6, blocos quebráveis), Wight (9, Skeleton/Zombie), Quimera (10). Lava do Covil ainda pendente.
- Minions: Goblin Minion/Warrior, Gray Ooze, Kobold, Hobgoblin, Bugbear, Skeleton, Zombie (`features/goblin/` por herança).
- Guerreiro **1–6**: Surto/Mente Tática (2), talentos gerais (4 e 6), Ataque Extra e Mudança Tática (5); criação com antecedente; 30 talentos ligados. **Subclasse (nível 3) ainda não.**
- Save/load (`Salvamento` → `user://save.json`), Compêndio com antecedentes/talentos, toque com **8 slots**.
- Celular: APK em `builds/android/dnd_in_a_piece.apk` (ajustes de toque quando o feedback do aparelho aparecer).
- Docs em **Diátaxis**: `docs/adr/`, `how-to/`, `reference/`, `backlog/` (1 pendência = 1 arquivo), `CHANGELOG.md`.
