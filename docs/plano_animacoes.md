# Plano de animações e efeitos (SpriteCook)

Lista de tudo que o jogo quer de animação, em ordem de prioridade, com o custo em créditos do
SpriteCook. Serve para decidir a compra com números reais. **Atualize ao gerar ou decidir algo.**
Saldo e regras de assinatura: ver o fim do arquivo.

## 1. Preços conferidos (sem gastar nada)

Consultados em 2026-11-08 pedindo ao SpriteCook com **saldo zero** (ele recusa e informa o custo).

| Pedido | Créditos |
|---|---|
| Personagem novo (base, de lado) | 12 |
| 1ª animação de uma rodada (idle, golpe, dano, morte, pulo, custom) | 20 |
| Animação extra **na mesma rodada** | 14 |
| Pose de andar ou de correr (uma vez por rodada) | +12 |
| Imagem avulsa, modelo padrão | 12 |
| Imagem avulsa, `pixel-engine-image-v1` (16 a 128 px, só texto) | **6** |
| Animar uma imagem (8 ou 16 quadros, motor v1.1) | 20 |
| Animar uma imagem, motor v1.5 (movimento mais preciso) | 26 |
| Remover fundo "Photoroom" em vez do básico | +16 a +24 |

**Efeito = imagem + animação = 6 + 20 = 26** (barato) ou 12 + 20 = 32 (modelo padrão).
Várias animações do **mesmo personagem na mesma rodada** saem mais baratas (20 + 14 + 14...).

## 2. Lista por prioridade

Legenda: ✅ já existe · 🔶 existe provisório · ⬜ falta. "Grátis" = dá para fazer por código no Godot.

### Prioridade 1: essencial (jogabilidade)

**Herói** (em uma rodada só: 20 + 14 + 14 = 48)

| # | Item | Onde aparece | Custo | Estado |
|---|---|---|---|---|
| 1 | Corte de cima | cortes de espada, machado, martelo | 20 | ⬜ (o 1º teste saiu como estocada) |
| 2 | Estocada | lanças, rapieira, adaga | 0 | 🔶 o golpe de teste já pago serve; falta ligar |
| 3 | Levar dano | todo golpe sofrido (hoje: recuo + pisca) | 14 | ⬜ |
| 4 | Morte / cair | tela "Você caiu!" | 14 | ⬜ |
| — | Parado, andar, pulo, correr | sempre | 0 | ✅ (correr nova: 32 créditos já gastos) |

**Monstros** (cada um: personagem + animações na mesma rodada)

| # | Item | Composição | Custo |
|---|---|---|---|
| 5 | Goblin Minion | base 12 + parado 20 + andar 14 (+12 pose) + golpe 14 + dano 14 + morte 14 + arremesso 14 | 114 |
| 6 | Goblin Warrior | igual ao Minion, com tiro de arco no lugar do arremesso | 114 |
| 7 | Gray Ooze (**opcional**) | base 12 + parado 20 + mover 14 + golpe 14 + dano 14 + morte 14 | 88 (o slime CC0 atual já tem as 5 animações) |

Alternativa grátis para 5 e 6: o **Royal Goblin** da página de sprites gratuitos do SpriteCook
(5 animações, uso comercial liberado), que economiza uns 100 créditos.

**Total da prioridade 1: 48 + 114 + 114 = 276 créditos** (+88 só se quiser refazer o Ooze).

### Prioridade 2: efeitos de combate (cada um 26)

| # | Efeito | De quem | Alternativa grátis |
|---|---|---|---|
| 8 | Arco de corte | herói | 🔶 já existe por script |
| 9 | Rastro de estocada | herói | 🔶 já existe por script |
| 10 | Impacto de contundente | herói | 🔶 já existe por script |
| 11 | Cura (Fôlego) | herói | brilho verde por código |
| 12 | Surto de Ação | herói | aura por código |
| 13 | Acerto crítico | herói | estrela por código |
| 14 | Subir de nível | herói | partículas por código |
| 15 | Respingo de ácido | Gray Ooze | partículas por código |
| 16 | Fumaça ao esconder | goblins | partículas por código |
| 17 | Nuvem de morte | todos | partículas por código |
| 18 | Impacto de flecha e adaga | goblins | faísca por código |

11 efeitos × 26 = **286** (ou 352 com o modelo padrão). Dá para cortar muito fazendo os de
"partículas por código" no Godot, e gastar crédito só nos que são a "cara" do jogo (8 a 10, 13).

### Prioridade 3: mapa e acabamento

| # | Item | Fase | Custo | Alternativa grátis |
|---|---|---|---|---|
| 19 | Tochas e braseiros | Ruína, Fortaleza | 26 | luz por código |
| 20 | Água e bolhas | Pântano | 26 | shader por código |
| 21 | Porta (hoje invisível) | todas | 26 | só imagem (6) |
| 22 | Baú abrindo | Clareira | 26 | — |
| 23 | Bandeira e estandarte | Fortaleza | 26 | — |

5 × 26 = **130** (ou 160). Vagalumes, folhas ao vento e poeira são partículas por código (0).

### Extras do herói (opcional: 14 cada se pedidos junto da rodada essencial; 48 se numa rodada à parte)

