# CLAUDE.md: Guia do projeto "rpg"

Este arquivo guia qualquer IA (Claude, Codex, Cursor etc.) que trabalhe neste projeto.
**Atualize-o sempre que uma decisão mudar.** O `AGENTS.md` aponta para cá.

## Visão do jogo
- **Estilo:** 2.5D. Mundo 3D; o jogador se move em X e Z. Personagens e cenário são sprites 2D (pixel art) que olham para a câmera.
- **Gênero:** RPG de aventura (provisório, a confirmar).
- **Movimento:** andar livre no chão (8 direções, WASD ou setas). Sem pulo por enquanto.
- **Câmera:** fixa, inclinada a ~45°, segue o jogador com suavização. Não gira.
- **Arte:** pixel art. Escala: **16 px = 1 metro** (`pixel_size = 0.0625`).
- **Referências:** Octopath Traveler, Don't Starve.
- **Plataforma:** PC (Windows).

## Sobre o usuário
- Já fez "um pouco" de jogo. Explique as decisões em linguagem simples, sem esconder o porquê.
- Comunicação em **português**.
- Toda resposta termina com: (1) o que foi feito, (2) como testar (passos exatos), (3) o que se sugere em seguida.

## Decisões tomadas
| Decisão | Escolha | Por quê |
|---|---|---|
| Motor | Godot 4.7.2, GDScript | Já instalado; sem C#. |
| Renderizador | GL Compatibility | Já configurado; leve e ótimo para pixel art. |
| Física | Jolt Physics | Padrão do projeto. |
| Billboard dos sprites | **Só no eixo Y** (`billboard = 2`, FIXED_Y) | O boneco fica "em pé" no chão e só gira para os lados. O billboard completo inclinaria o sprite para trás junto com a câmera a 45°, parecendo deitado no chão. |
| Transparência dos sprites | `alpha_cut = 1` (DISCARD) | Evita bugs de ordem de desenho entre sprites sobrepostos (usa o depth buffer). |
| Filtro de textura | Nearest (`texture_filter = 0`) nos sprites; nearest com mipmaps no chão | Pixel art nítida; o chão com mipmaps não "cintila" ao longe. |
| Importação de PNG | Lossless (`compress/mode=0`), sem "detect 3D" (`detect_3d/compress_to=0`) | Compressão VRAM borra/estraga pixel art. |
| Sombra do personagem | Sombra falsa (sprite oval deitado no chão); o sprite não projeta sombra | Sombra real de billboard fica estranha. |
| Movimento suave | Interpolação de física ligada; câmera move em `_process` usando `get_global_transform_interpolated()` | Evita tremedeira em monitores com Hz diferente da física (60). |
| Arte | Provisória gerada por script (`scripts/ferramentas/gerar_arte_provisoria.gd`); arte final pelo SpriteCook | Começar sem depender de arte externa; SpriteCook gasta créditos. |

## Estrutura de pastas
```
scenes/               cenas (.tscn); main.tscn é a cena principal
scripts/              scripts GDScript das cenas
scripts/ferramentas/  utilitários rodados pela linha de comando (não fazem parte do jogo)
assets/sprites/       imagens e SpriteFrames
assets/audio/         sons e músicas
assets/shaders/       shaders
autoload/             singletons globais (só o que for realmente global)
tests/                testes automáticos (rodam headless)
```

## Convenções
- **Arquivos e funções:** `snake_case` (ex.: `camera_seguidora.gd`, `_atualizar_animacao()`).
- **Classes e nós:** `PascalCase` (ex.: `class_name Jogador`, nó `Sprite`).
- **Comentários e nomes do jogo em português.** Termos do Godot ficam em inglês.
- Valores ajustáveis usam `@export`.
- Cenas pequenas e reutilizáveis; comunicação por **signals**; autoload só para o que é global.
- Ações de input: `mover_esquerda`, `mover_direita`, `mover_cima`, `mover_baixo` (Project Settings → Input Map).
- Edite `.tscn` à mão só em mudanças pequenas e seguras. Estruturas grandes: MCP do Godot ou editor.
- Nada de addons ou arquitetura complexa sem aprovação do usuário. Decisões grandes (inventário, save/load, IA de inimigos): proponha 2 opções com prós e contras.

## Como trabalhar
- Uma fatia pequena por vez. Ao terminar: o que mudou, como testar, próxima fatia sugerida. Não começar a próxima sem "ok".
- Teste você mesmo (rodar headless, ler log, testes). Pergunte ao usuário só o que é de sensação (movimento, câmera, visual), com perguntas específicas.
- Um commit por fatia concluída, mensagem clara em português.
- **Nunca** apagar arquivos do usuário nem fazer force-push. Se der muito errado, voltar ao último commit.

## Ferramentas disponíveis para a IA
- **MCP do Godot** (`godot`, em `.mcp.json`): rodar o projeto, ler o output de debug, criar cenas e nós.
- **Plugin GDScript LSP** (`gdscript@claude-code-gdscript`): diagnósticos e navegação em `.gd`. Usa `GODOT_EDITOR_PATH`.
- **SpriteCook** (plugin): gera sprites, animações e tilesets. **Gasta créditos**: avise o custo antes de gerar.

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
# Rodar headless por ~2 s só para ver erros no log
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --quit-after 120
# Regerar a arte provisória
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --script res://scripts/ferramentas/gerar_arte_provisoria.gd
```

## Como rodar os testes
Cada teste é um script em `tests/` que estende `SceneTree`, imprime `PASSOU`/`FALHOU` e sai com código 0 ou 1:
```powershell
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --script res://tests/teste_jogador.gd
```

## Armadilhas de 2.5D (já tratadas, manter)
- **Ordem de desenho:** sprites com `alpha_cut = 1` (DISCARD). Se usar alpha blend (ex.: sombra), ajustar `render_priority`.
- **Sombras:** sprite não projeta sombra (`cast_shadow = 0`); usa sombra falsa.
- **Pixel art borrada:** filtro nearest + importação lossless sem detect 3D. Ao adicionar PNG novo, conferir o `.import`.

## Estado atual
- Fatia 1: boneco andando numa relva verde (`scenes/main.tscn`).
