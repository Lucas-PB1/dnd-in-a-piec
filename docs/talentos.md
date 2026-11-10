# Talentos do livro base

> **Atenção:** este arquivo guarda as notas de planejamento e as decisões, em ordem. Os textos das seções antigas (antes de "Decisões do usuário") usam nomes e regras de planejamento (alguns de 2014). **Vale o que está no fim do arquivo (decisões confirmadas e nomes do livro) e a tabela de `tools/gerar_compendio.gd`**, conferida no PHB 2024 em português do site.

Notas de como os talentos de **origem** e os **gerais** do livro base entram no jogo. Uma frase nossa por talento. A escolha fica de fora: o antecedente é que vai marcar o de origem depois.

São 10 de origem e 42 gerais. Estilo de luta e dádiva épica ficam de fora. Magia fica de lado: a frase de cada um está no fim deste arquivo, e a gente só abre esse bloco quando a magia entrar. Os dois talentos de tiro já valem no disparo; a ficha começa sem nenhum talento.

## Já combinado

O catálogo (nome, categoria, pré-requisito, resumo e ícone 16×16) é uma fatia própria. Estes cinco já têm conta, e só mudam número quando o talento estiver na ficha. Hoje a ficha começa vazia.

- **Resistente** (origem): vida máxima +2 no nível 1.
- **Alerta** (origem): iniciativa +2. Não há rolagem de iniciativa; esse +2 encurta o intervalo entre ataques.
- **Atacante Selvagem** (origem): uma vez por rodada (1,5 s), o dano da arma é rolado duas vezes e fica o maior.
- **Brigão de Taverna** (origem): o soco passa de 1d1 para 1d4.
- **Veloz** (geral): deslocamento +10 pés. É de nível 4; a conta existe, a escolha não.

O +1 de atributo de todo talento geral usa a mesma conta e só soma quando o talento estiver na ficha.

## A ficha já sabe

Proficiência e atributo já vivem em `core/regras/ficha.gd` e `core/regras/proficiencias.gd`. Ligar é somar o que o talento dá, quando ele estiver na ficha.

- **Levemente Armado** (geral): acrescenta o treinamento de armadura leve.
- **Moderadamente Armado** (geral): acrescenta o treinamento de armadura média e de escudo.
- **Fortemente Armado** (geral): acrescenta o treinamento de armadura pesada.
- **Treinamento com Armas Marciais** (geral): concede proficiência com armas marciais.
- **Resiliente** (geral): +1 num atributo e proficiência numa salvaguarda.
- **Aumento de Valor de Habilidade** (geral): +2 num atributo, ou +1 em dois. Pode repetir.
- **Mestre em Armadura Média** (geral): o teto de Destreza da armadura média sobe para +3. Tirar a desvantagem de Furtividade espera o teste; hoje a armadura só guarda essa marca.

## O combate já quase faz

Golpe, tipos de dano, condições e ação bônus já existem. Cada um destes é uma regra pequena, sem sistema novo.

- **Mestre em Arma Grande** (geral): arma Pesada soma a proficiência no dano; crítico ou queda a zero abre o golpe extra, e a ação bônus já existe.
- **Mestre em Armadura Pesada** (geral): dano contundente, cortante e perfurante leva −2.
- **Cortador** (geral): acerto cortante aplica Lentidão; crítico dá desvantagem no próximo ataque do alvo.
- **Perfurador** (geral): pode rerrolar um dado de dano perfurante; no crítico rola um dado a mais.
- **Esmagador** (geral): acerto contundente empurra 5 pés, e o Empurrar da maestria já move; crítico dá vantagem no próximo ataque contra o alvo.
- **Empunhadura Dupla** (geral): a segunda arma não precisa ser Leve.
- **Mestre em Escudo** (geral): a ação bônus empurra com o escudo; salvaguarda de Destreza soma o bônus do escudo.
- **Investida** (geral): se está correndo (a Disparada), o próximo golpe soma 1d8 ou empurra 10 pés.
- **Duelista Defensivo** (geral): uma tecla curta soma a proficiência na CA contra um golpe corpo a corpo. Não há reação; vira um botão.
- **Sentinela** (geral): acerto zera o deslocamento do alvo por uma rodada. O ataque quando alguém sai do alcance espera essa regra.
- **Mestre em Arma de Haste** (geral): golpe extra da outra ponta na ação bônus. O ataque quando alguém entra no alcance espera essa regra.
- **Atleta** (geral): levantar de Caído gasta menos deslocamento. Escalar espera o cenário.
- **Sortudo** (origem): pontos para rerrolar o d20. O `Combate` já rola o dado. Não entrou nos cinco porque gasta uso, não é um bônus fixo. É o próximo efeito fácil.
- **Agarrador** (geral): espera a condição Agarrado, que ainda não existe.

