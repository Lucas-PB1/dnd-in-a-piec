# Decisões: criaturas e a arena

Parte da tabela de decisões do projeto (índice no `CLAUDE.md`). **Atualize aqui quando uma
decisão deste tema mudar.** Passo a passo de criatura nova em `docs/receitas.md` (receita 1).

| Decisão | Escolha | Por quê |
|---|---|---|
| Criaturas | Bloco de estatísticas do livro em `CriaturaRPG` (`core/dados/`): CA, dados de vida (vida = média, se não rolar), atributos, salvaguardas, iniciativa, deslocamento, percepção, resistências, Forma Corrosiva, ataque (nome, bônus, dano, tipo, alcance, corrói armadura), **arremesso** (quantidade, alcances, arma), **disparo** (quantidade, nome, alcances, dano, tipo; menor que 0 = munição não acaba), **Furtividade** (se tem, o bônus, e um dado extra quando o ataque tem vantagem) e **Fuga Ágil**. | Usar as criaturas do D&D em vez de inventar números. |
| Gray Ooze | `features/gray_ooze/`, ficha `data/gray_ooze.tres`: CA 9, PV 22 (3d8+9), iniciativa −2, 10 pés, Visão às Cegas 60 pés, Pseudópode +3 / 2d8+1 **ácido** / 5 pés que **corrói armadura**, **resistências** ácido/frio/fogo, **Forma Corrosiva** −1 por toque até −5. Estados Parado -> Perseguindo -> Atacando (janela 0,2-0,35 s) -> LevandoDano -> Morrendo; Caído achata. Arte: **SpriteCook** (folhas `ooze_*_sc.png`, SpriteFrames por `tools/gerar_monstros_spritecook.gd`); morte por código (`DissolverComponent`). A arte CC0 antiga do rvros ficou sem uso. Pode sair nos encontros das cinco fases. Ainda **não**: Amorfo. | Ficha do livro. |
| Goblin Minion | `features/goblin/` (`Goblin`, ficha `data/goblin_minion.tres`): CA 12, 7 PV (2d6), iniciativa +2, 30 pés, Visão no Escuro 60 pés, Adaga +4 / 1d4+2 perfurante, **Furtividade +6**. Começa em **Escondido** (invisível, sem colisão e sem hurtbox). Quando o herói entra na visão, rola Furtividade contra a Percepção passiva, uma vez e sem mostrar o dado. Abaixo da passiva: aparece e persegue. Alcançou: só aparece no corpo a corpo, já em Atacando, e esse primeiro golpe tem vantagem. Estados Escondido -> Parado -> Perseguindo -> Atacando (janela 0,1-0,3 s) / **Arremessando** (3 adagas, 20/60 pés: arremessa com o alvo fora do corpo a corpo e dentro dos 60; `AdagaGoblin` mira no peito na força do alcance longo, desvantagem além de 20, cai no longo) -> **Desengajando** (Fuga Ágil: depois de cada golpe recua 15 pés em Disparada, olhando para o alvo) -> LevandoDano (pisca 0,25 s) -> Morrendo; Caído deita girando. Arte: **SpriteCook** (folhas `minion_*_sc.png`, por `tools/gerar_monstros_spritecook.gd`; arremesso na animação `arremessar`); morte por código (`DissolverComponent`). A arte CC0 antiga ficou sem uso. Pode sair nas três primeiras fases ou vir pelo Trazer. | Pedido do usuário. |
| Goblin Warrior | Mesma máquina e o mesmo script `Goblin`, outra cena (`goblin_guerreiro.tscn`) e ficha `data/goblin_warrior.tres`: CA 15 (couro + escudo; o escudo não bloqueia), 10 PV (3d6), iniciativa +2, 30 pés, Visão no Escuro 60 pés. Cimitarra +4 / 1d6+2 cortante / 5 pés. Longe, **Arco Curto** +4 / 1d6+2 perfurante / 80/320 pés (`Flecha`, em `core/projeteis/`, compartilhada com o Wight; flechas não acabam; desvantagem além de 80, cai no 320; um tiro por rodada, 1,5 s). A visão é 60 pés. **A menos de 20 pés** ele guarda o arco e fecha para a cimitarra. Fuga Ágil igual ao Minion, só depois da cimitarra. A mesma Furtividade +6 e o mesmo Escondido do Minion. **+1d4** de dano quando o ataque tem vantagem (cimitarra e arco; no crítico esse dado também dobra). Esconder de novo no meio da luta ainda não existe. Arte: **SpriteCook** (folhas `warrior_*_sc.png`, por `tools/gerar_monstros_spritecook.gd`; tiro na animação `disparar`); morte por código (`DissolverComponent`). A arte CC0 antiga ficou sem uso. Pode sair a partir da Ruína ou vir pelo Trazer. | Pedido do usuário. |
| Monstros na campanha | Cada fase oferece pontos e tipos permitidos; `Armadilha` sorteia pontos sem repetir e um tipo por ponto até completar a cota. Ooze e Minion podem sair nas três primeiras fases; Warrior entra a partir da Ruína. A `main` define alvo e Percepção passiva, e acompanha a morte dos inimigos da cota. A porta só avança quando a cota acaba. "Tentar de novo" repõe a vida e sorteia a fase atual outra vez; a semente pode ser fixada nos testes. | Reaproveitar as criaturas em encontros variados sem colocar uma feature dentro de outra. |
| Criatura na arena | Tela de comandos (C), lista **Combate**: Gray Ooze, Goblin Minion e Goblin Warrior. **Trazer** põe uma cópia à frente do herói (15 pés) e a `main` chama `definir_alvo`. **Tirar da arena** apaga o grupo `monstros` e libera a porta. As criaturas trazidas não entram na cota nem voltam no "Tentar de novo". | Pedido do usuário. |
| Boneco de treino | `features/boneco_treino/`: CA 10, mostra dano/Errou!, pisca e balança, não perde vida. | Testar golpes. |

