# CLAUDE.md: Guia do projeto "rpg"

Este arquivo guia qualquer IA (Claude, Codex, Cursor etc.) que trabalhe neste projeto.
**Atualize-o sempre que uma decisão mudar.** O `AGENTS.md` aponta para cá.

## Visão do jogo
- **Estilo:** 2D de rolagem lateral (side-scroller). O herói corre para a frente e para trás pelo mapa, pula e (em breve) luta.
- **Gênero:** ação e plataforma. Jogo **original**: inspirado na sensação de jogos de ação lateral (ritmo rápido, controle justo), sem copiar personagens, fases, nomes ou visual de nenhum jogo existente.
- **Arte:** pixel art. Herói gerado no SpriteCook; cenário provisório gerado por script.
- **Plataforma:** PC (Windows). Teclado primeiro; controle depois.
- Histórico: o projeto começou em 2.5D (commits `60f2dda` e `0b1ca2b`) e mudou para 2D lateral na fatia 3.

## Sobre o usuário
- Já fez "um pouco" de jogo. Explique as decisões em linguagem simples, sem esconder o porquê.
- Comunicação em **português**.
- Toda resposta termina com: (1) o que foi feito, (2) como testar (passos exatos), (3) o que se sugere em seguida.

## Decisões tomadas
| Decisão | Escolha | Por quê |
|---|---|---|
| Motor | Godot 4.7.2, GDScript | Já instalado; sem C#. |
| Renderizador | GL Compatibility | Leve e ótimo para pixel art 2D. |
| Resolução interna | **640x360**, `stretch/mode = viewport`, `scale_mode = integer` | Pixel art ampliada sem borrar (2x = 1280x720, 3x = 1920x1080). |
| Filtro de textura | Nearest (padrão do projeto) | Pixel art nítida. |
| Unidade | Pixels. Ladrilhos de **32x32**. Herói com ~73 px de altura (~2,3 ladrilhos) | Proporção boa para ação lateral. |
| Importação de PNG | Lossless, sem mipmaps | Não estragar a pixel art. |
| Herói | `CharacterBody2D` + `AnimatedSprite2D`; origem nos pés; espelha com `flip_h` | Simples e padrão do Godot. |
| Sensação do pulo | Altura variável (soltar corta o pulo), coyote time, buffer de pulo, gravidade maior na queda | Controle "justo", típico do gênero. |
| Fase | `TileMapLayer` gerado por script a partir de um mapa em texto (`scripts/ferramentas/gerar_fase_teste.gd`); plataformas finas são *one-way* (atravessa por baixo) | Fácil de mudar o layout; depois dá para editar no editor. |
| Câmera | `Camera2D` filha do herói, com suavização, olha à frente na direção em que ele corre; limites calculados pelo tamanho da fase | Ver o que vem pela frente. |
| Movimento suave | Interpolação de física ligada | Sem tremedeira em monitores de 144 Hz. |

## Estrutura de pastas
```
scenes/               cenas (.tscn); main.tscn é a cena principal
scenes/fases/         fases (geradas ou montadas no editor)
scripts/              scripts GDScript das cenas
scripts/ferramentas/  utilitários rodados pela linha de comando (não fazem parte do jogo)
assets/sprites/       sprites e SpriteFrames (assets/sprites/heroi/ = herói)
assets/tiles/         ladrilhos e TileSet
assets/audio/         sons e músicas
assets/shaders/       shaders
autoload/             singletons globais (só o que for realmente global)
tests/                testes automáticos (rodam headless)
```

## Convenções
- **Arquivos e funções:** `snake_case` (ex.: `jogador.gd`, `_atualizar_animacao()`).
- **Classes e nós:** `PascalCase` (ex.: `class_name Jogador`, nó `Sprite`).
- **Comentários e nomes do jogo em português.** Termos do Godot ficam em inglês.
- Valores ajustáveis usam `@export`.
- Cenas pequenas e reutilizáveis; comunicação por **signals**; autoload só para o que é global.
- Ações de input: `mover_esquerda` (A, ←), `mover_direita` (D, →), `mover_baixo` (S, ↓), `pular` (Espaço, W, ↑).
- Edite `.tscn` à mão só em mudanças pequenas e seguras. Estruturas grandes: script gerador, MCP do Godot ou editor.
- Nada de addons ou arquitetura complexa sem aprovação do usuário. Decisões grandes (combate, inimigos, save/load): proponha 2 opções com prós e contras.

## Como trabalhar
- Uma fatia pequena por vez. Ao terminar: o que mudou, como testar, próxima fatia sugerida. Não começar a próxima sem "ok".
- Teste você mesmo (rodar headless, ler log, testes, prints com `capturar_tela.gd`). Pergunte ao usuário só o que é de sensação (pulo, corrida, câmera, visual), com perguntas específicas.
- Um commit por fatia concluída, mensagem clara em português.
- **Nunca** apagar arquivos do usuário nem fazer force-push. Se der muito errado, voltar ao último commit.

## Ferramentas disponíveis para a IA
- **MCP do Godot** (`godot`, em `.mcp.json`): rodar o projeto, ler o output de debug, criar cenas e nós.
- **Plugin GDScript LSP** (`gdscript@claude-code-gdscript`): diagnósticos em `.gd`. Usa `GODOT_EDITOR_PATH`. (Na fatia 1 estourou o tempo ao iniciar; com o editor aberto deve funcionar.)
- **SpriteCook** (plugin): gera sprites, animações e tilesets. **Gasta créditos**: avise o custo antes de gerar.
  - Preços: personagem base = 12; 1ª animação da rodada = 20, cada extra na mesma rodada = 14; preparo de pose (walk/run) = 12.
  - O herói é o asset `b484dd94-...` (perspectiva *platformer*). Gere novas animações **a partir dele**, não um personagem novo.
  - Todo asset gerado vai para o `spritecook-assets.json` (asset_id + sha12).
  - Chamadas com espera longa podem estourar o tempo mesmo dando certo: use `wait_seconds = 0` e acompanhe pelo `run_id`, ou confira com `list_animation_outputs` antes de repetir (para não pagar duas vezes).

## Como rodar
O executável do Godot está na variável de ambiente `GODOT_EDITOR_PATH`:
`C:\Users\lucas\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`

PowerShell:
```powershell
# Abrir o editor
& $env:GODOT_EDITOR_PATH --editor --path C:\Jogos\rpg
# Rodar o jogo
& $env:GODOT_EDITOR_PATH --path C:\Jogos\rpg
# Importar assets novos (depois de adicionar ou gerar PNGs)
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --import
# Rodar headless por ~3 s só para ver erros no log
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --quit-after 180
# Regerar a arte provisória (ladrilhos) e depois a fase de teste
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --script res://scripts/ferramentas/gerar_arte_provisoria.gd
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --import
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --script res://scripts/ferramentas/gerar_fase_teste.gd
# Tirar um print segurando teclas (precisa de janela; sem --headless)
& $env:GODOT_EDITOR_PATH --path C:\Jogos\rpg --script res://scripts/ferramentas/capturar_tela.gd -- mover_direita 40 C:/caminho/print.png
```

## Como rodar os testes
Cada teste é um script em `tests/` que estende `SceneTree`, imprime `PASSOU`/`FALHOU` e sai com código 0 ou 1:
```powershell
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --script res://tests/teste_jogador.gd
```

## Estado atual
- Fatias 1 e 2 (2.5D): boneco na relva e herói do SpriteCook. Substituídas pela fatia 3.
- Fatia 3: herói correndo e pulando numa fase de teste em 2D lateral.
