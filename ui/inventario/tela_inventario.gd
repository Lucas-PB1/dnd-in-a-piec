class_name TelaInventario
extends Control
## Tela de inventário (tecla I): lista à esquerda e, à direita, o item ou a ficha.
## Pausa o jogo enquanto está aberta. Não conhece o herói: quem monta o jogo
## responde a `abrir_pedido` chamando abrir().

## Emitido quando o jogador aperta I com a tela fechada.
signal abrir_pedido

const MARCA_EQUIPADO := "[E] "
const MARCA_PROFICIENTE := "*"

var _inventario: Inventario
var _ficha: Ficha
var _desarmado: Arma
var _texto_vida: String = ""

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
@onready var _texto_ficha: Label = %TextoFicha
@onready var _confirmacao: ConfirmationDialog = %Confirmacao


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	hide()
	_lista.item_selected.connect(func(_i: int) -> void: _atualizar_detalhes())
	_botao_equipar.pressed.connect(_alternar_equipamento)
	_botao_jogar_fora.pressed.connect(_perguntar_jogar_fora)
	_aba_item.pressed.connect(_mostrar_item.bind(true))
	_aba_ficha.pressed.connect(_mostrar_item.bind(false))
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
		var marca := MARCA_EQUIPADO if _inventario.esta_equipado(item) else ""
		_lista.add_item(marca + _nome_com_quantidade(item), item.icone)
	if not anterior.is_empty() and _lista.item_count > 0:
		_lista.select(mini(anterior[0], _lista.item_count - 1))
	_titulo.text = "Inventário (%d/%d)" % [_inventario.itens.size(), _inventario.capacidade]
	_atualizar_detalhes()
	_atualizar_ficha()


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
	var arma := Equipamento.arma(_inventario, _desarmado)
	var linhas: PackedStringArray = [
		"%s, %s" % [_ficha.nome, _ficha.classe.nome],
		"%s   CA %d   %d pés" % [_texto_vida, Equipamento.classe_armadura(_ficha, _inventario),
			int(Equipamento.deslocamento_pes(_ficha, _inventario))],
		_atributos_entre(0, 3),
		_atributos_entre(3, 6),
		_linha_equipamento(arma),
	]
	var ataque := Equipamento.bonus_ataque(_ficha, _inventario, arma)
	linhas.append("Ataque %s   Dano %s" % [Atributos.texto_bonus(ataque), Equipamento.texto_dano(_ficha, _inventario, arma)])
	_texto_ficha.text = "\n".join(linhas)


func _atributos_entre(inicio: int, fim: int) -> String:
	var partes: PackedStringArray = []
	for i in range(inicio, fim):
		partes.append(_atributo_curto(Atributos.TODOS[i]))
	return "   ".join(partes)


## "FOR 15 +2*" — o * marca salvaguarda em que a classe é proficiente.
func _atributo_curto(atributo: StringName) -> String:
	var valor: int = _ficha.atributos[atributo]
	var marca := MARCA_PROFICIENTE if _ficha.proficiente_em_salvaguarda(atributo) else ""
	return "%s %d %s%s" % [Atributos.SIGLAS[atributo], valor, Atributos.texto_modificador(valor), marca]


func _linha_equipamento(arma: Arma) -> String:
	var mao := "Mão: %s%s" % [arma.nome, " (duas mãos)" if _usa_duas_maos(arma) else ""]
	var corpo := "Corpo: %s" % _nome_ou_nada(Equipamento.armadura(_inventario))
	var extra := ""
	var escudo := Equipamento.escudo(_inventario)
	if escudo:
		extra = "   Escudo: %s" % escudo.nome
	var segunda := Equipamento.arma_secundaria(_inventario)
	if segunda:
		extra = "   Outra: %s" % segunda.nome
	return "%s   %s%s" % [mao, corpo, extra]


func _nome_ou_nada(item: Item) -> String:
	return item.nome if item else "(nada)"


## "Azagaia ×8" para pilhas; só o nome para o resto.
func _nome_com_quantidade(item: Item) -> String:
	var quantidade := _inventario.quantidade_de(item)
	return "%s ×%d" % [item.nome, quantidade] if quantidade > 1 else item.nome


## Arma de Duas Mãos, ou Versátil com a mão secundária livre.
func _usa_duas_maos(arma: Arma) -> bool:
	return arma.duas_maos or Equipamento.duas_maos(_inventario, arma)
