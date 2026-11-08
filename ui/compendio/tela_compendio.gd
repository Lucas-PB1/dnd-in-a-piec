class_name TelaCompendio
extends Control
## Compêndio: uma aba por assunto disponível para o jogador. Lista à esquerda, página à direita.
## Pausa o jogo. Não conhece o herói nem as regras: a `main` entrega as abas já montadas.

## Emitido ao fechar a tela, para quem controla a interface de toque.
signal fechou

const TEXTO_VAZIO := "Nada disponível aqui ainda."

## Nome da aba -> páginas (EntradaCompendio), na ordem das abas.
var _secoes: Dictionary[String, Array] = {}
var _paginas: Array = []

@onready var _abas: TabBar = %Abas
@onready var _lista: ItemList = %Lista
@onready var _nome: Label = %Nome
@onready var _tipo: Label = %Tipo
@onready var _texto: Label = %Texto
@onready var _contagem: Label = %Contagem
@onready var _botao_fechar: Button = %Fechar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	hide()
	_abas.tab_changed.connect(_mostrar_aba)
	_lista.item_selected.connect(_mostrar_pagina)
	_botao_fechar.pressed.connect(fechar)


func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento.is_action_pressed(&"ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()


## Abre na primeira aba. `secoes` vem de `Compendio.montar()`.
func abrir(secoes: Dictionary[String, Array]) -> void:
	_secoes = secoes
	_abas.clear_tabs()
	for nome in _secoes:
		_abas.add_tab(nome)
	_abas.current_tab = 0
	_mostrar_aba(0)
	show()
	_abas.grab_focus()
	get_tree().paused = true


func fechar() -> void:
	hide()
	get_tree().paused = false
	fechou.emit()


func _mostrar_aba(aba: int) -> void:
	if aba < 0 or aba >= _secoes.size():
		return
	_paginas = _secoes[_secoes.keys()[aba]]
	_lista.clear()
	for pagina: EntradaCompendio in _paginas:
		_lista.add_item(pagina.nome)
	_contagem.text = "%d no total" % _paginas.size()
	if _paginas.is_empty():
		_nome.text = ""
		_tipo.text = ""
		_texto.text = TEXTO_VAZIO
		return
	_lista.select(0)
	_mostrar_pagina(0)


func _mostrar_pagina(indice: int) -> void:
	var pagina: EntradaCompendio = _paginas[indice]
	_nome.text = pagina.nome
	_tipo.text = pagina.tipo
	_texto.text = pagina.texto
