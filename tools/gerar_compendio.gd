extends SceneTree
## Gera os dados do Compêndio: os 16 antecedentes do livro (PHB 2024) em data/antecedentes/ e os
## 52 talentos (10 de origem, 42 gerais) em data/talentos/. Só documentação: nada disto mexe na
## ficha ainda. As frases dos talentos vêm de docs/reference/talentos.md; mudou lá, mude aqui.
##   godot --headless --path . --script res://tools/gerar_compendio.gd
##   godot --headless --path . --import

const PASTA_ANTECEDENTES := "res://data/antecedentes/"
const PASTA_TALENTOS := "res://data/talentos/"
const O := TalentoRPG.Categoria.ORIGEM
const G := TalentoRPG.Categoria.GERAL
const PLANEJADO := TalentoRPG.Situacao.PLANEJADO
const ESPERA := TalentoRPG.Situacao.EM_ESPERA
const FORA := TalentoRPG.Situacao.FORA
const EQUIPAMENTO := "Ferramenta e pacote de equipamento do livro. O jogo só entregará o que já existe nele (por enquanto, nada)."

## O Compêndio só mostra o que o jogador consegue acessar. Nada é acessível ainda (os talentos de
## tiro já valem no disparo, mas a ficha não os escolhe). Quando um passar a ser escolhível, ponha o
## id aqui e rode o gerador. Antecedentes: nenhum acessível ainda.
const TALENTOS_FUNCIONANDO: Array[String] = [
	"alerta", "resistente", "atacante_selvagem", "brigao_de_taverna", "sortudo", "artesao", "perito",
	"aumento_de_atributo", "resiliente", "veloz", "mestre_armadura_media",
	"mestre_arma_grande", "mestre_armadura_pesada", "cortador", "perfurador", "esmagador", "empunhadura_dupla",
	"mestre_escudo", "atirador_de_elite", "especialista_em_besta", "especialista_em_pericia", "observador",
	"investida", "duelista_defensivo", "sentinela", "mestre_arma_haste", "atleta",
	"agarrador", "duravel", "envenenador",
]