## Tiro

A arma à distância já dispara. Estes dois saíram da lista de espera. A ficha começa sem talento: o teste é que coloca o nome para ver o efeito. Cobertura e o "ignorar Recarga" continuam anotados.

- **Atirador de Elite** (geral): o alcance longo do tiro deixa de dar desvantagem. Cobertura continua de fora, porque o jogo não tem cobertura.
- **Especialista em Besta** (geral): inimigo a 5 pés não dá desvantagem no tiro de besta. A ação bônus dispara de novo a Besta de Mão e gasta outro virote. Ignorar Recarga espera o ataque extra.

## Deixados de lado

Não entram na fila. Quando a fatia chegar, voltar aqui e usar a frase que já está escrita.

### Quando houver magia

- **Iniciado em Magia** (origem): dois truques e uma magia de 1º círculo de uma lista, usados um pouco por descanso.
- **Adepto Elemental** (geral): escolhe um tipo (ácido, frio, fogo e os outros) e ignora resistência a ele; o dado 1 vira 2.
- **Tocado pela Fada** (geral): +1 num atributo mental, um truque e duas magias de 1º círculo, uma delas Passo Nebuloso.
- **Tocado pela Sombra** (geral): +1 num atributo mental, um truque e duas magias de 1º círculo, uma delas Invisibilidade.
- **Telecinético** (geral): +1 num atributo mental, um empurrão à distância e o truque Mão Maga.
- **Telepata** (geral): +1 num atributo mental, fala na mente de uma criatura e a magia Detectar Pensamentos.
- **Conjurador de Rituais** (geral): um livro com magias que só saem como ritual.
- **Franco-atirador de Magia** (geral): ataque mágico à distância ignora meia cobertura e soma o alcance.
- **Conjurador de Guerra** (geral): conjurar no lugar de um ataque de oportunidade e segurar o foco com as mãos ocupadas.
- **Matador de Magos** (geral): quem conjura ao lado sofre desvantagem, e um acerto perto pode interromper a magia.

## Espera perícia, ferramenta ou descanso

Furtividade ainda não é teste. Não há descanso curto nem pontos de vida temporários.

- **Perito** (origem): proficiência em três perícias ou ferramentas.
- **Especialista em Perícia** (geral): +1 num atributo, uma proficiência e uma perícia com perícia especializada.
- **Ator** (geral): +1 de Carisma, vantagem para fingir ser outra pessoa e imitar voz.
- **Mente Aguçada** (geral): +1 de Inteligência e um estudo que revela detalhes do lugar.
- **Observador** (geral): +1 de Inteligência ou Sabedoria e bônus para perceber esconderijo e ler lábios.
- **Furtivo** (geral): vantagem em Furtividade com pouca luz e um tiro de cobertura não revela tanto.
- **Artesão** (origem): proficiência com ferramentas, desconto ao comprar e um item rápido por descanso.
- **Músico** (origem): proficiência com instrumento e uma canção que dá inspiração no fim do descanso.
- **Cozinheiro** (geral): +1 de Constituição ou Sabedoria, comida que cura um pouco e petisco que dá vida temporária.
- **Durável** (geral): +1 de Constituição e uma ação bônus que gasta um dado de vida para curar (versão do PHB 2024).
- **Líder Inspirador** (geral): um discurso curto dá vida temporária aos aliados.
- **Curandeiro** (origem): o kit de curandeiro cura (no estilo do Fôlego) e estabiliza quem caiu.
- **Envenenador** (geral): aplica veneno na arma. Também pede o tipo de dano veneno; `TiposDano` ainda não tem veneno.

## Fora por enquanto

- **Combatente Montado** (geral): protege a montaria e ganha vantagem contra quem é menor. Não há montaria.

## Decisões do usuário sobre os talentos de origem
- **Iniciado em Magia**: em espera até a magia existir. Acólito, Guia e Sábio esperam junto.
- **Músico**: em espera. A canção dá Inspiração a aliados e o jogo não tem aliados. O antecedente Artista espera junto.
- **Curandeiro**: em espera. O kit de curandeiro cura um aliado. O antecedente Eremita espera junto.
- **Artesão**: entra. 20% de desconto na loja (já existe) e, a cada fase nova, um item aleatório cai na mochila, só entre os itens que o jogo já tem.
- **Alerta, Resistente, Atacante Selvagem, Brigão de Taverna, Sortudo e Perito**: entram e estão **ligados** no código (efeitos em `features/jogador/talentos/` e Compêndio).

