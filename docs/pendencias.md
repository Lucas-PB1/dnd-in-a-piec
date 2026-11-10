# Pendências

Tudo o que **ainda falta**, num lugar só, para escolher a próxima fatia **sem inventar**.
Ao propor a próxima fatia, escolha daqui (3 opções ao usuário, a recomendada primeiro).
Ao fechar uma fatia: **tire daqui o que ficou pronto** e acrescente o que apareceu de novo.

Legenda de tamanho: **P** (uma tarde), **M** (uma fatia), **G** (várias fatias).

O que já foi (10 fases, chefes, loja, ouro, talentos 1–6, save/load, esconder de novo do Warrior,
Skeleton/Zombie, etc.) está em `docs/historico.md` — **não** repita aqui.

## 1. Próximas fatias sugeridas

| # | Fatia | Tam. | Onde mexe | Observação |
|---|---|---|---|---|
| 1 | **Validar o APK num celular Android** | P | `builds/android/dnd_in_a_piece.apk`, controles de toque | APK exportável; falta conferir no aparelho o tamanho dos alvos, movimento durante o ataque, pulo, escalada no toque e botões Defesa/Investida/Dado/Veneno/Sorte. |
| 2 | **Subclasse do Guerreiro** | M | `core/dados/`, criação, combate, árvore de habilidades | O nível 3 ainda não oferece a escolha de subclasse nem seus recursos (placeholder "Em breve"). |
| 3 | **Testes de habilidade nas fases** | M | `levels/`, interações e perícias | A regra e o toggle de Mente Tática estão prontos; falta uma interação de fase que peça um teste de perícia do herói. |
| 3a | **IA dos monstros: salto na patrulha/Fuga Ágil e vantagem de terreno** | M | `features/goblin/`, `core/regras/` | Saltar (incl. Ooze/chefes), cobertura, manter distância, recuar ferido e flanqueio **feitos**. Faltam: esperar em vantagem de terreno; salto na patrulha e na Fuga Ágil. |
| 4 | **Lava com dano no Covil (fase 10)** | M | `levels/`, `fase.gd` / gerador | Decisão do épico; a fase 10 existe sem lava. |
| 5 | **Refino visual do Minion (golpe e arremesso)** | P | `features/goblin/sprites/` | Sprites SpriteCook ligados; adaga ainda deforma em alguns quadros. Opcional. |
| 6 | **Arte própria do Pântano e da Ruína** | M | `levels/fundo_paralaxe.gd`, `assets/fundos/` | Hoje reusam floresta e fortaleza em outro tom. Faltam camadas próprias (não achei CC0). |
| 7 | **Som: o que falta** | M | `levels/sons.gd`, `data/` | Sons próprios de cada monstro (aviso do golpe e voz), música de derrota, ambiente por fase, equipar/pegar item, mixagem por distância e mais faixas (batalha só na Ruína e na Fortaleza). |
| 8 | **Minions novos por recolor** | M | `features/goblin/`, `data/`, fases | Ainda não: Bullywug, Bandit, Guard, Scout, Gnoll, Tough, Cultist, Priest Acolyte, Bandit Captain. Criar aos poucos (`/nova-criatura`). |
| 9 | **Ataques novos dos monstros** | M | `core/dados/criatura_rpg.gd`, estados | Só com fonte no livro (ex.: criatura nova). Ooze, Minion e Warrior já usam os ataques das fichas. |

## 2. Regras do livro que ainda não existem