| # | Item | Custo |
|---|---|---|
| 24 | Pose de cura (Fôlego) | 14 |
| 25 | Pose de Surto de Ação | 14 |
| 26 | Abaixar ou rolar | 14 |

## 3. Totais

| | Base | Realista (x1,5) | Pior caso (x2) |
|---|---|---|---|
| Prioridade 1 | 276 | 414 | 552 |
| + Prioridade 2 | 562 | 843 | 1.124 |
| + Prioridade 3 | 692 | 1.038 | 1.384 |
| + Extras do herói (rodada à parte: 48) | 740 | 1.110 | 1.480 |

(com o modelo padrão nos efeitos, some ~96: total base ~918.) As repetições existem porque a
geração por IA nem sempre acerta: no teste, a corrida saiu boa de primeira e o golpe só em parte.

## 4. Planos

| Plano | Preço | Créditos/mês | Observação |
|---|---|---|---|
| Grátis | 0 | 40 (não acumulam) | gerações aparecem na galeria pública |
| **Starter** | US$ 8 | 800 | cobre a prioridade 1 com folga |
| Adventurer | US$ 30 | 3.000 | cobre tudo, inclusive o pior caso |
| Créditos avulsos | ~1 centavo cada (confirmar no app) | nunca expiram | funcionam no plano grátis |

Starter x2 (US$ 16) cobre até a prioridade 3 no caso realista. Rende mais que o Adventurer.

## 5. Garantias e limites

- O custo aparece **antes** de gerar; o saldo atualiza em seguida.
- Cancelar é livre e você **mantém tudo o que gerou**. O uso comercial vale em todos os planos.
- Reembolso só por falha de entrega ou cobrança duplicada, **não** por "não gostei do resultado".
- Créditos de assinatura acumulam só até um mês de franquia; os avulsos não expiram.

## 6. Ordem sugerida

1. **Piloto:** corte de cima do herói (20) e o Minion completo (114). Avalie antes de seguir.
2. Resto da prioridade 1 (dano e morte do herói, Warrior e Ooze).
3. Prioridade 2, só os efeitos "cara do jogo"; o resto por código.
4. Prioridade 3 por último.

Enquanto não há créditos, dá para fazer por código: pausa de impacto, tremor de tela, poeira,
faíscas e as partículas marcadas como "grátis".

## 7. Teste dos pedidos (feito com saldo zero)

Os 42 pedidos estão em `docs/spritecook/prompts.json` (texto de cada um, o que conferir no resultado) e o
documento legível em `docs/spritecook/prompts.md`. O conferidor `tools/conferir_prompts_spritecook.ps1`
valida, sem gastar nada: quadros (as fases "Frames 1-2:...", cobrem de 1 a N sem buracos), frases
obrigatórias, tamanho, proibições e o custo de cada rodada pelas regras reais.

Teste no próprio SpriteCook (saldo 0: ele valida e recusa antes de cobrar):

| Verificação | Resultado |
|---|---|
| Quadros ímpares | recusado ("multiple of 2"): os nossos são pares |
| `source_view` inválido | recusado: o nosso (`front_idle`) é aceito |
| Tamanho máximo do pedido | **3.000 caracteres** (os nossos têm ~700 a 900) |
| Campo desconhecido em `custom_animations` | **ignorado em silêncio**: `negative_prompt` ali **não funciona** |
| Rodada de herói, personagem base, imagem de efeito, animação de efeito, rodada de monstro | todos aceitos |
| Custos | personagem 12, imagem 6 (pixel-engine) ou 12, animar imagem 20 (v1.1) ou 26 (v1.5) |

**Consequência:** nas animações guiadas as proibições vão **dentro do texto** ("Strictly avoid: ..."), o que o
gerador já faz no "Enviar assim". O `negative_prompt` só vale em `animate_game_art` (efeitos, motor v1.1).

## 8. Como economizar sem perder qualidade

| Medida | Economia | Impacto na qualidade |
|---|---|---|
| Manter o slime CC0 no Ooze | 88 | nenhum (já tem as 5 animações) |
| Pedir todas as animações de um personagem **na mesma rodada** | 6 cada (14 em vez de 20) | nenhum |
| Usar o golpe de teste já pago como estocada do herói | 14 | nenhum, se integrarmos bem |
| **Testar a base do monstro (12) antes de animar** | até 102 se a base for ruim | nenhum: evita gastar à toa |
| Dano dos monstros por código (tremor e pisca, já feito) | 14 cada | pequeno |
| Morte dos monstros por código (cair e sumir) | 14 cada | médio: perde a animação própria |
| Efeitos por partículas no Godot (cura, Surto, crítico, nível, ácido, fumaça, nuvem, impacto) | ~208 | pequeno; os efeitos "cara do jogo" ficam |
| Royal Goblin gratuito no lugar de um goblin | ~114 | depende de combinar com o estilo |

**Três configurações da prioridade 1:** completa 276 · econômica 220 (monstros sem dano e morte próprios)
· mínima ~162 (Royal Goblin gratuito no lugar do Warrior). O herói (48) fica sempre completo, porque é
o personagem mais visto.
