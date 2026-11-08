# Pedidos do SpriteCook (gerado)

Gerado de `docs/spritecook/prompts.json` por `tools/conferir_prompts_spritecook.ps1`. **Edite o .json, não este arquivo.**
Cada pedido está em inglês (é o que o motor entende melhor). Os campos 'Conferir' são para olhar o resultado antes de integrar.

## Como pedir

- **Animações do herói:** `generate_character_animations` com o personagem `b484dd94-593b-4f7b-a97a-0786ac93147d`, `perspective=platformer`, `custom_animations` com `label`, `prompt`, `source_view` e `output_frames`, e `negative_prompt` quando a ferramenta aceitar. Os itens da mesma rodada vão **juntos numa chamada** (20 + 14 + 14...).
- **Monstros:** primeiro `generate_character` (12) com o prompt da base; só anime se a base ficar boa. Presets (parado, andar, dano, morte) usam `animation_ids`; os golpes usam `custom_animations`.
- **Efeitos:** `generate_game_art` com `model=pixel-engine-image-v1` (64x64, 6 créditos), depois `animate_game_art` (20).
- Antes de gerar: `get_credit_balance`. Depois de gerar: salvar o `asset_id` no `spritecook-assets.json`.

## Custo por rodada (calculado)

| Rodada | Itens | Custo | Prioridade |
|---|---|---|---|
| heroi_essencial | 3 | 48 | 1 |
| heroi_extras | 3 | 48 | 0 |
| goblin_minion | 7 | 114 | 1 |
| goblin_warrior | 7 | 114 | 1 |
| gray_ooze | 6 | 88 | 0 |
| efeitos (16 x 26) | 16 | 416 | 2 e 3 |

Prioridade 0 = opcional (extras do herói e Gray Ooze, que já tem arte CC0).

## heroi_essencial

_Herói: golpe de cima, dano e morte numa rodada só (a 1ª custa 20, as outras 14)._

### h_corte_cima: Herói: corte de cima

- Tipo: animação personalizada, 8 quadros, prioridade 1.

**Enviar assim** (as proibições vão dentro do texto, porque `custom_animations` ignora `negative_prompt`):

```
The young adventurer in side view facing right, feet planted on the same ground line, same camera angle. Frames 1-2: the right fist, gripping an invisible sword hilt, lifts up and back above the head while the torso leans back and the knees bend. Frames 3-4: the body snaps forward and the arm swings down in a heavy diagonal arc across the body, shoulders and hips driving the swing, the front foot pressing into the ground. Frames 5-6: a short follow-through with the arm extended low in front, the backpack and messy hair bouncing. Frames 7-8: recover smoothly to the starting standing pose. Hands only, nothing drawn in the hand, no effects. Keep the same outline, colors and proportions in every frame. Strictly avoid: weapon, sword, turning around, back view, facing the camera, extra limbs, motion lines, speed effects, text.
```

Conferir no resultado:

- [ ] Corpo sempre de lado, virado para a direita (nenhum quadro de costas ou de frente).
- [ ] Braço sobe atrás da cabeça nos quadros 1-2 e desce na diagonal nos 3-4 (o acerto do jogo cai nos quadros 3-5).
- [ ] Nada desenhado na mão, sem linhas de movimento.
- [ ] Último quadro volta à pose parada.

> O 1º teste (mãos vazias) saiu como soco. Aqui o pedido é 'segurando um cabo invisível'; se vier soco de novo, repetir com 'both hands gripping' no lugar.

### h_dano: Herói: levar dano

- Tipo: animação personalizada, 8 quadros, prioridade 1.

**Enviar assim** (as proibições vão dentro do texto, porque `custom_animations` ignora `negative_prompt`):