## Missão da fase
- Cada fase tem um título (`Fase.missao`: "Limpe a clareira", "Abra a trilha"...). A `Missao` (regra pura) conta as mortes da cota: a HUD mostra "Título: derrote todos os inimigos" (sem a quantidade: as emboscadas são secretas) e, ao cumprir, fica verde com "Vá até a porta" e o herói avisa "Missão cumprida!". A porta já cobra a cota.
- Próximo: o tipo "derrote o chefe" (fases 3, 6, 9 e 10) e outros objetivos (sobreviver, alcançar), quando houver chefes.

## Minions novos (fichas conferidas com o usuário no Códice, Monster Manual 2024)
Fonte: `history-lilac.vercel.app`, arquivos `Monster Manual/09 - Monsters (H).md`, `03 - Monsters (B).md`, `12 - Monsters (K).md`. Arte grátis: recolorir/escalar a do Goblin.
| Criatura | ND | CA | PV | Vel. | FOR/DES/CON/INT/SAB/CAR | Ataques e traços |
|---|---|---|---|---|---|---|
| Hobgoblin Warrior (Fey, Leal e Mau) | 1/2 | 18 | 11 (2d8+2) | 30 pés | 13/12/12/10/10/9 | Espada Longa +3, 1,5 m, 12 (2d10+1) cortante; Arco Longo +3, 45/180 m, 5 (1d8+1) perfurante + 7 (3d4) veneno; **Táticas de Matilha** (vantagem se aliado a 1,5 m do alvo e não Incapacitado). Iniciativa +3. |
| Bugbear Warrior (Fey, Caótico e Mau) | 1 | 14 | 33 (6d8+6) | 30 pés | 15/14/13/8/11/9 | **Agarrar** +4, alcance 3 m, 9 (2d6+2) concussão, alvo Médio ou menor fica Agarrado (CD 12); Martelo Leve +4 (vantagem se alvo Agarrado), 3 m ou 6/18 m, 9 (3d4+2) concussão; **Abduzir** (move agarrado sem custo extra). Iniciativa +2. |
| Kobold Warrior (Dragon, Neutro) | 1/8 | 14 | 7 (3d6−3) | 30 pés | 7/15/9/8/7/8 | Adaga +4, 1,5 m ou 6/18 m, 4 (1d4+2) perfurante; **Táticas de Matilha**; **Sensibilidade à Luz Solar** (desvantagem em ataques e testes ao sol; só vale em fases de dia). Iniciativa +2. |
- O usuário confirmou a Espada Longa do Hobgoblin (2d10+1, sem veneno) como está no Códice.
- **No código:** cenas herdadas em `features/goblin/` (`hobgoblin_guerreiro` do Warrior, `bugbear_guerreiro` e `kobold_guerreiro` do Minion), com `criatura`, `escala_arte`, `cor_corpo` e caixas de colisão próprios. Tipo novo = cena + uma linha em `Main.CENAS_DOS_TIPOS` + o nome em `Fase.tipos_permitidos`.
- **Táticas de Matilha** (`TaticasDeMatilha`): aliado `Goblin` em pé (nem Caído nem morto) a 5 pés do alvo dá vantagem ao ataque. **Luz do Sol:** `Fase.luz_do_sol` (fases 1 e 2); a main avisa cada monstro; o Kobold ataca com desvantagem.
- **Bugbear:** o acerto de Agarrar usa a condição Agarrado que já existia (CD 12, escape por rodada). O Martelo Leve arremessado tem dano próprio (3d4+2). **Ainda não feito:** Abduzir (mover o agarrado sem custo) e a vantagem do Martelo Leve contra Agarrado, e o Martelo Leve em corpo a corpo.
- **Hobgoblin:** o "mais 7 (3d4) de veneno" do Arco Longo entra como dano extra do golpe (`EfeitoDanoAdicional`), sem resistência separada. O ouro dos três (8, 15, 2) é decisão do jogo, não do livro.
- A arte é a do Goblin só recolorida (retratos do bestiário ficam sem a cor). Arte própria seria pago.

