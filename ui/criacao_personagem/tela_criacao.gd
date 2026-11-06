class_name TelaCriacao
extends Control
## Criação em três passos: quem é o herói, os atributos e as maestrias (os tipos de arma que
## domina; Guerreiro: 3). Funciona com o jogo pausado.
## Ao confirmar, emite `confirmada`.

## Emitido ao clicar em "Começar", com a ficha montada e o pacote inicial escolhido
## (null se a classe não tiver pacotes).
signal confirmada(ficha: Ficha, pacote: PacoteInicial)

const LARGURA_AJUSTE := 28

## Classes que o jogador pode escolher (por enquanto só o Guerreiro).
@export var classes: Array[ClasseRPG] = []
## Arma da prévia do dano quando o pacote não põe nenhuma na mão (soco).
@export var arma_previa: Arma
## De onde vêm as armas que dá para dominar (Maestria em Armas).
@export var pasta_armas: String = "res://data/armas/"

enum Passo { QUEM, ATRIBUTOS, MAESTRIAS }
const TITULOS := {Passo.QUEM: "Quem é você", Passo.ATRIBUTOS: "Atributos", Passo.MAESTRIAS: "Maestrias"}

var _classe: ClasseRPG
var _pacote: PacoteInicial
var _compra := CompraDePontos.new()
var _rotulos_valor: Dictionary[StringName, Label] = {}
var _rotulos_mod: Dictionary[StringName, Label] = {}
var _botoes_menos: Dictionary[StringName, Button] = {}
var _botoes_mais: Dictionary[StringName, Button] = {}
## Armas que a classe pode dominar (proficiente), na ordem da lista.
var _armas: Array[Arma] = []

@onready var _campo_nome: LineEdit = %Nome
@onready var _escolha_classe: OptionButton = %Classe
@onready var _escolha_pacote: OptionButton = %Pacote
@onready var _pontos: Label = %Pontos
@onready var _grade: GridContainer = %Grade
@onready var _previa: Label = %Previa
@onready var _proficiencias: Label = %Proficiencias
@onready var _leva: Label = %Leva
@onready var _aviso: Label = %Aviso
@onready var _titulo: Label = %TituloPasso
@onready var _passo_quem: Control = %PassoQuem
@onready var _passo_atributos: Control = %PassoAtributos
@onready var _passo_maestrias: Control = %PassoMaestrias
@onready var _lista_maestrias: ItemList = %ListaMaestrias
@onready var _contagem_maestrias: Label = %ContagemMaestrias
@onready var _detalhe_maestria: Label = %DetalheMaestria
@onready var _botao_sugestao: Button = %Sugestao
@onready var _botao_comecar: Button = %Comecar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	if classes.is_empty():
		classes = [ClasseRPG.new()]
	if arma_previa == null:
		arma_previa = Arma.new()
	_preparar_campos()
	for atributo in Atributos.TODOS:
		_criar_linha(atributo)
	escolher_classe(0)
	_mostrar_passo(Passo.QUEM)
	_campo_nome.grab_focus()


func definir_nome(texto: String) -> void:
	_campo_nome.text = texto
	_atualizar()


func escolher_classe(indice: int) -> void:
	_classe = classes[indice]
	_escolha_classe.select(indice)
	_preencher_armas()
	_preencher_pacotes()
	_atualizar()


func escolher_pacote(indice: int) -> void:
	_pacote = _classe.pacotes_iniciais[indice] if indice < _classe.pacotes_iniciais.size() else null
	_escolha_pacote.select(indice)
	_marcar_armas_do_pacote()
	_atualizar()


## Usa a distribuição sugerida da classe escolhida.
func aplicar_sugestao() -> void:
	_compra.aplicar(_classe.atributos_sugeridos)
	_atualizar()


func mudar_atributo(atributo: StringName, quanto: int) -> void:
	if quanto > 0:
		_compra.aumentar(atributo)
	else:
		_compra.diminuir(atributo)
	_atualizar()


## Marca ou desmarca uma arma dominada (pelo nome). Não passa da quantidade da classe.
func marcar_arma(nome_arma: String, marcada: bool) -> void:
	for i in _armas.size():
		if _armas[i].nome == nome_arma:
			_ao_marcar(i, marcada)


