class_name TelaInventario
extends Control
## Tela de inventário (tecla I): lista de itens, detalhes, Equipar / Desequipar / Jogar fora,
## e a ficha do personagem. Pausa o jogo enquanto está aberta. Não conhece o herói:
## quem monta o jogo responde a `abrir_pedido` chamando abrir() com os dados.

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
		_inventario.desequipar(_inventario.espaco_de(item))


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
		_lista.add_item(marca + _nome_com_quantidade(item), item.icone)
	if not anterior.is_empty() and _lista.item_count > 0:
		_lista.select(mini(anterior[0], _lista.item_count - 1))
	_titulo.text = "Inventário (%d/%d)" % [_inventario.itens.size(), _inventario.capacidade]
	_atualizar_detalhes()
	_atualizar_ficha()


func _atualizar_detalhes() -> void:
	var item := _item_selecionado()
	_nome.text = item.nome if item else "(nenhum item)"
	_descricao.text = item.descricao if item else ""
	_dano_item.text = _texto_do_item(item)
	var equipado := _inventario != null and _inventario.esta_equipado(item)
	_botao_equipar.disabled = item == null or not item.equipavel() or equipado
	_botao_desequipar.disabled = not equipado
	_botao_jogar_fora.disabled = item == null


func _atualizar_ficha() -> void:
	var linhas: PackedStringArray = ["%s, %s" % [_ficha.nome, _ficha.classe.nome]]
	for atributo in Atributos.TODOS:
		linhas.append(_linha_atributo(atributo))
	linhas.append("%s   CA %d" % [_texto_vida, Equipamento.classe_armadura(_ficha, _inventario)])
	linhas.append("Inic. %s (%.1fs)   %d pés" % [Atributos.texto_bonus(_ficha.iniciativa()),
		EscalaDnd.intervalo_ataque(_ficha.iniciativa()), Equipamento.deslocamento_pes(_ficha, _inventario)])
	var arma := Equipamento.arma(_inventario, _desarmado)
	linhas.append("Mão: %s%s" % [arma.nome, " (duas mãos)" if _usa_duas_maos(arma) else ""])
	linhas.append("Corpo: %s" % _nome_ou_nada(Equipamento.armadura(_inventario)))
	var escudo := Equipamento.escudo(_inventario)
	if escudo:
		linhas.append("Escudo: %s" % escudo.nome)
	var segunda := Equipamento.arma_secundaria(_inventario)
	if segunda:
		linhas.append("Outra mão: %s (extra %s)" % [segunda.nome, Equipamento.texto_dano_extra(_ficha, segunda)])
	var ataque := Equipamento.bonus_ataque(_ficha, _inventario, arma)
	linhas.append("Ataque %s   Dano %s" % [Atributos.texto_bonus(ataque), Equipamento.texto_dano(_ficha, _inventario, arma)])
	_texto_ficha.text = "\n".join(linhas)


func _nome_ou_nada(item: Item) -> String:
	return item.nome if item else "(nada)"


## "Azagaia ×8" para pilhas; só o nome para o resto.
func _nome_com_quantidade(item: Item) -> String:
	var quantidade := _inventario.quantidade_de(item)
	return "%s ×%d" % [item.nome, quantidade] if quantidade > 1 else item.nome


## Arma de Duas Mãos, ou Versátil com a mão secundária livre.
func _usa_duas_maos(arma: Arma) -> bool:
	return arma.duas_maos or Equipamento.duas_maos(_inventario, arma)


## Detalhes extras do item selecionado: dano da arma ou regras da armadura.
func _texto_do_item(item: Item) -> String:
	if _ficha == null:
		return ""
	if item is Arma:
		return _texto_da_arma(item)
	if item is Armadura:
		return _texto_da_armadura(item)
	return ""


## "Dano: 1d10+2 cortante (duas mãos)" e os avisos: proficiência, arma Pesada, Corrosão.
func _texto_da_arma(arma: Arma) -> String:
	var texto := "Dano: %s %s%s" % [Equipamento.texto_dano(_ficha, _inventario, arma),
		TiposDano.nome(arma.tipo_dano), " (duas mãos)" if _usa_duas_maos(arma) else ""]
	if _ficha.fraco_para(arma):
		texto += "
Pesada: FOR abaixo de %d, ataca com desvantagem" % Ficha.FORCA_MINIMA_ARMA_PESADA
	if not _ficha.proficiente_com(arma):
		texto += "\nSem proficiência: -%d no ataque" % Ficha.BONUS_PROFICIENCIA
	var penalidade := _inventario.penalidade(arma)
	if penalidade > 0:
		texto += "\nCorroída: -%d no ataque" % penalidade
	return texto


## Avisos de regra da armadura para ESTA ficha: treinamento, Força, Furtividade, corrosão.
func _texto_da_armadura(armadura: Armadura) -> String:
	var avisos: PackedStringArray = []
	if not _ficha.treinado_com(armadura):
		avisos.append("Sem treinamento: " + ("não soma CA" if armadura.e_escudo() else "desvantagem em FOR e DES"))
	if _ficha.falta_forca_para(armadura):
		avisos.append("Precisa FOR %d: -%d pés" % [armadura.forca_minima, Ficha.PERDA_DESLOCAMENTO_SEM_FORCA])
	if armadura.desvantagem_furtividade:
		avisos.append("Desvantagem em Furtividade")
	var penalidade := _inventario.penalidade(armadura)
	if penalidade > 0:
		avisos.append("Corroída: -%d na CA" % penalidade)
	return "\n".join(avisos)


## "FOR 15 (+2) salv +4*" — o * marca salvaguarda em que a classe é proficiente.
func _linha_atributo(atributo: StringName) -> String:
	var valor: int = _ficha.atributos[atributo]
	var marca := MARCA_PROFICIENTE if _ficha.proficiente_em_salvaguarda(atributo) else ""
	return "%s %d (%s) salv %s%s" % [Atributos.SIGLAS[atributo], valor, Atributos.texto_modificador(valor),
		Atributos.texto_bonus(_ficha.bonus_salvaguarda(atributo)), marca]
