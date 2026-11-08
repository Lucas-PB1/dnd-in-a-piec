# Pendências

Tudo o que falta, num lugar só, para escolher a próxima fatia **sem inventar**. Ao propor a
próxima fatia, escolha daqui (e ofereça 3 opções ao usuário, a recomendada primeiro). Ao fechar
uma fatia: **tire daqui o que ficou pronto** e acrescente o que apareceu de novo.

Legenda de tamanho: **P** (uma tarde), **M** (uma fatia), **G** (várias fatias).

## 1. Próximas fatias sugeridas

| # | Fatia | Tam. | Onde mexe | Observação |
|---|---|---|---|---|
| 1 | **Validar o APK num celular Android** | P | `builds/android/dnd_in_a_piece.apk`, controles de toque | APK exportável; falta conferir no aparelho o tamanho dos alvos, movimento durante o ataque e resposta do pulo. |
| 2 | **Subclasse do Guerreiro** | M | `core/dados/`, criação, combate | O nível 3 ainda não oferece a escolha de subclasse nem seus recursos. |
| 3 | **Testes de habilidade nas fases** | M | `levels/`, interações e perícias | A regra e o toggle de Mente Tática estão prontos; falta uma interação que peça um teste de habilidade do herói. |
| 4 | **Esconder de novo** | M | `features/goblin/` | A outra metade da Fuga Ágil: o Goblin Warrior se esconde outra vez no meio da luta. O começo escondido e o +1d4 com vantagem já existem. |
| 5 | ~~Sprites novos dos monstros~~ (feito com o SpriteCook; falta só o refino do golpe do Minion e do arremesso) | M | `features/goblin/`, `tools/gerar_goblin*.gd` | Não há pacote CC0 melhor. Opção paga: [Rpg miniatures: The Goblins](https://ivoryred.itch.io/rpg-miniatures-the-goblins) (US$ 2,99, 4 goblins com dano e morte), só se o usuário comprar. |
| 8 | **Corte de cima do herói (SpriteCook)** | M | `features/jogador/sprites/`, `docs/spritecook/prompts.json` | Pendente. 2 tentativas (52 créditos) saíram parciais: a IA desenha uma espada e o golpe não desce claro. Ideia: 3ª tentativa só com "balança o braço de cima para baixo", avisando o custo antes. Hoje vale o golpe antigo. |
| 13 | **Som: o que falta** | M | `levels/sons.gd`, `data/` | Sons próprios de cada monstro (aviso do golpe e voz), música de derrota, ambiente por fase (vento, água), equipar e pegar item, mixagem por distância e mais faixas de música (a batalha toca só na Ruína e na Fortaleza). Ouvir com o jogo e ajustar volumes. |
| 9 | **Ligar as animações do SpriteCook nos goblins** | M | `features/goblin/sprites/`, `tools/gerar_goblin*.gd` | Minion pronto: parado, andar e dano aprovados. Golpe (quadros 3 e 7) e arremesso (quadros 4-5 e 6) têm a adaga deformada ou solta: usar só os quadros bons e a adaga por código, ou refazer (20 cada, na mesma rodada 14). Warrior aprovado (golpe com cimitarra levemente distorcida nos quadros 5-6; um pixel solto no dano). Ooze: parado e dano ok, deslizar parcial (quadros 6-7), pseudópode refeito e aprovado (v2). |
| 6 | **Arte própria do Pântano e da Ruína** | M | `levels/fundo_paralaxe.gd`, `assets/fundos/` | Hoje reusam floresta e fortaleza em outro tom. Faltam camadas de pântano e de ruína (não achei CC0). |
| 7 | **Ataques novos dos monstros** | M | `core/dados/criatura_rpg.gd`, estados | Só com fonte no livro (ex.: criatura nova com ataques próprios). O Ooze, o Minion e o Warrior já usam todos os ataques das fichas. |

## 2. Regras do livro que ainda não existem

| O quê | Tam. | Situação hoje |
|---|---|---|
| Raças/espécies | G | Deslocamento padrão 30 pés para todos (`Ficha.DESLOCAMENTO_PADRAO_PES`). |
| Antecedentes | M | Escolha de talento só quando existir antecedente; `Ficha.talentos` começa vazia. |
| INT e CAR | — | Entram no bônus da perícia escolhida (História, Intimidação, Persuasão). Essas perícias ainda não têm teste no jogo. SAB entra na Percepção passiva. |
| Outras perícias | — | Escolhidas e mostradas na ficha. Só a Percepção passiva muda o jogo. |
| Esconder de novo | M | O goblin começa escondido. A Fuga Ágil ainda não o esconde outra vez depois do golpe. |
| Desvantagem de armadura em Furtividade | P | A marca existe na armadura. O herói não rola Furtividade, então ela ainda não entra num teste. |
| Magia | G | Abrir o bloco de talentos de magia em `docs/talentos.md` na fatia dela. |
| Descanso curto | P | Second Wind recarrega ao entrar na fase seguinte (descanso longo) e no "Tentar de novo" (regra da casa); descanso curto ainda não existe. |
| Limite de tamanho do Empurrar e do Derrubar | P | Hoje vale para qualquer tamanho (o livro: Grande ou menor). |
| Amorfo (Gray Ooze) | P | Sem efeito no jogo. |
| Salvar e carregar o jogo | M | Só as configurações são salvas (`user://comandos.cfg`, `user://toque.cfg`). Decisão grande: propor 2 opções. |

## 3. Arte provisória (trocar quando der)

| O quê | Como trocar |
|---|---|
| Efeitos de golpe (arco, rastro, impacto) | Desenhados por script em `assets/efeitos/`. Pacote CC0 ou SpriteCook. |
| Ladrilhos e cenário | `tools/gerar_arte_provisoria.gd`. Pacote de tileset CC0 (`docs/artes_prontas.md`). |
| Armaduras no herói | O usuário achou "pouco épico"; ficou como pintura da túnica. Revisitar com arte nova. |
| Goblin com lança na arte, mas a ficha usa adaga | Achar ou gerar um goblin com adagas, se incomodar. |

## 4. Dívidas técnicas (pequenas)

| O quê | Quando resolver |
|---|---|
| Base comum das criaturas (perseguir, ritmo, condições, empurrão repetidos em Ooze e Goblin) | Antes de uma criatura que não reuse o Goblin (o Warrior usa a máquina dele). |
| `BotaoToque` e `AnalogicoToque` repetem "editando/destacado" | Ao criar o 3º tipo de controle de toque. |
| "Arma na mão ou desarmado" em 2 lugares (Jogador e TelaInventario) | Se aparecer um 3º lugar. |
| Sinais `pulou`/`reapareceu` do herói sem ouvinte | Quando houver som/efeito para eles, ou remover. |
| Projétil do herói pode nascer na altura da cabeça no 1º quadro do voo | Conferir em jogo; se for, nascer na ponta da arma. |

## 5. Mais para frente

- Controle (gamepad).
- iOS (precisa de Mac com Xcode).
- Trocar o nome do jogo antes de publicar ("D&D" é marca da Wizards of the Coast).
