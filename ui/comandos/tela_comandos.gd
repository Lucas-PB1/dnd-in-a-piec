class_name TelaComandos
extends Control
## Tela de opções (tecla C ou Opções no menu de pausa), em abas: Controles (trocar a tecla de cada ação),
## Toque (analógico ou setas, ajustar botões) e Combate (trazer ou tirar uma criatura, para testes). Pausa o jogo. Não conhece o herói:
## quem monta o jogo responde a `abrir_pedido` e a `trazer_pedido`.

## Emitido quando o jogador aperta C com a tela fechada.
signal abrir_pedido
## Emitido ao escolher Trazer, com a cena da criatura marcada.
signal trazer_pedido(cena: PackedScene)
## Emitido ao escolher Tirar da arena.
signal tirar_pedido
## Emitido quando muda o tipo dos controles de toque ou quando eles aparecem (já salvo).
signal opcoes_toque_mudaram
## Emitido ao escolher "Ajustar botões": quem monta o jogo abre a edição do layout de toque.
signal editar_toque_pedido
## Emitido ao fechar a tela para quem controla a interface de toque.
signal fechou

const TAMANHO_FONTE_LINHA := 12
## Altura dos botões da aba Toque (px da tela do jogo): grandes para o dedo.
const ALTURA_BOTAO_TOQUE := 36.0
const NOMES_DOS_VOLUMES := {&"Musica": "Música", &"Efeitos": "Efeitos", &"Interface": "Menus"}
const PASSO_DO_VOLUME := 0.05
const LARGURA_BARRA_DE_VOLUME := 220.0
const LARGURA_VALOR_DO_VOLUME := 40.0

var _acao_escolhida: StringName = &""
var _cenas: Array[PackedScene] = []
var _botoes: Dictionary[StringName, Button] = {}
var _lista_modo: OptionButton
var _lista_mostrar: OptionButton
var _lista_tela: OptionButton
var _botao_ajustar: Button

@onready var _lista_acoes: GridContainer = %ListaAcoes
@onready var _lista_criaturas: ItemList = %ListaCriaturas
@onready var _trazer: Button = %Trazer
@onready var _tirar: Button = %Tirar
@onready var _fechar: Button = %Fechar
@onready var _pagina_controles: Control = %PaginaControles
@onready var _pagina_toque: Control = %PaginaToque
@onready var _pagina_combate: Control = %PaginaCombate
@onready var _pagina_atalhos: Control = %PaginaAtalhos
@onready var _grade_atalhos: GridContainer = %GradeAtalhos
@onready var _aba_atalhos: Button = %AbaAtalhos
@onready var _pagina_som: Control = %PaginaSom
@onready var _grade_som: GridContainer = %GradeSom
@onready var _aba_som: Button = %AbaSom
@onready var _aba_controles: Button = %AbaControles
@onready var _aba_toque: Button = %AbaToque
@onready var _aba_combate: Button = %AbaCombate


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	for acao in Comandos.ACOES:
		var botao := Button.new()
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.add_theme_font_size_override(&"font_size", TAMANHO_FONTE_LINHA)
		botao.pressed.connect(_escolher_acao.bind(acao))
		_botoes[acao] = botao
		_lista_acoes.add_child(botao)
	var grupo := ButtonGroup.new()  # uma aba de cada vez
	for aba in [_aba_controles, _aba_toque, _aba_atalhos, _aba_som, _aba_combate]:
		aba.button_group = grupo
	_aba_controles.pressed.connect(_mostrar_pagina.bind(_pagina_controles))
	_aba_toque.pressed.connect(_mostrar_pagina.bind(_pagina_toque))
	_aba_atalhos.pressed.connect(_mostrar_pagina.bind(_pagina_atalhos))
	_aba_som.pressed.connect(_mostrar_pagina.bind(_pagina_som))
	_aba_combate.pressed.connect(_mostrar_pagina.bind(_pagina_combate))
	_trazer.pressed.connect(_pedir_trazer)
	_tirar.pressed.connect(tirar_pedido.emit)
	_fechar.pressed.connect(fechar)
	_criar_opcoes_toque()
	_criar_atalhos()
	_criar_volumes()
	_criar_opcao_tela()
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


## `permitir_ajuste` = false esconde "Ajustar botões" (no título não há jogo para ajustar).
func abrir(permitir_ajuste: bool = true) -> void:
	_acao_escolhida = &""
	_botao_ajustar.visible = permitir_ajuste
	_atualizar_rotulos()
	_lista_modo.select(OpcoesToque.modo)  # as opções são carregadas depois do _ready
	_lista_mostrar.select(OpcoesToque.mostrar)
	_marcar_atalhos()
	_marcar_volumes()
	_lista_tela.select(OpcoesTela.modo)
	_aba_controles.button_pressed = true
	_mostrar_pagina(_pagina_controles)
	show()
	get_tree().paused = true


func fechar() -> void:
	_acao_escolhida = &""
	set_process_input(false)
	hide()
	get_tree().paused = false
	fechou.emit()


## Mostra só a página da aba escolhida.
func _mostrar_pagina(pagina: Control) -> void:
	for candidata in [_pagina_controles, _pagina_toque, _pagina_atalhos, _pagina_som, _pagina_combate]:
		candidata.visible = candidata == pagina


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


