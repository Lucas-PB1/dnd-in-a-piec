# Changelog

O que já foi feito, em ordem (fatias do jogo). **Acrescente uma linha ao fechar cada fatia.**
O que falta: `docs/backlog/`. Decisões: `docs/adr/` (Diátaxis).

- Áudio: **ambiente por tema** (Floresta / Ruínas / Subterrâneo / Covil) em loop baixo sob a música; some no título, derrota e vitória. WAV sintetizados.
- Áudio: música de **derrota** (Robin Lamb, CC0) ao cair; SFX Kenney de **pegar item** e **equipar** (`Inventario.item_obtido` / `item_equipado`, silêncio em pacote/save).
- Fundos próprios do **Pântano** (Gothicvania Swamp) e da **Ruína** (GothicVania Cemetery), CC0 ansimuz; temas `pantano` e `ruina` em `FundoParalaxe`.
- Refino visual do Goblin Minion (golpe/arremesso SpriteCook): **aceito como está** — a adaga deforma em poucos quadros, mas no ritmo do jogo quase não se nota; sem gastar créditos nem editar pixel.
- Lava no Covil (fase 10): poças com **1d6 de fogo** a cada rodada enquanto o herói está em cima; `Combate.resolver_ambiente` + feature `lava`. Teste `teste_lava`.
- IA dos monstros: patrulha e Fuga Ágil saltam beiras; atirador/arremessador em vantagem de terreno (≥ 1 ladrilho) fica e ataca à distância. Testes em `teste_salto_monstros` e `teste_estrategia`.
- Desafio de perícia na Clareira: pedra com teste de **Atletismo** (E / Usar); Mente Tática pode intervir; sucesso remove o bloqueio. Feature `desafio_pericia`; teste `teste_desafio_pericia`.
- Subclasse do Guerreiro no nível 3: **Campeão** (Crítico Aprimorado 19–20, Atleta Notável com +prof na iniciativa sem empilhar com Alerta, vantagem em Atletismo, meio deslocamento após crítico). Resource SubclasseRPG, tela de escolha, save. Teste: `teste_subclasse_campeao`.
- Fatias 1 e 2 (2.5D): boneco na relva e herói do SpriteCook. Substituídas pela fatia 3 (commits `60f2dda` e `0b1ca2b`).
- Fatia 3: herói andando e pulando numa fase de teste em 2D lateral.
- Fatia 4: skills de código limpo, corrida com dois toques (animação provisória), fase reta, herói refatorado em física + componente visual.
- Skills godot-* criadas e código migrado: novas pastas, máquina de estados do herói, `StatsJogador` em `data/`, sem `get_parent()`, fase com API própria.
- Fatia 5: golpe de espada (J) no chão e no ar, arma como dado e sprite separado, Hitbox/Hurtbox, boneco de treino. Tentativa de usar pacote pronto (Hero Knight) foi cancelada e limpa.
- Fatia 6a: ficha de D&D (compra de pontos, vida d10 + CON, dano 1d6 + FOR/DES), tela de criação, HUD de vida.
- Fatia 6b: inventário (Item, Inventario, tela com I), espada começa na mochila, soco desarmado.
- Fatia 6c: espada equipada sempre na mão (ponto da mão por quadro), golpe girando a partir da mão.
- Fatia 7: tela de título "DnD in a Piece", criação com nome e classe, nome no HUD e no inventário.
- Fatia 8: combate de D&D (d20 contra CA, crítico, salvaguardas na ficha), Gray Ooze com a ficha do livro, herói leva dano/recua/pisca/reaparece.
- Ajuste: movimento pelo deslocamento de D&D e ritmo de ataque pela iniciativa (tiques).
- Fatia 9: "Você caiu!" com Tentar de novo; tipos de dano (espada perfurante, soco contundente, Pseudópode ácido); resistências do Ooze; Corrosão da arma.
- Proficiências de armas (efeito no ataque) e de armaduras (só na ficha da classe por enquanto).
- Fatia 10: 21 armaduras + escudos com as regras do livro, escolha na criação, armadura visível no herói, corrosão de armadura.
- Fatia 11a: 29 armas do PHB (dados + sprites provisórios), Versátil/Duas Mãos/Pesada/Alcance, pilhas, pacotes A e B na criação, baú do arsenal (E).
- Fatia 11b: duas armas leves (J J; a 2ª na outra mão), arremesso com K (cai no chão, E pega), escudo na frente do corpo. Pacote B já equipa Cimitarra e Espada Curta.
- Golpes das armas: arte do pacote CC0 Idylwild, golpe próprio para cada uma das 29 armas, área de acerto seguindo a arma, alcance de 5/10 pés com passo de estocada.
- Menus com ícones 16x16; Mangual e Chicote com quadros desenhados.
- Efeitos de golpe por tipo: arco, rastro e impacto.
- Fatia 11c: maestrias de arma (3 na criação), condições com ícones, vantagem/desvantagem, um alvo por golpe + Trespassar, Raspão, Corte Duplo.
- Revisão: duas armas (2ª atrás do corpo, extra em X), escudo seguro pela mão de trás, camada da mão por cima da arma, arremesso com carga (normal/longo), voo por tipo e queda no alvo.
- Armadura visível só na túnica (ladrilho do material). Sem ombro, peitoral, saia nem elmo por cima do corpo.
- Second Wind do Guerreiro (F): cura 1d10+1, 2 usos por luta, ação bônus, HUD «Fôlego 2/2». «Tentar de novo» devolve os usos.
- Tela de comandos (C): ver e trocar teclas (salvo em `user://comandos.cfg`) e trazer ou tirar o Gray Ooze. O trazido não volta no «Tentar de novo».
- Armas à distância do livro base: 9 armas, munição, K com mira (W/S), pacote B com Arco Longo e 20 flechas. Atirador de Elite e Especialista em Besta no tiro (`docs/reference/talentos.md`); a ficha começa sem talento.
- Disparo: quadros por arma; a munição escolhe a curva; a Destreza (referência 14) limita o teto da carga e o tempo para encher. Azagaia e dardo continuam no arremesso de Força.
- Disparo revisto: pose de mira no peito (montada das artes do herói), mão por cima da empunhadura e 8 quadros por arma (arcos, bestas, funda, zarabatana, pistola, mosquete).
- Armas à distância com a arte do Aerial Arsenal (CC0): arcos inclinados para a frente, bestas do pacote, pistola e mosquete de pederneira em pixel art e quadro de descanso.
- Força do tiro por arma: velocidade de saída pelo alcance longo do livro, impulso e peso por munição (antes todas as armas pareciam iguais na tela).
- Goblin Minion (ficha do livro): arremessa 3 adagas, golpeia de perto e Desengaja com a Fuga Ágil. Na tela de comandos (C -> Trazer).
- Goblin Warrior (ficha do livro): cimitarra de perto, arco curto de longe (flechas não acabam) e a mesma Fuga Ágil. Arte CC0 do Goblin Corps. Esconder e o +1d4 com vantagem ficam para a Furtividade.
- Goblins no mapa: Minion em x = 2176 e Warrior em x = 2752, cada um além dos 60 pés de visão de quem está antes, e fora dos tiros de teste. "Tentar de novo" recria os dois junto com o Ooze.
- O Goblin Warrior não metralha de perto: a menos de 20 pés guarda o arco e fecha para a cimitarra; de longe o tiro espera uma rodada (1,5 s). O Second Wind pinta o herói de verde e o número da cura sobe maior.
- Perícias e emboscada: o Guerreiro escolhe 2 perícias na criação (abre com Percepção e Atletismo). Os goblins começam escondidos e rolam Furtividade contra a Percepção passiva, sem mostrar o dado. Se a rolagem fica abaixo, aparecem a 60 pés; se alcança, só aparecem no corpo a corpo, já atacando, e esse golpe tem vantagem. O Warrior soma 1d4 quando o ataque tem vantagem.
- Guias para IA: `docs/reference/artes_prontas.md`, `docs/reference/arquitetura.md`, `docs/how-to/receitas.md`; regras do Cursor geradas das skills (`tools/gerar_regras_cursor.ps1`).
- Celular (fatia 1): tela larga (aspect expand), celular deitado, controles de toque (analógico ou setas + botões), correr segurando (Shift / borda do analógico).
- Celular (fatia 2): ajustar os controles de toque (arrastar, tamanho, transparência, Padrão, salvo).
- Organização: decisões divididas por tema em `docs/adr/`, pendências em `docs/backlog/`, comandos e agentes para Claude e Cursor.
- Campanha: cinco fases (Clareira, Trilha, Pântano, Ruína e Fortaleza) com buracos, plataformas e ambientes próprios; encontros sorteados por pontos e cota; portas avançam após derrotar a cota; vitória ao concluir a Fortaleza. Coberta por `tests/teste_campanha.gd` (fases prontas, porta barra e abre pela cota, vitória e "Jogar de novo").
- Progressão do Guerreiro nos níveis 1–3: escolha de nível inicial, XP por inimigo, marcos de 300/900 XP, PV por nível, Second Wind 1d10 + nível, escala aleatória da cota por nível e descanso longo ao trocar de fase. No nível 2 entram o Surto de Ação (imobiliza os inimigos por 1 s, uma vez por fase) e o toggle de Mente Tática (d10 automático após falha, só gasta Fôlego ao passar). Inclui controle de toque e testes em `tests/teste_progressao.gd`.
- Celular (fatia 3): botões virtuais propagam eventos para Bolsa, Menu e baú; inventário e comandos têm botão Fechar; controles somem enquanto as telas pausam. Pulo durante ataque, movimento durante golpe, alvos menores ampliados e nome no HUD com mais espaço. `tests/teste_toque.gd` cobre toque simultâneo, botões de ação e telas.
- Monstros: aviso antes do golpe (brilho de 0,35 s) no goblin e no Ooze, e patrulha dos goblins. Coberto por `tests/teste_comportamento.gd`.
- Monstros: tremor ao levar dano e sombra no chão (Minion, Warrior e Ooze), por script. Pacotes de arte pesquisados: nenhum CC0 melhor (o slime do rvros já é o do Ooze; o pacote completo de goblins do IvoryRed é pago).
- Mapas: fundos em camadas (parallax) de floresta e fortaleza, arte CC0 do ansimuz, um tom por fase. Coberto por `tests/teste_campanha.gd`.
- Mapas: chão recortado dos pacotes CC0 e relevo nas cinco fases (degraus, plataformas altas, pontos de armadilha extras), com teste de alcance pelo pulo. A Clareira ficou com 40 ladrilhos.
- Herói: corrida nova do SpriteCook (10 quadros) no lugar do andar acelerado. Golpe de teste do SpriteCook guardado em `heroi_ataque_teste.png`, sem uso ainda.
- SpriteCook: 42 pedidos prontos e conferidos (`docs/spritecook/`), testados no servidor com saldo zero; plano de animações e economia em `docs/spritecook/`.
- Sensação dos golpes por código (`levels/impacto.gd`): pausa no acerto, tremor de câmera, faíscas e poeira ao correr e pousar; vale para todo monstro novo. Coberto por `tests/teste_impacto.gd`. (prévia visual removida; o efeito ficou no código).
- SpriteCook: assinatura ativa (800 créditos). Tileset de chão de floresta (12 créditos, `assets/tiles/spritecook/chao_floresta.png`, ligado ao chão das fases de floresta pelo `tools/gerar_arte_provisoria.gd`) concluiu a missão "Make a tileset". Saldo: 788.
- Mapas: o chão da floresta sorteia 3 peças de relva e 4 de terra do tileset do SpriteCook (por posição, sempre igual na mesma célula). Colunas extras do atlas 4 a 8; as outras fases repetem o ladrilho normal.
- SpriteCook: corte de cima do herói gerado (20 créditos, `heroi_corte_cima.png`) e reprovado na conferência: quadros 1-2 viram de frente, 3-5 saem como comemoração e uma espada aparece. Saldo 828 (768 da assinatura + 60 avulsos, provavelmente o bônus da missão).
- SpriteCook: 2ª tentativa do corte de cima (`heroi_corte_cima_v2.png`, vista de corrida): corpo de lado, mas uma espada sai desenhada nos quadros 2-4 e o golpe não desce de forma clara. Custou 32 (20 + 12 do preparo de corrida, que eu não tinha contado). Saldo 796.
- SpriteCook: base do Goblin Minion gerada (12 créditos, `features/goblin/sprites/minion_base_spritecook.png`) e aprovada: goblin de lado, adaga na mão direita, traço limpo. Saldo 784. Animações ainda não pedidas.
- Morte por código (`core/componentes/dissolver_component.gd`): goblins e Ooze não usam mais animação de morte. Clarão branco com pausa e tremor, o corpo some de uma vez e sai uma explosão de fragmentos e fumaça (cor da pele por criatura). Corrigido junto: partículas sem textura saíam com 1 px, então as faíscas e a poeira do Impacto ficaram maiores. (prévia visual removida).
- SpriteCook: rodada do Goblin Minion (88 créditos, saldo 696): parado, andar e dano aprovados; golpe e arremesso parciais (adaga deformada em alguns quadros). Folhas em `features/goblin/sprites/minion_*_sc.png`, ainda não ligadas ao jogo.
- SpriteCook: rodada do Goblin Warrior (88 créditos): as cinco folhas aprovadas (parado, andar, dano, golpe de cimitarra e tiro de arco), em `features/goblin/sprites/warrior_*_sc.png`. Base do Gray Ooze (12) aprovada; rodada do Ooze (62: parado, deslizar, pseudópode e dano) em geração. Saldo previsto 522. Nada ligado ao jogo ainda.
- SpriteCook: rodada do Gray Ooze (62 créditos, saldo 522): parado e dano aceitos, deslizar parcial, pseudópode reprovado. Folhas em `features/gray_ooze/sprites/ooze_*_sc.png`, ainda não ligadas.
- SpriteCook: pseudópode do Ooze refeito (20 créditos, saldo 502): agora o punho de gosma vai para a direita (`ooze_pseudopode2_sc.png`), com uns arcos de movimento pequenos acima da cabeça.
- Monstros com a arte do SpriteCook (`tools/gerar_monstros_spritecook.gd`): Minion, Warrior e Ooze agora usam as folhas novas (parado, correr, golpe, dano, arremesso/tiro). Escalas 0,55 / 0,65 / 0,7; o ataque à distância usa a animação `arremessar` ou `disparar` (campo `animacao_distancia`). A arte antiga CC0 ficou nos arquivos, sem uso. O Ooze agora olha para a direita (flip invertido).
- Menus: tema novo com a arte CC0 do Kenney Pixel UI; menu de pausa (Esc ou Menu), Salvar e Continuar (`Salvamento`), Opções em abas, Esc que volta um nível em todo menu e três distribuições de atributos do Guerreiro. Testes: `teste_salvamento`, `teste_pausa`, `teste_telas_cabem`.
- Bestiário: menu clássico pela pausa, com silhueta até a primeira derrota e a ficha do livro depois; o save guarda as derrotas. Três páginas (Gray Ooze, Minion e Warrior). Distribuições do Guerreiro com INT 10 em média e pesada. Teste: `teste_bestiario`.
- Árvore de habilidades: menu pela pausa, com as habilidades do Guerreiro em colunas por nível, linhas de dependência e descrição (Segundo Fôlego, Maestrias, Treinamento, Perícias, Surto de Ação, Mente Tática e a Subclasse em breve). A pausa virou uma grade de dois botões por linha. Teste: `teste_habilidades`.
- Menus (2ª leva): árvore de habilidades refeita em linhas por nível, sem fios; toque com menos botões (Bolsa saiu, e Surto, Lançar e E só aparecem quando servem), maiores e sem sobreposição; HUD com barras e só com o que o herói tem; Opções no título. Fonte pixel testada e descartada. Testes: `teste_toque_layout`, `teste_botoes_contextuais`.
- Toque (3ª leva): Atacar, Pular e Lançar fixos; botão pequeno Abrir/Pegar só perto do baú ou de uma arma caída (sem a letra E); habilidades especiais numa barra de atalhos em arco com 6 slots, configurável na aba Atalhos das Opções. Teste: `teste_botoes_contextuais`.
- Habilidades (Surto, Fôlego, Mente Tática): o Surto de Ação agora acende uma aura e faz o próximo ataque sair em dobro (dois golpes seguidos, cada um com a sua rolagem), sem precisar de inimigo; Fôlego com anel e faíscas verdes; Mente Tática virou botão (tecla T) e as skills ativas ficam acesas na barra, e as desligadas, avermelhadas. `AuraComponent`. Teste: `teste_surto`.
- SpriteCook: golpe do herói pelo preset attack (20 créditos, saldo 482, `heroi_ataque_preset.png`): sem arma desenhada, mas é um soco e o corpo vira de frente nos quadros 4-5. Ainda não ligado.
- SpriteCook: 4ª tentativa do golpe do herói pela ferramenta de animar imagem, com a lista de proibições (20 créditos, saldo 462, `heroi_corte_v4.png`): sem arma desenhada, os punhos sobem acima da cabeça e descem à frente. O melhor resultado até agora; ainda não ligado.
- Golpe de corte do herói ligado ao jogo: animação `corte` (SpriteCook, 4ª tentativa) nas armas de corte, com o quadro seguindo o tempo do golpe de cada arma e a arma presa à mão. (prévia visual removida).
- SpriteCook: dano (8 quadros) e morte (12 quadros) do herói pelas receitas hurt e death (34 créditos, saldo 428), aprovados. Folhas em `features/jogador/sprites/heroi_dano_sc.png` e `heroi_morte_sc.png`.
- Herói: animações de dano e morte do SpriteCook ligadas. A tela "Você caiu!" agora aparece depois da animação de morte (1,4 s). Teste: `teste_heroi_dano_morte`.
- Som e música: efeitos nos golpes, pulo, habilidades, morte, menus e passos (pacotes CC0 da Kenney mais sons feitos por script), três músicas CC0 com transição suave entre fases e aba Som nas Opções (volume de música, efeitos e menus). Teste: `teste_som`.
- Compêndio: abertura pelo menu inicial e pela pausa; abas geradas só para conteúdo disponível (Guerreiro e habilidades, pacotes iniciais, maestrias, armas, armaduras/escudos e munições). Antecedentes e talentos seguem documentados em `data/`, mas ficam ocultos até serem acessíveis no jogo. Teste: `teste_compendio`.
- Nível 4 e escolha de talento: o limite da campanha subiu para o nível 4 (2700 XP) e a criação ganhou a opção "Nível 4". No nível 4 o herói tem uma escolha de talento geral (ou o Aumento de Valor de Habilidade, 2 pontos): `TelaTalento` abre sozinha ao subir de nível, e a pausa ganha o botão "Escolher talento" enquanto a escolha estiver pendente. A `Ficha` valida (talento geral e planejado, atributos permitidos, teto 20) e o save guarda a escolha. Os talentos escolhíveis são os 23 gerais marcados como planejados; os efeitos ainda não estão ligados. Teste: `teste_talento`.
- Antecedente na criação: passo novo "Antecedente" depois de "Quem é você", com os 11 antecedentes liberados, o aumento de atributo do livro (+2/+1 entre os 3 listados ou +1 nos três, somado depois da compra de pontos, teto 20), as 2 perícias dele (já marcadas e travadas; o Guerreiro escolhe as 2 dele entre as que sobram) e o talento de origem na ficha (só o nome por enquanto). `Ficha.antecedente` e o save guardam. A criação não deixa avançar com o passo incompleto (nome, pontos gastos, perícias, armas). No celular, o primeiro "voltar" com o nome em edição só fecha o teclado e o teclado não sobe sozinho ao abrir a tela. O Compêndio passou a mostrar a aba Antecedentes. Testes: `teste_criacao`, `teste_pausa`, `teste_compendio`.
- Talentos de origem funcionando: **Alerta** (+proficiência na iniciativa, ataque mais rápido), **Resistente** (+2 PV por nível), **Atacante Selvagem** (dano rolado duas vezes uma vez por rodada), **Brigão de Taverna** (soco 1d4 + FOR, rerrola 1, empurra 5 pés), **Sortudo** (2 pontos por fase, tecla G e botão "Sorte" armam a próxima rolagem com vantagem; linha "Sorte" no HUD), **Artesão** (item aleatório do arsenal a cada fase nova) e **Perito** (3 perícias à escolha no passo Perícias). Cada efeito foi confirmado com o usuário. O Compêndio mostra a aba Talentos com os 7. Teste: `teste_talentos_origem`, mais casos em `teste_criacao`.
- Talentos gerais, lote 1: **Resiliente** (proficiência na salvaguarda do atributo escolhido; só num atributo sem proficiência), **Veloz** (+10 pés) e **Mestre em Armadura Média** (teto de Destreza +3); o **Aumento de Valor de Habilidade** já valia. A tela de talento apaga os atributos que não servem. Teste: `teste_talentos_gerais`. O Compêndio mostra 11 talentos.
- Talentos gerais, lote 2: **Mestre em Arma Grande** (proficiência no dano da arma Pesada; crítico ou abate dá um golpe extra como o do Surto), **Mestre em Armadura Pesada** (-2 de dano físico com armadura pesada), **Cortador** (Lento; crítico dá desvantagem), **Perfurador** (rerrola o menor dado; crítico +1 dado), **Esmagador** (empurra 5 pés; crítico dá vantagem) e **Empunhadura Dupla** (segunda arma sem precisar ser Leve). Efeitos por rodada usam a recarga de 1,5 s do herói. `Golpe.resolvido` avisa crítico e abate. O Compêndio mostra 17 talentos.
- Talentos gerais, lote 3 (parte 1), conferido no PHB 2024 em português do site: **Mestre em Escudos** (golpe de escudo automático depois do acerto, salvaguarda de Força do alvo, empurra 5 pés ou derruba, alternando; uma vez por rodada), **Atirador de Elite** (também sem desvantagem com inimigo a 5 pés), **Especialista em Bestas**, **Observador** e **Especialista em Perícia** (a tela de talento ganhou os seletores de perícia e a ficha ganhou Especialização). Correções do livro: Mestre em Armas Grandes só dá +1 Força e o golpe extra vale com qualquer arma corpo a corpo; Combatente com Duas Armas exige atacar com uma arma Leve. Os talentos agora usam os nomes do livro em português (saves antigos migram). O Compêndio mostra 22 talentos.
- Talentos gerais, lote 3 (parte 2): **Sentinela** (acerto num alvo em movimento o deixa preso 1 s; condição Preso), **Duelista Defensivo** (botão B: janela de 0,75 s com +proficiência na CA contra golpe corpo a corpo, parry com efeito e som quando o bônus faz errar; espera de 1 s; só com arma de acuidade; flecha e adaga de goblin não contam), **Investida** (botão V alterna dano 1d8 e empurrão 10 pés; vale depois de correr 10 pés em linha reta, uma vez por rodada; a corrida fica 10 pés mais rápida; linha no HUD), **Mestre em Armas de Haste** (com Bordão, Lança ou arma Pesada com Alcance, o 2º J dá o golpe extra de 1d4 contundente com a outra ponta, na ação bônus) e **Atleta** (+5 pés, sem perder o controle ao levar um golpe; a escalada de paredes ficou para o cenário). O Compêndio mostra 27 talentos. Teste: `teste_talentos_lote3`.
- Controles de toque maiores e longe das bordas: botões e slots com raio 30 a 40 (antes 26 a 34), analógico 58, folga mínima de 20 px da borda (`MARGEM_BORDA`; também empurra para dentro o que o jogador salvou colado na borda) e folga extra para recortes e barras do sistema no celular. Os botões Defesa e Investida entram nos slots. Teste: `teste_toque_layout` confere margem e sobreposição.
- Talentos gerais, lote 4: **Agarrador** (o soco acertado agarra: condição Agarrado, sem deslocamento, escape a cada rodada contra CD 8 + FOR + prof., vantagem para o herói, solta se o herói se afasta), **Durável** (um dado de vida por nível; tecla H gasta um como ação bônus e cura o valor rolado; voltam a cada fase) e **Envenenador** (2 doses de veneno por fase; tecla N passa na arma; acerto: salvaguarda de CON ou 2d8 de veneno e Envenenado, com desvantagem nos ataques; tipo de dano veneno). Novo item **Veneno Básico** (`data/itens/`, no baú; +1d4 de veneno, só arma cortante ou perfurante; dura 15 s ou até o primeiro acerto). HUD: linhas Dados de vida e Veneno. A barra de atalhos do celular passou a ter 8 slots. O Compêndio mostra 30 talentos. Teste: `teste_talentos_lote4`.
- Atleta e Atirador de Elite completos, mapa fechado e porta de verdade: o **Atleta escala paredes** (estado `Escalando`: empurrando contra uma parede o herói sobe na velocidade de andar, sem limite de altura; no topo passa a quina; Pular solta da parede), o tiro do **Atirador de Elite atravessa** paredes, degraus e criaturas (cada uma uma vez) e só some no chão ou em 5 s (`ArmaArremessada._mover_atravessando`). A `Fase` agora **fecha o mapa** com laterais e um teto invisíveis (`Limites`, três planos no mundo) e desenha **a porta de verdade** na saída: arco de madeira em pixel art, recorte da folha de castelo do rubberduck (CC0, `assets/tiles/castelo/`, `tools/recortar_porta.gd`, creditada em `assets/CREDITOS.md`). Teste: `teste_escalada`.
- Auditoria e correções pequenas: `main._ha_menu_aberto()` (um lugar só para "há tela aberta", corrigindo duas checagens que esqueciam telas), a defesa do Duelista fecha ao cair ou reviver, `tela_talento` sem `get_parent()`, constante do alcance do agarrão, testes dos limites do mapa (laterais e teto) e docs atualizados (`CLAUDE.md`, aviso no `docs/reference/talentos.md`).
- Refatoração da auditoria: talentos por id na ficha e no save (migração de nomes antigos); `TesteBase` único (`tests/apoio_teste.gd`) para os testes; runner paralelo (`rodar_testes.ps1`, 3 testes ao mesmo tempo, `-Paralelo 1` volta ao sequencial: a suíte caiu de ~12 min para ~2 min); estado dos talentos do herói em seis classes puras (`features/jogador/talentos/`, com `teste_regras_do_heroi`); o `Golpe` perdeu os 17 campos "um por talento" e passou a carregar uma lista de `EfeitoDeGolpe` (`core/regras/efeitos/`).
- Inventário e golpe extra (em andamento): a 2ª arma vira a principal quando a principal sai (`Inventario._promover_segunda_arma`); a tela de inventário ganhou slots de equipamento (Mão principal, Mão secundária, Corpo, com selos P/S/C e cores iguais na lista) e a Ficha virou cartões e barras (`SlotsDeEquipamento`, `FichaVisual`, `EstiloCartao`). SpriteCook: 1ª tentativa do golpe extra de duas armas (`heroi_corte_duplo_v1.png`, 20 créditos, saldo 408): parcial, não ligada ao jogo.

