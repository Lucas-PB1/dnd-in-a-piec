# Prompts do Gemini: minions novos (Hobgoblin, Bugbear, Kobold)

Estilo de referência: a base do Goblin Warrior (`features/goblin/sprites/warrior_base_spritecook.png`):
pixel art de personagem inteiro, de lado (olhando para a direita), contorno escuro, poucas cores,
proporção levemente "chibi", fundo liso.

**Como usar:** cole um prompt por vez no Gemini **junto com a imagem de referência do Goblin Warrior**
(anexe o PNG). Peça 1 imagem por vez. Salve cada resultado como PNG e diga onde está.
Fichas do livro: `docs/decisoes/criaturas.md`.

## Parte comum (já incluída em cada prompt)
"Pixel art game sprite, single character, full body, side view facing right, standing idle pose,
dark 1-pixel outline, limited palette of at most 16 colors, flat shading with 3 tones, clean hard pixel
edges (no anti-aliasing, no blur, no gradients), plain solid light-gray background, no shadow on the
ground, no text, no border, centered. Chibi proportions exactly like the attached reference (a goblin warrior): oversized head about one third of the total height, short thick legs, simple readable shapes, few big details (no tiny armor plates or fine textures). Match its style, outline and shading."

## 1. Hobgoblin Warrior (Medium, soldado disciplinado)
"[Parte comum] A hobgoblin warrior: orange-red skin, broad shoulders, flat pointed ears, black hair
tied back, wearing half-plate armor in dull steel and a round shield on the left arm, holding a
longsword in the right hand. Disciplined soldier look, stern face. About 1.3 times taller than the
reference goblin."

## 2. Bugbear Warrior (Medium, grandalhão de braços longos)
"[Parte comum] A bugbear warrior: hulking, hunched, long muscular arms, shaggy brown fur on shoulders
and head, small dark eyes, wide jaw, wearing a hide armor vest, holding a light hammer in the right
hand and two more hammers on the belt. Menacing but a bit clumsy look. About 1.6 times taller than
the reference goblin and much wider."

## 3. Kobold Warrior (Small, dragãozinho covarde)
"[Parte comum] A kobold warrior: small reptilian dragon-like humanoid, rust-red scales, a short snout
with small horns, a thin tail, big yellow eyes, wearing a scrap cloth tunic, holding a dagger in the
right hand and two more daggers on the belt. Cowardly, scheming look. About 0.8 times the height of
the reference goblin."

## Depois que o Gemini gerar
1. Salve o PNG sem editar e diga o caminho.
2. A IA reduz para o grid de pixel, tira o fundo e limita a paleta (script em `tools/`), e mostra ao lado
   do Goblin Warrior e do herói para aprovar a escala.
3. Se aprovado: arte parada + animação por código (balanço, golpe, dano piscando) ou, se quiser, anima
   no SpriteCook a partir dessa base (20 a 1ª animação, 14 cada extra).

## Lição do 1º teste (Hobgoblin)
O 1º Hobgoblin do Gemini (`features/goblin/sprites/fonte_gemini/hobgoblin_gemini.png`) saiu com proporção
realista (cabeça pequena, corpo alto) e não combinou com o herói e o Goblin, que são chibi. Por isso os prompts
agora pedem chibi e formas simples. Ferramenta de limpeza e comparação: `tools/limpar_arte_gemini.gd`.

## Hobgoblin: arte ligada ao jogo (fluxo que deu certo)
1. Gemini gera a base chibi e 4 tiras (andar 6, golpe 5, parado 4, arco 5), todas olhando para a direita, fundo liso.
2. `tools/montar_tiras_gemini.gd` tira o fundo (inclusive o vazio dentro do arco), separa os quadros, iguala a escala
   (cabeça aos pés = 56 px) e alinha os pés num quadro comum de 69x62. Saída: `fonte_gemini/previa/`.
