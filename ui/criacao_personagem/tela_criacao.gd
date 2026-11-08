class_name TelaCriacao
extends Control
## Criação em quatro passos: quem é o herói, os atributos, as perícias (Guerreiro: 2) e as
## maestrias (os tipos de arma que domina; Guerreiro: 3). Funciona com o jogo pausado.
## Ao confirmar, emite `confirmada`.

## Emitido ao clicar em "Começar", com a ficha montada e o pacote inicial escolhido
## (null se a classe não tiver pacotes).
signal confirmada(ficha: Ficha, pacote: PacoteInicial)
## Esc no primeiro passo: quem montou o jogo volta ao título.
signal voltar_ao_titulo_pedido

const LARGURA_AJUSTE := 28
## Largura dos botões de distribuição pronta (px).
const LARGURA_BUILD := 150
## Espaço entre as partes de um atributo na grade (px).
const SEPARACAO_CELULA := 6

## Classes que o jogador pode escolher (por enquanto só o Guerreiro).
@export var classes: Array[ClasseRPG] = []
## Arma da prévia do dano quando o pacote não põe nenhuma na mão (soco).
@export var arma_previa: Arma
## De onde vêm as armas que dá para dominar (Maestria em Armas).
@export var pasta_armas: String = "res://data/armas/"

enum Passo { QUEM, ATRIBUTOS, PERICIAS, MAESTRIAS }

var _passo_atual: Passo = Passo.QUEM
const TITULOS := {
	Passo.QUEM: "Quem é você",
	Passo.ATRIBUTOS: "Atributos",
	Passo.PERICIAS: "Perícias",
	Passo.MAESTRIAS: "Maestrias",
}

var _classe: ClasseRPG
var _pacote: PacoteInicial
var _nivel_inicial: int = 1
var _compra := CompraDePontos.new()
var _rotulos_valor: Dictionary[StringName, Label] = {}
var _rotulos_mod: Dictionary[StringName, Label] = {}
var _botoes_menos: Dictionary[StringName, Button] = {}
var _botoes_mais: Dictionary[StringName, Button] = {}
## Armas que a classe pode dominar (proficiente), na ordem da lista.
var _armas: Array[Arma] = []

@onready var _campo_nome: LineEdit = %Nome
@onready var _escolha_classe: OptionButton = %Classe
@onready var _escolha_nivel: OptionButton = %Nivel
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
@onready var _passo_pericias: Control = %PassoPericias
@onready var _passo_maestrias: Control = %PassoMaestrias
@onready var _lista_pericias: ItemList = %ListaPericias
@onready var _contagem_pericias: Label = %ContagemPericias
@onready var _detalhe_pericia: Label = %DetalhePericia
@onready var _lista_maestrias: ItemList = %ListaMaestrias
@onready var _contagem_maestrias: Label = %ContagemMaestrias
@onready var _detalhe_maestria: Label = %DetalheMaestria
@onready var _caixa_builds: HBoxContainer = %Builds
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
	_preencher_pericias()
	_preencher_armas()
	_preencher_pacotes()
	_atualizar()


func escolher_nivel(indice: int) -> void:
	_nivel_inicial = clampi(indice + 1, 1, Ficha.NIVEL_MAXIMO)
	_escolha_nivel.select(_nivel_inicial - 1)
	_atualizar()


func escolher_pacote(indice: int) -> void:
	_pacote = _classe.pacotes_iniciais[indice] if indice < _classe.pacotes_iniciais.size() else null
	_escolha_pacote.select(indice)
	_marcar_armas_do_pacote()
	_atualizar()


## Aplica uma distribuição pronta da classe (ex.: Guerreiro de armadura pesada).
func aplicar_build(build: BuildSugerido) -> void:
	_compra.aplicar(build.atributos)
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


## Marca ou desmarca uma perícia (pelo id). Não passa da quantidade da classe.
func marcar_pericia(id: StringName, marcada: bool) -> void:
	var indice := _classe.pericias_escolhiveis.find(id)
	if indice >= 0:
		_ao_marcar_pericia(indice, marcada)


## Ids das perícias marcadas.
func pericias_marcadas() -> Array[StringName]:
	var ids: Array[StringName] = []
	for i in _lista_pericias.get_selected_items():
		ids.append(_classe.pericias_escolhiveis[i])
	return ids


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
	_escolha_nivel.add_item("Nível 1 · %d XP" % Ficha.XP_POR_NIVEL[1])
	_escolha_nivel.add_item("Nível 2 · %d XP" % Ficha.XP_POR_NIVEL[2])
	_escolha_nivel.add_item("Nível 3 · %d XP" % Ficha.XP_POR_NIVEL[3])
	_escolha_nivel.select(0)
	_escolha_nivel.item_selected.connect(escolher_nivel)
	_escolha_pacote.item_selected.connect(escolher_pacote)
	_escolha_classe.disabled = classes.size() == 1  # só uma classe por enquanto
	_botao_comecar.pressed.connect(confirmar)
	(%Atributos as Button).pressed.connect(_mostrar_passo.bind(Passo.ATRIBUTOS))
	(%Voltar as Button).pressed.connect(_mostrar_passo.bind(Passo.QUEM))
	(%IrPericias as Button).pressed.connect(_mostrar_passo.bind(Passo.PERICIAS))
	(%VoltarDasPericias as Button).pressed.connect(_mostrar_passo.bind(Passo.ATRIBUTOS))
	(%IrMaestrias as Button).pressed.connect(_mostrar_passo.bind(Passo.MAESTRIAS))
	(%VoltarAtributos as Button).pressed.connect(_mostrar_passo.bind(Passo.PERICIAS))
	_lista_pericias.multi_selected.connect(_ao_marcar_pericia)
	_lista_maestrias.multi_selected.connect(_ao_marcar)