```
The young adventurer in side view facing right, feet planted on the same ground line, same camera angle. Frames 1-2: a sudden hit, the head and shoulders snap backward, the torso arches and the arms lift slightly from the hips. Frames 3-4: the knees bend and he staggers one small step backward while the backpack swings forward. Frames 5-6: he steadies his feet and straightens up. Frames 7-8: settle smoothly back into the starting standing pose. No effects, no impact stars, no text. Keep the same outline, colors and proportions in every frame. Strictly avoid: turning around, back view, facing the camera, extra limbs, impact stars, blood, motion lines, text.
```

Conferir no resultado:

- [ ] Cabeça e ombros para trás nos quadros 1-2.
- [ ] Um pequeno passo para trás (pés não deslizam).
- [ ] Sem estrelas nem sangue.
- [ ] Volta à pose parada no fim.

### h_morte: Herói: morte (cair)

- Tipo: animação personalizada, 12 quadros, prioridade 1.

**Enviar assim** (as proibições vão dentro do texto, porque `custom_animations` ignora `negative_prompt`):

```
The young adventurer in side view facing right, same camera angle, on the same ground line. Frames 1-3: struck hard, the head snaps back, the arms fling outward and the torso arches. Frames 4-6: the knees buckle and he drops down onto his knees with his head hanging. Frames 7-9: he topples backward onto the ground, the backpack landing first. Frames 10-12: he lies flat on his back on the ground line, motionless, the last frame held perfectly still. No effects, no blood, no text. Keep the same outline, colors and proportions in every frame. Strictly avoid: turning around, facing the camera, extra limbs, blood, ghost, halo, motion lines, text.
```

Conferir no resultado:

- [ ] Cai para trás e termina deitado, imóvel, na linha do chão.
- [ ] O último quadro (12) é um quadro parado.
- [ ] Sem sangue, fantasma ou efeito.
- [ ] O corpo cabe no quadro de 80x80.

> 12 quadros custam o mesmo que 8. Se o quadro 12 não ficar parado, o jogo segura o último quadro por código.

## heroi_extras

_Herói: poses de cura, Surto de Ação e rolar._

### h_cura: Herói: Fôlego (cura)

- Tipo: animação personalizada, 8 quadros, prioridade 0.

**Enviar assim** (as proibições vão dentro do texto, porque `custom_animations` ignora `negative_prompt`):

```
The young adventurer in side view facing right, feet planted on the same ground line, same camera angle. Frames 1-2: he inhales deeply, the chest rises and the shoulders lift. Frames 3-5: both fists clench at the hips, the head tilts up and he exhales strongly while the body straightens with determination. Frames 6-8: he relaxes and settles back into the starting standing pose. No glow, no effects, no text. Keep the same outline, colors and proportions in every frame. Strictly avoid: turning around, back view, facing the camera, extra limbs, glow, sparkles, text.
```

Conferir no resultado:

- [ ] Respira fundo e solta, sem brilho (o brilho é feito por código).
- [ ] Sempre de lado, à direita.

### h_surto: Herói: Surto de Ação

- Tipo: animação personalizada, 8 quadros, prioridade 0.

**Enviar assim** (as proibições vão dentro do texto, porque `custom_animations` ignora `negative_prompt`):

```
The young adventurer in side view facing right, feet planted on the same ground line, same camera angle. Frames 1-2: he crouches slightly with both fists clenched and the jaw set. Frames 3-5: an explosive burst, the body leans hard forward, the arms pump back and the backpack swings, a fierce determined face. Frames 6-8: he holds an aggressive ready stance leaning forward, then eases back toward the starting pose. No effects, no aura, no text. Keep the same outline, colors and proportions in every frame. Strictly avoid: turning around, back view, facing the camera, extra limbs, aura, glow, motion lines, text.
```

Conferir no resultado:

- [ ] Agacha e explode para a frente nos quadros 3-5.
- [ ] Sem aura (a aura é por código).

### h_rolar: Herói: rolar / abaixar

- Tipo: animação personalizada, 8 quadros, prioridade 0.

**Enviar assim** (as proibições vão dentro do texto, porque `custom_animations` ignora `negative_prompt`):