- 2ª tentativa da animação do golpe extra (duas armas): `heroi_corte_duplo_v2.png` (SpriteCook, 20 créditos, saldo 388). Sempre de lado e sem arma, melhor que a v1; ainda não ligada ao jogo.
- Pose de guarda com duas armas (`heroi_guarda_dupla_v1.png`, 20 créditos, saldo 368): quase igual ao idle; não ligada ao jogo. A guarda atual é feita por código (lâminas erguidas).

- Épico 10 fases, fatia 1: ouro e saque. `Saque` (regra pura), `Ficha.ouro` (salvo), `CriaturaRPG.ouro`, HUD "Ouro", chip "po" na ficha, arma de saque na mochila; Carisma melhora ouro e chance de arma. Também: cada atributo explica o que faz (`Atributos.DESCRICOES`; dica na criação e na ficha, por toque ou mouse).
- Épico 10 fases, fatia 2: armas mágicas +1/+2/+3 (`Arma.bonus_magico`, brilho de cor, sem Corrosão, save e saque).
- Épico 10 fases, fatia 3: loja no início da fase (`Loja`, `Lojista`, `TelaLoja`; comprar, vender, estoque por fase, desconto do Artesão). Arte do lojista pelo SpriteCook: personagem (12) e animação parado (20); saldo 336.
- Épico 10 fases, fatia 4: missão por fase (`Missao`, título em `Fase.missao`, linha na HUD, aviso ao cumprir).
- Épico 10 fases, fatia 5: minions novos (Hobgoblin, Bugbear e Kobold Warrior) com as fichas do livro conferidas no Códice. Cenas herdadas do Goblin (`hobgoblin_guerreiro`, `bugbear_guerreiro`, `kobold_guerreiro`) com outra cor (`Goblin.cor_corpo`) e escala; `CriaturaRPG` ganhou dano adicional (veneno do Hobgoblin), agarrar (Bugbear, CD 12), arremesso com dano próprio (Martelo Leve) e os traços Táticas de Matilha (`TaticasDeMatilha`) e Sensibilidade à Luz Solar (`Fase.luz_do_sol`). A main escolhe a cena pelo mapa `CENAS_DOS_TIPOS`. Entram na campanha (Kobold nas fases 2–3, Hobgoblin na 4–5, Bugbear na 5), no bestiário e na tela de comandos. Arte grátis (recolor), sem créditos.

