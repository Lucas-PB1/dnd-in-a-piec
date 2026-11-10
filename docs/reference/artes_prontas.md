# Artes prontas: onde buscar e como usar

Guia para trazer arte de terceiros para o **DnD in a Piece** sem quebrar o estilo, a licença
nem a organização do projeto. Tudo o que já foi usado está em `assets/CREDITOS.md`.

---

## 1. Onde buscar

| Site | Bom para | Dica de busca |
|---|---|---|
| **OpenGameArt** (opengameart.org) | Personagens, monstros, ícones, armas | Filtre por licença **CC0**. Coleções úteis: *2D::Sprite::Sidescroll*, *CC0 Walk Cycles*, *Pixel Art - Characters*. |
| **itch.io** (itch.io/game-assets/free) | Pacotes de monstros e cenários mais completos | Busque "pixel art", "side view", "platformer", e filtre *Free*. Leia a licença na página: varia muito. |
| **Kenney** (kenney.nl) | Interface, ícones, ladrilhos | Tudo CC0. Estilo mais "limpo": combina melhor com menus que com personagens. |
| **SpriteCook** (plugin do projeto) | Arte sob medida, no estilo do herói | Custa créditos (ver a seção 6). Use quando nada pronto servir. |

Autores que já combinaram com o jogo:
- **Idylwild** (OpenGameArt): Arsenal, Armory e Aerial Arsenal (armas, armaduras, armas à distância).
- **rvros** (itch.io): slime (Gray Ooze).
- **thekingphoenix** (OpenGameArt): goblin.

Comece pelos outros pacotes desses autores: o estilo já combina.

## 2. Licença: o que pode e o que não pode

| Licença | Pode usar? | O que fazer |
|---|---|---|
| **CC0** (domínio público) | Sim, a preferida | Anotar em `assets/CREDITOS.md` mesmo assim (cortesia e controle). |
| **CC-BY** (3.0 / 4.0) | Sim | Crédito **obrigatório** em `assets/CREDITOS.md` e, um dia, numa tela de créditos do jogo. |
| **CC-BY-SA** | Evitar | Obriga a liberar as versões modificadas na mesma licença. |
| **GPL / OGA-BY** | Evitar | Regras complicadas para um jogo fechado. |
| **NC** (não comercial) | Não | Impede vender o jogo um dia. |
| "Free" sem licença escrita | Não | Sem licença não há permissão. Pergunte ao autor ou procure outro. |

Também não serve arte que copia personagens, cenários ou o visual de jogos existentes,
mesmo que esteja "liberada": o jogo é original.

## 3. Como saber se combina com o jogo

Antes de baixar, confira na prévia:

- **Visão de lado** (*side view*). Arte de cima (*top-down*) ou isométrica não serve para personagens.
- **Pixel art com contorno escuro**, como o herói e as armas do Idylwild.
- **Tamanho**: o jogo roda em 640x360 com ladrilhos de 32x32. O herói tem uns 73 px de altura.
  - Criatura **Pequena** (goblin): uns 50-56 px. Uma arte de 32x32 ampliada 2x fica certa.
  - Criatura **Média**: 64-80 px.
  - **Grande**: dois ladrilhos de largura ou mais.
  - Ícones de menu: **16x16**. Armas na mão: os ícones de 32x32 do Idylwild.
- **Animações mínimas para um inimigo**: parado, andar ou correr, atacar e morrer. Animação de dano é bônus: sem ela, o código faz o inimigo piscar.
- A arte deve **olhar para um lado só** (direita ou esquerda): o jogo espelha.

## 4. Baixar

1. **Peça permissão** ao usuário antes, dizendo o nome dos arquivos, a fonte e o tamanho.
2. Baixe só o que for usar (ex.: só as versões "right", não as "left").
3. Guarde o **original** numa pasta `fonte_<pacote>/` ao lado da arte final
   (ex.: `assets/armas/fonte_aereo/`). Assim dá para regerar tudo depois.
4. Anote o crédito em `assets/CREDITOS.md`: arte, autor, link, licença, onde está.

## 5. Onde colocar (skill `godot-estrutura-pastas`)

| O que é | Pasta |
|---|---|
| Arte de **uma** feature (inimigo, herói) | `features/<nome>/sprites/` |
| Arte **compartilhada** (armas, armaduras, efeitos, ladrilhos) | `assets/<tipo>/` |
| Resources que usam a arte (`.tres` de armas, criaturas) | `data/` |
| Script que converte ou monta a arte | `tools/gerar_<nome>.gd` |

## 6. Como usar no Godot