```
The young adventurer in side view facing right, on the same ground line, same camera angle. Frames 1-2: he crouches low and leans forward. Frames 3-6: he tucks into a forward roll along the ground, the body curled into a ball with the backpack on top, rotating once toward the right. Frames 7-8: he springs back up onto his feet into the starting standing pose. No effects, no dust, no text. Keep the same outline, colors and proportions in every frame. Strictly avoid: turning around, facing the camera, extra limbs, dust, motion lines, text.
```

Conferir no resultado:

- [ ] Rola uma vez para a direita e volta de pé.
- [ ] Sem poeira (a poeira é por código).

## goblin_minion

_Goblin Minion: personagem novo + animações numa rodada._

### g_minion_base: Goblin Minion: personagem base

- Tipo: personagem base, imagem, prioridade 1.

```
A small scrawny goblin, side profile facing right, large pointy ears, olive green skin, dirty brown rags, a rusty dagger in the right hand and a sly grin, cute chibi proportions, clean dark outline, readable silhouette, full body
```

Conferir no resultado:

- [ ] Lado, virado para a direita, corpo inteiro.
- [ ] Menor que o herói (Pequeno no livro).
- [ ] Adaga na mão direita (ficha: adaga).
- [ ] Mesmo traço do herói: contorno escuro, proporções fofas.

> Gera 1 imagem base (12). As animações só valem se a base estiver boa: se não, refazer a base antes de animar.

### g_minion_parado: Goblin Minion: parado (preset)

- Tipo: preset 'idle', 8 quadros, prioridade 1.

```
(preset 'idle' do SpriteCook, sem texto próprio)
```

Conferir no resultado:

- [ ] Respira e balança as orelhas, sem sair do lugar.

> Usa o preset: já deu certo no herói.

### g_minion_andar: Goblin Minion: andar (preset, com pose de andar)

- Tipo: preset 'walk', 8 quadros, prioridade 1.

```
(preset 'walk' do SpriteCook, sem texto próprio)
```

Conferir no resultado:

- [ ] Passos alternados de lado, virado para a direita.

> O preparo da pose custa +12 (uma vez por rodada). Serve também de correr: o jogo acelera o andar.

### g_minion_golpe: Goblin Minion: golpe de adaga

- Tipo: animação personalizada, 8 quadros, prioridade 1.

**Enviar assim** (as proibições vão dentro do texto, porque `custom_animations` ignora `negative_prompt`):

```
The goblin in side view facing right, feet planted on the same ground line, same camera angle. Frames 1-2: the dagger hand pulls back beside the hip while the shoulders hunch. Frames 3-4: a quick stabbing lunge, the body snaps forward and the arm extends fully with the dagger pointing ahead. Frames 5-6: hold the extended pose briefly, then pull the arm back. Frames 7-8: return to the guarded stance. The dagger keeps the same size and color. No effects, no text. Strictly avoid: turning around, back view, facing the camera, extra weapons, extra limbs, motion lines, text.
```

Conferir no resultado:

- [ ] Braço estica nos quadros 3-4 (o acerto do jogo: 0,1 a 0,3 s).
- [ ] A adaga não muda de tamanho nem de cor.

### g_minion_arremesso: Goblin Minion: arremesso de adaga

- Tipo: animação personalizada, 8 quadros, prioridade 1.

**Enviar assim** (as proibições vão dentro do texto, porque `custom_animations` ignora `negative_prompt`):

```
The goblin in side view facing right, feet planted on the same ground line, same camera angle. Frames 1-2: the throwing arm cocks back behind the head with the dagger raised, the body leaning back. Frames 3-4: an overhand throw, the arm whips forward and the hand opens at release, the body leaning into the throw. Frames 5-6: follow-through with the arm extended forward and the hand empty. Frames 7-8: return to the guarded stance. The thrown dagger is not drawn after release and nothing flies through the air. No effects, no text. Strictly avoid: turning around, back view, facing the camera, flying dagger, projectile, motion lines, extra limbs, text.
```

Conferir no resultado:

- [ ] A adaga sai da mão no quadro 3-4 e a mão fica vazia (a adaga voando é do jogo).
- [ ] Nada voando no quadro.