## Nomes das armas marcadas.
func armas_marcadas() -> Array[String]:
	var nomes: Array[String] = []
	for i in _lista_maestrias.get_selected_items():
		nomes.append(_armas[i].nome)
	return nomes


## Só confirma com um nome, todos os pontos gastos e as maestrias escolhidas.
func confirmar() -> void:
	if _falta_algo() != "":
		return
	confirmada.emit(_ficha_atual(), _pacote)


func _preparar_campos() -> void:
	_campo_nome.max_length = Ficha.TAMANHO_MAXIMO_NOME
	_campo_nome.text_changed.connect(func(_t: String) -> void: _atualizar())
	_campo_nome.text_submitted.connect(func(_t: String) -> void: confirmar())
	for classe in classes:
		_escolha_classe.add_item(classe.nome)
	_escolha_classe.item_selected.connect(escolher_classe)
	_escolha_pacote.item_selected.connect(escolher_pacote)
	_escolha_classe.disabled = classes.size() == 1  # só uma classe por enquanto
	_botao_sugestao.pressed.connect(aplicar_sugestao)
	_botao_comecar.pressed.connect(confirmar)
	(%Atributos as Button).pressed.connect(_mostrar_passo.bind(Passo.ATRIBUTOS))
	(%Voltar as Button).pressed.connect(_mostrar_passo.bind(Passo.QUEM))
	(%IrMaestrias as Button).pressed.connect(_mostrar_passo.bind(Passo.MAESTRIAS))
	(%VoltarAtributos as Button).pressed.connect(_mostrar_passo.bind(Passo.ATRIBUTOS))
	_lista_maestrias.multi_selected.connect(_ao_marcar)


func _mostrar_passo(passo: Passo) -> void:
	_passo_quem.visible = passo == Passo.QUEM
	_passo_atributos.visible = passo == Passo.ATRIBUTOS
	_passo_maestrias.visible = passo == Passo.MAESTRIAS
	_titulo.text = TITULOS[passo]


## Lista as armas em que a classe é proficiente: "Espada Longa (Enfraquecer)".
func _preencher_armas() -> void:
	_armas.clear()
	for recurso in Recursos.da_pasta(pasta_armas):
		var arma := recurso as Arma
		if arma and arma.maestria != &"" and arma.categoria in _classe.proficiencias_armas:
			_armas.append(arma)
	_lista_maestrias.clear()
	for arma in _armas:
		_lista_maestrias.add_item("%s (%s)" % [arma.nome, Proficiencias.NOMES_MAESTRIAS[arma.maestria]], arma.icone)


## Começa com as armas do pacote marcadas (até a quantidade da classe).
func _marcar_armas_do_pacote() -> void:
	_lista_maestrias.deselect_all()
	if _pacote == null:
		return
	for item in _pacote.itens:
		if item is Arma:
			marcar_arma(item.nome, true)


## Marcou (ou desmarcou) a arma `indice`. Passou do limite = não marca. Mostra a maestria.
func _ao_marcar(indice: int, marcada: bool) -> void:
	var nome_arma := _armas[indice].nome
	var outras := armas_marcadas().filter(func(n: String) -> bool: return n != nome_arma).size()
	if marcada and outras < _classe.quantidade_maestrias:
		_lista_maestrias.select(indice, false)
	else:
		_lista_maestrias.deselect(indice)
	var arma := _armas[indice]
	_detalhe_maestria.text = "%s — %s: %s" % [arma.nome, Proficiencias.NOMES_MAESTRIAS[arma.maestria],
		Proficiencias.DESCRICOES_MAESTRIAS[arma.maestria]]
	_atualizar()


## Lista os pacotes da classe ("Pacote A") e escolhe o primeiro. O que leva fica numa linha.
func _preencher_pacotes() -> void:
	_escolha_pacote.clear()
	for pacote in _classe.pacotes_iniciais:
		_escolha_pacote.add_item(pacote.nome)
	_escolha_pacote.disabled = _classe.pacotes_iniciais.is_empty()
	escolher_pacote(0)