## Decisões do usuário sobre os talentos gerais (um por um)
- **Levemente Armado**: em espera (o Guerreiro já tem o treinamento; só sobraria o +1 de atributo).
- **Moderadamente Armado, Fortemente Armado e Treinamento com Armas Marciais**: em espera (mesmo motivo: o Guerreiro já tem os treinamentos).
- **Resiliente, Aumento de Valor de Habilidade e Mestre em Armadura Média**: entram (planejados). O +1/+2 de atributo só vale a partir do nível 4; a Furtividade do Mestre em Armadura Média espera o teste.
- **Mestre em Arma Grande**: entra. A arma Pesada soma a proficiência no dano. O golpe extra do crítico ou do abate reaproveita o ataque duplo do Surto de Ação (o próximo ataque sai em dobro).
- **Mestre em Armadura Pesada, Cortador e Perfurador**: entram (planejados). Cortador reaproveita Lentidão e Enfraquecer das maestrias; Perfurador é parente do Atacante Selvagem.
- **Esmagador e Empunhadura Dupla**: entram (planejados).
- **Mestre em Escudo**: entra completo (+1 FOR, empurrão com o escudo por botão novo como ação bônus, soma do bônus do escudo na salvaguarda de Destreza).
- **Investida**: entra. Um botão de alternância troca entre "Empurrão" e "Dano" (o botão mostra qual está ativo); correndo e acertando, aplica o escolhido (+1d8 ou empurrar 10 pés).
- **Duelista Defensivo**: entra como botão de defesa. Janela de 0,75 s com +proficiência na CA; se apertado no instante exato do golpe, vira um parry com efeito visual. Tempo de espera de até 1 s.
- **Sentinela**: entra. Um acerto num alvo que está se movendo o deixa imóvel por 1 s; se ele estava parado, não prende; se ele se mover sem ser acertado, segue normal.
- **Mestre em Arma de Haste**: entra só com o golpe extra da outra ponta (como o ataque duplo das duas armas, com animação curta e dano menor, 1d4). O ataque a quem entra no alcance fica de fora.
- **Atleta**: entra completo. Levanta de Caído muito mais rápido e sem tempo de recuperação ao cair ou ao tomar dano; escalada em paredes (andar em diagonal por murinhos baixos, pede suporte no cenário); pequeno aumento de velocidade.
- **Agarrador**: entra com a condição nova Agarrado. O soco acertado agarra o alvo; o herói ataca com vantagem nele; enquanto o herói continua acertando, o alvo não sai. Os monstros precisam tentar escapar do agarrão e podem atacar mesmo agarrados.
- **Atirador de Elite**: entra. O alcance longo deixa de dar desvantagem. A cobertura vira "o tiro atravessa obstáculos e outras criaturas, acertando também quem está atrás".
- **Quando se escolhe um talento geral**: ao subir de nível (níveis 4 e 6). O herói vai até o nível **6** (`Ficha.NIVEL_MAXIMO`).
- **Especialista em Besta**: entra completo (sem recarga, sem desvantagem de perto, ataque extra com a segunda besta).
- **Especialista em Perícia**: entra (planejado). O efeito aparece conforme as perícias ganharem teste; hoje só a Percepção conta.
- **Ator**: em espera (não há diálogo, disfarce nem NPCs).
- **Mente Aguçada**: em espera (perícias de conhecimento sem teste; o "estudo" se parece com a Percepção passiva).
- **Observador**: entra (planejado). A Percepção passiva do herói sobe; ler lábios fica de fora.
- **Furtivo**: em espera (o herói não se esconde; sistema novo).
- **Cozinheiro**: em espera (sem descanso curto, vida temporária nem comida).
- **Durável**: entra como talento individual (não preso ao Guerreiro). Versão do PHB 2024: +1 de Constituição e uma ação bônus que gasta um dado de vida e recupera PV pelo resultado. O herói tem tantos dados de vida quanto o nível. Falta confirmar se o resultado soma o modificador de CON e a regra de vantagem nas salvaguardas contra a morte (o jogo não tem). Correção: o "mínimo de 2× o modificador" era do livro de 2014.
- **Líder Inspirador**: em espera (sem aliados nem vida temporária).
- **Envenenador**: entra, junto com o item **Veneno Básico** (PHB 2024: 100 PO; ação bônus para passar numa arma cortante ou perfurante; dura 1 minuto ou até causar dano; +1d4 de veneno). O talento: +1 DES ou INT, kit de envenenador, aplicar com ação bônus; quem sofre o dano faz salvaguarda de CON (CD 8 + mod. + proficiência) ou leva 2d8 de veneno e fica Envenenado até o fim do próximo turno do herói; ignora resistência a veneno. Conferir o texto no livro (uma fonte parece misturar 2014).
- **Os 9 talentos de magia** (Adepto Elemental, Tocado pela Fada, Tocado pela Sombra, Telecinético, Telepata, Conjurador de Rituais, Franco-atirador de Magia, Conjurador de Guerra, Matador de Magos): em espera até a magia entrar no jogo.
- **Combatente Montado**: em espera (não há montarias).