> Se a adaga continuar desenhada voando, recortar por código ou refazer.

### g_minion_dano: Goblin Minion: levar dano (preset)

- Tipo: preset 'hurt', 8 quadros, prioridade 1.

```
(preset 'hurt' do SpriteCook, sem texto próprio)
```

Conferir no resultado:

- [ ] Recua com o impacto e volta à pose.

> Economia: o jogo já treme e pisca ao apanhar. Se faltar crédito, este quadro pode ficar de fora (-14).

### g_minion_morte: Goblin Minion: morte (preset)

- Tipo: preset 'death', 12 quadros, prioridade 1.

```
(preset 'death' do SpriteCook, sem texto próprio)
```

Conferir no resultado:

- [ ] Cai e fica deitado, imóvel, no último quadro.

> Economia: dá para trocar por cair e sumir por código (-14).

## goblin_warrior

_Goblin Warrior: personagem novo + animações numa rodada._

### g_warrior_base: Goblin Warrior: personagem base

- Tipo: personagem base, imagem, prioridade 1.

```
A goblin warrior, side profile facing right, green skin, large pointy ears, a scarred cheek, studded leather armor, a small round wooden shield on the left arm and a curved scimitar in the right hand, cute chibi proportions, clean dark outline, readable silhouette, full body
```

Conferir no resultado:

- [ ] Escudo redondo no braço esquerdo, cimitarra na direita (ficha: CA 15 com escudo).
- [ ] Um pouco maior e mais forte que o Minion, mas ainda Pequeno.

> Se quiser economizar: reaproveitar a base do Minion com outra cor (-114) perde o escudo e a cimitarra.

### g_warrior_parado: Goblin Warrior: parado (preset)

- Tipo: preset 'idle', 8 quadros, prioridade 1.

```
(preset 'idle' do SpriteCook, sem texto próprio)
```

Conferir no resultado:

- [ ] Respira, escudo e cimitarra acompanham.

### g_warrior_andar: Goblin Warrior: andar (preset, com pose de andar)

- Tipo: preset 'walk', 8 quadros, prioridade 1.

```
(preset 'walk' do SpriteCook, sem texto próprio)
```

Conferir no resultado:

- [ ] Passos de lado, escudo e cimitarra na mão certa.

> Preparo +12.

### g_warrior_golpe: Goblin Warrior: golpe de cimitarra

- Tipo: animação personalizada, 8 quadros, prioridade 1.

**Enviar assim** (as proibições vão dentro do texto, porque `custom_animations` ignora `negative_prompt`):

```
The goblin warrior in side view facing right, feet planted on the same ground line, same camera angle. Frames 1-2: the scimitar arm rises back over the shoulder while the shield arm stays forward and the body leans back. Frames 3-4: a diagonal slash, the arm swings down across the body with the shoulders and hips driving it, the shield held steady in front. Frames 5-6: short follow-through with the scimitar low and extended. Frames 7-8: return to the guarded stance. The scimitar and shield keep the same size and color. No effects, no text. Strictly avoid: turning around, back view, facing the camera, extra weapons, extra limbs, motion lines, text.
```

Conferir no resultado:

- [ ] Corte na diagonal nos quadros 3-4, escudo parado na frente.
- [ ] Armas não mudam de tamanho.

### g_warrior_arco: Goblin Warrior: tiro de arco curto

- Tipo: animação personalizada, 8 quadros, prioridade 1.

**Enviar assim** (as proibições vão dentro do texto, porque `custom_animations` ignora `negative_prompt`):

```
The goblin warrior in side view facing right, feet planted on the same ground line, same camera angle, now holding a short bow instead of the scimitar. Frames 1-2: the bow arm extends forward and the other hand reaches back for the string. Frames 3-4: the string hand pulls back to the cheek, the body leaning into the draw. Frames 5: hold the tense aim. Frames 6-8: release, the string hand snaps back, the bow arm holds steady, then relax toward the guarded stance. No arrow in flight, no effects, no text. Strictly avoid: turning around, back view, facing the camera, flying arrow, projectile, motion lines, extra limbs, text.
```