## Fatia: Hobgoblin com arte própria (Gemini) e IA que salta
- Hobgoblin Warrior com arte gerada no Gemini, limpa por `tools/montar_tiras_gemini.gd` e montada por
  `tools/montar_frames_gemini.gd` (animações parado, correr, atacar, disparar; dano por código).
- Monstros (Goblin e variantes) saltam degraus, atravessam vãos e descem quedas atrás do alvo (`SaltoDnd`,
  `SensorDeTerreno`, estado `Pulando`); teste `tests/teste_salto_monstros.gd`.
- IA dos monstros: cobertura contra tiros do herói (`Abrigo`, `BuscaDeAbrigo`, estado `Cobrindo`) e estratégia
  (`EstrategiaDeMonstro`, estado `Afastando`: manter distância e recuar ferido). Testes `teste_cobertura.gd` e `teste_estrategia.gd`.
- `tests/rodar_testes.ps1` ganhou limite de tempo por teste (mata o travado e reprova).
- IA dos monstros: flanqueio em grupo (estado `Flanqueando`, só manobra, sem vantagem). Teste `teste_flanqueio.gd`.
- Bugbear Warrior com arte própria (Gemini): correr, agarrar, parado e arremessar; limpeza de franja nas tiras.
- Kobold Warrior com arte própria (Gemini): correr, estocada, parado e arremessar. Os três minions novos têm arte própria.
- Primeiro chefe, o Ankheg (fase 3): ficha do livro, arte do SpriteCook (base + parado, andar, mordida, cuspe; 74 créditos), mordida que agarra o herói (ele tenta escapar a cada rodada, pular antecipa), Borrifo Ácido por salvaguarda de Destreza, escavação com emboscada, missão "derrote o Ankheg", barra de vida do chefe e entrada no bestiário e em Trazer. Teste `teste_ankheg.gd`. Depois de jogar: a saída do chão virou um salto de verdade que cai no ponto marcado (marca vermelha, terra, tremor de tela) e ganhou as animações `cavar`, `saltar` e `pousar` (48 créditos); `tools/abrir_fase.gd` abre o jogo direto numa fase (`-- 3`).
- Segundo chefe, o Minotauro de Baphomet (fase 6): ficha do livro (sem o atordoamento), arte do SpriteCook (base, parado, investida, chifrada, glaive; 90 créditos, `andar` falhou e fica pendente), Glaive Abissal de 10 pés e Chifrada em investida (com 10 pés de corrida soma 3d6 e derruba o herói, que ganhou o estado `Caido`), blocos quebráveis (`BlocoQuebravel`) que a investida e o glaive quebram, arena de chão reto na fase 6 e barra de vida do chefe. Corrigido de passagem: a fase antiga sai da árvore na hora ao trocar de fase (o colisor velho empurrava o chefe que nascia longe). Teste `teste_minotauro.gd`.
- Terceiro chefe, o Corpo Seco (Wight), na fase 7 provisória (Cripta): ficha do livro, espada, arco (flecha extraída para `core/projeteis/flecha`), Drenar Vida que reduz o máximo de PV até o descanso longo, dano necrótico, acompanhantes que surgem ao despertar (`Fase.acompanhantes_do_chefe`), arte do SpriteCook (88 créditos), `tests/teste_wight.gd`.
- Fases 7 (Mina) e 8 (Caverna Úmida) criadas; a Cripta do Wight virou a 9 (última por enquanto). Wight mais agressivo só na IA (50% Drenar Vida, 85% de vontade de atirar, aviso de 0,35 s). Imunidades (Gray Ooze, Wight), XP dos goblins corrigido, salto compartilhado (`SaltadorDeMonstro`) para todos os mobs.
- Chefe final, a Quimera (fase 10, Covil): ficha do livro (Cabeçada que derruba, Mordida com 4d6+4 com vantagem, Garra, Sopro de Fogo em cone com recarga 5-6 que toma o lugar da Garra), arte do Gemini (parado, andar, armar, ataque, sopro, pular, voar, morte, dano, rugido), estados Rugindo/Atacando/Soprando/Pulando/Caido/Morrendo, rugido de entrada, fase 10 gerada (arena larga, fundo avermelhado), bestiário e Trazer. `teste_quimera.gd`; `teste_campanha` e `teste_regras_dnd` com 10 fases. O voo e a lava ficaram pendentes.
- Quimera mais viva (2026-11-10): padrões Bote, Investida de cabeçada, Voo com Mergulho (estados Bote, Investindo, Voando, Mergulhando), escolha por distância sem repetir, fúria abaixo de metade da vida (rugido, recargas e aviso mais curtos), golpes "Bote" e "Mergulho" que derrubam; `tests/teste_quimera.gd` cobre os quatro.
- Minotauro: animação `andar` própria (8 quadros, SpriteCook, 20 créditos, saldo 32), no lugar dos quadros emprestados da investida.
- Skeleton (ND 1/4, 2026-11-10): ficha conferida no Códice, arte do Gemini (parado, andar, golpe, arco, morte), vulnerável a contundente (regra nova `vulnerabilidades`), animação de morte nos Goblins, fases 8, 9 e 10 e acompanhantes do Wight; `tests/teste_skeleton.gd`. 
- Zombie (ND 1/4, 2026-11-10): ficha conferida no Códice, arte do Gemini (parado, andar, pancada, morte), Fortitude dos Mortos-Vivos (regra nova na `DefesaComponent`, com `TiposDano.RADIANTE`), Cripta (fase 9) e acompanhante do Wight; `tests/teste_zombie.gd`.
- Rampa de mobs por fase (2026-11-10): fase 1 ganha Kobold; Mina (7) = Ooze, Warrior, Bugbear, Skeleton; Caverna (8) = Ooze, Warrior, Bugbear, Skeleton, Zombie; Covil (10) = Warrior, Hobgoblin, Bugbear, Skeleton, Zombie (sem Ooze, a mais difícil); Cripta e fases 2 a 6 como estavam. As constantes do `tools/gerar_fase_teste.gd` agora refletem o que está nas cenas. `teste_campanha` fecha a tela de talento (o nível 4 chega antes da vitória).
- Níveis 5 e 6 do Guerreiro: Ataque Extra (2 golpes por ataque, 4 com Surto; a arma da outra mão não dobra), Mudança Tática (Fôlego dá +15 pés por 3 s), proficiência +3, segundo talento no nível 6, XP 3600/4800 (regra da casa). Contador `_golpes_encadeados` no herói; testes em `teste_surto`, `teste_progressao`, `teste_talento`.
- Sons dos monstros e chefes: golpe das criaturas, rugido ao despertar e ao morrer, tremor do chão (sintetizados em `tools/gerar_sons.gd`); música das fases 6–10 (OpenGameArt CC0).