## IA: saltar obstáculos, vãos e quedas (Goblin e variantes)
- Regra pura `core/regras/salto_dnd.gd` (`SaltoDnd`) + sensor `core/utilitarios/sensor_de_terreno.gd` + estado `Pulando`
  (`features/goblin/estados/estado_goblin_pulando.gd`). Na perseguição, ao bater numa parede ou chegar numa beira, o
  Goblin sonda o chão à frente (passo de 8 px) e decide: **subir** um degrau, **atravessar** um vão ou **descer** uma queda.
- Números do livro: salto em distância = Força em pés; em altura = 3 pés + mod. de Força (com corrida, que a perseguição dá).
- **Regras da casa (aprovadas pelo usuário em 2026-11-09):** o monstro agarra a borda com os braços (+3 pés ao degrau que sobe);
  desce até 15 pés sem se machucar, e só quando o alvo está pelo menos 24 px abaixo (ou a queda é de até 1 ladrilho).
  Não há dano de queda para monstros.
- Resultado: Força 8 (Goblin) sobe 1 ladrilho; Força 7 (Kobold) não; Hobgoblin (13) e Bugbear (15) sobem 1 ladrilho e
  atravessam vãos de 13 e 15 pés (83 e 96 px).
- Não feito: Gray Ooze (script próprio), Patrulha e Fuga Ágil continuam parando na beira; cobertura contra ataques à
  distância e escolha de estratégia são as próximas fatias da IA.

## IA: cobertura contra ataques à distância
- A main avisa os monstros quando o herói atira ou arremessa (`perceber_disparo(origem)`). Se o monstro percebe o herói,
  não está no corpo a corpo nem a menos de 3 ladrilhos, ele procura abrigo (`quer_cobertura`): ponto a até 6 ladrilhos,
  alcançável a pé, onde uma parede corta a linha entre o tiro e o peito dele (`BuscaDeAbrigo` + regra `Abrigo`).
- Estado `Cobrindo`: corre (Disparada) até o abrigo; já protegido, fica onde está. Espera o herói ficar 2 s sem atirar
  (máx. 5 s) ou chegar ao corpo a corpo, e volta a perseguir.
- Arqueiros e arremessadores só atiram com a linha livre (`pode_atirar`/`pode_arremessar` olham o mundo): não gastam
  flecha na parede.
- Limite: o abrigo tem de ser alcançável andando; paredes que bloqueiam o caminho não servem (pular para o abrigo fica para depois).