Conferir no resultado:

- [ ] Arco curto na mão da frente, corda puxada até o rosto (quadros 3-4).
- [ ] Nenhuma flecha voando (a flecha é do jogo).

> Pode sair com a cimitarra no lugar do arco: nesse caso, repetir com o arco no primeiro termo do pedido.

### g_warrior_dano: Goblin Warrior: levar dano (preset)

- Tipo: preset 'hurt', 8 quadros, prioridade 1.

```
(preset 'hurt' do SpriteCook, sem texto próprio)
```

Conferir no resultado:

- [ ] Recua e volta à pose.

> Pode ficar de fora (-14): o jogo treme e pisca.

### g_warrior_morte: Goblin Warrior: morte (preset)

- Tipo: preset 'death', 12 quadros, prioridade 1.

```
(preset 'death' do SpriteCook, sem texto próprio)
```

Conferir no resultado:

- [ ] Cai e fica deitado, imóvel.

> Pode ser cair e sumir por código (-14).

## gray_ooze

_Gray Ooze (opcional: o slime CC0 atual já tem as 5 animações)._

### o_base: Gray Ooze: personagem base (opcional)

- Tipo: personagem base, imagem, prioridade 0.

```
A gray ooze, a translucent gray-green slime blob with a glossy surface, dripping edges and two small dark eyes, side profile facing right, cute chibi proportions, clean dark outline, readable silhouette, full body
```

Conferir no resultado:

- [ ] Gosma cinza translúcida com contorno escuro, olhos pequenos.

> Opcional: o slime CC0 atual (rvros) já tem parado, andar, golpe, dano e morte. Só vale se o estilo destoar do herói.

### o_parado: Gray Ooze: parado (preset)

- Tipo: preset 'idle', 8 quadros, prioridade 0.

```
(preset 'idle' do SpriteCook, sem texto próprio)
```

Conferir no resultado:

- [ ] Pulsa devagar no lugar.

### o_mover: Gray Ooze: deslizar

- Tipo: animação personalizada, 8 quadros, prioridade 0.

**Enviar assim** (as proibições vão dentro do texto, porque `custom_animations` ignora `negative_prompt`):

```
The gray ooze in side view facing right, on the same ground line, same camera angle. Frames 1-2: the body stretches forward low along the ground. Frames 3-4: the front pulls ahead while the rear drags and thins. Frames 5-6: the rear catches up and the body bunches and rises. Frames 7-8: settle back into the starting round shape. The glossy surface and two small eyes stay the same. No effects, no puddle trail, no text. Strictly avoid: turning around, facing the camera, extra eyes, puddle trail, motion lines, text.
```

Conferir no resultado:

- [ ] Estica, arrasta e junta, sem deixar rastro.

### o_golpe: Gray Ooze: pseudópode

- Tipo: animação personalizada, 8 quadros, prioridade 0.

**Enviar assim** (as proibições vão dentro do texto, porque `custom_animations` ignora `negative_prompt`):

```
The gray ooze in side view facing right, on the same ground line, same camera angle. Frames 1-2: the body compresses and pulls back, gathering force. Frames 3-4: a thick pseudopod lashes forward to the right from the front of the body and stays extended. Frames 5-6: the pseudopod whips back into the body. Frames 7-8: settle back into the starting round shape. No acid drops, no effects, no text. Strictly avoid: turning around, facing the camera, acid drops, splash, extra eyes, motion lines, text.
```

Conferir no resultado:

- [ ] Pseudópode estica para a direita nos quadros 3-4 (acerto: 0,2 a 0,35 s).

### o_dano: Gray Ooze: levar dano (preset)

- Tipo: preset 'hurt', 8 quadros, prioridade 0.

```
(preset 'hurt' do SpriteCook, sem texto próprio)
```

Conferir no resultado:

- [ ] Amassa e balança com o impacto.

