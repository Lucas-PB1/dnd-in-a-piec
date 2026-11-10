class_name Salvamento
extends RefCounted
## Salvar e carregar o jogo: um arquivo JSON em user://. Guarda a ficha, a mochila (com o
## desgaste, as quantidades e o que está equipado) e a fase. Ao continuar, o herói volta ao
## começo dessa fase com a vida cheia. Regra pura: não mexe em cena nenhuma.

## Onde o jogo fica salvo. Os testes trocam por outro arquivo, para não apagar o save de verdade.
static var caminho: String = "user://save.json"
## Sobe quando o formato muda, para não ler um arquivo antigo errado.
const VERSAO := 1
## Onde ficam os itens do jogo; o save guarda só o nome e busca o item aqui ao carregar.
const PASTA_TALENTOS := "res://data/talentos"
const PASTAS_ITENS: Array[String] = ["res://data/armas", "res://data/armaduras", "res://data/municoes", "res://data/itens"]

static var _catalogo: Dictionary[String, String] = {}
## Nomes de talento de saves antigos -> nome do livro em português. O save agora guarda o id; estes e os nomes do livro
## ainda são aceitos ao carregar (o id sai do `TalentoRPG` de mesmo nome).
const NOMES_ANTIGOS_DE_TALENTOS := {
	"Resistente": "Robusto", "Perito": "Habilidoso", "Cortador": "Retalhador",
	"Empunhadura Dupla": "Combatente com Duas Armas", "Mestre em Arma Grande": "Mestre em Armas Grandes",
	"Mestre em Armadura Média": "Mestre em Armaduras Médias", "Mestre em Armadura Pesada": "Mestre em Armaduras Pesadas",
	"Mestre em Escudo": "Mestre em Escudos", "Mestre em Arma de Haste": "Mestre em Armas de Haste",
	"Especialista em Besta": "Especialista em Bestas", "Aumento de Valor de Habilidade": "Aumento no Valor de Atributo",
}


static func existe() -> bool:
	return FileAccess.file_exists(caminho)


static func apagar() -> void:
	if existe():
		DirAccess.remove_absolute(caminho)


## Grava o jogo. `indice_fase` é o número da fase (1 = Clareira). Devolve false se não conseguiu.
static func gravar(ficha: Ficha, inventario: Inventario, indice_fase: int, bestiario: Bestiario = null) -> bool:
	var arquivo := FileAccess.open(caminho, FileAccess.WRITE)
	if arquivo == null:
		return false
	arquivo.store_string(JSON.stringify(para_dicionario(ficha, inventario, indice_fase, bestiario), "\t"))
	return true


## Lê o jogo salvo. Vazio se não existe, está estragado ou é de outra versão.
static func ler() -> Dictionary:
	if not existe():
		return {}
	var leitor := JSON.new()
	if leitor.parse(FileAccess.get_file_as_string(caminho)) != OK:
		return {}  # arquivo estragado: trata como sem jogo salvo, sem barulho no log
	var dados: Variant = leitor.data
	if dados is Dictionary and int((dados as Dictionary).get("versao", 0)) == VERSAO:
		return dados
	return {}


static func para_dicionario(ficha: Ficha, inventario: Inventario, indice_fase: int, bestiario: Bestiario = null) -> Dictionary:
	var itens: Array[Dictionary] = []
	for item in inventario.itens:
		itens.append({
			"nome": item.nome if not (item is Arma and (item as Arma).bonus_magico > 0) else Arma.separar_nome_magico(item.nome)[0],
			"quantidade": inventario.quantidade_de(item),
			"desgaste": inventario.penalidade(item),
			"bonus_magico": (item as Arma).bonus_magico if item is Arma else 0,
		})
	return {
		"versao": VERSAO,
		"fase": indice_fase,
		"ficha": {
			"nome": ficha.nome,
			"classe": ficha.classe.resource_path,
			"nivel": ficha.nivel,
			"experiencia": ficha.experiencia,
			"ouro": ficha.ouro,
			"atributos": ficha.atributos,
			"armas_dominadas": ficha.armas_dominadas,
			"talentos": ficha.talentos,
			"escolhas_de_talento": ficha.escolhas_de_talento_feitas,
			"subclasse": ficha.subclasse,
			"antecedente": ficha.antecedente,
			"salvaguardas_extras": ficha.salvaguardas_extras,
			"pericias": ficha.pericias,
			"pericias_especializadas": ficha.pericias_especializadas,
		},
		"mochila": {"itens": itens, "equipados": _posicoes_dos_equipados(inventario)},
		"bestiario": bestiario.para_dicionario() if bestiario else {},
	}


