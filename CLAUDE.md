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
| Fase | `TileMapLayer` gerado por script a partir de um mapa em texto (`tools/gerar_fase_teste.gd`); plataformas finas são *one-way* (atravessa por baixo). Script raiz `levels/fase.gd` (`Fase`) expõe `posicao_inicio()`, `area_jogavel()` e `limite_queda()` | Fácil de mudar o layout; quem usa a fase não mexe nos nós internos. |
| Fase atual | **Reta**, 120 ladrilhos, sem plataformas nem buracos (pedido do usuário). Os tipos `=` e `P` continuam disponíveis no gerador para depois. | Focar em andar, correr e pular. |
| Correr | **Dois toques rápidos na direção** e segurar (`janela_toque_duplo` = 0,25 s) = **Disparada do D&D (2× o deslocamento)**. Soltar ou inverter volta a andar. Lógica reutilizável em `ToqueDuplo`. | Escolha do usuário. |
| Animação de correr | **Provisória:** quadros do walk a 20 fps (animação `correr` em `heroi_frames.tres`). Trocar pela animação `run` do SpriteCook (~32 créditos) sem mexer no código. | Só sobraram 2 créditos. |
| Arquitetura do herói | `jogador.gd` = ferramentas de física + API pública. Comportamento na **máquina de estados** (`core/estados/`): estados `Parado`, `Andando`, `Correndo`, `NoAr` em `features/jogador/estados/`. Números em `data/jogador_padrao.tres` (`StatsJogador`). `AnimacaoJogador` e `CameraJogador` não conhecem o Jogador: ele chama `atualizar()`/`olhar_para()` (call down). | Skills godot-*. |
| Mudar balanceamento | `data/jogador_padrao.tres`: aceleração, pulo, toque duplo, buffer de ataque, dano sofrido. **Velocidade e ritmo de ataque NÃO ficam aqui:** vêm da ficha de D&D (deslocamento e iniciativa). | Dados separados do código. |
| Classe do herói | **Guerreiro (estilo D&D)**: espada (e futuramente escudo/outras armas). | Pedido do usuário. |
| Regras de D&D 5e | Classes puras em `core/regras/`: `Dado` ("1d6"), `Atributos` (mod = (valor-10)/2 p/ baixo), `CompraDePontos` (27 pts, 8 a 15, custos do livro), `Ficha` (vida e dano). Testes em `tests/teste_regras_dnd.gd`. | Testável sem abrir o jogo. |
| Vida | Nível 1 = **dado de vida máximo da classe + mod. CON** (Guerreiro d10, `data/classe_guerreiro.tres`). Mínimo 1. `HealthComponent`: dano, `vida_mudou`, `morreu`. | Regra do livro; usuário escolheu d10. |
| Dano | **Dados da arma + mod.** (`Dado` aceita "2d8+1"). Arma com `acuidade` usa o maior entre FOR e DES (espada curta: 1d6, acuidade). **Mínimo 1** por acerto. | Regra do livro; mínimo 1 é regra da casa. |
| Combate (D&D) | **d20 + bônus de ataque >= CA do alvo** acerta (`Combate.resolver_ataque`). **20 natural** = crítico (acerta sempre, dados de dano em dobro, bônus não). **1 natural** erra sempre. Quem ataca monta um `Golpe` (nome, bônus, dado); quem é atingido resolve contra a própria CA no `DefesaComponent`. Herói: ataque = +2 proficiência + mod da arma; **CA = 10 + DES** (sem armadura). Textos flutuantes: dano, "Errou!", "Crítico X!" (`TextoFlutuanteComponent`). | Escolha do usuário (fiel ao D&D). |
| Salvaguarda | `Combate.passou_salvaguarda(bonus, cd)`: d20 + bônus >= CD. Bônus = mod + proficiência se a classe/criatura for proficiente (Guerreiro: FOR e CON, em `ClasseRPG.salvaguardas_proficientes`). **Por enquanto só aparece na ficha** (nenhum efeito pede salvaguarda ainda). | Pedido do usuário. |
| Criaturas | Bloco de estatísticas do livro em `CriaturaRPG` (`core/dados/`), ex.: `data/gray_ooze.tres` (CA 9, PV 22 = média de 3d8+9, atributos, iniciativa −2, Pseudópode +3 / 2d8+1 **ácido** / 5 pés, 10 pés, Visão às Cegas 60 pés, **resistências** ácido/frio/fogo, **Forma Corrosiva** −1 por toque até −5). Ainda **não**: Amorfo e a corrosão de **armadura** (não há armadura). | Usar as criaturas do D&D em vez de inventar números. |
| Escala D&D | `EscalaDnd`: **5 pés = 1 ladrilho (32 px)**; **1 rodada = 1,5 s**. **Movimento = deslocamento da ficha**: herói 30 pés ≈ 128 px/s (correndo 256), Ooze 10 pés ≈ 43 px/s. **Ritmo de ataque = iniciativa em tiques**: intervalo = (10 − iniciativa) × 0,1 s, mínimo 3 tiques. Herói: iniciativa = mod. DES (+2 → 0,8 s); criatura: campo `iniciativa` da ficha (Ooze −2 → 1,2 s). O herói tem buffer de ataque (`tempo_buffer_ataque`). Ainda sem raças: deslocamento padrão 30 pés (`Ficha.DESLOCAMENTO_PADRAO_PES`). | Pedido do usuário. |
| Gray Ooze | `features/gray_ooze/`: estados Parado -> Perseguindo -> Atacando (janela 0,2-0,35 s) -> LevandoDano -> Morrendo. Arte: slime CC0 de **rvros**, recolorida de cinza por `tools/gerar_gray_ooze.gd` (créditos em `assets/CREDITOS.md`). Fica no grupo `monstros`; a `main` chama `definir_alvo(herói)` em todo monstro do grupo. | |
| Herói apanhando | Acerto -> estado `LevandoDano` (recuo `recuo_dano`, `tempo_recuo`) + **invencível piscando** por `tempo_invencibilidade` (dados em `StatsJogador`). Vida zerou -> sinal `caiu` -> a `main` mostra **"Você caiu!"** (`ui/derrota/`, pausa). **Tentar de novo**: `reviver()` (início, vida cheia) e os monstros são **recriados** como no começo. Sem ninguém escutando `caiu` (F6), revive sozinho. | Pedido do usuário. |
| Nome do jogo | **"DnD in a Piece"**, em `project.godot` (`application/config/name`); a tela de título lê de lá. "D&D" é marca da Wizards of the Coast: trocar o nome se um dia for publicar. | Pedido do usuário. |
| Início do jogo | `main`: **tela de título** (`ui/titulo/`: Novo Jogo, Sair) -> **criação** -> jogo. Título e criação pausam o jogo e escondem o HUD. `mostrar_inicio = false` pula tudo (testes). | Pedido do usuário. |
| Criação | `ui/criacao_personagem/`: **nome** (até 16 letras, obrigatório), **classe** (lista `classes_disponiveis` da `main`; hoje só Guerreiro) e atributos por **compra de pontos**. Botão com a sugestão da classe. INT, SAB e CAR ainda não fazem nada. | Pedido do usuário. |
| HUD | `ui/hud/`: "Nome (Classe)" e "PV atual/máximo". | |
| Itens | `Item` (`core/dados/item.gd`: nome, descrição, ícone, `espaco`). `Arma` é um `Item` do espaço `mao`. | Base para qualquer item. |
| Inventário | Regra pura `Inventario` (`core/regras/`): adicionar (capacidade 12), equipar (troca; o antigo fica na mochila), desequipar, **jogar fora = apaga** (desequipa antes). Item equipado continua na lista. O herói tem `inventario` e `itens_iniciais` (a espada começa na mochila, sem equipar). | Pedido do usuário. |
| Tela de inventário | `ui/inventario/`, tecla **I** (Esc também fecha), **pausa o jogo**. Lista, detalhes, Equipar/Desequipar/Jogar fora (com confirmação) e a ficha. Não conhece o herói: emite `abrir_pedido` e a `main` chama `abrir(...)`. Não abre durante a criação. | |
| Tipos de dano | `TiposDano` (`core/regras/`): contundente, cortante, perfurante, ácido, frio, fogo. **Espada Curta = perfurante** (igual ao livro), **soco = contundente**, Pseudópode = ácido. `Arma.tipo_dano`; o `Golpe` leva o tipo. **Resistência** (`DefesaComponent.resistencias`): dano pela metade, arredondado para baixo (pode dar 0); o texto mostra "(resistiu)". | Pedido do usuário. |
| Corrosão (armas) | Arma **não mágica** (`Arma.corroivel`) que causa dano no Ooze leva −1 no ataque (cumulativo) e é **destruída em −5**. O desgaste fica **no Inventario** (`penalidade`/`desgastar`), por item: o herói guarda **cópias** dos itens iniciais, e o `.tres` nunca muda. O alvo avisa pelo sinal `Golpe.arma_corroida`; quem decide o que acontece com a arma é o dono. O inventário mostra "Corroída: −X no ataque". | Regra da ficha do Ooze. |
| Proficiências | `Proficiencias` (`core/regras/`): armas **simples/marcial** e armaduras **leve/média/pesada/escudo**. `ClasseRPG.proficiencias_armas` e `treinamento_armaduras` (Guerreiro: tudo). `Arma.categoria` (Espada Curta = marcial; vazio = desarmado, sempre proficiente). **Arma sem proficiência: não soma o +2 de proficiência no ataque** (`Ficha.proficiente_com`). Criação mostra as proficiências da classe; o inventário avisa "Sem proficiência". | Regra do livro. |
| Armaduras | **21 armaduras** do Empório (PHB, Obojima, Northlands) em `data/armaduras/*.tres`, geradas por `tools/gerar_armaduras.gd` (**edite a TABELA, não os .tres**). `Armadura` (`core/dados/`): categoria, `ca_base`, `soma_destreza`, `max_destreza`, `forca_minima`, `desvantagem_furtividade`, cor e padrão visual. Espaços: **corpo** (armadura) e **mão secundária** (escudo). **CA** (`Ficha.classe_armadura`): sem armadura 10+DES; leve base+DES; média base+DES (máx.); pesada base; escudo +bônus (**só com treinamento**). **FOR abaixo do mínimo: −10 pés.** **Sem treinamento:** desvantagem nos testes de FOR/DES (= ataques; `Combate.rolar_d20` com desvantagem). **Furtividade:** só aparece (ainda não há testes de Furtividade). `Equipamento` (`core/regras/`) junta ficha + inventário (arma, armadura, escudo, CA, deslocamento, golpe) para herói e inventário calcularem igual. | Regras do livro; pedido do usuário. |
| Armadura inicial | `ClasseRPG.armaduras_iniciais` (Guerreiro: **Cota de Malha** ou **Couro Batido**); escolhida na criação e já vestida. A prévia mostra CA, deslocamento e o aviso de Força. | Pedido do usuário. |
| Armadura visível | Shader `assets/shaders/roupa_armadura.gdshader` no sprite do herói: troca a túnica azul pela cor da armadura mantendo luz e sombra, com padrão (malha, tachas, placas, acolchoado, escamas). Escudo: `EscudoJogador` na **mão de trás** (pontos de trás em `PontosMao`, marcados pela mesma ferramenta), desenhado atrás do corpo. Arte do escudo provisória por script. | Pedido do usuário. |
| Corrosão (armadura) | Pseudópode (`ataque_corroi_armadura`) que acerta: armadura não mágica perde 1 de CA (desgaste no Inventario) e **se desfaz quando a CA dela chega a 10**. | Regra da ficha do Ooze. |
| Desarmado | Mão vazia = `data/ataque_desarmado.tres` ("1d1" + FOR = soco de D&D, contundente, não sofre Corrosão, alcance curto, sem sprite de arma). | Regra do livro. |
| Ataque | Tecla **J** -> estado `Atacando`. No chão freia e fica firme; no ar continua caindo; não vira durante o golpe. | Peso de Guerreiro. |
| Arma = equipamento | `Arma` (`core/dados/arma.gd`) em `data/arma_*.tres`: dano, alcance, tempos da janela de acerto, ângulos e **textura**. A espada é um **sprite separado** girado pelo `AtaqueJogador`, então trocar de arma aparece na tela. | Equipamento visível sem redesenhar o herói. |
| Componentes de combate | `core/componentes/`: `HitboxComponent` (entrega um `Golpe`, 1x por alvo por golpe), `HurtboxComponent` (só emite `golpe_recebido`), `DefesaComponent` (CA, resolve, tira vida, `invulneravel`), `HealthComponent`, `TextoFlutuanteComponent`. Camadas: 1 `mundo`, 2 `jogador`, 3 `hurtbox_inimigo`, 4 `hurtbox_jogador`, 5 `inimigo`. | Reutilizável por herói, inimigos e boneco. |
| Pacotes prontos de personagem | **Não usar** para o herói (decisão do usuário: o equipamento fica "pintado" no sprite). Talvez em outros casos. | Equipamento visível. |
| Arte do golpe | Provisória por script: `assets/armas/espada_curta.png`, `assets/efeitos/corte.png` (+ `corte_frames.tres`). Pose do herói = quadros 2 e 3 do jump. | Grátis; trocar depois. |
| Arma na mão | A arma equipada fica **sempre na mão da frente**. `features/jogador/sprites/pontos_mao.tres` (`PontosMao`) guarda o ponto da mão em cada quadro de cada animação + o ângulo de descanso por animação. Gerado por `tools/marcar_pontos_mao.gd` (acha a mancha cor de pele mais à frente; quadros em que a mão some usam a média dos vizinhos). **Rode de novo sempre que mudar a arte do herói.** `AnimacaoJogador.ponto_da_mao()` -> `AtaqueJogador.seguir_mao()` todo quadro; o golpe gira a partir da mão. | Pedido do usuário. |
| Ângulo de descanso | ~35° (ponta para baixo e à frente). Mais que isso a lâmina (30 px) atravessa o chão. | |
| Câmera | `Camera2D` filha do herói, com suavização, olha à frente na direção em que ele corre; limites calculados pelo tamanho da fase | Ver o que vem pela frente. |
| Movimento suave | Interpolação de física ligada | Sem tremedeira em monitores de 144 Hz. |

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

