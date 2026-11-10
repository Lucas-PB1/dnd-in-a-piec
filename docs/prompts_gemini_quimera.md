# Prompts do Gemini: Quimera (chefe final, fase 10, Covil)

Ficha do livro (Monster Manual 2024, `Chimera`, conferida no Códice) e como entra no jogo em `docs/decisoes/criaturas.md`
(seção da Quimera, quando for implementada).

**Quimera** · Monstruosidade Grande, Caótica e Má · **ND 6 (2.300 XP)** · CA 14 · **PV 114 (12d10+48)** · 30 pés, voo 60 pés ·
FOR 19 DES 11 CON 19 INT 3 SAB 14 CAR 10 · Percepção +8 (passiva 18) · Visão no Escuro 60 pés · iniciativa +0.
- **Ataques Múltiplos:** Cabeçada + Mordida + Garra; pode trocar a Garra pelo Sopro de Fogo, se disponível.
- **Mordida:** +7, 5 pés, 2d6+4 perfurante (4d6+4 se o ataque teve vantagem).
- **Garra:** +7, 5 pés, 1d6+4 cortante.
- **Cabeçada:** +7, 5 pés, 1d12+4 contundente; derruba o alvo Médio ou menor (o herói cai).
- **Sopro de Fogo (Recarga 5-6):** Cone de 15 pés, salvaguarda de Destreza CD 15, 7d8 de fogo (metade se passar).

## Estilo e escala
Estilo de **chefe**: pixel art sombria e realista (não chibi; a primeira tentativa chibi saiu "infantil" e foi descartada),
de lado olhando para a direita, contorno escuro, paleta escura e fosca. Na **base**, anexe como referência a base do
Minotauro e a do Wight. Nas **tiras**, anexe só a **base da Quimera aprovada** (a versão sombria, com juba marrom-ferrugem,
cabeça de bode preta, cauda verde-escura e asas rasgadas).
Escala: Grande, bem maior que o herói (o Minotauro tem uns 4 ladrilhos de altura); a Quimera é de quatro patas, então fica
mais **comprida do que alta**: uns 3 ladrilhos de altura da pata ao topo das cabeças e 4 de comprimento.

## Parte comum (já incluída em cada prompt)
"Pixel art game sprite of a boss monster, single creature, full body, side view facing right, dark 1-pixel outline,
limited palette of at most 24 colors, dark moody palette, shaded with 4 tones, clean hard pixel edges (no anti-aliasing,
no blur, no gradients), plain solid light-gray background, no shadow on the ground, no text, no border, centered.
Realistic dark-fantasy proportions, a heavy, battle-scarred, dangerous look, NOT cute, NOT chibi, NOT cartoon."
Se sair fofa de novo, acrescente: "menacing, gritty, grim, like a boss from a dark fantasy game such as Dark Souls or
Castlevania, no smiling, no rounded cartoon shapes".

## 1. Base (pose parada) — APROVADA
"[Parte comum] A chimera, a large four-legged monster made of three animals: the body and front head of a muscular lion,
snarling with bared fangs, a ragged dark mane in dull brown and rust, glowing red eyes, scars across the muzzle and flank;
a second goat head with two long curved horns growing from the middle of its back, black fur, glowing red eyes, mouth
slightly open; and a long scaly serpent-like tail that ends in a small dragon head with open jaws and a faint orange glow
in the throat. Torn, leathery bat-like dragon wings on its back, half folded. Lion paws with long dark claws, goat hooves
on the back legs. Dull tawny fur, charred black patches, dark green scales on the tail, muted colors, a hint of embers.
Powerful, hunched, predatory stance, head lowered. Large and heavy, about 4 times as wide as a human."
(Fonte aprovada: anexe o PNG dessa base nas tiras. Salve-o em `features/quimera/sprites/fonte_gemini/quimera_base_gemini.png`.)

## Tiras (uma por pedido, anexando a base aprovada)
Frase comum das tiras: "Sprite sheet strip, N frames side by side in ONE horizontal row, same creature as the attached
base image (same colors, three heads, wings, proportions, dark realistic style, NOT cute, NOT chibi), side view facing
right, every frame the same size
and scale, feet on the same baseline, plain solid light-gray background, no shadows, no text, no frame borders, clean hard
pixel edges, no anti-aliasing."

