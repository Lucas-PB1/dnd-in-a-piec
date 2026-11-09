class_name TelaInventario
extends Control
## Tela de inventário (tecla I): lista à esquerda e, à direita, o item ou a ficha.
## Pausa o jogo enquanto está aberta. Não conhece o herói: quem monta o jogo
## responde a `abrir_pedido` chamando abrir().

## Emitido quando o jogador aperta I com a tela fechada.
signal abrir_pedido
## Emitido ao fechar a tela para quem controla a interface de toque.
signal fechou

const FAIXA_DO_EQUIPADO := 0.35

var _inventario: Inventario
var _ficha: Ficha
var _desarmado: Arma
var _vida_atual: int = 0
var _vida_maxima: int = 0

@onready var _titulo: Label = %Titulo
@onready var _lista: ItemList = %Lista
@onready var _nome: Label = %Nome
@onready var _dano_item: Label = %DanoItem
@onready var _botao_equipar: Button = %Equipar
@onready var _botao_jogar_fora: Button = %JogarFora
@onready var _painel_item: Control = %PainelItem
@onready var _painel_ficha: Control = %PainelFicha
@onready var _aba_item: Button = %AbaItem
@onready var _aba_ficha: Button = %AbaFicha
@onready var _botao_fechar: Button = %Fechar
@onready var _slots: SlotsDeEquipamento = %Slots
@onready var _ficha_visual: FichaVisual = %FichaVisual
@onready var _confirmacao: ConfirmationDialog = %Confirmacao


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	hide()
	_lista.item_selected.connect(func(_i: int) -> void: _atualizar_detalhes())
	_botao_equipar.pressed.connect(_alternar_equipamento)
	_botao_jogar_fora.pressed.connect(_perguntar_jogar_fora)
	_aba_item.pressed.connect(_mostrar_item.bind(true))
	_aba_ficha.pressed.connect(_mostrar_item.bind(false))
	_botao_fechar.pressed.connect(fechar)
	_slots.slot_escolhido.connect(_selecionar_item)
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
	_vida_atual = vida_atual
	_vida_maxima = vida_maxima
	_inventario.mudou.connect(_atualizar)
	_mostrar_item(true)
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
	fechou.emit()


func equipar_selecionado() -> void:
	var item := _item_selecionado()
	if item:
		_inventario.equipar(item)


func desequipar_selecionado() -> void:
	var item := _item_selecionado()
	if item and _inventario.esta_equipado(item):
		_inventario.desequipar(_inventario.espaco_de(item))


## Joga fora sem perguntar (a pergunta fica no botão; os testes chamam direto).
func jogar_fora_selecionado() -> void:
	var item := _item_selecionado()
	if item:
		_inventario.descartar(item)


func _alternar_equipamento() -> void:
	var item := _item_selecionado()
	if item == null:
		return
	if _inventario.esta_equipado(item):
		desequipar_selecionado()
	else:
		equipar_selecionado()


func _mostrar_item(item_visivel: bool) -> void:
	_painel_item.visible = item_visivel
	_painel_ficha.visible = not item_visivel
	_aba_item.disabled = item_visivel
	_aba_ficha.disabled = not item_visivel


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
		_adicionar_na_lista(item)
	if not anterior.is_empty() and _lista.item_count > 0:
		_lista.select(mini(anterior[0], _lista.item_count - 1))
	_titulo.text = "Inventário (%d/%d)" % [_inventario.itens.size(), _inventario.capacidade]
	_slots.mostrar(_inventario, _desarmado.nome)
	_atualizar_detalhes()
	_atualizar_ficha()


## Um item na lista: ícone, nome e, se está equipado, o selo da mão ([P], [S], [C]) na cor do slot dela.
func _adicionar_na_lista(item: Item) -> void:
	var espaco := _inventario.espaco_de(item)
	var marca := "[%s] " % EstiloCartao.selo_do_espaco(espaco) if espaco != &"" else ""
	var indice := _lista.add_item(marca + _nome_com_quantidade(item), item.icone)
	if espaco != &"":  # faixa na cor do slot (o texto continua legível, inclusive selecionado)
		_lista.set_item_custom_bg_color(indice, Color(EstiloCartao.cor_do_espaco(espaco), FAIXA_DO_EQUIPADO))


## O jogador clicou num slot: seleciona o item na mochila e mostra os detalhes (dá para desequipar).
func _selecionar_item(item: Item) -> void:
	var indice := _inventario.itens.find(item)
	if indice < 0:
		return
	_lista.select(indice)
	_mostrar_item(true)
	_atualizar_detalhes()


func _atualizar_detalhes() -> void:
	var item := _item_selecionado()
	_nome.text = item.nome if item else "(nenhum item)"
	_dano_item.text = ResumoItem.texto(item, _ficha, _inventario)
	_ajustar_botao_equipar(item)
	_botao_jogar_fora.disabled = item == null


func _ajustar_botao_equipar(item: Item) -> void:
	var equipado := item != null and _inventario != null and _inventario.esta_equipado(item)
	_botao_equipar.text = "Desequipar" if equipado else "Equipar"
	_botao_equipar.disabled = item == null or not item.equipavel()


func _atualizar_ficha() -> void:
	_ficha_visual.mostrar(_ficha, _inventario, _desarmado, _vida_atual, _vida_maxima)


## "Azagaia ×8" para pilhas; só o nome para o resto.
func _nome_com_quantidade(item: Item) -> String:
	var quantidade := _inventario.quantidade_de(item)
	return "%s ×%d" % [item.nome, quantidade] if quantidade > 1 else item.nome