3. As tiras são copiadas para `features/goblin/sprites/hobgoblin_*.png` e `tools/montar_frames_gemini.gd` gera
   `hobgoblin_frames.tres` (`dano` repete o 1º quadro do parado; a cena já treme e pisca por código).
4. Tempos: golpe 12 fps (acerto 0,15–0,3 s), arco 10 fps (flecha solta em 0,25 s).
Bugbear e Kobold repetem o fluxo; os dois arremessam, então pedem também uma tira de `arremessar`.

## Roteiro por criatura (o que funcionou no Hobgoblin)
Sempre **anexe o Hobgoblin chibi aprovado** (`fonte_gemini/hobgoblin_chibi_gemini.png`) e o Goblin Warrior como
referência de estilo. Ordem: 1) base parada; 2) aprovar; 3) as tiras, uma por pedido, **anexando a base aprovada**.

Frase comum das tiras: "Sprite sheet strip, N frames side by side in ONE horizontal row, same character as the attached
base image (same colors, outfit, proportions, chibi style), side view facing right, every frame the same size and scale,
feet on the same baseline, plain solid light-gray background, no shadows, no text, no frame borders, clean hard pixel
edges, no anti-aliasing."

### Bugbear Warrior: tiras
- **andar (6):** "[comum] 6-frame walk cycle, hunched heavy stride, long arms swinging, hammer in the right hand."
- **golpe (5):** "[comum] 5-frame melee attack: frame 1 stands, frame 2 winds up with both long arms pulled back, frame 3 lunges
  forward with both arms stretched out to grab (the 'grab' attack), frame 4 holds, frame 5 recovers."
- **parado (4):** "[comum] 4-frame idle, slow heavy breathing, shoulders rising and falling, hammer in hand."
- **arremessar (5):** "[comum] 5-frame throw: frame 1 stands holding a light hammer, frame 2 raises the hammer behind the head,
  frame 3 throws it forward (arm fully extended), frame 4 follow-through, frame 5 recovers. No hammer flying in the frames."

### Kobold Warrior: tiras
- **andar (6):** "[comum] 6-frame quick scurrying run, hunched, tail swaying, dagger in the right hand."
- **golpe (5):** "[comum] 5-frame dagger stab: stands, pulls the dagger back, stabs forward, holds, recovers."
- **parado (4):** "[comum] 4-frame idle, nervous fidgeting, tail twitching, dagger in hand."
- **arremessar (5):** "[comum] 5-frame dagger throw: stands, raises the dagger behind the head, throws forward, follow-through, recovers.
  No dagger flying in the frames."

Montagem (igual ao Hobgoblin): `tools/montar_tiras_gemini.gd` (altura do corpo em px da arte, uma tira por
animação) e `tools/montar_frames_gemini.gd` (gera o `*_frames.tres`; `arremessar` toca como o `disparar` do Hobgoblin).

## Bugbear: arte ligada ao jogo
- Base chibi + 4 tiras (andar 6, golpe de agarrar 5, parado 4, arremessar 5), corpo de 62 px de arte, quadro 67x66.
- `tools/montar_tiras_gemini.gd` agora também tira a **franja clara** da borda (`FerramentasPixel.limpar_franja`).
- Cena `bugbear_guerreiro.tscn`: `arremessar` toca no arremesso do martelo (o projétil ainda é o da adaga),
  janela do agarrão 0,15–0,35 s, martelo sai em 0,25 s.

## Kobold: arte ligada ao jogo
- Base chibi + 4 tiras (andar 6, golpe 6, parado 4, arremessar 5), corpo de 40 px de arte, quadro 53x41.
- `tools/limpar_arte_gemini.gd` aceita um 5º argumento (altura da arte nova na comparação) e a prévia de
  `tools/montar_tiras_gemini.gd` deixa a última linha (herói) mais alta que as outras.
- Cena `kobold_guerreiro.tscn`: estocada 0,14–0,36 s, adaga arremessada solta em 0,2 s.
