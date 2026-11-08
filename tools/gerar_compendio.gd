extends SceneTree
## Gera os dados do Compêndio: os 16 antecedentes do livro (PHB 2024) em data/antecedentes/ e os
## 52 talentos (10 de origem, 42 gerais) em data/talentos/. Só documentação: nada disto mexe na
## ficha ainda. As frases dos talentos vêm de docs/talentos.md; mudou lá, mude aqui.
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
const TALENTOS_FUNCIONANDO: Array[String] = []

## [id, nome, categoria, resumo, situação, motivo]
const TALENTOS := [
	["resistente", "Resistente", O, "Vida máxima +2 por nível (no nível 1, +2).", PLANEJADO, "Conta combinada; entra quando o antecedente escolher o talento."],
	["alerta", "Alerta", O, "Soma a proficiência na iniciativa; aqui encurta o intervalo entre ataques.", PLANEJADO, "Conta combinada; não há rolagem de iniciativa."],
	["atacante_selvagem", "Atacante Selvagem", O, "Uma vez por rodada, rola o dano da arma duas vezes e fica o maior.", PLANEJADO, "Conta combinada."],
	["brigao_de_taverna", "Brigão de Taverna", O, "O soco passa de 1d1 para 1d4 e pode empurrar.", PLANEJADO, "Conta combinada."],
	["sortudo", "Sortudo", O, "Pontos de sorte para rerrolar um d20 (ou forçar o rerrolar de um ataque contra você).", PLANEJADO, "O próximo efeito fácil: o Combate já rola o dado."],
	["iniciado_em_magia", "Iniciado em Magia", O, "Dois truques e uma magia de 1º círculo de uma lista, usados um pouco por descanso.", ESPERA, "Espera a magia entrar no jogo."],
	["perito", "Perito", O, "Proficiência em três perícias ou ferramentas à escolha.", ESPERA, "Espera as perícias virarem teste."],
	["artesao", "Artesão", O, "Proficiência com ferramentas, desconto ao comprar e um item rápido por descanso.", ESPERA, "Espera ferramentas, comércio e descanso."],
	["musico", "Músico", O, "Proficiência com instrumento e uma canção que dá inspiração no fim do descanso.", ESPERA, "Espera instrumentos, inspiração e descanso."],
	["curandeiro", "Curandeiro", O, "O kit de curandeiro cura (no estilo do Fôlego) e estabiliza quem caiu.", ESPERA, "Espera o kit de curandeiro e aliados para curar."],
	["veloz", "Veloz", G, "Deslocamento +10 pés.", PLANEJADO, "Conta combinada; é de nível 4 e a escolha de talento ainda não existe."],
	["levemente_armado", "Levemente Armado", G, "+1 num atributo e treinamento com armadura leve.", PLANEJADO, "A ficha já sabe somar treinamentos."],
	["moderadamente_armado", "Moderadamente Armado", G, "+1 num atributo e treinamento com armadura média e escudo.", PLANEJADO, "A ficha já sabe somar treinamentos."],
	["fortemente_armado", "Fortemente Armado", G, "+1 num atributo e treinamento com armadura pesada.", PLANEJADO, "A ficha já sabe somar treinamentos."],
	["armas_marciais", "Treinamento com Armas Marciais", G, "Proficiência com armas marciais.", PLANEJADO, "A ficha já sabe somar treinamentos."],
	["resiliente", "Resiliente", G, "+1 num atributo e proficiência numa salvaguarda.", PLANEJADO, "A ficha já sabe somar o que o talento dá."],
	["aumento_de_atributo", "Aumento de Valor de Habilidade", G, "+2 num atributo, ou +1 em dois. Pode repetir.", PLANEJADO, "A ficha já sabe somar o que o talento dá."],
	["mestre_armadura_media", "Mestre em Armadura Média", G, "O teto de Destreza da armadura média sobe para +3 e a Furtividade deixa de sofrer desvantagem.", PLANEJADO, "A desvantagem de Furtividade espera o teste."],
	["mestre_arma_grande", "Mestre em Arma Grande", G, "Arma Pesada soma a proficiência no dano; crítico ou abater abre um golpe extra.", PLANEJADO, "A ação bônus já existe."],
	["mestre_armadura_pesada", "Mestre em Armadura Pesada", G, "Dano contundente, cortante e perfurante sofrido leva −2.", PLANEJADO, "Regra pequena de combate."],
	["cortador", "Cortador", G, "Acerto cortante aplica Lentidão; crítico dá desvantagem no próximo ataque do alvo.", PLANEJADO, "Regra pequena de combate."],
	["perfurador", "Perfurador", G, "Pode rerrolar um dado de dano perfurante; no crítico rola um dado a mais.", PLANEJADO, "Regra pequena de combate."],
	["esmagador", "Esmagador", G, "Acerto contundente empurra 5 pés; crítico dá vantagem no próximo ataque contra o alvo.", PLANEJADO, "O Empurrar da maestria já move."],
	["empunhadura_dupla", "Empunhadura Dupla", G, "A segunda arma não precisa ser Leve.", PLANEJADO, "Regra pequena de combate."],
	["mestre_escudo", "Mestre em Escudo", G, "A ação bônus empurra com o escudo; a salvaguarda de Destreza soma o bônus do escudo.", PLANEJADO, "Regra pequena de combate."],
	["investida", "Investida", G, "Se está correndo, o próximo golpe soma 1d8 ou empurra 10 pés.", PLANEJADO, "Regra pequena de combate."],
	["duelista_defensivo", "Duelista Defensivo", G, "Soma a proficiência na CA contra um golpe corpo a corpo.", PLANEJADO, "Não há reação: viraria um botão."],
	["sentinela", "Sentinela", G, "Acerto zera o deslocamento do alvo por uma rodada.", PLANEJADO, "O ataque ao sair do alcance espera essa regra."],
	["mestre_arma_haste", "Mestre em Arma de Haste", G, "Golpe extra com a outra ponta na ação bônus.", PLANEJADO, "O ataque ao entrar no alcance espera essa regra."],
	["atleta", "Atleta", G, "Levantar de Caído gasta menos deslocamento.", PLANEJADO, "Escalar espera o cenário."],
	["agarrador", "Agarrador", G, "Vantagem em ataques contra quem você agarra e agarrar sem soltar a arma.", ESPERA, "Espera a condição Agarrado."],
	["atirador_de_elite", "Atirador de Elite", G, "O alcance longo do tiro deixa de dar desvantagem.", PLANEJADO, "A arma à distância já dispara; cobertura fica de fora."],
	["especialista_em_besta", "Especialista em Besta", G, "Inimigo a 5 pés não dá desvantagem no tiro de besta; a ação bônus dispara a Besta de Mão.", PLANEJADO, "A arma à distância já dispara."],
	["adepto_elemental", "Adepto Elemental", G, "Escolhe um tipo de dano mágico e ignora resistência a ele; o dado 1 vira 2.", ESPERA, "Espera a magia."],
	["tocado_pela_fada", "Tocado pela Fada", G, "+1 num atributo mental, um truque e duas magias de 1º círculo, uma delas Passo Nebuloso.", ESPERA, "Espera a magia."],
	["tocado_pela_sombra", "Tocado pela Sombra", G, "+1 num atributo mental, um truque e duas magias de 1º círculo, uma delas Invisibilidade.", ESPERA, "Espera a magia."],
	["telecinetico", "Telecinético", G, "+1 num atributo mental, um empurrão à distância e o truque Mão Maga.", ESPERA, "Espera a magia."],
	["telepata", "Telepata", G, "+1 num atributo mental, fala na mente de uma criatura e a magia Detectar Pensamentos.", ESPERA, "Espera a magia."],
	["conjurador_de_rituais", "Conjurador de Rituais", G, "Um livro com magias que só saem como ritual.", ESPERA, "Espera a magia."],
	["franco_atirador_de_magia", "Franco-atirador de Magia", G, "Ataque mágico à distância ignora meia cobertura e soma o alcance.", ESPERA, "Espera a magia."],
	["conjurador_de_guerra", "Conjurador de Guerra", G, "Conjurar no lugar de um ataque de oportunidade e segurar o foco com as mãos ocupadas.", ESPERA, "Espera a magia."],
	["matador_de_magos", "Matador de Magos", G, "Quem conjura ao lado sofre desvantagem, e um acerto perto pode interromper a magia.", ESPERA, "Espera a magia."],
	["especialista_em_pericia", "Especialista em Perícia", G, "+1 num atributo, uma proficiência e uma perícia com perícia especializada.", ESPERA, "Espera as perícias virarem teste."],
	["ator", "Ator", G, "+1 de Carisma, vantagem para fingir ser outra pessoa e imitar voz.", ESPERA, "Espera as perícias virarem teste."],
	["mente_agucada", "Mente Aguçada", G, "+1 de Inteligência e um estudo que revela detalhes do lugar.", ESPERA, "Espera as perícias virarem teste."],
	["observador", "Observador", G, "+1 de Inteligência ou Sabedoria e bônus para perceber esconderijo e ler lábios.", ESPERA, "Espera as perícias virarem teste."],
	["furtivo", "Furtivo", G, "Vantagem em Furtividade com pouca luz; um tiro de cobertura não revela tanto.", ESPERA, "Furtividade ainda não é teste do herói."],
	["cozinheiro", "Cozinheiro", G, "+1 de Constituição ou Sabedoria, comida que cura um pouco e petisco que dá vida temporária.", ESPERA, "Espera descanso e vida temporária."],
	["duravel", "Durável", G, "+1 de Constituição; cada dado de vida gasto num descanso recupera no mínimo o dobro do modificador.", ESPERA, "Espera o descanso curto."],
	["lider_inspirador", "Líder Inspirador", G, "Um discurso curto dá vida temporária aos aliados.", ESPERA, "Espera aliados e vida temporária."],
	["envenenador", "Envenenador", G, "Aplica veneno na arma.", ESPERA, "Espera o tipo de dano veneno em TiposDano."],
	["combatente_montado", "Combatente Montado", G, "Protege a montaria e ganha vantagem contra quem é menor.", FORA, "Não há montaria."],
]

const FOR := Atributos.FORCA
const DES := Atributos.DESTREZA
const CON := Atributos.CONSTITUICAO
const INT := Atributos.INTELIGENCIA
const SAB := Atributos.SABEDORIA
const CAR := Atributos.CARISMA

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
	talento.nome = linha[1]
	talento.categoria = linha[2]
	talento.resumo = linha[3]
	talento.situacao = linha[4]
	talento.motivo = linha[5]
	ResourceSaver.save(talento, "%s%02d_%s.tres" % [PASTA_TALENTOS, indice + 1, talento.id])


func _gravar_antecedente(indice: int, linha: Array) -> void:
	var antecedente: AntecedenteRPG = AntecedenteRPG.new()
	antecedente.id = linha[0]
	antecedente.nome = linha[1]
	antecedente.descricao = linha[2]
	antecedente.atributos.assign(linha[3])
	antecedente.talento = linha[4]
	antecedente.pericias.assign(linha[5])
	antecedente.ferramenta = linha[6]
	antecedente.equipamento = EQUIPAMENTO
	ResourceSaver.save(antecedente, "%s%02d_%s.tres" % [PASTA_ANTECEDENTES, indice + 1, antecedente.id])
