# Talentos do livro base

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
- **Durável** (geral): +1 de Constituição, e cada dado de vida gasto num descanso recupera no mínimo o dobro do modificador.
- **Líder Inspirador** (geral): um discurso curto dá vida temporária aos aliados.
- **Curandeiro** (origem): o kit de curandeiro cura (no estilo do Fôlego) e estabiliza quem caiu.
- **Envenenador** (geral): aplica veneno na arma. Também pede o tipo de dano veneno; `TiposDano` ainda não tem veneno.

## Fora por enquanto

- **Combatente Montado** (geral): protege a montaria e ganha vantagem contra quem é menor. Não há montaria.