## Fatia: faxina pós-auditoria (docs, limpeza, sons, hardening, sprites)
- Docs sincronizados com o código: 10 fases, nível 1–6, chefes (Ankheg/Minotauro/Wight/Quimera), loja, talentos ligados (`CLAUDE.md`, `arquitetura.md`, `base.md`, `criaturas.md`, `talentos.md`, `pendencias.md`, `CREDITOS.md`).
- Limpeza: pastas vazias `export_templates/` e `feature_profiles/`; APKs antigos (só `dnd_in_a_piece.apk` + `.idsig`); pipelines `fonte_gemini/` removidos do Git.
- Bug em `levels/sons.gd`: `is_connected` com `Callable.bind` novo a cada vez (rugido/clique duplicáveis); corrigido com métodos estáveis + `_sinal_ja_tem`.
- Hardening: `HitboxComponent.ligar` zera `acertou_algum`; contrato documentado nos sinais do herói; `fase.gd` 1–10; StringNames no arremesso.
- Sprites de loja e baú em `sprites/`; split da loja documentado.
- Runner `rodar_testes.ps1`: cada teste imprime `>> OK` / `>> FALHOU` com motivo; resumo final com a lista; ignora vazamento ObjectDB do Godot; exige linha `PASSOU`; se falhar sob paralelo, **repete uma vez sozinho** (anti-flake). `TesteBase._terminar` e testes que saíam sem `PASSOU` corrigidos.