## IA: estratégia (manter distância e recuar ferido)
- Regra pura `EstrategiaDeMonstro` + estado `Afastando`. Vale a distância quando o ataque à distância da ficha bate
  pelo menos tanto quanto o corpo a corpo (`CriaturaRPG.dano_medio_a_distancia`, soma o dano adicional): hoje Goblin
  Warrior, Hobgoblin, Kobold e Goblin Minion.
- Decisão do usuário: **recua enquanto for vantajoso; se o herói chegar perto (corpo a corpo), usa a espada.** Ou seja:
  com o herói a menos de 20 pés mas fora do alcance da arma, recua na Disparada (até 1 s, a cada 1,5 s, só se tiver
  chão e espaço atrás) e volta a atirar; encostou, luta de perto; encurralado, luta.
- Ferido (1/3 da vida ou menos) e com aliado em pé a até 8 ladrilhos: recua até 8 ladrilhos do herói (até 3 s), uma vez por vida.
- Não feito: esperar em vantagem de terreno.

## IA: flanqueio (só manobra)
- Decisão do usuário: **flanquear não dá vantagem no ataque**; é só uma estratégia de posição.
- Quando um aliado já segura o herói de perto (corpo a corpo) do MESMO lado em que este monstro está, a menos de
  8 ladrilhos, ele corre (Disparada) para o lado oposto do herói, passando por ele (monstros não colidem com o herói),
  e volta a perseguir (estado `Flanqueando`, regra `Flanqueio.lado`). No máximo uma manobra a cada 6 s; ferido não flanqueia.

## Chefe da fase 3: Ankheg (Monster Manual 2024, ficha conferida com o usuário no Códice, `Monster Manual/02 - Monstros (A)`)
Monstruosidade Grande, Imparcial · **ND 2 (450 XP)** · CA 14 · **PV 45 (6d10+12)** · 30 pés, escavação 10 pés · FOR 17 DES 11 CON 14 INT 1 SAB 13 CAR 6 · Visão no Escuro e Sentido Sísmico 60 pés · iniciativa +0.
- **Mordida:** +5 (**vantagem se o alvo está Agarrado** por ele), 1,5 m, 10 (2d6+3) cortante + 3 (1d6) ácido; alvo Grande ou menor fica **Agarrado (CD 13)**.
- **Borrifo Ácido (Recarga 6):** salvaguarda de Destreza CD 12, linha de 30 pés x 5 pés, 14 (4d6) ácido, metade se passar.
- **Escavador de Túneis:** atravessa rocha à metade da escavação; no jogo é a mecânica "cava, avança por baixo e emerge".
- **No código:** `features/ankheg/` (`ankheg.gd`, cena, 8 estados, arte SpriteCook em `sprites/`). Ficha em `data/ankheg.tres`; o Borrifo e a escavação são campos novos da `CriaturaRPG` (`linha_*`, `escavacao_pes`).
- **Luta (decisões de jogo, não do livro):** Perseguindo decide: cavar (herói a 150 px ou mais, a cada 9 s) → morder (ao alcance) → borrifar (herói na linha de 30 pés, Borrifo recarregado) → andar. Cavando: toca a animação `cavar`, então some (sem colisão nem hurtbox), avança por baixo no deslocamento de escavação **em Disparada** (20 pés/rodada) e a terra mexendo é o aviso; Emergindo: 0,6 s de tremor e marca vermelha no ponto, então **salta da terra** (física, 460 px/s para cima, animação `saltar` presa no quadro de subida) e cai no mesmo x; ao pousar, a animação `pousar` é o bote e a mordida acerta nos quadros 2–4, **sem aviso e com vantagem**, com tela tremendo. **Borrifo em área de verdade:** o jato dispara da boca (cresce em 0,12 s) com gotas de ácido e respingo no fim da linha, e acerta **todos** na linha, inclusive outros monstros (cada um rola a própria salvaguarda), nunca o próprio Ankheg (`HitboxComponent.atinge_todos` e `ignorar`). **Só cava onde há terra:** chão contínuo até o herói (degrau e paredão contam como terra, vão não); barrado por degrau alto demais para o salto, **cava por baixo e sai em cima**; com vão no caminho, anda e **salta vãos, degraus e quedas como os goblins** (`SaltoDnd`, estado `Pulando`), e a escavação emerge ao fim da terra. Arte do salto, pouso e cavar: SpriteCook (48 créditos); do `saltar` só os quadros 0–3 servem (os 4–7 têm a altura pintada no quadro). A recarga rola 1d6 a cada rodada (volta com 6). Chefe não "se assusta" com golpe (só pisca); Derrubar o deita.
- **Missão:** `Fase.chefe` (`&"ankheg"`) + marcador `Chefe` na fase; o chefe entra na cota da porta e a missão vira "derrote o Ankheg" (`Missao.chefe`). A HUD mostra a barra de vida dele no alto (`Hud.mostrar_chefe`).