## Esc volta um passo; no primeiro, pede para voltar ao título.
func _unhandled_input(evento: InputEvent) -> void:
	if not evento.is_action_pressed(&"ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	match _passo_atual:
		Passo.QUEM:
			voltar_ao_titulo_pedido.emit()
		Passo.ATRIBUTOS:
			_mostrar_passo(Passo.QUEM)
		Passo.PERICIAS:
			_mostrar_passo(Passo.ATRIBUTOS)
		Passo.MAESTRIAS:
			_mostrar_passo(Passo.PERICIAS)


func _mostrar_passo(passo: Passo) -> void:
	_passo_atual = passo
	_passo_quem.visible = passo == Passo.QUEM
	_passo_atributos.visible = passo == Passo.ATRIBUTOS
	_passo_pericias.visible = passo == Passo.PERICIAS
	_passo_maestrias.visible = passo == Passo.MAESTRIAS
	_titulo.text = TITULOS[passo]


## Lista as perícias da classe e marca as sugeridas (até a quantidade).
func _preencher_pericias() -> void:
	_lista_pericias.clear()
	for id in _classe.pericias_escolhiveis:
		_lista_pericias.add_item(Pericia.texto_da_lista(id))
	for id in _classe.pericias_sugeridas:
		marcar_pericia(id, true)


## Marcou (ou desmarcou) a perícia `indice`. Passou do limite = não marca.
func _ao_marcar_pericia(indice: int, marcada: bool) -> void:
	var id := _classe.pericias_escolhiveis[indice]
	var outras := pericias_marcadas().filter(func(p: StringName) -> bool: return p != id).size()
	if marcada and outras < _classe.quantidade_pericias:
		_lista_pericias.select(indice, false)
	else:
		_lista_pericias.deselect(indice)
	_detalhe_pericia.text = Pericia.descricao(id)
	_atualizar()


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
	ficha.definir_nivel_inicial(_nivel_inicial)
	ficha.armas_dominadas = armas_marcadas()
	ficha.pericias = pericias_marcadas()
	return ficha


## O que impede de começar ("" = nada).
func _falta_algo() -> String:
	if not Ficha.nome_valido(_campo_nome.text):
		return "Escreva um nome"
	if _classe.quantidade_pericias > 0 and pericias_marcadas().size() != _classe.quantidade_pericias:
		return "Escolha %d perícias" % _classe.quantidade_pericias
	if armas_marcadas().size() != _classe.quantidade_maestrias:
		return "Escolha %d armas" % _classe.quantidade_maestrias
	return ""


func _criar_linha(atributo: StringName) -> void:
	var celula := HBoxContainer.new()  # sigla, valor, modificador, - e +: um atributo por célula da grade
	celula.add_theme_constant_override(&"separation", SEPARACAO_CELULA)
	celula.add_child(_rotulo(Atributos.SIGLAS[atributo]))
	_rotulos_valor[atributo] = _rotulo("")
	_rotulos_mod[atributo] = _rotulo("")
	_botoes_menos[atributo] = _botao("-", mudar_atributo.bind(atributo, -1))
	_botoes_mais[atributo] = _botao("+", mudar_atributo.bind(atributo, 1))
	for no in [_rotulos_valor[atributo], _rotulos_mod[atributo], _botoes_menos[atributo], _botoes_mais[atributo]]:
		celula.add_child(no)
	_grade.add_child(celula)


## Um botão por distribuição pronta da classe. Só refaz se a classe mudou.
func _montar_builds() -> void:
	var builds := _classe.builds_sugeridos
	if _caixa_builds.get_child_count() == builds.size():
		return
	for botao in _caixa_builds.get_children():
		botao.queue_free()
	for build in builds:
		var botao := _botao(build.nome, aplicar_build.bind(build))
		botao.custom_minimum_size = Vector2(LARGURA_BUILD, 0)
		_caixa_builds.add_child(botao)


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
	_contagem_pericias.text = "Escolha %d perícias (%d/%d). Percepção passiva: %d." % [
		_classe.quantidade_pericias, pericias_marcadas().size(), _classe.quantidade_pericias,
		ficha.percepcao_passiva()]
	_previa.text = _texto_previa(ficha)
	_aviso.text = _texto_aviso(ficha)
	_leva.text = "Leva: %s" % _pacote.texto_itens() if _pacote else ""
	_proficiencias.text = "Proficiência: %s · %s" % [Proficiencias.texto_armas(_classe.proficiencias_armas),
		Proficiencias.texto_armaduras(_classe.treinamento_armaduras)]
	_montar_builds()
	_contagem_maestrias.text = "Domine %d tipos de arma (%d/%d marcadas). Só com elas a maestria vale." % [
		_classe.quantidade_maestrias, armas_marcadas().size(), _classe.quantidade_maestrias]
	var falta := _falta_algo()
	_botao_comecar.disabled = falta != ""
	_botao_comecar.text = "Começar" if falta == "" else falta


## "Vida 12 · CA 16 · 30 pés · Dano 2d6+2".
func _texto_previa(ficha: Ficha) -> String:
	var armadura := _pacote.armadura() if _pacote else null
	var arma := _pacote.arma() if _pacote and _pacote.arma() else arma_previa
	return "Nível %d · Vida %d · CA %d · %d pés · Dano %s" % [ficha.nivel, ficha.vida_maxima(), ficha.classe_armadura(armadura),
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
