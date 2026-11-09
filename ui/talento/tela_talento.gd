class_name TelaTalento
extends Control
## Escolha do talento do nível 4: lista dos talentos que o herói pode pegar à esquerda e, à direita,
## o texto, os atributos que ele aumenta e o botão Escolher. Pausa o jogo. A tela guarda a escolha
## na ficha (regra pura) e avisa pelo sinal; quem cuida da vida e do HUD é a `main`.

## O jogador escolheu: a ficha já tem o talento e os aumentos.
signal talento_escolhido(talento: TalentoRPG)
## Emitido ao fechar a tela, para quem controla a interface de toque.
signal fechou

const TEXTO_VAZIO := "Nenhum talento disponível agora."
const TEXTO_SEM_ATRIBUTO := "Este talento não aumenta atributo."

var _ficha: Ficha
var _talentos: Array[TalentoRPG] = []
var _aumentos: Array[StringName] = []

@onready var _lista: ItemList = %Lista
@onready var _nome: Label = %Nome
@onready var _tipo: Label = %Tipo
@onready var _texto: Label = %Texto
@onready var _atributos: HFlowContainer = %Atributos
@onready var _aviso_atributos: Label = %AvisoAtributos
@onready var _linha_pericia_1: Control = %LinhaPericia1
@onready var _linha_pericia_2: Control = %LinhaPericia2
@onready var _rotulo_pericia_1: Label = %RotuloPericia1
@onready var _rotulo_pericia_2: Label = %RotuloPericia2
@onready var _pericia_1: OptionButton = %Pericia1
@onready var _pericia_2: OptionButton = %Pericia2
@onready var _botao_escolher: Button = %Escolher
@onready var _botao_limpar: Button = %Limpar
@onready var _botao_fechar: Button = %Fechar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	hide()
	_lista.item_selected.connect(_mostrar_pagina)
	_botao_escolher.pressed.connect(escolher)
	_botao_limpar.pressed.connect(_limpar_aumentos)
	_pericia_1.item_selected.connect(_ao_mudar_pericia_1)
	_pericia_2.item_selected.connect(func(_i: int) -> void: _atualizar_estado())
	_botao_fechar.pressed.connect(fechar)


