class_name TelaBau
extends Control
## Tela do baú do arsenal: lista o que há no baú e "Pegar" põe uma CÓPIA na mochila (o baú
## nunca esvazia). Pausa o jogo enquanto está aberta. Não conhece o herói nem o baú: quem
## monta o jogo chama abrir() com os itens e o inventário.

const AVISO_CHEIA := "Mochila cheia! Jogue algo fora (I)."
const AVISO_PEGOU := "Pegou: %s"

var _itens: Array[Item] = []
var _inventario: Inventario

@onready var _lista: ItemList = %Lista
@onready var _nome: Label = %Nome
@onready var _descricao: Label = %Descricao
@onready var _regras: Label = %Regras
@onready var _aviso: Label = %Aviso
@onready var _mochila: Label = %Mochila
@onready var _botao_pegar: Button = %Pegar
@onready var _botao_fechar: Button = %Fechar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	hide()
	_lista.item_selected.connect(func(_i: int) -> void: _atualizar_detalhes())
	_lista.item_activated.connect(func(_i: int) -> void: pegar_selecionado())
	_botao_pegar.pressed.connect(pegar_selecionado)
	_botao_fechar.pressed.connect(fechar)


func _unhandled_input(evento: InputEvent) -> void:
	if visible and (evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("interagir")):
		fechar()
		get_viewport().set_input_as_handled()


## Abre mostrando os `itens` do baú; "Pegar" adiciona cópias no `inventario`.
func abrir(itens: Array[Item], inventario: Inventario) -> void:
	_itens = itens
	_inventario = inventario
	_lista.clear()
	for item in _itens:
		_lista.add_item(item.nome, item.icone)
	_aviso.text = ""
	if _lista.item_count > 0:
		_lista.select(0)
	_atualizar_detalhes()
	show()
	_lista.grab_focus()
	get_tree().paused = true


func fechar() -> void:
	hide()
	get_tree().paused = false


## Põe uma cópia do item selecionado na mochila. Devolve false se não deu (mochila cheia).
func pegar_selecionado() -> bool:
	var item := _item_selecionado()
	if item == null:
		return false
	var pegou := _inventario.adicionar(item.duplicate())
	_aviso.text = AVISO_PEGOU % item.nome if pegou else AVISO_CHEIA
	_atualizar_detalhes()
	return pegou


func _item_selecionado() -> Item:
	var selecionados := _lista.get_selected_items()
	return _itens[selecionados[0]] if not selecionados.is_empty() else null


func _atualizar_detalhes() -> void:
	var item := _item_selecionado()
	_nome.text = item.nome if item else "(baú vazio)"
	_descricao.text = item.descricao if item else ""
	_regras.text = _texto_regras(item)
	_botao_pegar.disabled = item == null
	if _inventario:
		_mochila.text = "Mochila: %d/%d" % [_inventario.itens.size(), _inventario.capacidade]


## "Dano 1d8 cortante · 3 lb. · 15 GP" ou "CA 16 · 55 lb. · 75 GP".
func _texto_regras(item: Item) -> String:
	if item is Arma:
		var arma := item as Arma
		return "Dano %s %s · %s · %s" % [arma.dados_dano, TiposDano.nome(arma.tipo_dano), arma.peso, arma.preco]
	if item is Armadura:
		var armadura := item as Armadura
		return "%s · %s · %s" % [armadura.texto_ca(), armadura.peso, armadura.preco]
	return ""
