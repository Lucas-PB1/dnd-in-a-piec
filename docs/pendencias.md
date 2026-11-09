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
| 3a | **IA dos monstros: cobertura e estratégia** | M | `features/goblin/`, `core/regras/` | Saltar, cobertura, manter distância e recuar ferido (feitos). Flanqueio (só manobra) também feito. Faltam: esperar em vantagem de terreno e levar o salto ao Gray Ooze, à patrulha e à Fuga Ágil. |
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

## Antecedentes e talentos (só documentados)
- Os dados existem, mas nenhum antecedente ou talento está acessível ainda. O Compêndio (menu inicial e pausa) só cria essas abas quando houver conteúdo disponível; para liberar um talento funcional, marque o id em `TALENTOS_FUNCIONANDO` de `tools/gerar_compendio.gd` e rode o gerador.
- Passo de criação com o antecedente (+2/+1 ou +1/+1/+1 depois da compra de pontos, teto 20, perícias, talento de origem). Itens só os que o jogo já tem. Antes disso, decidir com o usuário: Iniciado em Magia, Músico, Artesão e Curandeiro.
- Efeitos dos talentos de origem: Alerta, Resistente, Atacante Selvagem, Perito, Sortudo, Brigão de Taverna (contas em `docs/talentos.md`).
- Talentos de origem decididos: entram Alerta, Resistente, Atacante Selvagem, Brigão de Taverna, Sortudo, Perito e Artesão (desconto de 20% exige a loja; item aleatório por fase). Em espera: Iniciado em Magia, Músico e Curandeiro (ver `docs/talentos.md`). Falta decidir os talentos gerais.
- Atleta: escalar paredes e murinhos em diagonal precisa de suporte no cenário (fases e colisão); decidir o desenho das paredes com o usuário.
- Agarrador: criar a condição Agarrado e a IA dos monstros tentando escapar (e atacando preso). Regra de escape ainda por definir com o usuário.
- Nível 4 do Guerreiro: é onde se escolhe o talento geral (ou o aumento de atributo). O jogo hoje para no nível 3.
- Atirador de Elite: o tiro precisa atravessar obstáculos e criaturas (hoje não há obstáculos que bloqueiem).
- **Munição (decisão do usuário):** o jogo não conta flechas nem virotes; o disparo não gasta munição. Só existe munição quando ela for especial (flecha com efeito). Falta: tirar a contagem da munição comum (disparo, inventário, pacotes iniciais, aba Itens do Compêndio) e manter só as especiais. Atualizar `docs/decisoes/armas_e_itens.md` ao fazer.
- Dados de vida: o herói tem tantos dados quanto o nível e pode gastá-los para curar (rola o dado + mod. de CON). Base do talento Durável (ação bônus que gasta um dado de vida e cura; versão PHB 2024). Decidir com o usuário como gasta (botão, quando, limite por fase).
- Envenenador e Veneno Básico: criar o tipo de dano veneno em `TiposDano`, a condição Envenenado e o item Veneno Básico (gerador de itens). Fontes e texto em `docs/talentos.md`.
- Talentos escolhíveis no nível 4 (23 gerais planejados) ainda sem efeito: ligar um por um. Resiliente também precisa guardar qual salvaguarda recebeu proficiência. Depois, os talentos ligados entram no Compêndio.
- **Antecedente na criação (decidido):** passo novo depois de "Quem é você". O jogador escolhe um dos 11 antecedentes que entram, o aumento de atributo (+2/+1 ou +1/+1/+1 entre os 3 listados, depois da compra de pontos, teto 20) e recebe o talento de origem. As 2 perícias do antecedente já vêm marcadas e travadas; o Guerreiro escolhe as suas 2 entre as que sobram da lista dele. Os cinco em espera não aparecem.
- O talento de origem do antecedente entra na ficha só pelo nome; falta ligar os efeitos (Alerta, Resistente, Atacante Selvagem, Brigão de Taverna, Sortudo, Artesão). Perito (Charlatão, Nobre, Escriba) ainda precisa do passo de escolher as 3 perícias ou ferramentas. Validar no aparelho o "voltar" com o teclado aberto.
- Talentos de origem prontos (Alerta, Resistente, Atacante Selvagem, Brigão, Sortudo, Artesão, Perito). Faltam: loja com 20% de desconto do Artesão; salvaguardas do herói com a sorte; verificar no aparelho o botão "Sorte" nos atalhos (layouts salvos antigos precisam pôr a Sorte num slot em Opções > Atalhos). Próximos: efeitos dos 23 talentos gerais do nível 4.
- Talentos gerais: todos os 30 escolhíveis estão ligados e completos. Falta validar no aparelho os botões novos (Defesa, Investida, Dado de vida, Veneno), o tamanho dos botões e a escalada no toque (empurrar o analógico contra a parede); a loja do Artesão; a porta ainda não muda de aparência quando a cota abre (aberta ou fechada).
- Dívidas que sobraram da auditoria: `jogador.gd` ainda tem ~1250 linhas (arremesso e disparo, Surto, Fôlego e golpes ainda moram nele: o próximo corte é um componente de ataque e um de disparo); as perícias do herói não têm teste rolado no jogo (só a Percepção passiva); `Compendio` está em `ui/` porque usa `ResumoItem`.

