class_name TelaSubclasse
extends Control
## Escolha da subclasse no nível 3: lista à esquerda e texto à direita. Pausa o jogo.
## Guarda a escolha na ficha e avisa pela `main` pelo sinal. Não conhece o herói além da ficha.

## A ficha já tem a subclasse.
signal subclasse_escolhida(subclasse: SubclasseRPG)
## Emitido ao fechar a tela, para quem controla a interface de toque.
signal fechou

const TEXTO_VAZIO := "Nenhuma subclasse disponível agora."

var _ficha: Ficha
var _opcoes: Array[SubclasseRPG] = []

@onready var _lista: ItemList = %Lista
@onready var _nome: Label = %Nome
@onready var _texto: Label = %Texto
@onready var _botao_escolher: Button = %Escolher
@onready var _botao_fechar: Button = %Fechar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_lista.item_selected.connect(_mostrar_pagina)
	_botao_escolher.pressed.connect(escolher)
	_botao_fechar.pressed.connect(fechar)


func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento.is_action_pressed(&"ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()


## Abre com as subclasses que a ficha pode escolher agora.
func abrir(ficha: Ficha, todas: Array[SubclasseRPG]) -> void:
	_ficha = ficha
	_opcoes.clear()
	for candidata in todas:
		if candidata.escolhivel_para(ficha):
			_opcoes.append(candidata)
	_lista.clear()
	for candidata in _opcoes:
		_lista.add_item(candidata.nome)
	show()
	if _opcoes.is_empty():
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


## Confirma a subclasse mostrada. false se a ficha não aceita.
func escolher() -> bool:
	var candidata := _atual()
	if candidata == null or not _ficha.escolher_subclasse(candidata):
		return false
	subclasse_escolhida.emit(candidata)
	fechar()
	return true


func _atual() -> SubclasseRPG:
	var indices := _lista.get_selected_items()
	if indices.is_empty() or indices[0] >= _opcoes.size():
		return null
	return _opcoes[indices[0]]


func _mostrar_vazio() -> void:
	_nome.text = ""
	_texto.text = TEXTO_VAZIO
	_botao_escolher.disabled = true


func _mostrar_pagina(indice: int) -> void:
	if indice < 0 or indice >= _opcoes.size():
		_mostrar_vazio()
		return
	var candidata := _opcoes[indice]
	_nome.text = candidata.nome
	_texto.text = candidata.descricao
	_botao_escolher.disabled = not _ficha.escolha_de_subclasse_pendente()
