class_name TelaEstilo
extends Control
## Troca/preparação de Estilos de Luta ao subir de nível: marca até a capacidade da ficha
## e confirma. Pausa o jogo. A `main` abre quando há pendência.

signal estilos_confirmados(ids: Array[StringName])
signal fechou

const TEXTO_VAZIO := "Nenhum estilo disponível."

var _ficha: Ficha
var _opcoes: Array[EstiloDeLutaRPG] = []

@onready var _contagem: Label = %Contagem
@onready var _lista: ItemList = %Lista
@onready var _nome: Label = %Nome
@onready var _fonte: Label = %Fonte
@onready var _texto: Label = %Texto
@onready var _botao_confirmar: Button = %Confirmar
@onready var _botao_fechar: Button = %Fechar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_lista.item_selected.connect(_mostrar_pagina)
	_lista.multi_selected.connect(func(_i: int, _s: bool) -> void: _atualizar_estado())
	_botao_confirmar.pressed.connect(confirmar)
	_botao_fechar.pressed.connect(fechar)


func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento.is_action_pressed(&"ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()


func abrir(ficha: Ficha, todos: Array[EstiloDeLutaRPG]) -> void:
	_ficha = ficha
	_opcoes = todos.filter(func(e: EstiloDeLutaRPG) -> bool: return e.no_jogo)
	_lista.clear()
	for estilo in _opcoes:
		var i := _lista.add_item(estilo.nome)
		if estilo.id in ficha.estilos:
			_lista.select(i, false)
	_atualizar_contagem()
	show()
	if _opcoes.is_empty():
		_mostrar_vazio()
	else:
		var sel := _lista.get_selected_items()
		_mostrar_pagina(sel[0] if not sel.is_empty() else 0)
	_lista.grab_focus()
	get_tree().paused = true


func fechar() -> void:
	hide()
	get_tree().paused = false
	fechou.emit()


func confirmar() -> bool:
	var ids := _ids_marcados()
	if not _ficha.confirmar_troca_de_estilo(ids):
		return false
	estilos_confirmados.emit(ids)
	fechar()
	return true


func _ids_marcados() -> Array[StringName]:
	var ids: Array[StringName] = []
	for i in _lista.get_selected_items():
		ids.append(_opcoes[i].id)
	return ids


func _mostrar_vazio() -> void:
	_nome.text = ""
	_fonte.text = ""
	_texto.text = TEXTO_VAZIO
	_botao_confirmar.disabled = true


func _mostrar_pagina(indice: int) -> void:
	if indice < 0 or indice >= _opcoes.size():
		_mostrar_vazio()
		return
	var estilo := _opcoes[indice]
	_nome.text = estilo.nome
	_fonte.text = estilo.fonte
	_texto.text = estilo.descricao
	_atualizar_estado()


func _atualizar_estado() -> void:
	_atualizar_contagem()
	var n := _lista.get_selected_items().size()
	_botao_confirmar.disabled = n < 1 or n > _ficha.capacidade_estilos() or not _ficha.escolha_de_estilo_pendente()


func _atualizar_contagem() -> void:
	_contagem.text = "Prepare até %d estilo(s) (%d marcados)." % [
		_ficha.capacidade_estilos(), _lista.get_selected_items().size()]