## Épico: 10 fases, chefes, ouro, loja e armas mágicas (pedido do usuário, 2026-11-09)
Decisões dele: chefe a cada 3 fases (3, 6, 9) e um **super chefe na 10**, cada um com jogabilidade diferente;
missão visível por fase ("derrote todos os inimigos" e variações); inimigos comuns variam com o ambiente;
inimigos soltam **ouro e armas**; **loja no início da fase** (comprar e vender); armas mágicas **+1, +2, +3**
(só bônus de ataque/dano e um efeito de cor); a chance de drop de arma e a quantidade de ouro sofrem **influência
direta do Carisma** (regra da casa, pedida por ele). Inimigos candidatos (Monster Manual 2024, do Códice dele,
history-lilac.vercel.app): Kobold Warrior, Skeleton, Zombie, Hobgoblin Warrior, Rust Monster, Bugbear Warrior,
Animated Armor; chefes Ankheg (ND 2) e outros até ND 3. Ainda por decidir: plano de criaturas e ordem das fatias.
Fatias sugeridas: (1) ouro e drops + regra do Carisma; (2) armas mágicas +1/+2/+3; (3) loja no início da fase
(desconto 20% do Artesão); (4) missões por fase; (5) criaturas novas por ambiente; (6) chefes das fases 3, 6, 9; (7) fases 6 a 10 e super chefe.

### Estratégia de criaturas e chefes (decidida com o usuário em 2026-11-09)
- **Chefes pagos (SpriteCook)**, um por 3 fases; antes de animar, gerar só a base (12 créditos) para aprovação. Escolhidos: **Fase 3 Ankheg** (ND 2: cava e sai debaixo do herói, morde e agarra, cospe ácido em linha), **Fase 6 Minotaur of Baphomet** (ND 3: investida em linha, empurra e derruba, fica atordoado se bater na parede), **Fase 9 Wight** (ND 3: drena vida e invoca Skeletons e Zombies). **Fase 10 (super chefe): Ettin (ND 4, duas cabeças; a 2ª acorda com metade da vida e ataca dos dois lados).** Arte enxuta ~74 créditos por chefe (base 12, parado 20, andar 14, golpe 14, ataque especial 14); saldo em 2026-11-09: 336.
- **(Feito: Kobold, Hobgoblin e Bugbear.)** **Minions grátis e familiares, sem limite de quantidade:** recolor e escala das artes que já temos. Do Goblin: Kobold Warrior (1/8), Hobgoblin Warrior (1/2), Bugbear Warrior (1, golpe com alcance), Bullywug Warrior (1/4), Gnoll Warrior (1/2). Do herói (humanos): Bandit (1/8), Guard (1/8), Cultist (1/8), Tough (1/2), Scout (1/2, arco), Priest Acolyte (1/4), Bandit Captain (2). Mortos-vivos com sombreado em cima do herói: Skeleton (1/4), Zombie (1/4). Variar por ambiente.
- Fases 6 a 10: ambientes novos (sugestão: Caverna, Mina, Cripta, Montanha, Covil); a fase 5 deixa de ser a última.
- A contagem de inimigos não aparece na missão (as emboscadas são secretas).
- **(Feito: Ankheg, chefe da fase 3, 2026-11-09; saldo do SpriteCook: 262.)** Falta validar a sensação no jogo (tamanho da arte, tempo do aviso da terra, dificuldade do Borrifo). Próximos chefes: Minotaur (fase 6), Wight (fase 9), Ettin (fase 10). Ainda sem animação de **morte** própria do Ankheg (usa o dissolver) nem de **escavar/emergir** (usa a terra e a mordida); o cuspe da arte sobe a cabeça e o jato é desenhado à frente.