### Resumo dos talentos gerais
- **Entram (planejados):** Veloz, Resiliente, Aumento de Valor de Habilidade, Mestre em Armadura Média, Mestre em Arma Grande, Mestre em Armadura Pesada, Cortador, Perfurador, Esmagador, Empunhadura Dupla, Mestre em Escudo, Investida, Duelista Defensivo, Sentinela, Mestre em Arma de Haste, Atleta, Agarrador, Atirador de Elite, Especialista em Besta, Especialista em Perícia, Observador, Durável e Envenenador.
- **Em espera:** Levemente Armado, Moderadamente Armado, Fortemente Armado, Treinamento com Armas Marciais, Ator, Mente Aguçada, Furtivo, Cozinheiro, Líder Inspirador, Combatente Montado e os 9 de magia.

## Antecedentes (decisão do usuário)
- **Entram (planejados), 11:** Artesão, Charlatão, Criminoso, Fazendeiro, Guarda, Mercador, Nobre, Marinheiro, Escriba, Soldado e Viajante (seus talentos de origem entram).
- **Em espera, 5:** Acólito, Guia e Sábio (Iniciado em Magia), Artista (Músico) e Eremita (Curandeiro).
- O Compêndio só mostra antecedentes e talentos quando o jogador conseguir escolhê-los (passo de criação com antecedente: ver `docs/pendencias.md`).

## Efeitos dos talentos de origem (confirmados com o usuário)
- **Alerta**: soma o bônus de proficiência (+2) à iniciativa; com DES +2 o intervalo de ataque vai de 0,8 s para 0,6 s.
- **Resistente**: vida máxima +2 por nível (nível 4: +8).
- **Atacante Selvagem**: uma vez por rodada (1,5 s), o primeiro acerto rola o dano duas vezes e fica o maior (no crítico, o dano dobrado também entra na comparação).
- **Brigão de Taverna**: soco desarmado 1d4 + Força, rerrola dados de dano que tirem 1 no soco, e empurra 5 pés uma vez por rodada. Só vale sem arma na mão.
- **Sortudo**: 2 pontos de sorte por fase (a proficiência). Um botão arma a sorte (como o Surto de Ação): a próxima rolagem do herói (ataque, salvaguarda ou teste) rola dois d20 e fica o melhor. Os pontos voltam a cada fase nova.
- **Artesão**: a cada fase nova cai um item aleatório na mochila, de qualquer arma ou armadura do arsenal (se a mochila estiver cheia, não entra). O desconto de 20% espera a loja.
- **Perito**: o jogador marca 3 perícias extras no passo Perícias da criação (entre as 18 do jogo, menos as já treinadas). Ferramentas não contam.

## Nomes do livro (PHB 2024 em português)
Os nomes do jogo seguem o livro: Robusto (era Resistente), Habilidoso (Perito), Retalhador (Cortador), Combatente com Duas Armas (Empunhadura Dupla), Mestre em Armas Grandes, Mestre em Armaduras Médias, Mestre em Armaduras Pesadas, Mestre em Escudos, Mestre em Armas de Haste, Especialista em Bestas, Mente Afiada, Chef (era Cozinheiro), Treinado em Armaduras Leves, Médias e Pesadas, Aumento no Valor de Atributo, Tocado pelas Fadas e pelas Sombras, Conjurador Ritualista, Atirador Arcano e Telepático. Os textos acima ainda usam os nomes antigos nas frases; vale o do livro. Saves antigos trocam os nomes sozinhos (`Salvamento.NOMES_ANTIGOS_DE_TALENTOS`).