## Docs: Diátaxis (2026-11-10)
- Reorganização: `docs/adr/` (ex-decisões), `docs/how-to/receitas.md`, `docs/reference/` (arquitetura, artes, export Android, talentos), `docs/backlog/` (1 pendência = 1 arquivo com YAML), `docs/CHANGELOG.md` (ex-histórico). Removidos `pendencias.md` monolítico, `arquivo/` (plano SpriteCook, prompts Gemini, prévias, rascunho de talentos). Índice em `docs/README.md`; comandos `/proxima-fatia` e `/fechar-fatia` atualizados.

## Fatia: limite de tamanho Empurrar/Derrubar (PHB 2024)
- `CriaturaRPG.tamanho` (Minúsculo…Imenso) preenchido nas fichas; `CondicoesComponent` só aplica Empurrar/Derrubar até Grande (Enorme+ → "Grande demais!"). Teste em `teste_maestrias.gd`.

## Fatia: kit básico das criaturas (`MontagemDeCriatura`)
- ADR com 3 camadas: kit sempre / capacidades da ficha / específico de verdade. `MontagemDeCriatura` em `core/regras/` aplica ficha (incl. vulnerabilidades, fortitude, imunidades), condições, empurrão e Lentidão no andar.
- Ooze, Goblin e os 4 chefes migrados; chefes passam a respeitar Lentidão. Receita 1 atualizada. Backlog `base-comum-criaturas` fechado; abertos `capacidades-*` (disparo-sol, arremesso, tática, investida, furtividade, fuga-ágil, matilha, voo, linha-área).
- Teste `tests/teste_montagem_de_criatura.gd`.