## Estrutura de pastas
Regras na skill `godot-estrutura-pastas`. Hoje:
```
core/estados/            Estado, MaquinaEstados (genéricos)
core/componentes/        Hitbox, Hurtbox, Defesa, Health, TextoFlutuante (componentes de combate)
core/dados/              Item, Arma, Armadura, ClasseRPG, CriaturaRPG (Resources)
core/regras/             Dado, Atributos, CompraDePontos, Ficha, Inventario, Golpe, Combate, EscalaDnd,
                         TiposDano, Proficiencias, Equipamento
ui/titulo/               tela de título (DnD in a Piece)
ui/criacao_personagem/   tela de criação (nome, classe, compra de pontos)
ui/inventario/           tela de inventário (tecla I)
ui/hud/                  HUD (nome, vida)
ui/derrota/              tela "Você caiu!"
core/utilitarios/        ToqueDuplo
features/jogador/        jogador.tscn/.gd, stats_jogador.gd, animacao_jogador.gd,
						 camera_jogador.gd, ataque_jogador.gd, estados/, sprites/
features/boneco_treino/  boneco de treino (CA 10, mostra dano/Errou!, pisca e balança)
features/gray_ooze/      Gray Ooze (D&D): cena, estados/, sprites/
levels/                  main.tscn/.gd (cena principal), fase.gd, fase_teste.tscn
data/                    jogador_padrao, arma_espada_curta, ataque_desarmado, classe_guerreiro, gray_ooze (.tres), armaduras/
assets/tiles/            ladrilhos e TileSet (compartilhado)
assets/armas/, efeitos/, armaduras/, shaders/  armas, efeitos, escudos, shader da roupa
tools/                   gerar_arte_provisoria, gerar_fase_teste, gerar_armaduras, marcar_pontos_mao, gerar_gray_ooze, capturar_tela
tests/                   teste_*.gd, rodar_testes.ps1
```