## Número da fase salva (pelo menos 1).
static func fase_de(dados: Dictionary) -> int:
	return maxi(int(dados.get("fase", 1)), 1)


## Monta a ficha salva, ou null se faltar a classe.
static func montar_ficha(dados: Dictionary) -> Ficha:
	var f: Dictionary = dados.get("ficha", {})
	var classe := load(str(f.get("classe", ""))) as ClasseRPG if ResourceLoader.exists(str(f.get("classe", ""))) else null
	if classe == null:
		return null
	var atributos: Dictionary = {}
	for chave in f.get("atributos", {}):
		atributos[StringName(chave)] = int(f["atributos"][chave])
	var ficha := Ficha.new(classe, atributos, str(f.get("nome", Ficha.NOME_PADRAO)))
	ficha.nivel = clampi(int(f.get("nivel", 1)), 1, Ficha.NIVEL_MAXIMO)
	ficha.experiencia = int(f.get("experiencia", 0))
	ficha.ouro = maxi(int(f.get("ouro", 0)), 0)
	ficha.armas_dominadas.assign(f.get("armas_dominadas", []))
	for nome in f.get("talentos", []):
		ficha.talentos.append(id_do_talento(str(nome)))
	ficha.escolhas_de_talento_feitas = int(f.get("escolhas_de_talento", 0))
	ficha.subclasse = StringName(str(f.get("subclasse", "")))
	ficha.antecedente = StringName(str(f.get("antecedente", "")))
	for atributo in f.get("salvaguardas_extras", []):
		ficha.salvaguardas_extras.append(StringName(atributo))
	for pericia in f.get("pericias", []):
		ficha.pericias.append(StringName(pericia))
	for pericia in f.get("pericias_especializadas", []):
		ficha.pericias_especializadas.append(StringName(pericia))
	return ficha


## Esvazia a mochila e põe de volta o que foi salvo (itens novos, com o mesmo desgaste).
static func restaurar_inventario(dados: Dictionary, inventario: Inventario) -> void:
	var mochila: Dictionary = dados.get("mochila", {})
	inventario.limpar()
	var guardados: Array[Item] = []
	for linha: Dictionary in mochila.get("itens", []):
		var modelo := item_chamado(str(linha.get("nome", "")))
		if modelo == null:
			guardados.append(null)  # item que não existe mais: segura o número da posição
			continue
		var copia := _copia_do_modelo(modelo, int(linha.get("bonus_magico", 0)))
		inventario.adicionar_com_desgaste(copia, int(linha.get("desgaste", 0)), int(linha.get("quantidade", 1)))
		guardados.append(copia)
	for indice in mochila.get("equipados", []):
		var item: Item = guardados[int(indice)] if int(indice) < guardados.size() else null
		if item != null:
			inventario.equipar(item)


## Cópia nova do item do jogo; arma mágica salva volta com o mesmo bônus.
static func _copia_do_modelo(modelo: Item, bonus_magico: int) -> Item:
	if modelo is Arma and bonus_magico > 0:
		return (modelo as Arma).com_bonus_magico(bonus_magico)
	return modelo.duplicate() as Item

## Põe de volta as criaturas já derrotadas.
static func restaurar_bestiario(dados: Dictionary, bestiario: Bestiario) -> void:
	bestiario.carregar(dados.get("bestiario", {}))


## O id do talento de um save: já é um id, ou é um nome (do livro ou antigo) de talento em `data/talentos`.
static func id_do_talento(valor: String) -> StringName:
	var nome := NOMES_ANTIGOS_DE_TALENTOS.get(valor, valor) as String
	for recurso in Recursos.da_pasta(PASTA_TALENTOS):
		var talento := recurso as TalentoRPG
		if String(talento.id) == valor or talento.nome == nome:
			return talento.id
	return StringName(valor)

## O item do jogo com esse nome (a base, não uma cópia), ou null.
static func item_chamado(nome: String) -> Item:
	if _catalogo.is_empty():
		_montar_catalogo()
	return load(_catalogo[nome]) as Item if _catalogo.has(nome) else null


static func _montar_catalogo() -> void:
	for pasta in PASTAS_ITENS:
		for arquivo in ResourceLoader.list_directory(pasta):
			if not arquivo.ends_with(".tres"):
				continue
			var item := load("%s/%s" % [pasta, arquivo]) as Item
			if item != null:
				_catalogo[item.nome] = item.resource_path


## Posições (na lista de itens) dos equipados, na ordem em que foram equipados.
static func _posicoes_dos_equipados(inventario: Inventario) -> Array[int]:
	var ordem: Array[int] = []
	for item in inventario.equipados_em_ordem():
		ordem.append(inventario.itens.find(item))
	return ordem
