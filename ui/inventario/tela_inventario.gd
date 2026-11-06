class_name TelaInventario
extends Control
## Tela de inventário (tecla I): lista de itens, detalhes, Equipar / Desequipar / Jogar fora,
## e a ficha do personagem. Pausa o jogo enquanto está aberta. Não conhece o herói:
## quem monta o jogo responde a `abrir_pedido` chamando abrir() com os dados.

## Emitido quando o jogador aperta I com a tela fechada.
signal abrir_pedido

const MARCA_EQUIPADO := "[E] "

var _inventario: Inventario
var _ficha: Ficha
var _desarmado: Arma
var _texto_vida: String = ""

@onready var _titulo: Label = %Titulo
@onready var _lista: ItemList = %Lista
@onready var _nome: Label = %Nome
@onready var _descricao: Label = %Descricao
@onready var _dano_item: Label = %DanoItem
@onready var _botao_equipar: Button = %Equipar
@onready var _botao_desequipar: Button = %Desequipar
@onready var _botao_jogar_fora: Button = %JogarFora
@onready var _texto_ficha: Label = %TextoFicha
@onready var _confirmacao: ConfirmationDialog = %Confirmacao


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	hide()
	_lista.item_selected.connect(func(_i: int) -> void: _atualizar_detalhes())
	_botao_equipar.pressed.connect(equipar_selecionado)
	_botao_desequipar.pressed.connect(desequipar_selecionado)
	_botao_jogar_fora.pressed.connect(_perguntar_jogar_fora)
	_confirmacao.confirmed.connect(jogar_fora_selecionado)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("inventario"):
		if visible:
			fechar()
		else:
			abrir_pedido.emit()
		get_viewport().set_input_as_handled()
	elif visible and evento.is_action_pressed("ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()


## Abre a tela mostrando o `inventario` e a ficha. `desarmado` = o que conta como arma
## quando a mão está vazia.
func abrir(inventario: Inventario, ficha: Ficha, vida_atual: int, vida_maxima: int, desarmado: Arma) -> void:
	_inventario = inventario
	_ficha = ficha
	_desarmado = desarmado
	_texto_vida = "PV %d/%d" % [vida_atual, vida_maxima]
	_inventario.mudou.connect(_atualizar)
	_atualizar()
	if _lista.item_count > 0:
		_lista.select(0)
		_atualizar_detalhes()
	show()
	_lista.grab_focus()
	get_tree().paused = true


func fechar() -> void:
	if _inventario and _inventario.mudou.is_connected(_atualizar):
		_inventario.mudou.disconnect(_atualizar)
	hide()
	get_tree().paused = false


func equipar_selecionado() -> void:
	var item := _item_selecionado()
	if item:
		_inventario.equipar(item)


func desequipar_selecionado() -> void:
	var item := _item_selecionado()
	if item and _inventario.esta_equipado(item):
		_inventario.desequipar(item.espaco)


## Joga fora sem perguntar (a pergunta fica no botão; os testes chamam direto).
func jogar_fora_selecionado() -> void:
	var item := _item_selecionado()
	if item:
		_inventario.descartar(item)


func _perguntar_jogar_fora() -> void:
	var item := _item_selecionado()
	if item:
		_confirmacao.dialog_text = "Jogar fora: %s?\nO item some para sempre." % item.nome
		_confirmacao.popup_centered()


func _item_selecionado() -> Item:
	var selecionados := _lista.get_selected_items()
	if _inventario == null or selecionados.is_empty():
		return null
	return _inventario.itens[selecionados[0]]


func _atualizar() -> void:
	var anterior := _lista.get_selected_items()
	_lista.clear()
	for item in _inventario.itens:
		var marca := MARCA_EQUIPADO if _inventario.esta_equipado(item) else ""
		_lista.add_item(marca + item.nome, item.icone)
	if not anterior.is_empty() and _lista.item_count > 0:
		_lista.select(mini(anterior[0], _lista.item_count - 1))
	_titulo.text = "Inventário (%d/%d)" % [_inventario.itens.size(), _inventario.capacidade]
	_atualizar_detalhes()
	_atualizar_ficha()


func _atualizar_detalhes() -> void:
	var item := _item_selecionado()
	_nome.text = item.nome if item else "(nenhum item)"
	_descricao.text = item.descricao if item else ""
	var arma := item as Arma
	_dano_item.text = "Dano: %s" % _ficha.texto_dano(arma) if arma and _ficha else ""
	var equipado := _inventario != null and _inventario.esta_equipado(item)
	_botao_equipar.disabled = item == null or not item.equipavel() or equipado
	_botao_desequipar.disabled = not equipado
	_botao_jogar_fora.disabled = item == null


func _atualizar_ficha() -> void:
	var linhas: PackedStringArray = ["%s, %s" % [_ficha.nome, _ficha.classe.nome]]
	for atributo in Atributos.TODOS:
		var valor: int = _ficha.atributos[atributo]
		linhas.append("%s %d (%s)" % [Atributos.SIGLAS[atributo], valor, Atributos.texto_modificador(valor)])
	linhas.append("")
	linhas.append(_texto_vida)
	var na_mao := _inventario.equipado(Item.ESPACO_MAO) as Arma
	var arma := na_mao if na_mao else _desarmado
	linhas.append("Mão: %s" % arma.nome)
	linhas.append("Dano: %s" % _ficha.texto_dano(arma))
	_texto_ficha.text = "\n".join(linhas)