## Fatia: capacidade disparo + sensível ao sol (`DisparoDeCriatura`)
- `DisparoDeCriatura` em `core/regras/`: munição da ficha, soltar flecha, alcance longo, linha de tiro, desvantagem por sol. Goblin e Wight usam a mesma implementação; IA de quando atirar fica na feature.
- Backlog `capacidades-disparo-sol` fechado. Teste `tests/criaturas/teste_disparo_de_criatura.gd`.

## Fatia: pastas com limite ~20 (tests, regras, backlog)
- Skill `godot-estrutura-pastas`: meta ~20 arquivos úteis por pasta (sem `.uid`/`.import`).
- `tests/`: subpastas `combate/`, `criaturas/`, `heroi/`, `ui/`, `campanha/`, `regras/`; `rodar_testes.ps1` recursive.
- `core/regras/`: `base/`, `combate/`, `criaturas/`, `mundo/` (+ `efeitos/` que já existia).
- `docs/backlog/`: subpastas por `area`. Comandos `/proxima-fatia` e `/testar` atualizados.

## Fatia: capacidade arremesso (`ArremessoDeCriatura`)
- `ArremessoDeCriatura` em `core/regras/criaturas/`: munição e alcances da ficha, soltar `ProjetilArremesso` (`core/projeteis/`). Goblin usa a capacidade; IA de quando arremessar fica na feature.
- Removidos `AdagaGoblin` / `adaga_goblin.*` da feature. Backlog `capacidades-arremesso` fechado. Teste `tests/criaturas/teste_arremesso_de_criatura.gd`.

