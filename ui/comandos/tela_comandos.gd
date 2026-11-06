class_name TelaComandos
extends Control
## Tela de comandos (tecla C): mostra o que cada botão faz e deixa trocar a tecla.
## Na mesma tela, traz ou tira uma criatura da arena. Pausa o jogo. Não conhece o herói:
## quem monta o jogo responde a `abrir_pedido` e a `trazer_pedido`.

## Emitido quando o jogador aperta C com a tela fechada.
signal abrir_pedido
## Emitido ao escolher Trazer, com a cena da criatura marcada.
signal trazer_pedido(cena: PackedScene)
## Emitido ao escolher Tirar da arena.
signal tirar_pedido

const TAMANHO_FONTE_LINHA := 12

var _acao_escolhida: StringName = &""
var _cenas: Array[PackedScene] = []
var _botoes: Dictionary[StringName, Button] = {}

@onready var _lista_acoes: VBoxContainer = %ListaAcoes
@onready var _lista_criaturas: ItemList = %ListaCriaturas
@onready var _trazer: Button = %Trazer
@onready var _tirar: Button = %Tirar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	for acao in Comandos.ACOES:
		var botao := Button.new()
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.add_theme_font_size_override(&"font_size", TAMANHO_FONTE_LINHA)
		botao.pressed.connect(_escolher_acao.bind(acao))
		_botoes[acao] = botao
		_lista_acoes.add_child(botao)
	_trazer.pressed.connect(_pedir_trazer)
	_tirar.pressed.connect(tirar_pedido.emit)
	set_process_input(false)
	_atualizar_rotulos()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed(&"comandos"):
		if visible:
			fechar()
		else:
			abrir_pedido.emit()
		get_viewport().set_input_as_handled()
	elif visible and evento.is_action_pressed(&"ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()


## Enquanto uma ação está escolhida, a próxima tecla vira o atalho dela (Esc cancela).
func _input(evento: InputEvent) -> void:
	if not visible or _acao_escolhida == &"" or not _capturar_tecla(evento):
		return
	get_viewport().set_input_as_handled()


## Lista do combate. `cenas` acompanha `nomes`, na mesma ordem.
func definir_criaturas(nomes: PackedStringArray, cenas: Array[PackedScene]) -> void:
	_cenas = cenas
	_lista_criaturas.clear()
	for nome in nomes:
		_lista_criaturas.add_item(nome)
	if _lista_criaturas.item_count > 0:
		_lista_criaturas.select(0)


func abrir() -> void:
	_acao_escolhida = &""
	_atualizar_rotulos()
	show()
	get_tree().paused = true


func fechar() -> void:
	_acao_escolhida = &""
	set_process_input(false)
	hide()
	get_tree().paused = false


func _escolher_acao(acao: StringName) -> void:
	_acao_escolhida = acao
	set_process_input(true)
	_atualizar_rotulos()


func _capturar_tecla(evento: InputEvent) -> bool:
	if not (evento is InputEventKey):
		return false
	var tecla := evento as InputEventKey
	if not tecla.pressed or tecla.echo:
		return false
	if tecla.physical_keycode != KEY_ESCAPE:
		Comandos.aplicar_tecla(_acao_escolhida, tecla.physical_keycode)
		Comandos.salvar()
	_acao_escolhida = &""
	set_process_input(false)
	_atualizar_rotulos()
	return true


func _pedir_trazer() -> void:
	var marcados := _lista_criaturas.get_selected_items()
	if marcados.is_empty():
		return
	trazer_pedido.emit(_cenas[marcados[0]])


func _atualizar_rotulos() -> void:
	for acao in _botoes:
		var botao: Button = _botoes[acao]
		var espera := " ..." if acao == _acao_escolhida else ""
		botao.text = "%s: %s%s" % [Comandos.nome(acao), Comandos.tecla_de(acao), espera]