## [id, nome, categoria, resumo, situação, motivo]
const TALENTOS := [
	["resistente", "Robusto", O, "Vida máxima +2 por nível.", PLANEJADO, "Conta combinada; entra quando o antecedente escolher o talento."],
	["alerta", "Alerta", O, "Soma o bônus de proficiência à iniciativa: o herói ataca mais rápido.", PLANEJADO, "Conta combinada; não há rolagem de iniciativa."],
	["atacante_selvagem", "Atacante Selvagem", O, "Uma vez por rodada, o primeiro acerto rola o dano duas vezes e fica com o maior.", PLANEJADO, "Conta combinada."],
	["brigao_de_taverna", "Brigão de Taverna", O, "Sem arma, o soco causa 1d4 + Força, rerrola dados que tirarem 1 e empurra o alvo 5 pés (uma vez por rodada).", PLANEJADO, "Conta combinada."],
	["sortudo", "Sortudo", O, "2 pontos de sorte por fase. Um botão (tecla G) arma a sorte: a próxima rolagem do herói, de ataque ou de teste, usa o melhor de dois d20.", PLANEJADO, "O próximo efeito fácil: o Combate já rola o dado."],
	["iniciado_em_magia", "Iniciado em Magia", O, "Dois truques e uma magia de 1º círculo de uma lista, usados um pouco por descanso.", ESPERA, "Decidido: em espera até a magia existir (Acólito, Guia e Sábio esperam junto)."],
	["perito", "Habilidoso", O, "Proficiência em 3 perícias à escolha, entre todas as do jogo (na criação).", PLANEJADO, "Escolhido para entrar cedo; as perícias novas já existem na ficha, falta o teste delas."],
	["artesao", "Artesão", O, "A cada fase nova, um item aleatório do arsenal (arma ou armadura) cai na mochila, se houver lugar.", PLANEJADO, "Decidido com o usuário. O desconto espera a loja existir; o item aleatório usa só itens que o jogo já tem."],
	["musico", "Músico", O, "Proficiência com instrumento e uma canção que dá inspiração no fim do descanso.", ESPERA, "Decidido: em espera, porque a canção dá Inspiração a aliados e o jogo não tem aliados."],
	["curandeiro", "Curandeiro", O, "O kit de curandeiro cura (no estilo do Fôlego) e estabiliza quem caiu.", ESPERA, "Decidido: em espera, porque o kit de curandeiro cura um aliado e o jogo não tem aliados."],
	["veloz", "Veloz", G, "Deslocamento +10 pés (30 vira 40).", PLANEJADO, "Conta combinada; é de nível 4 e a escolha de talento ainda não existe."],
	["levemente_armado", "Treinado em Armaduras Leves", G, "+1 num atributo e treinamento com armadura leve.", ESPERA, "Decidido: em espera, porque o Guerreiro já tem esse treinamento e só sobraria o +1 de atributo."],
	["moderadamente_armado", "Treinado em Armaduras MÃ©dias", G, "+1 num atributo e treinamento com armadura média e escudo.", ESPERA, "Decidido: em espera, porque o Guerreiro já tem esse treinamento e só sobraria o +1 de atributo."],
	["fortemente_armado", "Treinado em Armaduras Pesadas", G, "+1 num atributo e treinamento com armadura pesada.", ESPERA, "Decidido: em espera, porque o Guerreiro já tem esse treinamento e só sobraria o +1 de atributo."],
	["armas_marciais", "Treinamento com Armas Marciais", G, "Proficiência com armas marciais.", ESPERA, "Decidido: em espera, porque o Guerreiro já tem esse treinamento e só sobraria o +1 de atributo."],
	["resiliente", "Resiliente", G, "+1 num atributo em que o herói ainda não tem proficiência na salvaguarda, e proficiência nela.", PLANEJADO, "A ficha já sabe somar o que o talento dá."],
	["aumento_de_atributo", "Aumento no Valor de Atributo", G, "+2 num atributo, ou +1 em dois (teto 20). Pode repetir.", PLANEJADO, "A ficha já sabe somar o que o talento dá."],
	["mestre_armadura_media", "Mestre em Armadura Média", G, "+1 em Força ou Destreza. O teto de Destreza da armadura média sobe de +2 para +3 na CA.", PLANEJADO, "A desvantagem de Furtividade espera o teste."],
	["mestre_arma_grande", "Mestre em Armas Grandes", G, "+1 em Força. A arma Pesada soma a proficiência no dano. Crítico ou abate com uma arma corpo a corpo faz um golpe extra logo em seguida, como o Surto de Ação (uma vez por rodada).", PLANEJADO, "Decidido: o golpe extra reaproveita o ataque duplo do Surto de Ação."],
	["mestre_armadura_pesada", "Mestre em Armaduras Pesadas", G, "+1 em Força ou Constituição. Com armadura pesada vestida, o dano contundente, cortante e perfurante sofrido cai em 2.", PLANEJADO, "Regra pequena de combate."],
	["cortador", "Retalhador", G, "+1 em Força ou Destreza. O acerto cortante deixa o alvo Lento (uma vez por rodada); o crítico dá desvantagem ao próximo ataque dele.", PLANEJADO, "Regra pequena de combate."],
	["perfurador", "Perfurador", G, "+1 em Força ou Destreza. O acerto perfurante rerrola o menor dado de dano (uma vez por rodada); o crítico rola um dado a mais.", PLANEJADO, "Regra pequena de combate."],
	["esmagador", "Esmagador", G, "+1 em Força ou Constituição. O acerto contundente empurra o alvo 5 pés (uma vez por rodada); o crítico dá vantagem ao próximo ataque contra ele.", PLANEJADO, "O Empurrar da maestria já move."],
	["empunhadura_dupla", "Combatente com Duas Armas", G, "+1 em Força ou Destreza. Atacando com uma arma Leve, a segunda arma da outra mão pode ser qualquer arma corpo a corpo de uma mão.", PLANEJADO, "Regra pequena de combate."],
	["mestre_escudo", "Mestre em Escudos", G, "+1 em Força. Com escudo, depois de acertar uma arma corpo a corpo o alvo faz salvaguarda de Força (CD 8 + Força + proficiência); se falhar, é empurrado 5 pés ou derrubado (alterna a cada uso), uma vez por rodada.", PLANEJADO, "Regra pequena de combate."],
	["investida", "Investida", G, "+1 em Força ou Destreza. Depois de correr 10 pés em linha reta, o ataque soma 1d8 ou empurra 10 pés (um botão alterna o modo, uma vez por rodada). A corrida também fica 10 pés mais rápida.", PLANEJADO, "Regra pequena de combate."],
	["duelista_defensivo", "Duelista Defensivo", G, "+1 em Destreza. Com arma de acuidade, um botão abre uma defesa de 0,75 s: +proficiência na CA contra golpes corpo a corpo, com um parry quando o golpe erra por isso.", PLANEJADO, "Não há reação: viraria um botão."],
	["sentinela", "Sentinela", G, "+1 em Força ou Destreza. Acertar um alvo que está se movendo o deixa preso por 1 s.", PLANEJADO, "O ataque ao sair do alcance espera essa regra."],
	["mestre_arma_haste", "Mestre em Armas de Haste", G, "+1 em Força ou Destreza. Com Bordão, Lança ou arma Pesada com Alcance, o segundo ataque do combo é um golpe extra de 1d4 contundente com a outra ponta (ação bônus).", PLANEJADO, "O ataque ao entrar no alcance espera essa regra."],
	["atleta", "Atleta", G, "+1 em Força ou Destreza. Deslocamento +5 pés, o herói não perde o controle ao levar um golpe e escala paredes: empurrando contra uma, sobe na velocidade de andar até o topo.", PLANEJADO, "Escalar espera o cenário."],
	["agarrador", "Agarrador", G, "+1 em Força ou Destreza. O soco acertado agarra o alvo (uma vez por rodada): ele fica sem deslocamento, tenta escapar a cada rodada (CD 8 + Força + proficiência) e o herói o ataca com vantagem.", PLANEJADO, "Decidido com o usuário (ver docs/reference/talentos.md)."],
	["atirador_de_elite", "Atirador de Elite", G, "+1 em Destreza. O alcance longo e o inimigo a 5 pés deixam de dar desvantagem no tiro, e a flecha atravessa paredes, degraus e criaturas do cenário (cada criatura uma vez), parando só no chão.", PLANEJADO, "A arma à distância já dispara; cobertura fica de fora."],
	["especialista_em_besta", "Especialista em Bestas", G, "+1 em Destreza. A besta não perde com inimigo colado e a Besta de Mão ganha o ataque extra.", PLANEJADO, "A arma à distância já dispara."],
	["adepto_elemental", "Adepto Elemental", G, "Escolhe um tipo de dano mágico e ignora resistência a ele; o dado 1 vira 2.", ESPERA, "Espera a magia."],
	["tocado_pela_fada", "Tocado pelas Fadas", G, "+1 num atributo mental, um truque e duas magias de 1º círculo, uma delas Passo Nebuloso.", ESPERA, "Espera a magia."],
	["tocado_pela_sombra", "Tocado pelas Sombras", G, "+1 num atributo mental, um truque e duas magias de 1º círculo, uma delas Invisibilidade.", ESPERA, "Espera a magia."],
	["telecinetico", "Telecinético", G, "+1 num atributo mental, um empurrão à distância e o truque Mão Maga.", ESPERA, "Espera a magia."],
	["telepata", "TelepÃ¡tico", G, "+1 num atributo mental, fala na mente de uma criatura e a magia Detectar Pensamentos.", ESPERA, "Espera a magia."],
	["conjurador_de_rituais", "Conjurador Ritualista", G, "Um livro com magias que só saem como ritual.", ESPERA, "Espera a magia."],
	["franco_atirador_de_magia", "Atirador Arcano", G, "Ataque mágico à distância ignora meia cobertura e soma o alcance.", ESPERA, "Espera a magia."],
	["conjurador_de_guerra", "Conjurador de Guerra", G, "Conjurar no lugar de um ataque de oportunidade e segurar o foco com as mãos ocupadas.", ESPERA, "Espera a magia."],
	["matador_de_magos", "Matador de Magos", G, "Quem conjura ao lado sofre desvantagem, e um acerto perto pode interromper a magia.", ESPERA, "Espera a magia."],
	["especialista_em_pericia", "Especialista em Perícia", G, "+1 num atributo, proficiência numa perícia nova e Especialização numa perícia treinada (a proficiência conta em dobro).", PLANEJADO, "Decidido com o usuário (ver docs/reference/talentos.md)."],
	["ator", "Ator", G, "+1 de Carisma, vantagem para fingir ser outra pessoa e imitar voz.", ESPERA, "Decidido com o usuário: em espera (ver docs/reference/talentos.md)."],
	["mente_agucada", "Mente Aguçada", G, "+1 de Inteligência e um estudo que revela detalhes do lugar.", ESPERA, "Decidido com o usuário: em espera (ver docs/reference/talentos.md)."],
	["observador", "Observador", G, "+1 em Inteligência ou Sabedoria e uma perícia entre Intuição, Investigação e Percepção: proficiência ou, se já treina, Especialização.", PLANEJADO, "Decidido com o usuário (ver docs/reference/talentos.md)."],
	["furtivo", "Furtivo", G, "Vantagem em Furtividade com pouca luz; um tiro de cobertura não revela tanto.", ESPERA, "Decidido com o usuário: em espera (ver docs/reference/talentos.md)."],
	["cozinheiro", "Chef", G, "+1 de Constituição ou Sabedoria, comida que cura um pouco e petisco que dá vida temporária.", ESPERA, "Decidido com o usuário: em espera (ver docs/reference/talentos.md)."],
	["duravel", "Durável", G, "+1 em Constituição. Um dado de vida por nível, que voltam a cada fase. Uma ação bônus (tecla H) gasta um e cura o valor rolado.", PLANEJADO, "Decidido: entra como talento individual; exige o sistema de dados de vida (um por nível)."],
	["lider_inspirador", "Líder Inspirador", G, "Um discurso curto dá vida temporária aos aliados.", ESPERA, "Decidido com o usuário: em espera (ver docs/reference/talentos.md)."],
	["envenenador", "Envenenador", G, "+1 em Destreza ou Inteligência. Duas doses de veneno por fase: uma ação bônus (tecla N) passa a dose na arma e o acerto força salvaguarda de Constituição; falhou, leva 2d8 de veneno e fica Envenenado (desvantagem nos ataques). Também usa o item Veneno Básico.", PLANEJADO, "Decidido: entra com o item Veneno Básico; exige o tipo veneno e a condição Envenenado."],
	["combatente_montado", "Combatente Montado", G, "Protege a montaria e ganha vantagem contra quem é menor.", ESPERA, "Decidido: em espera até existirem montarias."],
]

