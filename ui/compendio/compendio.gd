class_name Compendio
extends RefCounted
## Monta as páginas do Compêndio a partir dos dados do jogo. Regra pura, sem tela. Seções vazias
## não aparecem; entram só conteúdos acessíveis, como Guerreiro, maestrias e itens do arsenal.

const ABA_GUERREIRO := "Guerreiro"
const ABA_PACOTES := "Pacotes"
const ABA_MAESTRIAS := "Maestrias"
const ABA_ARMAS := "Armas"
const ABA_ARMADURAS := "Armaduras"
const ABA_ITENS := "Itens"
const ABA_ANTECEDENTES := "Antecedentes"
const ABA_TALENTOS := "Talentos"
const PASTA_ARMAS := "res://data/armas"
const PASTA_ARMADURAS := "res://data/armaduras"
const PASTA_MUNICOES := "res://data/municoes"
const PASTA_ANTECEDENTES := "res://data/antecedentes"
const PASTA_TALENTOS := "res://data/talentos"


## Todas as abas, na ordem em que aparecem: nome da aba -> páginas.
static func montar(classe: ClasseRPG) -> Dictionary[String, Array]:
	var armas: Array[Item] = _itens(PASTA_ARMAS)
	var secoes: Dictionary[String, Array] = {}
	_adicionar_secao(secoes, ABA_GUERREIRO, guerreiro(classe))
	_adicionar_secao(secoes, ABA_PACOTES, pacotes(classe))
	_adicionar_secao(secoes, ABA_MAESTRIAS, maestrias(armas))
	_adicionar_secao(secoes, ABA_ARMAS, itens(armas))
	_adicionar_secao(secoes, ABA_ARMADURAS, itens(_itens(PASTA_ARMADURAS)))
	_adicionar_secao(secoes, ABA_ITENS, itens(_itens(PASTA_MUNICOES)))
	_adicionar_secao(secoes, ABA_ANTECEDENTES, antecedentes(Recursos.da_pasta(PASTA_ANTECEDENTES)))
	_adicionar_secao(secoes, ABA_TALENTOS, talentos(Recursos.da_pasta(PASTA_TALENTOS)))
	return secoes


## A classe em uma página e uma por habilidade que já existe (as "em breve" ficam de fora).
static func guerreiro(classe: ClasseRPG) -> Array:
	var paginas: Array = []
	if classe == null:
		return paginas
	paginas.append(EntradaCompendio.new(classe.nome, "Classe", _texto_da_classe(classe)))
	for habilidade in classe.habilidades:
		if not habilidade.em_breve:
			paginas.append(EntradaCompendio.new(habilidade.nome, "Habilidade · nível %d" % habilidade.nivel_minimo, habilidade.descricao))
	return paginas


## Os pacotes iniciais que o jogador pode escolher na criação do Guerreiro.
static func pacotes(classe: ClasseRPG) -> Array:
	var paginas: Array = []
	if classe == null:
		return paginas
	for pacote in classe.pacotes_iniciais:
		var equipados: Array[String] = []
		for item in pacote.equipar:
			equipados.append(item.nome)
		var texto := "Itens: %s\nComeça equipado: %s" % [pacote.texto_itens(), ", ".join(equipados)]
		paginas.append(EntradaCompendio.new(pacote.nome, "Pacote inicial", texto))
	return paginas


## Uma página por maestria, com as armas do arsenal que a têm.
static func maestrias(armas: Array[Item]) -> Array:
	var paginas: Array = []
	for id in Proficiencias.NOMES_MAESTRIAS:
		var texto: String = Proficiencias.DESCRICOES_MAESTRIAS[id]
		var com_ela: Array[String] = []
		for item in armas:
			if item is Arma and (item as Arma).maestria == id:
				com_ela.append(item.nome)
		if not com_ela.is_empty():
			texto += "\n\nArmas: %s" % ", ".join(com_ela)
		paginas.append(EntradaCompendio.new(Proficiencias.NOMES_MAESTRIAS[id], "Maestria de arma", texto))
	return paginas


## Armas ou armaduras: uma página por item, com o resumo do arsenal.
static func itens(lista: Array[Item]) -> Array:
	var paginas: Array = []
	for item in lista:
		var tipo := "Item"
		if item is Arma:
			tipo = "Arma"
		elif item is Armadura:
			tipo = "Escudo" if (item as Armadura).e_escudo() else "Armadura"
		elif item is Municao:
			tipo = "Munição"
		paginas.append(EntradaCompendio.new(item.nome, tipo, ResumoItem.texto(item).replace(" · ", "\n")))
	return paginas


static func antecedentes(todos: Array[Resource]) -> Array:
	var paginas: Array = []
	for recurso in todos:
		var a := recurso as AntecedenteRPG
		if a.no_jogo:
			paginas.append(EntradaCompendio.new(a.nome, "Antecedente", _texto_do_antecedente(a)))
	return paginas


static func talentos(todos: Array[Resource]) -> Array:
	var paginas: Array = []
	for recurso in todos:
		var t := recurso as TalentoRPG
		if t.no_jogo:
			paginas.append(EntradaCompendio.new(t.nome, TalentoRPG.nome_da_categoria(t.categoria), t.resumo))
	return paginas


static func _itens(pasta: String) -> Array[Item]:
	var achados: Array[Item] = []
	for recurso in Recursos.da_pasta(pasta):
		achados.append(recurso as Item)
	return achados


static func _adicionar_secao(secoes: Dictionary[String, Array], nome: String, paginas: Array) -> void:
	if not paginas.is_empty():
		secoes[nome] = paginas


static func _texto_da_classe(classe: ClasseRPG) -> String:
	return "Dado de vida: d%d\nSalvaguardas: %s\nArmas: %s\nArmaduras: %s\nPerícias: escolhe %d de %d" % [
		classe.dado_vida, _nomes(classe.salvaguardas_proficientes, Atributos.NOMES),
		_nomes(classe.proficiencias_armas, Proficiencias.NOMES_ARMAS),
		_nomes(classe.treinamento_armaduras, Proficiencias.NOMES_ARMADURAS),
		classe.quantidade_pericias, classe.pericias_escolhiveis.size()]


static func _texto_do_antecedente(a: AntecedenteRPG) -> String:
	var pericias: Array[String] = []
	for pericia in a.pericias:
		pericias.append(Pericia.nome_de(pericia))
	return "%s\n\nAtributos: %s\nPerícias: %s\nFerramenta: %s" % [
		a.descricao, _nomes(a.atributos, Atributos.NOMES), ", ".join(pericias), a.ferramenta]


static func _nomes(ids: Array, tabela: Dictionary) -> String:
	var nomes: Array[String] = []
	for id in ids:
		nomes.append(tabela.get(id, String(id)))
	return ", ".join(nomes)