func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento.is_action_pressed(&"ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()


## Abre com os talentos que o herói pode escolher agora (os gerais já liberados).
func abrir(ficha: Ficha, todos: Array[TalentoRPG]) -> void:
	_ficha = ficha
	_talentos = todos.filter(func(t: TalentoRPG) -> bool: return t.escolhivel())
	_lista.clear()
	for talento in _talentos:
		_lista.add_item(talento.nome)
	show()
	if _talentos.is_empty():
		_mostrar_vazio()
	else:
		_lista.select(0)
		_mostrar_pagina(0)
	_lista.grab_focus()
	get_tree().paused = true


func fechar() -> void:
	hide()
	get_tree().paused = false
	fechou.emit()


## Confirma o talento mostrado com os aumentos marcados. false se a ficha não aceita.
func escolher() -> bool:
	var talento := _talento_atual()
	if talento == null or not _ficha.escolher_talento(talento, _aumentos, _pericias_escolhidas()):
		return false
	talento_escolhido.emit(talento)
	fechar()
	return true


func _talento_atual() -> TalentoRPG:
	var escolhidos := _lista.get_selected_items()
	if escolhidos.is_empty():
		return null
	return _talentos[escolhidos[0]]


func _mostrar_vazio() -> void:
	_nome.text = ""
	_tipo.text = ""
	_texto.text = TEXTO_VAZIO
	_aumentos.clear()
	_montar_botoes_de_atributo(null)
	_montar_pericias(null)
	_atualizar_estado()


func _mostrar_pagina(indice: int) -> void:
	var talento := _talentos[indice]
	_nome.text = talento.nome
	_tipo.text = TalentoRPG.nome_da_categoria(talento.categoria)
	_texto.text = talento.resumo
	_aumentos.clear()
	_montar_botoes_de_atributo(talento)
	_montar_pericias(talento)
	_atualizar_estado()


## Um botão por atributo que o talento permite; cada clique soma um ponto.
func _montar_botoes_de_atributo(talento: TalentoRPG) -> void:
	for botao in _atributos.get_children():
		botao.queue_free()
	if talento == null:
		return
	for atributo in talento.atributos:
		var botao := Button.new()
		botao.text = "%s %d" % [Atributos.SIGLAS[atributo], _ficha.atributos[atributo]]
		botao.custom_minimum_size = Vector2(64, 28)
		botao.disabled = talento.pontos_de_atributo == 1 and not _ficha.atributo_serve_ao_talento(talento, atributo)
		botao.pressed.connect(_somar_aumento.bind(atributo))
		_atributos.add_child(botao)


## Observador e Especialista em Perícia escolhem perícia: mostra os seletores certos.
func _montar_pericias(talento: TalentoRPG) -> void:
	_linha_pericia_1.visible = false
	_linha_pericia_2.visible = false
	if talento == null:
		return
	match talento.id:
		Ficha.TALENTO_OBSERVADOR:
			_rotulo_pericia_1.text = "Perícia"
			_preencher_pericias(_pericia_1, Ficha.PERICIAS_DO_OBSERVADOR, true)
			_linha_pericia_1.visible = true
		Ficha.TALENTO_ESPECIALISTA_EM_PERICIA:
			_rotulo_pericia_1.text = "Nova perícia"
			_rotulo_pericia_2.text = "Especialização"
			var novas: Array[StringName] = []
			for id: StringName in Pericia.ATRIBUTO:
				if not _ficha.proficiente_na_pericia(id):
					novas.append(id)
			_preencher_pericias(_pericia_1, novas, false)
			_linha_pericia_1.visible = true
			_linha_pericia_2.visible = true
			_ao_mudar_pericia_1(0)


## Põe as perícias no seletor. `marcar` mostra "(Especialização)" nas que o herói já treina.
func _preencher_pericias(seletor: OptionButton, ids: Array[StringName], marcar: bool) -> void:
	seletor.clear()
	for id in ids:
		var texto := Pericia.nome_de(id)
		if marcar and _ficha.proficiente_na_pericia(id):
			texto += " (Especialização)"
		seletor.add_item(texto)
		seletor.set_item_metadata(seletor.item_count - 1, id)
	if seletor.item_count > 0:
		seletor.select(0)


## A perícia nova mudou: a Especialização pode cair nela ou em qualquer perícia já treinada.
func _ao_mudar_pericia_1(_indice: int) -> void:
	if _linha_pericia_2.visible:
		var treinadas: Array[StringName] = []
		if _pericia_1.item_count > 0:
			treinadas.append(_pericia_1.get_item_metadata(_pericia_1.selected))
		for id in _ficha.pericias:
			if id not in _ficha.pericias_especializadas:
				treinadas.append(id)
		_preencher_pericias(_pericia_2, treinadas, false)
	_atualizar_estado()


## As perícias marcadas nos seletores que estão à mostra.
func _pericias_escolhidas() -> Array[StringName]:
	var escolhidas: Array[StringName] = []
	for linha in [[_linha_pericia_1, _pericia_1], [_linha_pericia_2, _pericia_2]]:
		var seletor: OptionButton = linha[1]
		if (linha[0] as Control).visible and seletor.item_count > 0:
			escolhidas.append(seletor.get_item_metadata(seletor.selected))
	return escolhidas

func _somar_aumento(atributo: StringName) -> void:
	var talento := _talento_atual()
	if talento == null or _aumentos.size() >= talento.pontos_de_atributo:
		return
	_aumentos.append(atributo)
	_atualizar_estado()


func _limpar_aumentos() -> void:
	_aumentos.clear()
	_atualizar_estado()


func _atualizar_estado() -> void:
	var talento := _talento_atual()
	_botao_escolher.disabled = talento == null or not _ficha.pode_escolher_talento(talento, _aumentos, _pericias_escolhidas())
	_botao_limpar.disabled = _aumentos.is_empty()
	if talento == null:
		_aviso_atributos.text = ""
	elif talento.pontos_de_atributo == 0:
		_aviso_atributos.text = TEXTO_SEM_ATRIBUTO
	else:
		_aviso_atributos.text = _texto_dos_aumentos(talento)


func _texto_dos_aumentos(talento: TalentoRPG) -> String:
	var marcados: Array[String] = []
	for atributo in _aumentos:
		marcados.append("+1 " + Atributos.NOMES[atributo])
	var faltam := talento.pontos_de_atributo - _aumentos.size()
	var resumo := ", ".join(marcados) if not marcados.is_empty() else "nenhum"
	return "Aumento: %s (faltam %d)" % [resumo, faltam]