const FOR := Atributos.FORCA
const DES := Atributos.DESTREZA
const CON := Atributos.CONSTITUICAO
const INT := Atributos.INTELIGENCIA
const SAB := Atributos.SABEDORIA
const CAR := Atributos.CARISMA

## Onde cada talento geral deixa pôr o +1 de atributo (PHB 2024; conferir no livro). O Aumento de Valor de
## Habilidade é à parte: 2 pontos em qualquer atributo.
const ATRIBUTOS_DO_TALENTO := {
	"veloz": [DES, CON],
	"resiliente": Atributos.TODOS,
	"mestre_armadura_media": [FOR, DES],
	"mestre_arma_grande": [FOR],
	"mestre_armadura_pesada": [FOR, CON],
	"cortador": [FOR, DES],
	"perfurador": [FOR, DES],
	"esmagador": [FOR, CON],
	"empunhadura_dupla": [FOR, DES],
	"mestre_escudo": [FOR],
	"investida": [FOR, DES],
	"duelista_defensivo": [DES],
	"sentinela": [FOR, DES],
	"mestre_arma_haste": [FOR, DES],
	"atleta": [FOR, DES],
	"agarrador": [FOR, DES],
	"atirador_de_elite": [DES],
	"especialista_em_besta": [DES],
	"especialista_em_pericia": Atributos.TODOS,
	"observador": [INT, SAB],
	"duravel": [CON],
	"envenenador": [DES, INT],
}
const ID_AUMENTO := "aumento_de_atributo"
const PONTOS_DO_AUMENTO := 2