## Chefe da fase 6: Minotauro de Baphomet (Monster Manual 2024, `Minotaur of Baphomet`, ficha sem a regra da casa do atordoamento)
Monstruosidade Grande, Caótica e Má · **ND 3 (700 XP)** · CA 14 · **PV 85 (10d10+30)** · 40 pés · FOR 18 DES 11 CON 16 INT 6 SAB 16 CAR 9 · iniciativa +0.
- **Glaive Abissal:** +6, alcance **10 pés**, 1d12+4 cortante + 3d6 necrótico (o necrótico entra no mesmo dano, sem tipo separado).
- **Chifrada (Recarga 5-6):** +6, 4d6+4 perfurante; se **correu 10 pés ou mais em linha reta** antes do acerto, soma 3d6 e o alvo fica **Caído** (efeito `Derrubada`). O livro dá ainda o atordoamento ao bater na parede; **não está no jogo** (decisão do usuário, 2026-11-09).
- **No código:** `features/minotauro/` (`minotauro.gd`, cena, 6 estados: Parado, Perseguindo, Atacando, Investindo, Caido, Morrendo). Ficha em `data/minotauro.tres`; a Chifrada é o grupo `chifrada_*` da `CriaturaRPG` e `golpe_chifrada(com_carreira)`. Arte SpriteCook (base + parado, investida, chifrada, glaive; 90 créditos; quadros de 190 px, escala 0,9): **a `andar` falhou** (queda do provedor) e a caminhada usa os quadros 5-8 da investida; falta gerar a `andar` própria.
- **Luta (decisões de jogo):** Perseguindo decide: **investir** (Chifrada pronta e herói entre 126 e 446 px, na mesma altura e com chão à frente) → **glaive** (herói a 94 px ou menos) → andar. A Chifrada rola 1d6 a cada rodada (volta com 5 ou 6). Investindo: aviso de 0,6 s (agacha e brilha), corre em **Disparada** (80 pés/rodada) até 320 px; os chifres ligam sem carreira e **passam a somar o dano e derrubar ao completar 64 px**; ao acertar, dá o bote (animação `chifrada`) e treme a tela; errando (parede, queda ou 320 px) fica cansado 0,9 s. Atacando: aviso de 0,6 s e o golpe na janela 0,46–0,62 s da animação.
- **Blocos quebráveis** (`features/bloco_quebravel/`, grupo `quebravel`, sólidos como o chão): a **investida os quebra** e segue em frente (carga com bloco no caminho não para); encostado num bloco com o herói fora do alcance do glaive, ele o **golpeia** (senão o herói se esconderia atrás do pilar e o chefe ficaria preso). A área de impacto é `Area2D` **sem `monitorable = false`** (com ele a área não enxerga corpos). Cada quebra treme a tela (4 px; a Chifrada que acerta, 7 px).
- **Herói derrubado:** ver `regras_dnd.md` (estado `Caido` do herói).
- **Fase 6 (Labirinto):** arena de chão reto nas colunas 44 a 61 (`tools/gerar_fase_teste.gd`, chaves `chefe` e `quebraveis`): o chefe espera na coluna 56, com dois pilares de 2 blocos nas colunas 49 e 52; cota de 4 inimigos mais o chefe; a porta só abre quando ele cai. O Minotauro **não salta** (a arena não tem degrau); fora da arena ele só anda.

