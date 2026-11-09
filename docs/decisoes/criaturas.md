# Decisões: criaturas e a arena

Parte da tabela de decisões do projeto (índice no `CLAUDE.md`). **Atualize aqui quando uma
decisão deste tema mudar.** Passo a passo de criatura nova em `docs/receitas.md` (receita 1).

| Decisão | Escolha | Por quê |
|---|---|---|
| Criaturas | Bloco de estatísticas do livro em `CriaturaRPG` (`core/dados/`): CA, dados de vida (vida = média, se não rolar), atributos, salvaguardas, iniciativa, deslocamento, percepção, resistências, Forma Corrosiva, ataque (nome, bônus, dano, tipo, alcance, corrói armadura), **arremesso** (quantidade, alcances, arma), **disparo** (quantidade, nome, alcances, dano, tipo; menor que 0 = munição não acaba), **Furtividade** (se tem, o bônus, e um dado extra quando o ataque tem vantagem) e **Fuga Ágil**. | Usar as criaturas do D&D em vez de inventar números. |
| Gray Ooze | `features/gray_ooze/`, ficha `data/gray_ooze.tres`: CA 9, PV 22 (3d8+9), iniciativa −2, 10 pés, Visão às Cegas 60 pés, Pseudópode +3 / 2d8+1 **ácido** / 5 pés que **corrói armadura**, **resistências** ácido/frio/fogo, **Forma Corrosiva** −1 por toque até −5. Estados Parado -> Perseguindo -> Atacando (janela 0,2-0,35 s) -> LevandoDano -> Morrendo; Caído achata. Arte: **SpriteCook** (folhas `ooze_*_sc.png`, SpriteFrames por `tools/gerar_monstros_spritecook.gd`); morte por código (`DissolverComponent`). A arte CC0 antiga do rvros ficou sem uso. Pode sair nos encontros das cinco fases. Ainda **não**: Amorfo. | Ficha do livro. |
| Goblin Minion | `features/goblin/` (`Goblin`, ficha `data/goblin_minion.tres`): CA 12, 7 PV (2d6), iniciativa +2, 30 pés, Visão no Escuro 60 pés, Adaga +4 / 1d4+2 perfurante, **Furtividade +6**. Começa em **Escondido** (invisível, sem colisão e sem hurtbox). Quando o herói entra na visão, rola Furtividade contra a Percepção passiva, uma vez e sem mostrar o dado. Abaixo da passiva: aparece e persegue. Alcançou: só aparece no corpo a corpo, já em Atacando, e esse primeiro golpe tem vantagem. Estados Escondido -> Parado -> Perseguindo -> Atacando (janela 0,1-0,3 s) / **Arremessando** (3 adagas, 20/60 pés: arremessa com o alvo fora do corpo a corpo e dentro dos 60; `AdagaGoblin` mira no peito na força do alcance longo, desvantagem além de 20, cai no longo) -> **Desengajando** (Fuga Ágil: depois de cada golpe recua 15 pés em Disparada, olhando para o alvo) -> LevandoDano (pisca 0,25 s) -> Morrendo; Caído deita girando. Arte: **SpriteCook** (folhas `minion_*_sc.png`, por `tools/gerar_monstros_spritecook.gd`; arremesso na animação `arremessar`); morte por código (`DissolverComponent`). A arte CC0 antiga ficou sem uso. Pode sair nas três primeiras fases ou vir pelo Trazer. | Pedido do usuário. |
| Goblin Warrior | Mesma máquina e o mesmo script `Goblin`, outra cena (`goblin_guerreiro.tscn`) e ficha `data/goblin_warrior.tres`: CA 15 (couro + escudo; o escudo não bloqueia), 10 PV (3d6), iniciativa +2, 30 pés, Visão no Escuro 60 pés. Cimitarra +4 / 1d6+2 cortante / 5 pés. Longe, **Arco Curto** +4 / 1d6+2 perfurante / 80/320 pés (`FlechaGoblin`; flechas não acabam; desvantagem além de 80, cai no 320; um tiro por rodada, 1,5 s). A visão é 60 pés. **A menos de 20 pés** ele guarda o arco e fecha para a cimitarra. Fuga Ágil igual ao Minion, só depois da cimitarra. A mesma Furtividade +6 e o mesmo Escondido do Minion. **+1d4** de dano quando o ataque tem vantagem (cimitarra e arco; no crítico esse dado também dobra). Esconder de novo no meio da luta ainda não existe. Arte: **SpriteCook** (folhas `warrior_*_sc.png`, por `tools/gerar_monstros_spritecook.gd`; tiro na animação `disparar`); morte por código (`DissolverComponent`). A arte CC0 antiga ficou sem uso. Pode sair a partir da Ruína ou vir pelo Trazer. | Pedido do usuário. |
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