## Antecedentes que o jogador consegue escolher na criação (o talento de origem deles entra).
## Os outros 5 (Acólito, Guia, Sábio, Artista, Eremita) esperam o talento deles.
const ANTECEDENTES_DISPONIVEIS: Array[String] = [
	"artesao", "charlatao", "criminoso", "fazendeiro", "guarda", "mercador",
	"nobre", "marinheiro", "escriba", "soldado", "viajante",
]

## [id, nome, descrição, [3 atributos], talento, [2 perícias], ferramenta]
const ANTECEDENTES := [
	["acolito", "Acólito", "Serviu num templo, entre rezas, ritos e estudo dos textos sagrados.", [INT, SAB, CAR], "iniciado_em_magia", [Pericia.INTUICAO, Pericia.RELIGIAO], "Suprimentos de caligrafia"],
	["artesao", "Artesão", "Aprendeu um ofício numa oficina e cresceu entre ferramentas e clientes.", [FOR, DES, INT], "artesao", [Pericia.INVESTIGACAO, Pericia.PERSUASAO], "Ferramentas de artesão (à escolha)"],
	["charlatao", "Charlatão", "Vive de lábia: golpes, disfarces e histórias bem contadas.", [DES, CON, CAR], "perito", [Pericia.ENGANACAO, Pericia.PRESTIDIGITACAO], "Kit de falsificação"],
	["criminoso", "Criminoso", "Ganhou a vida fora da lei, atento a becos e a quem o segue.", [DES, CON, INT], "alerta", [Pericia.PRESTIDIGITACAO, Pericia.FURTIVIDADE], "Ferramentas de ladrão"],
	["artista", "Artista", "Viveu de palco e estrada, atraindo plateias com música, dança ou contos.", [FOR, DES, CAR], "musico", [Pericia.ACROBACIA, Pericia.ATUACAO], "Instrumento musical (à escolha)"],
	["fazendeiro", "Fazendeiro", "Cresceu entre plantações e rebanhos, com o corpo forte de quem trabalha a terra.", [FOR, CON, SAB], "resistente", [Pericia.LIDAR_COM_ANIMAIS, Pericia.NATUREZA], "Ferramentas de carpinteiro"],
	["guarda", "Guarda", "Vigiou muralhas, portões e caravanas, sempre de olho em problemas.", [FOR, INT, SAB], "alerta", [Pericia.ATLETISMO, Pericia.PERCEPCAO], "Jogo (à escolha)"],
	["guia", "Guia", "Levou viajantes por ermos e trilhas, lendo o terreno e o tempo.", [DES, CON, SAB], "iniciado_em_magia", [Pericia.FURTIVIDADE, Pericia.SOBREVIVENCIA], "Ferramentas de cartógrafo"],
	["eremita", "Eremita", "Passou anos isolado, em meditação, estudo ou penitência.", [CON, SAB, CAR], "curandeiro", [Pericia.MEDICINA, Pericia.RELIGIAO], "Kit de herbalismo"],
	["mercador", "Mercador", "Negociou em feiras e rotas comerciais, de olho no lucro.", [CON, INT, CAR], "sortudo", [Pericia.LIDAR_COM_ANIMAIS, Pericia.PERSUASAO], "Ferramentas de navegador"],
	["nobre", "Nobre", "Cresceu entre privilégios, etiqueta e intrigas de família.", [FOR, INT, CAR], "perito", [Pericia.HISTORIA, Pericia.PERSUASAO], "Jogo (à escolha)"],
	["sabio", "Sábio", "Passou a juventude entre livros, mestres e bibliotecas.", [CON, INT, SAB], "iniciado_em_magia", [Pericia.ARCANISMO, Pericia.HISTORIA], "Suprimentos de caligrafia"],
	["marinheiro", "Marinheiro", "Trabalhou em navios, entre tempestades, cordas e brigas de porto.", [FOR, DES, SAB], "brigao_de_taverna", [Pericia.ACROBACIA, Pericia.PERCEPCAO], "Ferramentas de navegador"],
	["escriba", "Escriba", "Copiou e organizou documentos, com letra firme e olho para detalhes.", [DES, INT, SAB], "perito", [Pericia.INVESTIGACAO, Pericia.PERCEPCAO], "Suprimentos de caligrafia"],
	["soldado", "Soldado", "Serviu num exército ou numa milícia, treinado para a batalha.", [FOR, DES, CON], "atacante_selvagem", [Pericia.ATLETISMO, Pericia.INTIMIDACAO], "Jogo (à escolha)"],
	["viajante", "Viajante", "Cresceu sem teto fixo, sobrevivendo de favores e de bom senso nas estradas.", [DES, SAB, CAR], "sortudo", [Pericia.INTUICAO, Pericia.FURTIVIDADE], "Ferramentas de ladrão"],
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_ANTECEDENTES))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_TALENTOS))
	for i in TALENTOS.size():
		_gravar_talento(i, TALENTOS[i])
	for i in ANTECEDENTES.size():
		_gravar_antecedente(i, ANTECEDENTES[i])
	print("Compêndio gerado: %d talentos e %d antecedentes." % [TALENTOS.size(), ANTECEDENTES.size()])
	quit()