- **parado (4):** "[comum] 4-frame idle, slow heavy breathing, lion mane moving, goat head chewing, dragon tail head swaying
  slowly, wings twitching."
- **andar (6):** "[comum] 6-frame prowling walk cycle, four legs in a heavy stalking stride, heads bobbing, tail swaying."
- **ataque (7):** "[comum] 7-frame triple melee attack: frame 1 stands, frame 2 lowers the goat head and rears back, frame 3
  rams forward with the goat horns (headbutt), frame 4 snaps the lion jaws forward (bite), frame 5 swipes with a front
  claw, frame 6 holds, frame 7 recovers."
- **sopro (6):** "[comum] 6-frame fire breath: frame 1 stands, frame 2 rears the dragon-head tail forward over the back and
  inhales (glowing mouth), frame 3 the mouth opens wide with a bright orange glow, frame 4 a cone of orange-yellow flames
  bursts forward from the dragon head, frame 5 the flames at full size, frame 6 recovers. Flames are part of the frames."
- **cabecada (5):** "[comum] 5-frame headbutt charge: stands, crouches low with the goat head down and horns forward, springs
  forward in a short lunge, the horns strike at full extension, recovers." (o golpe que derruba o herói, usado também na
  investida; pode ser a mesma tira de `ataque` se quiser economizar um pedido)
- **voo (4, opcional):** "[comum] 4-frame hover: the bat-like wings open wide and flap, legs tucked, body slightly raised,
  all three heads facing forward."

## Versão final dos prompts (a que funcionou)
As tiras `parado`, `andar`, `ataque`, `sopro`, `pular` e `voar` já estão salvas em `fonte_gemini/` (`quimera_<nome>_gemini.png`).
O que fez as tiras darem certo: **lacuna larga entre os quadros** ("LARGE EMPTY GAP", nada de um quadro toca o vizinho),
**corpo plantado** quando o ataque não move o corpo ("body and all four feet stay planted, never rears up or jumps, no dust"),
**cauda igual em todos os quadros**, e descrever **um quadro por vez**.

Bloco comum: "Sprite sheet strip, N frames in ONE horizontal row, very wide image, each frame inside its own equal cell with a
LARGE EMPTY GAP of plain background between creatures (nothing of one frame may touch or overlap the next, the tail and all
heads stay inside their own cell), same creature as the attached base image (same colors, three heads, wings, proportions,
dark realistic style, NOT cute, NOT chibi), side view facing right, every frame the same size and scale. Plain solid
light-gray background, no shadows, no text, no frame borders, clean hard pixel edges, no anti-aliasing."

- **morte (6):** [bloco comum, N=6] "The long green tail with the dragon head follows the body in every frame. No dust, no
  effects. 6-frame death: Frame 1: standing. Frame 2: staggers back, all three heads thrown back in pain, eyes shut. Frame 3:
  the front legs buckle, the body sinks. Frame 4: collapses onto its side. Frame 5: lying on its side on the ground, wings
  spread limp, heads down. Frame 6: lying motionless, eyes dark, tail limp, a few embers."
- **levando dano (3):** [bloco comum, N=3] "The body and all four feet stay planted in the same position. Frame 1: the heads
  jerk back, eyes shut, mouths open in pain. Frame 2: the body is pushed back slightly, the wings flinch. Frame 3: recovering,
  heads lowering again, snarling."
- **rugido de entrada (5):** [bloco comum, N=5] "The body and all four paws stay planted on the ground, it never rears up. The
  tail with the dragon head stays curled in the same shape. Frame 1: standing. Frame 2: the chest swells, heads lowered,
  inhaling. Frame 3: all three heads thrown up with the mouths wide open roaring, the wings spread wide. Frame 4: holds the
  roar, a few embers around the heads. Frame 5: back to standing."
- **caído:** sem tira nova; usa os quadros 4 e 5 da morte (e a ordem inversa para levantar).

## Depois que o Gemini gerar
1. Salve cada PNG sem editar em `features/quimera/sprites/fonte_gemini/` e diga os caminhos.
2. A IA roda `tools/montar_tiras_gemini.gd` (tira o fundo, separa os quadros, iguala a escala e alinha os pés) e
   `tools/montar_frames_gemini.gd` (gera o `quimera_frames.tres`), como no Hobgoblin; mostra a prévia ao lado do herói e do
   Minotauro para aprovar a escala.