## Fatia: capacidade tática IA (`TaticaDeCriatura`)
- `TaticaDeCriatura` em `core/regras/criaturas/`: cobertura, flanqueio e estratégia (timers + decisões). Goblin e Gray Ooze ligam as três; chefes ficam de fora (ADR).
- Ooze ganhou estados `Cobrindo` / `Flanqueando` / `Afastando`. Backlog `capacidades-tatica-ia` fechado. Teste `tests/criaturas/teste_tatica_de_criatura.gd`.

## Fatia: capacidade investida (`InvestidaDeCriatura`)
- `InvestidaDeCriatura` em `core/regras/criaturas/`: recarga X-6, janela de distância, carreira e `golpe`. Minotauro e Quimera usam; quebrar blocos / fúria / aceleração ficam na feature.
- Backlog `capacidades-investida` fechado. Teste `tests/criaturas/teste_investida_de_criatura.gd`.

## Fatia: capacidade furtividade (`FurtividadeDeCriatura`)
- `FurtividadeDeCriatura` em `core/regras/criaturas/`: rolagem secreta vs Percepção passiva, emboscada e `esconde_de_novo`. Goblin usa; sprite/colisão e estado `Escondido` ficam na feature.
- Backlog `capacidades-furtividade` fechado. Teste `tests/criaturas/teste_furtividade_de_criatura.gd`.