func _gravar_talento(indice: int, linha: Array) -> void:
	var talento: TalentoRPG = TalentoRPG.new()
	talento.id = linha[0]
	talento.no_jogo = linha[0] in TALENTOS_FUNCIONANDO
	_ligar_atributos(talento)
	talento.nome = linha[1]
	talento.categoria = linha[2]
	talento.resumo = linha[3]
	talento.situacao = linha[4]
	talento.motivo = linha[5]
	ResourceSaver.save(talento, "%s%02d_%s.tres" % [PASTA_TALENTOS, indice + 1, talento.id])


func _ligar_atributos(talento: TalentoRPG) -> void:
	if talento.id == ID_AUMENTO:
		talento.atributos.assign(Atributos.TODOS)
		talento.pontos_de_atributo = PONTOS_DO_AUMENTO
		talento.repetivel = true
	elif ATRIBUTOS_DO_TALENTO.has(String(talento.id)):
		talento.atributos.assign(ATRIBUTOS_DO_TALENTO[String(talento.id)])
		talento.pontos_de_atributo = 1


func _gravar_antecedente(indice: int, linha: Array) -> void:
	var antecedente: AntecedenteRPG = AntecedenteRPG.new()
	antecedente.id = linha[0]
	antecedente.no_jogo = linha[0] in ANTECEDENTES_DISPONIVEIS
	antecedente.nome = linha[1]
	antecedente.descricao = linha[2]
	antecedente.atributos.assign(linha[3])
	antecedente.talento = linha[4]
	antecedente.pericias.assign(linha[5])
	antecedente.ferramenta = linha[6]
	antecedente.equipamento = EQUIPAMENTO
	ResourceSaver.save(antecedente, "%s%02d_%s.tres" % [PASTA_ANTECEDENTES, indice + 1, antecedente.id])