## Chefe da cripta: Corpo Seco (Wight) (Monster Manual 2024, `Wight`; fase 9)
Morto-vivo Médio, Neutro e Mau · **ND 3 (700 XP)** · CA 14 · **PV 82 (11d8+33)** · 30 pés · FOR 15 DES 14 CON 16 INT 10 SAB 13 CAR 15 · iniciativa +4 · resistente a necrótico · Sensibilidade à Luz Solar (`sensivel_ao_sol`, desvantagem na fase de dia).
- **Ataques Múltiplos:** dois ataques por ação (`Wight.ATAQUES_POR_ACAO`), cada um Espada Necrótica, Arco Necrótico ou Drenar Vida (substitui um ataque).
- **Espada Necrótica:** +4, 5 pés, 1d8+2 cortante + 1d8 necrótico (o necrótico entra no mesmo dano, sem tipo separado). **Arco Necrótico:** +4, 150/600 pés, 1d8+2 perfurante + 1d8 necrótico; usa a `Flecha` de `core/projeteis/`.
- **Drenar Vida:** salvaguarda de Constituição CD 13, 1d8+2 necrótico; quem falha também perde o **máximo de PV** em igual valor (`HealthComponent.reduzir_maximo`, efeito `EfeitosDeTalento.DrenarVida`); volta no descanso longo (`Jogador.descansar_longo`). O humanoide morto virar Zumbi em 24 h não existe.
- **Não modelado:** imunidade a veneno/exaustão (a ficha não tem imunidades ainda).
- **Acompanhantes:** ao perceber o herói pela primeira vez (sinal `despertou`), a `main` faz surgirem os tipos de `Fase.acompanhantes_do_chefe` perto dele, só pra parecer invocação (sem regra da casa): não contam na cota nem na missão, mas dão XP e ouro. **Pendente:** hoje são 2 Goblin Minion no lugar de Skeleton/Zombie, que ainda não existem.
- **Luta (decisões de jogo):** Perseguindo escolhe: ao alcance, ataca de perto (50% de cada ataque é Drenar Vida); longe (mais de 128 px, com linha de tiro e 85% de vontade, sorteada a cada ação) atira; senão anda. Aviso de 0,35 s (brilho verde) antes da sequência.
- **No código:** `features/wight/` (`wight.gd`, cena, 6 estados: Parado, Perseguindo, Atacando, Atirando, Caido, Morrendo), `data/wight.tres`, `data/bestiario/wight.tres`. Arte do SpriteCook (base, parado, andar, espada, arco, drenar; 88 créditos).
- **Fase 9 (Cripta):** `tools/gerar_fase_teste.gd` (chaves `chefe` e `acompanhantes`), arena de chão reto, ele espera na coluna 44. É a última fase por enquanto (o Ettin virá na 10).

## Conferência das fichas com o livro (2026-11-09)
Todos os mobs foram conferidos com o Códice (CA, PV, atributos, ataques, alcances, XP, traços). Só divergia:
- **XP:** Goblin Minion era 50 (livro: **25**, ND 1/8) e Goblin Warrior 100 (livro: **50**, ND 1/4). Corrigidos.
- **Imunidades** (faltavam): Gray Ooze é imune a **Caído, Agarrado e Preso** (e a Cego, Enfeitiçado, Surdo, Exaustão, Amedrontado, que o jogo não tem); Wight é imune a **veneno** (dano) e à condição **Envenenado**. Modelado em `CriaturaRPG.imunidades_dano` / `imunidades_condicoes`, aplicado por `DefesaComponent.imunidades` e `CondicoesComponent.imunidades` (aviso "Imune!").
- **Não modelado:** Escalada 10 pés do Gray Ooze (ele pula em vez de escalar), Forma Amorfa, Abduzir do Bugbear, Sentido Sísmico do Ankheg.
- Percepção do Wight é 120 pés (o livro tem Visão no Escuro 60): de propósito, para o arco valer na arena.
- **Salto:** todos os monstros que andam (Goblin e variantes, Ankheg, Gray Ooze, Minotauro, Wight) saltam degraus, vãos e quedas pelo mesmo `SaltadorDeMonstro` (`core/componentes/`) e a regra `SaltoDnd` (altura e distância pela Força).
