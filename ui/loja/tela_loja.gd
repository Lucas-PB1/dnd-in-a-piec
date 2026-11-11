class_name TelaLoja
extends Control
## Tela da loja do início da fase: comprar (o estoque da fase) e vender (a mochila). O ouro e a mochila são do herói,
## mas a tela só recebe a Ficha e o Inventario (não conhece o Jogador). Pausa o jogo. Quem monta o jogo chama abrir().

## Emitido ao fechar a tela para quem controla a interface de toque.
signal fechou
## O ouro mudou numa compra ou venda (a HUD se atualiza).
signal ouro_mudou(ouro: int)

const AVISO_COMPROU := "Comprou: %s"
const AVISO_VENDEU := "Vendeu: %s"
const AVISO_SEM_OURO := "Ouro insuficiente."
const AVISO_CHEIA := "Mochila cheia! Venda ou jogue algo fora."
const AVISO_RENOVOU := "Mercadoria nova."
const COR_OURO := Color(1.0, 0.84, 0.4)

var _estoque: Array[Item] = []
var _visiveis: Array[Item] = []
var _ficha: Ficha
var _inventario: Inventario
var _comprando: bool = true
var _indice_fase: int = 1
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _renovacoes: int = 0

@onready var _lista: ItemList = %Lista
@onready var _nome: Label = %Nome
@onready var _regras: Label = %Regras
@onready var _aviso: Label = %Aviso
@onready var _ouro: Label = %Ouro
@onready var _botao_acao: Button = %Acao
@onready var _botao_fechar: Button = %Fechar
@onready var _botao_comprar: Button = %ModoComprar
@onready var _botao_vender: Button = %ModoVender
@onready var _botao_renovar: Button = %Renovar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	hide()
	_lista.item_selected.connect(func(_i: int) -> void: _atualizar_detalhes())
	_lista.item_activated.connect(func(_i: int) -> void: confirmar())
	_botao_acao.pressed.connect(confirmar)
	_botao_fechar.pressed.connect(fechar)
	_botao_comprar.pressed.connect(_escolher_modo.bind(true))
	_botao_vender.pressed.connect(_escolher_modo.bind(false))
	_botao_renovar.pressed.connect(renovar_estoque)


func _unhandled_input(evento: InputEvent) -> void:
	if visible and (evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("interagir")):
		fechar()
		get_viewport().set_input_as_handled()


## Abre com o `estoque` da fase (a lista é alterada: o comprado sai dela).
## `indice_fase` e `rng` servem para renovar a mercadoria.
func abrir(estoque: Array[Item], ficha: Ficha, inventario: Inventario, indice_fase: int = 1, rng: RandomNumberGenerator = null) -> void:
	_estoque = estoque
	_ficha = ficha
	_inventario = inventario
	_indice_fase = indice_fase
	_rng = rng if rng != null else RandomNumberGenerator.new()
	_renovacoes = 0
	_aviso.text = ""
	_escolher_modo(true)
	_atualizar_botao_renovar()
	show()
	_lista.grab_focus()
	get_tree().paused = true


func fechar() -> void:
	hide()
	get_tree().paused = false
	fechou.emit()


## Paga (1ª grátis, depois +10 po por vez) e sorteia estoque novo no mesmo array.
func renovar_estoque() -> bool:
	if not _comprando or _ficha == null:
		return false
	var resposta := Loja.renovar(_ficha, _renovacoes, _indice_fase, _rng)
	var resultado: Loja.Resultado = resposta.resultado
	if resultado != Loja.Resultado.OK:
		_aviso.text = AVISO_SEM_OURO
		return false
	_estoque.clear()
	for item in resposta.estoque as Array:
		_estoque.append(item as Item)
	_renovacoes += 1
	_aviso.text = AVISO_RENOVOU
	ouro_mudou.emit(_ficha.ouro)
	_atualizar_botao_renovar()
	_preencher_lista()
	return true


## Compra ou vende o item escolhido, conforme o modo. Devolve true se a troca aconteceu.
func confirmar() -> bool:
	var item := _item_selecionado()
	if item == null:
		return false
	var resultado := Loja.comprar(item, _ficha, _inventario) if _comprando else Loja.vender(item, _ficha, _inventario)
	_aviso.text = _texto_do_resultado(resultado, item)
	if resultado != Loja.Resultado.OK:
		return false
	if _comprando and not Loja.fica_no_estoque(item):
		_estoque.erase(item)
	ouro_mudou.emit(_ficha.ouro)
	_atualizar_botao_renovar()
	_preencher_lista()
	return true


func _texto_do_resultado(resultado: Loja.Resultado, item: Item) -> String:
	match resultado:
		Loja.Resultado.OK:
			return (AVISO_COMPROU if _comprando else AVISO_VENDEU) % item.nome
		Loja.Resultado.SEM_OURO:
			return AVISO_SEM_OURO
		Loja.Resultado.MOCHILA_CHEIA:
			return AVISO_CHEIA
	return ""


func _escolher_modo(comprando: bool) -> void:
	_comprando = comprando
	_botao_comprar.disabled = comprando
	_botao_vender.disabled = not comprando
	_botao_acao.text = "Comprar" if comprando else "Vender"
	_atualizar_botao_renovar()
	_preencher_lista()


func _atualizar_botao_renovar() -> void:
	var custo := Loja.preco_da_renovacao(_renovacoes)
	_botao_renovar.visible = _comprando
	_botao_renovar.text = "Trocar (grátis)" if custo == 0 else "Trocar (%d po)" % custo
	_botao_renovar.disabled = not _comprando or _ficha == null or _ficha.ouro < custo


func _preencher_lista() -> void:
	_visiveis = _estoque.duplicate() if _comprando else _inventario.itens.duplicate()
	var anterior := _lista.get_selected_items()
	_lista.clear()
	for item in _visiveis:
		_lista.add_item("%s  (%d po)" % [item.nome, _preco_mostrado(item)], item.icone)
		if item is Arma:
			_lista.set_item_icon_modulate(_lista.item_count - 1, (item as Arma).cor_do_brilho())
	if _lista.item_count > 0:
		_lista.select(mini(anterior[0] if not anterior.is_empty() else 0, _lista.item_count - 1))
	_atualizar_detalhes()


func _preco_mostrado(item: Item) -> int:
	return Loja.preco_de_compra(item, _ficha) if _comprando else Loja.preco_de_venda(item, _inventario)


func _item_selecionado() -> Item:
	var selecionados := _lista.get_selected_items()
	return _visiveis[selecionados[0]] if not selecionados.is_empty() else null


func _atualizar_detalhes() -> void:
	var item := _item_selecionado()
	_nome.text = item.nome if item else ("(nada à venda)" if _comprando else "(mochila vazia)")
	_regras.text = ResumoItem.texto(item, _ficha, _inventario) if item else ""
	_botao_acao.disabled = item == null
	_ouro.text = "Ouro %d · Mochila %d/%d" % [_ficha.ouro, _inventario.itens.size(), _inventario.capacidade]
	_ouro.add_theme_color_override(&"font_color", COR_OURO)