| O quê | Tam. | Situação hoje |
|---|---|---|
| Raças/espécies | G | Deslocamento padrão 30 pés para todos (`Ficha.DESLOCAMENTO_PADRAO_PES`). |
| Magia | G | Abrir o bloco de talentos de magia em `docs/talentos.md` na fatia dela. |
| Descanso curto | P | Second Wind recarrega ao entrar na fase seguinte (descanso longo) e no "Tentar de novo" (regra da casa); descanso curto ainda não existe. |
| Limite de tamanho do Empurrar e do Derrubar | P | Hoje vale para qualquer tamanho (o livro: Grande ou menor). |
| Amorfo (Gray Ooze) | P | Sem efeito no jogo. |
| Desvantagem de armadura em Furtividade | P | A marca existe na armadura. O herói não rola Furtividade, então ela ainda não entra num teste. |
| INT e CAR em testes | — | Entram no bônus da perícia escolhida (História, Intimidação, Persuasão). Essas perícias ainda não têm teste no jogo. SAB entra na Percepção passiva. |
| Outras perícias | — | Escolhidas e mostradas na ficha. Só a Percepção passiva muda o jogo (até existir #3). |
| Antecedentes / talentos em espera | — | Criação com 11 antecedentes e 30 talentos ligados. Em espera (magia/aliados): ver `docs/talentos.md`. |

## 3. Arte provisória (trocar quando der)

| O quê | Como trocar |
|---|---|
| Efeitos de golpe (arco, rastro, impacto) | Desenhados por script em `assets/efeitos/`. Pacote CC0 ou SpriteCook. |
| Ladrilhos e cenário | `tools/gerar_arte_provisoria.gd`. Pacote de tileset CC0 (`docs/artes_prontas.md`). |
| Armaduras no herói | O usuário achou "pouco épico"; ficou como pintura da túnica. Revisitar com arte nova. |
| Goblin com lança na arte, mas a ficha usa adaga | Achar ou gerar um goblin com adagas, se incomodar. |
| Corte de cima do herói | Animação `corte` já ligada (SpriteCook). Refino opcional se a espada/gesto incomodar. |

## 4. Dívidas técnicas (pequenas)

| O quê | Quando resolver |
|---|---|
| Base comum das criaturas (perseguir, ritmo, condições, empurrão repetidos em Ooze e Goblin) | Antes de uma criatura que não reuse o Goblin (o Warrior usa a máquina dele). |
| `BotaoToque` e `AnalogicoToque` repetem "editando/destacado" | Ao criar o 3º tipo de controle de toque. |
| "Arma na mão ou desarmado" em 2 lugares (Jogador e TelaInventario) | Se aparecer um 3º lugar. |
| Sinais `pulou`/`reapareceu` do herói sem ouvinte | Quando houver som/efeito para eles, ou remover. |
| Projétil do herói pode nascer na altura da cabeça no 1º quadro do voo | Conferir em jogo; se for, nascer na ponta da arma. |
| `jogador.gd` ainda grande (~1400 linhas): cortar ataque/disparo em componentes | Quando for mexer de novo no combate do herói. |
| Balancear Quimera vs invencibilidade ~1 s do herói (combo quase 1 hit) | Depois de validar a sensação no jogo. |
| Usar animação `dano` da Quimera (arte existe, nenhum estado toca) ou remover | Ao refinar a Quimera. |
| Renomear/dividir `features/goblin/` (skeleton/zombie moram ali por herança) | Só se as variantes crescerem demais. |
| Validar equilíbrio dos níveis 5–6 (Ataque Extra) nas fases 8–10 | Se ficar fácil: subir XP em `Ficha.XP_POR_NIVEL` ou inimigos em `Main.INIMIGOS_EXTRA_POR_NIVEL`. |
| Validar sensação dos chefes (Ankheg, Minotauro, Wight, Quimera) | Depois de jogar; morte própria do Ankheg/Minotauro ainda usa dissolver/terra. |

## 5. Mais para frente

- Controle (gamepad).
- iOS (precisa de Mac com Xcode).
- Trocar o nome do jogo antes de publicar ("D&D" é marca da Wizards of the Coast).
- Porta muda de aparência quando a cota abre.
- Munição comum some do inventário/Compêndio (só especiais).
- Atirador de Elite atravessando obstáculos de verdade (hoje quase não há obstáculo que bloqueie tiro).
