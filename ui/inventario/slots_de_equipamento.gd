class_name SlotsDeEquipamento
extends VBoxContainer
## Os slots do que o herói leva equipado: Mão principal, Mão secundária e Corpo, cada um com selo colorido, ícone e
## nome do item. Clicar num slot com item avisa (`slot_escolhido`) para a tela mostrar e poder desequipar.
## Não conhece o herói: recebe o Inventario e o nome do que vale como mão vazia.

## O jogador clicou no slot deste item (a tela seleciona o item na mochila).
signal slot_escolhido(item: Item)

const ESPACOS: Array[StringName] = [Item.ESPACO_MAO, Item.ESPACO_MAO_SECUNDARIA, Item.ESPACO_CORPO]
const ROTULOS := {Item.ESPACO_MAO: "Mão principal", Item.ESPACO_MAO_SECUNDARIA: "Mão secundária", Item.ESPACO_CORPO: "Corpo"}
const TAMANHO_ICONE := Vector2(24, 24)
const ALTURA_MINIMA := 50.0
const TEXTO_VAZIO := "(vazio)"
const TEXTO_DUAS_MAOS := "duas mãos"

var _cartoes: Dictionary[StringName, PanelContainer] = {}
var _itens: Dictionary[StringName, Item] = {}


func _ready() -> void:
	add_theme_constant_override(&"separation", 4)
	for espaco in ESPACOS:
		var cartao := _criar_cartao(espaco)
		_cartoes[espaco] = cartao
		add_child(cartao)


## Mostra o que está em cada slot. `mao_vazia` = o nome do soco (Desarmado) quando não há arma na mão principal.
func mostrar(inventario: Inventario, mao_vazia: String) -> void:
	for espaco in ESPACOS:
		var item := inventario.equipado(espaco)
		_itens[espaco] = item
		var duas_maos := espaco == Item.ESPACO_MAO_SECUNDARIA and item != null and item == inventario.equipado(Item.ESPACO_MAO)
		_preencher(_cartoes[espaco], espaco, item, mao_vazia, duas_maos)


func _criar_cartao(espaco: StringName) -> PanelContainer:
	var cartao := PanelContainer.new()
	cartao.name = "Slot_%s" % espaco
	cartao.custom_minimum_size = Vector2(0, ALTURA_MINIMA)
	cartao.gui_input.connect(_ao_clicar.bind(espaco))
	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override(&"separation", 1)
	cartao.add_child(coluna)
	coluna.add_child(_rotulo("Rotulo", 10))
	var linha := HBoxContainer.new()
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_theme_constant_override(&"separation", 4)
	coluna.add_child(linha)
	var icone := TextureRect.new()
	icone.name = "Icone"
	icone.custom_minimum_size = TAMANHO_ICONE
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_child(icone)
	var nome := _rotulo("Nome", 12)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	linha.add_child(nome)
	return cartao


func _rotulo(nome: String, tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.name = nome
	rotulo.add_theme_font_size_override(&"font_size", tamanho)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rotulo


func _preencher(cartao: PanelContainer, espaco: StringName, item: Item, mao_vazia: String, duas_maos: bool) -> void:
	var cor := EstiloCartao.cor_do_espaco(espaco)
	var cabecalho := cartao.find_child("Rotulo", true, false) as Label
	cabecalho.text = "[%s] %s" % [EstiloCartao.selo_do_espaco(espaco), ROTULOS[espaco]]
	cabecalho.add_theme_color_override(&"font_color", cor)
	cartao.add_theme_stylebox_override(&"panel", EstiloCartao.cartao(cor if item != null else EstiloCartao.BORDA))
	var icone := cartao.find_child("Icone", true, false) as TextureRect
	var nome := cartao.find_child("Nome", true, false) as Label
	icone.texture = item.icone if item != null else null
	icone.modulate = Color(1, 1, 1, 0.55) if duas_maos else Color.WHITE
	nome.text = _texto_do_nome(espaco, item, mao_vazia, duas_maos)
	nome.add_theme_color_override(&"font_color", Color.WHITE if item != null else EstiloCartao.TEXTO_FRACO)
	cartao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if item != null else Control.CURSOR_ARROW


func _texto_do_nome(espaco: StringName, item: Item, mao_vazia: String, duas_maos: bool) -> String:
	if duas_maos:
		return "%s (%s)" % [item.nome, TEXTO_DUAS_MAOS]
	if item != null:
		return item.nome
	return mao_vazia if espaco == Item.ESPACO_MAO else TEXTO_VAZIO


func _ao_clicar(evento: InputEvent, espaco: StringName) -> void:
	var clicou := evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed and (evento as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	var item: Item = _itens.get(espaco)
	if clicou and item != null:
		slot_escolhido.emit(item)