## Uma barra de volume por barramento (música, efeitos, interface), com o valor em porcentagem ao lado.
func _criar_volumes() -> void:
	for barramento in OpcoesSom.BARRAMENTOS:
		var rotulo := Label.new()
		rotulo.text = NOMES_DOS_VOLUMES[barramento]
		_grade_som.add_child(rotulo)
		var barra := HSlider.new()
		barra.min_value = 0.0
		barra.max_value = 1.0
		barra.step = PASSO_DO_VOLUME
		barra.custom_minimum_size = Vector2(LARGURA_BARRA_DE_VOLUME, ALTURA_BOTAO_TOQUE)
		barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		barra.name = "Volume_%s" % barramento
		_grade_som.add_child(barra)
		var valor := Label.new()
		valor.custom_minimum_size = Vector2(LARGURA_VALOR_DO_VOLUME, 0)
		valor.name = "Valor_%s" % barramento
		_grade_som.add_child(valor)
		barra.value_changed.connect(_escolher_volume.bind(barramento, valor))


## Modo da janela no PC (Janela / Tela cheia), na mesma aba Som.
func _criar_opcao_tela() -> void:
	var rotulo := Label.new()
	rotulo.text = "Tela"
	_grade_som.add_child(rotulo)
	_lista_tela = _lista_de_opcoes(OpcoesTela.NOMES, _escolher_tela)
	_lista_tela.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista_tela.custom_minimum_size = Vector2(LARGURA_BARRA_DE_VOLUME, ALTURA_BOTAO_TOQUE)
	_grade_som.add_child(_lista_tela)
	_grade_som.add_child(Control.new())  # ocupa a 3ª coluna da grade


func _escolher_tela(indice: int) -> void:
	OpcoesTela.definir(indice)
	OpcoesTela.salvar()


func _marcar_volumes() -> void:
	for barramento in OpcoesSom.BARRAMENTOS:
		(_grade_som.get_node("Volume_%s" % barramento) as HSlider).set_value_no_signal(OpcoesSom.volume_de(barramento))
		(_grade_som.get_node("Valor_%s" % barramento) as Label).text = _texto_do_volume(OpcoesSom.volume_de(barramento))


func _escolher_volume(valor: float, barramento: StringName, rotulo: Label) -> void:
	OpcoesSom.definir(barramento, valor)
	OpcoesSom.salvar()
	rotulo.text = _texto_do_volume(valor)


func _texto_do_volume(valor: float) -> String:
	return "%d%%" % roundi(valor * 100.0)


## Um seletor por slot da barra de habilidades do celular (OpcoesToque.slots).
func _criar_atalhos() -> void:
	for slot in OpcoesToque.QUANTIDADE_SLOTS:
		var rotulo := Label.new()
		rotulo.text = "Botão %d" % (slot + 1)
		_grade_atalhos.add_child(rotulo)
		var lista := _lista_de_opcoes(_nomes_dos_atalhos(), _escolher_atalho.bind(slot))
		lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_grade_atalhos.add_child(lista)


## "Vazio" e depois as habilidades, na ordem de OpcoesToque.HABILIDADES.
func _nomes_dos_atalhos() -> PackedStringArray:
	var nomes := PackedStringArray([OpcoesToque.NOME_SLOT_VAZIO])
	for acao in OpcoesToque.HABILIDADES:
		nomes.append(OpcoesToque.HABILIDADES[acao])
	return nomes


func _marcar_atalhos() -> void:
	var acoes := OpcoesToque.HABILIDADES.keys()
	for slot in OpcoesToque.QUANTIDADE_SLOTS:
		var lista := _grade_atalhos.get_child(slot * 2 + 1) as OptionButton
		lista.select(acoes.find(OpcoesToque.slots[slot]) + 1)


func _escolher_atalho(indice: int, slot: int) -> void:
	var acoes := OpcoesToque.HABILIDADES.keys()
	OpcoesToque.slots[slot] = acoes[indice - 1] if indice > 0 else &""
	_salvar_toque()


## Celular: analógico ou setas, e quando os controles aparecem (OpcoesToque).
func _criar_opcoes_toque() -> void:
	_lista_modo = _lista_de_opcoes(OpcoesToque.NOMES_MODO, _escolher_modo)
	_lista_mostrar = _lista_de_opcoes(OpcoesToque.NOMES_MOSTRAR, _escolher_mostrar)
	_pagina_toque.add_child(_lista_modo)
	_pagina_toque.add_child(_lista_mostrar)
	var ajustar := Button.new()
	ajustar.name = "AjustarToque"
	_botao_ajustar = ajustar
	ajustar.custom_minimum_size = Vector2(0, ALTURA_BOTAO_TOQUE)
	ajustar.text = "Ajustar botões"
	ajustar.add_theme_font_size_override(&"font_size", TAMANHO_FONTE_LINHA)
	ajustar.pressed.connect(_pedir_edicao_toque)
	_pagina_toque.add_child(ajustar)


func _lista_de_opcoes(nomes: PackedStringArray, ao_escolher: Callable) -> OptionButton:
	var lista := OptionButton.new()
	lista.custom_minimum_size = Vector2(0, ALTURA_BOTAO_TOQUE)
	lista.add_theme_font_size_override(&"font_size", TAMANHO_FONTE_LINHA)
	for nome in nomes:
		lista.add_item(nome)
	lista.item_selected.connect(ao_escolher)
	return lista


func _escolher_modo(indice: int) -> void:
	OpcoesToque.modo = indice as OpcoesToque.Modo
	_salvar_toque()


func _escolher_mostrar(indice: int) -> void:
	OpcoesToque.mostrar = indice as OpcoesToque.Mostrar
	_salvar_toque()


## Fecha esta tela e pede a edição do layout dos controles de toque.
func _pedir_edicao_toque() -> void:
	fechar()
	editar_toque_pedido.emit()


func _salvar_toque() -> void:
	OpcoesToque.salvar()
	opcoes_toque_mudaram.emit()


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