### 6.1 Formato
- O Godot **não lê GIF**. Converta cada GIF numa **tira PNG** (um quadro ao lado do outro,
  todos do mesmo tamanho). Foi assim no goblin: quadros de 48x32, com o ataque mais largo por causa da lança.
  - No Windows, o PowerShell faz isso com `System.Drawing` (`SelectActiveFrame` em cada quadro).
  - O atraso de cada quadro do GIF diz o fps (10 centésimos = 10 fps).
- Depois de pôr PNGs novos:
  ```powershell
  & $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --import
  ```
- O projeto já importa PNG **sem perdas, sem mipmaps e com filtro Nearest** (pixel nítido).
  Não mude isso.

### 6.2 Animações (SpriteFrames)
- **Não monte à mão no editor.** Faça um script em `tools/` que lê as tiras e salva o
  `SpriteFrames` (`.tres`). Exemplos: `tools/gerar_goblin.gd`, `tools/gerar_gray_ooze.gd`.
  - Tabela `ANIMACOES`: nome -> quantidade de quadros, fps, repete.
  - Nomes usados pelos inimigos: `parado`, `andar` ou `correr`, `atacar`, `dano`, `morrer`.
- Rodar (sem `--debug`):
  ```powershell
  & $env:GODOT_EDITOR_PATH --headless --path C:\Jogos\rpg --script res://tools/gerar_goblin.gd
  ```

### 6.3 Encaixe na cena
- A **origem do nó fica nos pés** da criatura. O gerador do goblin imprime o retângulo
  usado no 1º quadro: com ele, calcule o `offset` do `AnimatedSprite2D`.
  - `offset = (centro do quadro) - (ponto dos pés na arte)`.
  - Goblin: quadro 48x32, pés no meio do corpo em (13, 32), então `offset = (24-13, 16-32) = (11, -16)`.
- **Ampliação**: `scale = (2, 2)` para arte de 32 px.
- **Espelhar**: use `sprite.scale.x = escala * direcao` quando o `offset` não for zero
  (o `flip_h` não espelha o `offset`). Se o corpo estiver no meio do quadro, `flip_h` serve
  (é o caso do Gray Ooze).
- Ajuste as formas de colisão (corpo, alvo e golpe) ao tamanho do corpo, não ao do quadro.

### 6.4 Armas e armaduras (ícones)
- Os ícones do Idylwild vêm **na diagonal**. O gerador guarda `angulo_arte` e `pegada`
  (onde a mão segura) em cada `Arma`, e o `DesenhoArma` gira a arte.
- **Edite a TABELA do gerador, não os `.tres`**: `tools/gerar_armas.gd` e `tools/gerar_armaduras.gd`.
- Ícone de menu 16x16: `FerramentasPixel.reduzir` (escolhe o pixel de luz mediana em cada
  bloco, para as hastes finas não sumirem).
- Mudou a arte do herói? Rode de novo `tools/marcar_pontos_mao.gd` (ponto e camada da mão).

### 6.5 Arte do herói ou de uma pose que falta
- Às vezes dá para **montar** uma pose com pedaços que já existem, como a pose de mira
  (`tools/montar_pose_mira.gd`: tronco de um quadro do pulo + pernas do parado).
  Prefira isso a gerar arte nova.

## 7. SpriteCook (quando nada pronto serve)

- **Custa créditos**: avise o custo e espere o ok.
  - Personagem base: 12.
  - 1ª animação da rodada: 20; cada extra na mesma rodada: 14.
  - Preparo de pose (walk/run): 12.
- Gere novas animações do herói **a partir do asset dele** (`b484dd94-...`), não um personagem novo.
- Registre todo asset gerado no `spritecook-assets.json` (asset_id + sha12).
- Chamadas longas podem estourar o tempo: use `wait_seconds = 0` e acompanhe pelo `run_id`.

## 8. Conferir no jogo

1. Rode os testes:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Jogos\rpg\tests\rodar_testes.ps1
   ```
2. Tire um print com a arte nova (`tools/capturar_tela.gd`, com janela, sem `--headless`) e confira:
   - os pés estão no chão;
   - o tamanho está certo perto do herói;
   - a arte vira para o lado certo;
   - o golpe sai da mão.
3. Inimigo novo: entre na lista **Trazer** da tela de comandos (`levels/main.gd`,
   `_cenas_criaturas`) para testar sem mexer no mapa.

## Checklist rápido

- [ ] Licença CC0 (ou CC-BY com crédito) conferida na página do pacote
- [ ] Visão de lado, pixel art com contorno, tamanho compatível
- [ ] Permissão para baixar (arquivos, fonte, tamanho)
- [ ] Original em `fonte_<pacote>/`, crédito em `assets/CREDITOS.md`
- [ ] GIF convertido em tira PNG; `--import`
- [ ] SpriteFrames gerado por script em `tools/`
- [ ] Origem nos pés, `offset` e escala certos, espelhamento testado
- [ ] Testes passando e print conferido