## Convenções
- Os detalhes de estilo estão na skill `godot-estilo-gdscript`; abaixo ficam só os específicos do projeto.
- **Arquivos e funções:** `snake_case` (ex.: `jogador.gd`, `_atualizar_animacao()`).
- **Classes e nós:** `PascalCase` (ex.: `class_name Jogador`, nó `Sprite`).
- **Comentários e nomes do jogo em português.** Termos do Godot ficam em inglês.
- Balanceamento em Resources (`data/`); ajustes só visuais podem ficar em `@export` do componente.
- Ações de input: `mover_esquerda` (A, ←), `mover_direita` (D, →), `mover_baixo` (S, ↓), `pular` (Espaço, W, ↑), `atacar` (J), `inventario` (I).
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
# Rodar headless por ~3 s só para ver erros no log.
# --debug é OBRIGATÓRIO: sem ele, os avisos de GDScript (ex.: UNUSED_SIGNAL) não aparecem,
# mas o editor mostra. O tests/rodar_testes.ps1 já usa --debug.
& $env:GODOT_EDITOR_PATH --headless --debug --path C:\Jogos\rpg --quit-after 180
# Regerar a arte provisória (ladrilhos) e depois a fase de teste
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --script res://tools/gerar_arte_provisoria.gd
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --import
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --script res://tools/gerar_fase_teste.gd
# Remarcar o ponto da mão (depois de mudar a arte do herói); o argumento salva uma folha de revisão
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --script res://tools/marcar_pontos_mao.gd -- C:/caminho/revisao.png
# Tirar um print segurando teclas (precisa de janela; sem --headless). Opções: inicio, equipar
& $env:GODOT_EDITOR_PATH --path C:\Jogos\rpg --script res://tools/capturar_tela.gd -- mover_direita 40 C:/caminho/print.png equipar
```
**Atenção:** depois de criar um `class_name` novo, rode `--import` antes de qualquer script de `tools/`.
Se um script de ferramenta tiver erro e for rodado com `--debug`, o Godot fica parado no depurador (não termina):
rode as ferramentas sem `--debug`.
```powershell
```

## Como rodar os testes
Cada teste é um script `tests/teste_*.gd` que estende `SceneTree`, imprime `PASSOU`/`FALHOU` e sai com código 0 ou 1.
Rodar **tudo** (importa, roda o jogo procurando erros/avisos e roda todos os testes):
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Jogos\rpg\tests\rodar_testes.ps1
```
Um teste só:
```powershell
& $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --script res://tests/teste_jogador.gd
```