func _ficha_atual() -> Ficha:
	var ficha := Ficha.new(_classe, _compra.valores, _campo_nome.text)
	ficha.armas_dominadas = armas_marcadas()
	return ficha


## O que impede de começar ("" = nada).
func _falta_algo() -> String:
	if not Ficha.nome_valido(_campo_nome.text):
		return "Escreva um nome"
	if _compra.pontos_restantes() != 0:
		return "Gaste todos os pontos"
	if armas_marcadas().size() != _classe.quantidade_maestrias:
		return "Escolha %d armas" % _classe.quantidade_maestrias
	return ""


func _criar_linha(atributo: StringName) -> void:
	_grade.add_child(_rotulo(Atributos.SIGLAS[atributo]))
	_rotulos_valor[atributo] = _rotulo("")
	_rotulos_mod[atributo] = _rotulo("")
	_botoes_menos[atributo] = _botao("-", mudar_atributo.bind(atributo, -1))
	_botoes_mais[atributo] = _botao("+", mudar_atributo.bind(atributo, 1))
	for no in [_rotulos_valor[atributo], _rotulos_mod[atributo], _botoes_menos[atributo], _botoes_mais[atributo]]:
		_grade.add_child(no)


func _atualizar() -> void:
	if _classe == null:
		return
	var restantes := _compra.pontos_restantes()
	_pontos.text = "Pontos restantes: %d de %d" % [restantes, CompraDePontos.PONTOS_TOTAIS]
	for atributo in Atributos.TODOS:
		var valor: int = _compra.valores[atributo]
		_rotulos_valor[atributo].text = str(valor)
		_rotulos_mod[atributo].text = Atributos.texto_modificador(valor)
		_botoes_menos[atributo].disabled = not _compra.pode_diminuir(atributo)
		_botoes_mais[atributo].disabled = not _compra.pode_aumentar(atributo)
	var ficha := _ficha_atual()
	_previa.text = _texto_previa(ficha)
	_aviso.text = _texto_aviso(ficha)
	_leva.text = "Leva: %s" % _pacote.texto_itens() if _pacote else ""
	_proficiencias.text = "Proficiência: %s · %s" % [Proficiencias.texto_armas(_classe.proficiencias_armas),
		Proficiencias.texto_armaduras(_classe.treinamento_armaduras)]
	_botao_sugestao.text = "Sugestão do %s" % _classe.nome
	_contagem_maestrias.text = "Domine %d tipos de arma (%d/%d marcadas). Só com elas a maestria vale." % [
		_classe.quantidade_maestrias, armas_marcadas().size(), _classe.quantidade_maestrias]
	var falta := _falta_algo()
	_botao_comecar.disabled = falta != ""
	_botao_comecar.text = "Começar" if falta == "" else falta


## "Vida 12 · CA 16 · 30 pés · Dano 2d6+2".
func _texto_previa(ficha: Ficha) -> String:
	var armadura := _pacote.armadura() if _pacote else null
	var arma := _pacote.arma() if _pacote and _pacote.arma() else arma_previa
	return "Vida %d · CA %d · %d pés · Dano %s" % [ficha.vida_maxima(), ficha.classe_armadura(armadura),
		int(ficha.deslocamento_pes(armadura)), ficha.texto_dano(arma, arma.e_versatil())]


func _texto_aviso(ficha: Ficha) -> String:
	var armadura := _pacote.armadura() if _pacote else null
	var arma := _pacote.arma() if _pacote and _pacote.arma() else arma_previa
	var avisos: PackedStringArray = []
	if ficha.falta_forca_para(armadura):
		avisos.append("A %s pede FOR %d: -%d pés" % [armadura.nome, armadura.forca_minima, Ficha.PERDA_DESLOCAMENTO_SEM_FORCA])
	if ficha.fraco_para(arma):
		avisos.append("%s é Pesada: FOR abaixo de %d, desvantagem" % [arma.nome, Ficha.FORCA_MINIMA_ARMA_PESADA])
	return "\n".join(avisos)


func _rotulo(texto: String) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	return rotulo


func _botao(texto: String, ao_apertar: Callable) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.custom_minimum_size = Vector2(LARGURA_AJUSTE, 0)
	botao.pressed.connect(ao_apertar)
	return botao
