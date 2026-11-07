class_name TelaBau
extends Control
## Tela do baú do arsenal: filtra armas ou armaduras e "Pegar" põe uma CÓPIA na mochila
## (o baú nunca esvazia). Pausa o jogo. Quem monta o jogo chama abrir().

const AVISO_CHEIA := "Mochila cheia! Jogue algo fora (I)."
const AVISO_PEGOU := "Pegou: %s"
const FILTRO_TUDO := 0
const FILTRO_ARMAS := 1
const FILTRO_ARMADURAS := 2

## Emitido ao fechar a tela para quem controla a interface de toque.
signal fechou

var _itens: Array[Item] = []
var _visiveis: Array[Item] = []
var _inventario: Inventario
var _filtro: int = FILTRO_TUDO

@onready var _lista: ItemList = %Lista
@onready var _nome: Label = %Nome
@onready var _regras: Label = %Regras
@onready var _aviso: Label = %Aviso
@onready var _mochila: Label = %Mochila
@onready var _botao_pegar: Button = %Pegar
@onready var _botao_fechar: Button = %Fechar
@onready var _botao_tudo: Button = %FiltroTudo
@onready var _botao_armas: Button = %FiltroArmas
@onready var _botao_armaduras: Button = %FiltroArmaduras


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	hide()
	_lista.item_selected.connect(func(_i: int) -> void: _atualizar_detalhes())
	_lista.item_activated.connect(func(_i: int) -> void: pegar_selecionado())
	_botao_pegar.pressed.connect(pegar_selecionado)
	_botao_fechar.pressed.connect(fechar)
	_botao_tudo.pressed.connect(_escolher_filtro.bind(FILTRO_TUDO))
	_botao_armas.pressed.connect(_escolher_filtro.bind(FILTRO_ARMAS))
	_botao_armaduras.pressed.connect(_escolher_filtro.bind(FILTRO_ARMADURAS))


func _unhandled_input(evento: InputEvent) -> void:
	if visible and (evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("interagir")):
		fechar()
		get_viewport().set_input_as_handled()


## Abre mostrando os `itens` do baú; "Pegar" adiciona cópias no `inventario`.
func abrir(itens: Array[Item], inventario: Inventario) -> void:
	_itens = itens
	_inventario = inventario
	_aviso.text = ""
	_escolher_filtro(FILTRO_TUDO)
	show()
	_lista.grab_focus()
	get_tree().paused = true


func fechar() -> void:
	hide()
	get_tree().paused = false
	fechou.emit()


## Põe uma cópia do item selecionado na mochila. Devolve false se não deu (mochila cheia).
func pegar_selecionado() -> bool:
	var item := _item_selecionado()
	if item == null:
		return false
	var pegou := _inventario.adicionar(item.duplicate())
	_aviso.text = AVISO_PEGOU % item.nome if pegou else AVISO_CHEIA
	_atualizar_detalhes()
	return pegou


func _escolher_filtro(filtro: int) -> void:
	_filtro = filtro
	_botao_tudo.disabled = filtro == FILTRO_TUDO
	_botao_armas.disabled = filtro == FILTRO_ARMAS
	_botao_armaduras.disabled = filtro == FILTRO_ARMADURAS
	_preencher_lista()


func _preencher_lista() -> void:
	_visiveis.clear()
	for item in _itens:
		if _passa_filtro(item):
			_visiveis.append(item)
	_lista.clear()
	for item in _visiveis:
		_lista.add_item(item.nome, item.icone)
	if _lista.item_count > 0:
		_lista.select(0)
	_atualizar_detalhes()


func _passa_filtro(item: Item) -> bool:
	if _filtro == FILTRO_ARMAS:
		return item is Arma or item is Municao
	if _filtro == FILTRO_ARMADURAS:
		return item is Armadura
	return true


func _item_selecionado() -> Item:
	var selecionados := _lista.get_selected_items()
	return _visiveis[selecionados[0]] if not selecionados.is_empty() else null


func _atualizar_detalhes() -> void:
	var item := _item_selecionado()
	_nome.text = item.nome if item else "(nada neste filtro)"
	_regras.text = ResumoItem.texto(item)
	_botao_pegar.disabled = item == null
	if _inventario:
		_mochila.text = "Mochila %d/%d" % [_inventario.itens.size(), _inventario.capacidade]