## Estado atual
- Fatias 1 e 2 (2.5D): boneco na relva e herói do SpriteCook. Substituídas pela fatia 3.
- Fatia 3: herói andando e pulando numa fase de teste em 2D lateral.
- Fatia 4: skills de código limpo, corrida com dois toques (animação provisória), fase reta, herói refatorado em física + componente visual.
- Skills godot-* criadas e código migrado: novas pastas, máquina de estados do herói, `StatsJogador` em `data/`, sem `get_parent()`, fase com API própria.
- Fatia 5: golpe de espada (J) no chão e no ar, arma como dado e sprite separado, Hitbox/Hurtbox, boneco de treino. Tentativa de usar pacote pronto (Hero Knight) foi cancelada e limpa.
- Fatia 6a: ficha de D&D (compra de pontos, vida d10 + CON, dano 1d6 + FOR/DES), tela de criação, HUD de vida.
- Fatia 6b: inventário (Item, Inventario, tela com I), espada começa na mochila, soco desarmado.
- Fatia 6c: espada equipada sempre na mão (ponto da mão por quadro), golpe girando a partir da mão.
- Fatia 7: tela de título "DnD in a Piece", criação com nome e classe, nome no HUD e no inventário.
- Fatia 8: combate de D&D (d20 contra CA, crítico, salvaguardas na ficha), Gray Ooze com a ficha do livro, herói leva dano/recua/pisca/reaparece.
- Ajuste: movimento pelo deslocamento de D&D e ritmo de ataque pela iniciativa (tiques).
- Fatia 9: "Você caiu!" com Tentar de novo; tipos de dano (espada perfurante, soco contundente, Pseudópode ácido); resistências do Ooze; Corrosão da arma.
- Proficiências de armas (efeito no ataque) e de armaduras (só na ficha da classe por enquanto).
- Fatia 10: 21 armaduras + escudos com as regras do livro, escolha na criação, armadura visível no herói, corrosão de armadura.
- Próximas ideias: como obter as outras armaduras (baú/loja); testes de Furtividade; usar salvaguarda em algum efeito; Cimitarra/Espada Longa (cortantes).
- Pendências pequenas: sinais `pulou`/`reapareceu` do herói sem ouvinte; "arma na mão ou desarmado" está em 2 lugares (Jogador e TelaInventario) — extrair se aparecer um 3º.