### o_morte: Gray Ooze: morte (preset)

- Tipo: preset 'death', 12 quadros, prioridade 0.

```
(preset 'death' do SpriteCook, sem texto próprio)
```

Conferir no resultado:

- [ ] Derrete numa poça e fica parado.

## efeito_heroi

### e_arco_corte: Efeito: arco de corte (herói)

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 2.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a bright white crescent slash arc, side view, simple clean shape, transparent background, pixel art
```

Animação:

```
The white crescent slash sweeps from the upper left to the lower right, grows quickly to full size, holds for one frame, then fades out. The arc stays in the same place and keeps the same white color.
```

Negativo:

```
character, weapon, text, background
```

Conferir no resultado:

- [ ] Branco puro (a cor vem da arma por tinta).
- [ ] Cresce, segura 1 quadro e some.

> Hoje existe por script (4 quadros). Só trocar se ficar melhor.

### e_rastro: Efeito: rastro de estocada (herói)

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 2.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a thin white horizontal thrust streak made of a few long speed lines, side view, transparent background, pixel art
```

Animação:

```
The white speed lines shoot forward to the right, stretch out to full length, then fade quickly. The streak stays on the same horizontal line.
```

Negativo:

```
character, weapon, text, background
```

Conferir no resultado:

- [ ] Linhas brancas horizontais, somem rápido.

> Hoje existe por script.

### e_impacto: Efeito: impacto de contundente (herói)

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 2.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a white impact burst ring with small sparks, front view, transparent background, pixel art
```

Animação:

```
The white ring bursts outward from the center with small sparks flying out, expands to full size and then fades away. The center stays fixed.
```

Negativo:

```
character, weapon, text, background
```

Conferir no resultado:

- [ ] Anel branco com faíscas que expande e some.

> Hoje existe por script.

### e_critico: Efeito: acerto crítico (herói)

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 2.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a golden four-pointed star burst with a bright white center, transparent background, pixel art
```

Animação:

```
The golden star pops in small, flares to full size with a bright white flash at the center, then shrinks and fades. It stays centered the whole time.
```

Negativo:

```
character, text, background
```

Conferir no resultado:

- [ ] Estrela dourada que abre e some, centrada.

> Pode ser feito por partículas (grátis).

### e_cura: Efeito: cura (Fôlego)

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 2.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a green healing glow with small rising plus-shaped sparkles, transparent background, pixel art
```

Animação:

```
Small green plus-shaped sparkles float upward from the bottom while a soft green glow pulses around them, then everything fades out softly.
```

Negativo:

```
character, text, background
```

Conferir no resultado:

- [ ] Brilho verde com cruzes subindo.

> Pode ser feito por partículas (grátis).

### e_surto: Efeito: Surto de Ação

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 2.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a golden-orange energy aura flame shape, tall, side view, transparent background, pixel art
```

Animação:

```
The golden-orange flames flicker upward in a loop, swaying slightly and pulsing in brightness. The base stays fixed on the ground line and the loop closes smoothly.
```

Negativo:

```
character, text, background
```

Conferir no resultado:

- [ ] Aura dourada em laço, base fixa.

> Pode ser feito por partículas (grátis).

### e_nivel: Efeito: subir de nível

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 2.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a column of golden light with rising stars, transparent background, pixel art
```

Animação:

```
The column of golden light shoots up from the ground, small stars rise inside it, and it fades out at the top. The base stays fixed.
```

Negativo:

```
character, text, background
```

Conferir no resultado:

- [ ] Coluna dourada que sobe e some.

> Pode ser feito por partículas (grátis).

## efeito_inimigo

### e_acido: Efeito: respingo de ácido (Gray Ooze)

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 2.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a splash of green acid with a few droplets, side view, transparent background, pixel art
```

Animação:

```
The green acid splashes outward from the center with droplets flying and then falling, the splash spreads out and shrinks away. The center stays fixed.
```

Negativo:

```
character, text, background
```

Conferir no resultado:

- [ ] Respingo verde que abre e some.

> Pode ser feito por partículas (grátis).

### e_fumaca: Efeito: fumaça ao esconder (goblins)

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 2.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a puff of gray smoke cloud, front view, transparent background, pixel art
```

Animação:

```
The gray smoke puffs out from a small cloud to a large one, swirling softly, then thins out and fades. The center stays fixed.
```

Negativo:

```
character, text, background
```

Conferir no resultado:

- [ ] Nuvem cinza que cresce e some.

> Pode ser feito por partículas (grátis).

### e_morte_nuvem: Efeito: nuvem de morte (todos)

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 2.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a white poof cloud with small star sparks, front view, transparent background, pixel art
```

Animação:

```
The white poof bursts out in a round cloud with small sparks flying outward, then the cloud shrinks and fades. The center stays fixed.
```

Negativo:

```
character, text, background
```

Conferir no resultado:

- [ ] Nuvem branca com faíscas que some.

> Pode ser feito por partículas (grátis).

### e_flecha_impacto: Efeito: impacto de flecha e adaga

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 2.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a small white spark hit with a few tiny shards, front view, transparent background, pixel art
```

Animação:

```
The small white sparks burst out with a few tiny shards, expand briefly and fade out fast. The center stays fixed.
```

Negativo:

```
character, text, background
```

Conferir no resultado:

- [ ] Faísca pequena e rápida.

> Pode ser feito por partículas (grátis).

## mapa

### m_tocha: Mapa: tocha (Ruína e Fortaleza)

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 3.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a wall torch with an orange flame on a dark wooden handle, side view, transparent background, pixel art
```

Animação:

```
The torch flame flickers in a loop, swaying slightly and changing height, with a few small embers rising. The wooden handle does not move and the loop closes smoothly.
```

Negativo:

```
character, text, background
```

Conferir no resultado:

- [ ] Só a chama se mexe; o cabo fica parado.
- [ ] Laço sem salto.

> A luz da tocha pode ser feita por código.

### m_agua: Mapa: água com bolhas (Pântano)

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 3.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a strip of murky green swamp water with a few bubbles, side view, seamless horizontal, transparent background, pixel art
```

Animação:

```
The swamp water surface ripples gently from side to side while a few bubbles rise and pop. The strip stays seamless horizontally and the loop closes smoothly.
```

Negativo:

```
character, text
```

Conferir no resultado:

- [ ] Laço contínuo, emenda horizontal sem corte.

> Pode ser feito por shader (grátis).

### m_porta: Mapa: porta (hoje invisível)

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 3.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a tall arched wooden door with iron bands set in a stone frame, front view, transparent background, pixel art
```

Animação:

```
The door glows faintly with a soft golden light along its edges in a slow pulsing loop, the wood and stone staying still. The loop closes smoothly.
```

Negativo:

```
character, text, background
```

Conferir no resultado:

- [ ] Porta de madeira com ferro, brilho suave nas bordas.

> Só a imagem custa 6; a animação (+20) é opcional.

### m_bau: Mapa: baú abrindo (Clareira)

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 3.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a closed wooden treasure chest with iron corners, side view, transparent background, pixel art
```

Animação:

```
The chest lid swings open, a golden glow bursts out of the opening and settles into a soft shine. The chest base stays fixed.
```

Negativo:

```
character, text, background
```

Conferir no resultado:

- [ ] Tampa abre, brilho dourado, base parada.

### m_bandeira: Mapa: bandeira (Fortaleza)

- Tipo: efeito (imagem + animação), 8 quadros, prioridade 3.

Imagem (`pixel-engine-image-v1`, 64x64):

```
a red banner flag on a tall wooden pole with a simple emblem, side view, transparent background, pixel art
```

Animação:

```
The red flag waves in the wind in a smooth loop, the cloth rippling toward the right. The pole does not move and the loop closes smoothly.
```

Negativo:

```
character, text, background
```

Conferir no resultado:

- [ ] Só o pano balança; a haste fica parada.

