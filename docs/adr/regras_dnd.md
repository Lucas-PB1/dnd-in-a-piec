# Decisões: regras de D&D 5e (PHB 2024)

Parte da tabela de decisões do projeto (índice no `CLAUDE.md`). **Atualize aqui quando uma
decisão deste tema mudar.** Contas puras em `core/regras/`; testes em `tests/teste_regras_dnd.gd`
e `tests/teste_combate_dnd.gd`.

| Decisão | Escolha | Por quê |
|---|---|---|
| Regras de D&D 5e | Classes puras em `core/regras/`: `Dado` ("1d6", "2d8+1"), `Atributos` (mod = (valor-10)/2 para baixo), `CompraDePontos` (27 pts, 8 a 15, custos do livro), `Ficha` (vida, dano, ataque, CA, maestrias, perícias), `Pericia`. | Testável sem abrir o jogo. |
| Vida | Nível 1 = **dado de vida máximo da classe + mod. CON** (Guerreiro d10, `data/classe_guerreiro.tres`). Mínimo 1. `HealthComponent`: dano, `vida_mudou`, `morreu`. | Regra do livro; usuário escolheu d10. |
| Níveis e XP | Campanha até o nível 8 (ver abaixo). Marcos: 0, 300, 900, 2700, 3600, 4800, 6000, 7200 XP. Cada nível após o primeiro acrescenta o valor fixo médio do d10 (6) + CON aos PV máximos e atuais. A cota da fase concede XP por criatura (Goblin 50, Ooze 100, Warrior 100); o nível aumenta na hora. A criação pode começar em qualquer nível até o máximo. | PHB 2024; simplificado à faixa da campanha. [Progressão de personagem](https://www.dndbeyond.com/sources/dnd/br-2024/creating-a-character). |
| Progressão do Guerreiro | Proficiência +2 até o nível 4 e +3 do 5 em diante. Fôlego segue com 2 usos; cura 1d10 + nível. **Subclasse no nível 3:** Campeão (ver abaixo). Talentos gerais nos níveis **4, 6 e 8**. | PHB 2024. |
| Subclasse Campeão (nv 3) | Escolha em `Ficha.subclasse` / `SubclasseRPG` (`data/subclasses/`). **Crítico Aprimorado:** `Golpe.limiar_critico` 19 (crítico se acertou e d20 ≥ limiar; 20 natural sempre acerta). **Atleta Notável:** “vantagem em iniciativa” = **+proficiência** (regra de casa, igual Alerta; **não empilha**); vantagem em Atletismo; após crítico, meio deslocamento livre (OA não existe no jogo). **Nível 7 — Estilo Extra:** capacidade **3** estilos (`Additional Fighting Style`). | PHB 2024; iniciativa pedida pelo usuário. |
| Surto de Ação | A partir do nível 2, uma vez por fase, o próximo ataque corpo a corpo sai **em dobro**: dois golpes seguidos, cada um com a sua rolagem (aproxima do livro, onde o Surto dá uma ação extra e o Ataque pode ser feito de novo). Recarrega no **descanso curto ou longo** (ver Descansos). | Pedido do usuário; difere um pouco do PHB 2024 (só o ataque dobra). |
| Descansos | **Curto** ao sair de fase **sem** chefe: Fôlego, Sorte, Surto e ação bônus; **não** enche PV nem tira drenar (Drenar Vida). **Longo** ao sair de fase **com** chefe, ao morrer (“Tentar de novo”), ao **subir de nível** e ao começar/continuar: PV cheio, máximo restaurado, Fôlego, Surto, dados de vida e veneno. | Regra da casa (opção 1, 2026-11-10); mais duro entre chefes, generoso na morte. |
| Mente Tática | A partir do nível 2, ligada (tecla T ou botão) tenta automaticamente 1d10 depois de uma falha em teste de habilidade. O teste inclui o d10; só consome um uso de Fôlego se virar sucesso. Desligado, não rola o dado. O resolvedor está em `Pericia`. Na campanha: `DesafioPericia` (ex.: pedra na Clareira, Atletismo CD 12) chama `Jogador.rolar_teste_pericia`. | PHB 2024; automatização do gasto escolhida pelo usuário. |
| Desafio de perícia | `features/desafio_pericia/`: obstáculo com E; a `main` rola e chama `concluir(passou)`. Sucesso remove o bloqueio; falha tem recarga curta. Toque: rótulo **Usar**. | Pedido do usuário. |
| Dano | **Dados da arma + mod.** Arma com `acuidade` usa o maior entre FOR e DES. À distância usa DES. **Mínimo 1** por acerto. | Livro; mínimo 1 é regra da casa. |
| Combate | **d20 + bônus de ataque >= CA do alvo** acerta (`Combate.resolver_ataque`). **20 natural** sempre acerta. **Crítico** se acertou e d20 ≥ `Golpe.limiar_critico` (padrão 20; Campeão 19): dados de dano em dobro, bônus não. **1 natural** erra sempre. Quem ataca monta um `Golpe`; quem é atingido resolve contra a própria CA no `DefesaComponent`. Herói: ataque = proficiência (+2) + mod. da arma. Textos flutuantes: dano, "Errou!", "Crítico X!" (`TextoFlutuanteComponent`). | Escolha do usuário (fiel ao D&D). |
| Vantagem e desvantagem | 2d20, o maior ou o menor; as duas juntas se anulam (`Combate.rolar_d20`). | Livro. |
| Salvaguarda | `Combate.passou_salvaguarda(bonus, cd)`: d20 + bônus >= CD. Bônus = mod. + proficiência se proficiente (Guerreiro: FOR e CON, `ClasseRPG.salvaguardas_proficientes`). Usada pelo Derrubar (CON da criatura). | Pedido do usuário. |
| Escala D&D | `EscalaDnd`: **5 pés = 1 ladrilho (32 px)**; **1 rodada = 1,5 s**. **Movimento = deslocamento da ficha**: 30 pés ≈ 128 px/s (Disparada 256), 10 pés ≈ 43 px/s. **Ritmo de ataque = iniciativa em tiques**: intervalo = (10 − iniciativa) × 0,1 s, mínimo 3 tiques. Herói: iniciativa = mod. DES (+2 -> 0,8 s); criatura: campo `iniciativa` da ficha. Buffer de ataque do herói (`tempo_buffer_ataque`). Sem raças: deslocamento padrão 30 pés (`Ficha.DESLOCAMENTO_PADRAO_PES`). **Força de tiro e arremesso**: velocidade de saída = raiz(g × alcance longo) (`velocidade_para_alcance`). | Pedido do usuário. |
| Tipos de dano | `TiposDano`: contundente, cortante, perfurante, ácido, frio, fogo. Espada Curta perfurante (como no livro), soco contundente, Pseudópode ácido. O `Golpe` leva o tipo. **Resistência** (`DefesaComponent.resistencias`): metade, arredondada para baixo (pode dar 0); o texto mostra "(resistiu)". | Pedido do usuário. |
| Proficiências | `Proficiencias`: armas **simples/marcial** e armaduras **leve/média/pesada/escudo**. `ClasseRPG.proficiencias_armas` e `treinamento_armaduras` (Guerreiro: tudo). `Arma.categoria` (vazio = desarmado, sempre proficiente). **Arma sem proficiência: não soma o +2** (`Ficha.proficiente_com`). A ficha escreve "prof. +2" (ou "sem prof."); o item avisa "Sem proficiência". | Livro. |
| Estilo de Luta | Guerreiro escolhe **1 estilo** na criação (`data/estilos/`, `EstiloDeLutaRPG`). Do **nível 2**: capacidade **2** e **uma troca** por nível (`Ficha.escolha_de_estilo_pendente`; pausa). **Campeão nv 7:** capacidade **3**. 18 estilos. **Rajada**: toggle R; ligada abre mão de qualquer vantagem no C/C por 2º alvo perto. **Disparo Duplo**: 1º tiro com desvantagem libera 2º K imediato também com desvantagem. | Pedido do usuário (2026-11-11). |
| Maestrias | O Guerreiro domina **3 tipos de arma** (`ClasseRPG.quantidade_maestrias`), escolhidos no 5º passo da criação. `Ficha.armas_dominadas`, `domina`, `maestria_de`, **CD = 8 + mod. do ataque + prof.** O `Golpe` leva `maestria`, `cd_maestria`, `dano_raspao`, `trespassar`, `autor_id`, `vantagem`. **Um golpe acerta UM alvo** (o mais perto). **Trespassar** (acertou: 2º alvo a até 5 pés do 1º leva outro ataque, dano sem mod. positivo); **Raspão** (errou: dano = mod.); **Corte Duplo** (golpe extra J J não gasta a ação bônus; sem ele, o extra é 1 por rodada); **Empurrar** (10 pés) e **Derrubar** (salvaguarda de CON; falhou = Caído) só em alvo **Grande ou menor** (`CriaturaRPG.tamanho`; Enorme+ avisa "Grande demais!"); **Enfraquecer** (próximo ataque do alvo com desvantagem); **Lentidão** (−10 pés por 1 rodada, se causou dano; não acumula); **Atormentar** (próximo ataque de quem marcou com vantagem). "Até o próximo turno" = 1 rodada (1,5 s). | PHB 2024; escolhas do usuário. |
| Condições | `CondicoesComponent` (Ooze, Goblin, boneco): **Caído** (meia rodada deitado = levantar gasta metade do deslocamento; ataques contra ele com **vantagem**), **Lento**, **Enfraquecido**, **Atormentado**. Ícones 8x8 acima do alvo (`assets/efeitos/condicoes.png`) e avisos no texto flutuante (textos que saem juntos empilham). | Escolhas do usuário. |
| Talentos | Lista viva em `docs/reference/talentos.md` (ligados vs em espera). Origem vem do antecedente; gerais nos níveis **4, 6 e 8**. **30 talentos escolhíveis ligados** (efeitos em `features/jogador/talentos/` e `EfeitosDeTalento`). Magia e o resto em espera: abrir na fatia correspondente. | Pedido do usuário. |
| Desarmado | Mão vazia = `data/ataque_desarmado.tres` ("1d1" + FOR = soco, contundente, não sofre Corrosão, alcance curto, sem sprite de arma). | Livro. |

## Níveis 4, 6 e 8 e talentos
- Cada um desses níveis dá uma escolha de talento geral ou o Aumento no Valor de Atributo (+2, ou +1 em dois). Origem vem do antecedente na criação.
- `Ficha.escolhas_de_talento_pendentes()`, `pode_escolher_talento()` e `escolher_talento()` guardam o **id** em `ficha.talentos` e somam o aumento (teto 20). Só entram os gerais com situação planejada (`TalentoRPG.escolhivel()`). Atributos/perícias por talento: `tools/gerar_compendio.gd`.
- Efeitos ligados: ver seções abaixo e `docs/reference/talentos.md`.

## Talentos de origem (efeitos ligados)
- `Ficha` guarda o **id** do talento (`TalentoRPG.id`, não o nome de tela) e aplica: Alerta em `iniciativa()`, Resistente em `vida_maxima()`, Brigão de Taverna em `dado_dano()` (soco = arma sem categoria) e nas marcas do `Golpe` (`rerrolar_um`, `empurrao_pes`), Atacante Selvagem na marca `selvagem`.
- Efeitos "uma vez por rodada" (1,5 s): o `Golpe` avisa `efeito_usado`; o herói começa a recarga e desliga a marca no golpe seguinte enquanto recarrega (`Jogador._recarga_efeito`).
- Sortudo: `Jogador.armar_sorte()` (tecla G, botão da barra). O próximo golpe do herói sai com vantagem, ou o próximo teste de perícia falho rola de novo; gasta 1 ponto. Salvaguardas do herói ainda não usam a sorte. Artesão: 20% na loja + item aleatório por fase. A defesa do Sortudo (forçar o atacante a rolar pior) não existe.
- Perito: `TelaCriacao` mostra todas as perícias do jogo quando o antecedente dá o Perito; o jogador marca as 2 da classe mais 3 quaisquer, e pelo menos 2 têm de ser da lista do Guerreiro.

## Talentos gerais ligados (lotes 1 e 2)
- Na ficha: Resiliente (`salvaguardas_extras`), Veloz (+10 pés), Mestre em Armadura Média (teto de DES +3), Mestre em Arma Grande (+proficiência no dano da arma Pesada), Aumento de Valor de Habilidade.
- O `Golpe` leva uma lista de `EfeitoDeGolpe` (`core/regras/efeitos/`; cada talento é uma classe em `EfeitosDeTalento`): a `Ficha` monta a lista, o herói tira os efeitos "uma vez por rodada" que ainda recarregam (`por_rodada`), e o alvo e o `Combate` perguntam a cada efeito (`ao_acertar`, `dano_no_alvo`, `rerrola_um`, `rola_duas_vezes`, `dano_extra`). Talento novo = uma classe nova e uma linha em `Ficha._juntar_efeitos_de_talento`.
- O estado dos talentos do herói (Sorte, dados de vida, veneno, janela de defesa, Investida, recargas) vive em classes puras de `features/jogador/talentos/` com teste próprio (`teste_regras_do_heroi`); o `Jogador` só liga com a tela e o corpo. Saves antigos com nomes de talento migram em `Salvamento.id_do_talento`.
- Mestre em Armadura Pesada: `DefesaComponent.reducao_fisica` (o herói liga com armadura pesada vestida). Empunhadura Dupla: `Inventario.segunda_arma_livre`.
- Mestre em Arma Grande: crítico ou abate (`Golpe.resolvido`) deixa um golpe extra pendente, o mesmo mecanismo do Surto de Ação.

## Talentos gerais: lotes 3 e 4
- Condições novas em `CondicoesComponent` (sem ícone, aparecem como aviso): Preso (Sentinela, 1 s, só se o alvo estava se movendo), Agarrado (Agarrador; tentativa de escape a cada rodada, solta se o herói se afasta), Envenenado (Envenenador; `consumir_desvantagem()` devolve true sem gastar). Tipo de dano `veneno` em `TiposDano`.
- No `Golpe`: `sentinela`, `investida_dano`, `escudo_cd`, `agarra`/`agarra_cd`, `veneno_extra`, `veneno_potente`/`veneno_cd`, `corpo_a_corpo`. O herói liga/desliga e cuida das recargas de 1,5 s; o alvo aplica os efeitos.
- Duelista Defensivo: `DefesaComponent.bonus_ca_corpo_a_corpo` na janela de 0,75 s; `aparou` quando o bônus faz um golpe errar. Investida: a corrida em linha reta é medida em `Jogador._corrida_reta_px`. Haste: `Jogador._cabo_da_haste()` é uma `Arma` montada (1d4 contundente). Durável e Envenenador: `Jogador` guarda dados de vida e doses, repostos a cada fase.
- A escalada do Atleta (`Escalando`) e o tiro que atravessa do Atirador de Elite estão prontos.

## Saque e perícias (regra da casa)
- Cada inimigo da cota solta **ouro** (`CriaturaRPG.ouro`, sorteado de 0,5 a 1,5 vezes) e, às vezes, uma **arma** (`Saque`).
- **Intimidação** (bônus passivo): ouro ±10% por ponto (mínimo 50%). **Sobrevivência**: chance de arma 15% + 3% por ponto (entre 5% e 50%).
- **Persuasão**: desconto na loja (2% por ponto positivo; soma com Artesão 20%; teto 50%).
- Subir de nível = **descanso longo**. Percepção passiva vs Furtividade dos goblins já existia.
- A arma cai direto na mochila (se estiver cheia, avisa "Mochila cheia" e se perde). Ouro na HUD e na ficha.

## Salvaguarda no lugar de ataque e herói agarrado (fatia do Ankheg)
- `Golpe.cd_salvaguarda` > 0 faz o alvo **rolar a salvaguarda** do `atributo_salvaguarda` (d20 + bônus da ficha) em vez de o ataque rolar contra a CA: falhou, dano inteiro; passou, metade (`Combate.resolver_salvaguarda`); resistência ao tipo reduz de novo. O herói usa `Defesa.bonus_salvaguardas`, preenchido da `Ficha` ao mudar a ficha.
- **Herói agarrado** (`AgarraoDoHeroi`, regra pura): um golpe com o efeito Agarrar que acerta quem não tem `Condicoes` (o herói) avisa o dono (`Defesa.agarrado`). Agarrado não anda nem pula, mas **pode golpear**. A cada rodada rola Força ou Destreza (o melhor bônus) contra a CD; **pular antecipa a tentativa** depois de meia rodada. Solta se quem agarrou some.

## Herói derrubado (Chifrada do Minotauro)
- O efeito `Derrubada` (`EfeitosDeTalento.Derrubada`) deixa um alvo com `Condicoes` **Caído** (meia rodada). O herói não tem `Condicoes`: `Defesa.derrubado` avisa o dono e o `Jogador` troca para o estado **`Caido`**: é lançado para longe (1,4x o recuo de um golpe comum), fica deitado (sprite girado) sem controle por meia rodada, levanta em 0,3 s e volta a andar ou cair. Dano e invencibilidade são os de um golpe comum.

## Máximo de PV drenado (Drenar Vida do Wight)
- `HealthComponent.reduzir_maximo(q)` corta o máximo (mínimo 1) e a vida atual; `maximo_drenado` guarda o total. Subir de nível respeita o drenado; `restaurar_maximo()` devolve tudo e é chamado no `descansar_longo` do herói. O `DefesaComponent` aplica quando o golpe tem o efeito `DrenarVida` e o alvo falhou na salvaguarda.
- Novo tipo de dano: **necrótico** (`TiposDano.NECROTICO`).

## Níveis 5–8 (regra da casa nos limites de XP)
- A campanha vai até o **nível 8**. XP: 0, 300, 900, 2700 (livro) e **3600, 4800, 6000, 7200** (casa; o livro pede 6500/14000/23000/34000). Com a rampa de mobs, o herói chega alto na campanha; criação pode começar já no 7 ou 8.
- **Bônus de proficiência +3** do nível 5 em diante (`Ficha.bonus_proficiencia()`; a constante `BONUS_PROFICIENCIA` = +2 vale até o nível 4). Sobe ataque, CD, salvaguardas, perícias, Sortudo etc.
- **Ataque Extra (nível 5)**: a ação de Atacar rola **dois golpes** seguidos (`Ficha.golpes_por_ataque()`; cada um com a sua rolagem). Com o **Surto de Ação** a ação inteira dobra: **quatro golpes**. O golpe da outra mão (arma dupla, ação bônus) **não** é multiplicado. Contador `Jogador._golpes_encadeados`; o estado Atacando encadeia os golpes. Crítico/abate do Mestre em Arma Grande soma mais um golpe.
- **Mudança Tática (nível 5)**: usar o Fôlego dá **+15 pés de deslocamento por 3 s** (casa; no livro é um movimento livre sem ataque de oportunidade, que o jogo não tem).
- **Níveis 6 e 8**: escolhas de talento geral (`Ficha.NIVEIS_TALENTO_GERAL` = 4, 6 e 8).
- **Nível 7 (Campeão)**: *Additional Fighting Style* — capacidade de estilos sobe para **3**.