## Fatia: capacidade Fuga Ágil (`FugaAgilDeCriatura`)
- `FugaAgilDeCriatura` em `core/regras/criaturas/`: traço da ficha, velocidade de Disparada e duração do recuo. Goblin usa; estado `Desengajando` e `recuar` ficam na feature.
- Backlog `capacidades-fuga-agil` fechado. Teste `tests/criaturas/teste_fuga_agil_de_criatura.gd`.

## Fatia: capacidade Táticas de Matilha (`MatilhaDeCriatura`)
- `MatilhaDeCriatura` em `core/regras/criaturas/`: flag da ficha + aliados do grupo `monstros` (não só Goblin). Goblin/Hobgoblin/Kobold usam.
- Backlog `capacidades-matilha` fechado. Teste `tests/criaturas/teste_matilha_de_criatura.gd`.

## Fatia: capacidade voo (`VooDeCriatura`)
- Campo `voo_pes` em `CriaturaRPG`; Quimera = 60. `VooDeCriatura`: velocidade, altura-alvo e `sobre_o_alvo`. Mergulho/animação na feature.
- Backlog `capacidades-voo` fechado. Teste `tests/criaturas/teste_voo_de_criatura.gd`.

## Fatia: capacidade linha/área (`LinhaDeCriatura`)
- `LinhaDeCriatura` em `core/regras/criaturas/`: recarga X-6, dimensões, `golpe` e `alvo_na_area`. Ankheg (Borrifo) e Quimera (Sopro) usam; hitbox/VFX e estados ficam na feature.
- Backlog `capacidades-linha-area` fechado. Teste `tests/criaturas/teste_linha_de_criatura.gd`.

## Limpeza: backlog sem “validar sensação”
- Removidos itens que só pediam jogar/anotar (`validar-chefes`, `balance-quimera`, `equilibrio-niveis-5-6`, `validar-apk`). Regra no `docs/backlog/README.md`: feedback de sensação não vira pendência.
