class_name ControlesToque
extends CanvasLayer
## Controles na tela para celular: analógico OU setas à esquerda (OpcoesToque.modo) e os
## botões de ação à direita, presos aos cantos (a tela larga do celular é respeitada).
## Aparecem só com tela de toque, ou como a opção mandar (OpcoesToque.mostrar). Não
## conhecem o herói: apertam as mesmas ações do InputMap que as teclas.
## Modo de edição (editar()): arrastar muda o lugar, − / + o tamanho do selecionado, a barra
## a transparência; Padrão desfaz tudo; Pronto salva (OpcoesToque) e emite edicao_terminada.

## Emitido ao apertar Pronto no modo de edição (o layout já foi salvo).
signal edicao_terminada

## Analógico: [id, canto (âncora 0..1), centro a partir do canto (px), raio].
const ANALOGICO := ["analogico", Vector2(0, 1), Vector2(76, -76), 46.0]
## Setas: [ação, seta, canto, centro, raio]. ↑ mira para cima (não pula; o pulo tem botão).
const SETAS := [
	[&"mover_esquerda", Vector2.LEFT, Vector2(0, 1), Vector2(36, -62), 22.0],
	[&"mover_direita", Vector2.RIGHT, Vector2(0, 1), Vector2(110, -62), 22.0],
	[&"mirar_cima", Vector2.UP, Vector2(0, 1), Vector2(73, -104), 18.0],
	[&"mover_baixo", Vector2.DOWN, Vector2(0, 1), Vector2(73, -22), 18.0],
]
## Botões: [ação, texto, canto, centro, raio].
const BOTOES := [
	[&"atacar", "Atacar", Vector2(1, 1), Vector2(-50, -54), 28.0],
	[&"pular", "Pular", Vector2(1, 1), Vector2(-120, -36), 26.0],
	[&"arremessar", "Lançar", Vector2(1, 1), Vector2(-42, -126), 22.0],
	[&"folego", "Fôlego", Vector2(1, 1), Vector2(-108, -102), 19.0],
	[&"interagir", "E", Vector2(1, 1), Vector2(-164, -82), 20.0],
	[&"surto_acao", "Surto", Vector2(1, 1), Vector2(-174, -140), 20.0],
	[&"inventario", "Bolsa", Vector2(1, 0), Vector2(-26, 24), 21.0],
	[&"comandos", "Menu", Vector2(1, 0), Vector2(-68, 24), 21.0],
]
## Camada: acima do jogo e do HUD, abaixo dos menus (Interface = 10).
const CAMADA := 5
## Limites e passo do tamanho na edição (raio, px).
const RAIO_MINIMO := 12.0
const RAIO_MAXIMO := 64.0
const PASSO_RAIO := 3.0
const SEM_DEDO := -1
const TEMA := preload("res://ui/tema_menu.tres")
const TAMANHO_FONTE_EDICAO := 10
## Tamanho mínimo dos botões do painel de edição (px): dá para acertar com o dedo.
const TAMANHO_BOTAO_PAINEL := Vector2(30, 24)
const DICA_EDICAO := "Arraste para mudar o lugar. Toque num controle e use − / + para o tamanho."

var _raiz: Control
var _analogico: AnalogicoToque
var _setas: Array[BotaoToque] = []
var _botoes: Array[BotaoToque] = []
## id -> controle e id -> [canto, centro, raio] padrão.
var _controles: Dictionary[String, Control] = {}
var _padroes: Dictionary[String, Array] = {}

var _editando: bool = false
var _painel: PanelContainer
var _barra_opacidade: HSlider
var _selecionado: Control
var _dedo_edicao: int = SEM_DEDO
## Do centro do controle até o dedo, para ele não pular quando começa a arrastar.
var _pegada: Vector2 = Vector2.ZERO


func _ready() -> void:
	layer = CAMADA
	process_mode = Node.PROCESS_MODE_ALWAYS
	_raiz = Control.new()
	_raiz.name = "Raiz"
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_raiz)
	_analogico = AnalogicoToque.new()
	_analogico.name = "Analogico"
	_registrar(ANALOGICO[0], _analogico, ANALOGICO[1], ANALOGICO[2], ANALOGICO[3])
	for d in SETAS:
		_setas.append(_criar_botao(d[0], "", d[1], d[2], d[3], d[4]))
	for d in BOTOES:
		_botoes.append(_criar_botao(d[0], d[1], Vector2.ZERO, d[2], d[3], d[4]))
	_criar_painel()
	aplicar_layout()
	atualizar()


## Mostra ou esconde pelas opções (e esconde de vez nas telas de pausa, se `escondido`).
func atualizar(escondido: bool = false) -> void:
	_raiz.visible = _editando or (not escondido and OpcoesToque.visiveis())
	_analogico.visible = OpcoesToque.modo == OpcoesToque.Modo.ANALOGICO
	for seta in _setas:
		seta.visible = OpcoesToque.modo == OpcoesToque.Modo.SETAS
	_raiz.modulate.a = OpcoesToque.opacidade


## Põe cada controle no lugar e tamanho salvos (ou no padrão).
func aplicar_layout() -> void:
	for id in _controles:
		var padrao: Array = _padroes[id]
		var salvo: Array = OpcoesToque.posicoes.get(id, [])
		if salvo.size() == 5:
			_posicionar(_controles[id], Vector2(salvo[0], salvo[1]), Vector2(salvo[2], salvo[3]), salvo[4])
		else:
			_posicionar(_controles[id], padrao[0], padrao[1], padrao[2])


func esta_visivel() -> bool:
	return _raiz.visible


func esta_editando() -> bool:
	return _editando


## O botão da `acao` (para testes); null se não houver.
func botao(acao: StringName) -> BotaoToque:
	for b in _setas + _botoes:
		if b.acao == acao:
			return b
	return null


func analogico() -> AnalogicoToque:
	return _analogico


# --- Edição do layout -------------------------------------------------------------

## Entra no modo de edição (quem chama pausa o jogo). Os controles param de apertar.
func editar() -> void:
	_editando = true
	_definir_edicao(true)
	_barra_opacidade.set_value_no_signal(OpcoesToque.opacidade)
	_painel.show()
	_selecionar(null)
	atualizar()


## Pronto: salva o layout e volta a jogar.
func terminar_edicao() -> void:
	_editando = false
	_dedo_edicao = SEM_DEDO
	_definir_edicao(false)
	_selecionar(null)
	_painel.hide()
	OpcoesToque.salvar()
	atualizar()
	edicao_terminada.emit()


## Padrão: lugares, tamanhos e transparência de fábrica.
func restaurar_padrao() -> void:
	OpcoesToque.posicoes.clear()
	OpcoesToque.opacidade = OpcoesToque.OPACIDADE_PADRAO
	_barra_opacidade.set_value_no_signal(OpcoesToque.opacidade)
	aplicar_layout()
	atualizar()


## − / +: muda o tamanho do selecionado, mantendo o centro.
func mudar_tamanho(passos: int) -> void:
	if _selecionado == null:
		return
	var raio := clampf(_raio_de(_selecionado) + passos * PASSO_RAIO, RAIO_MINIMO, RAIO_MAXIMO)
	_mover_para(_selecionado, _centro_de(_selecionado), raio)


func mudar_opacidade(valor: float) -> void:
	OpcoesToque.opacidade = clampf(valor, OpcoesToque.OPACIDADE_MINIMA, 1.0)
	_raiz.modulate.a = OpcoesToque.opacidade


func _input(evento: InputEvent) -> void:
	if not _editando:
		return
	if evento is InputEventScreenTouch:
		var toque := evento as InputEventScreenTouch
		if toque.pressed and _dedo_edicao == SEM_DEDO and not _painel.get_global_rect().has_point(toque.position):
			_pegar(toque.index, toque.position)
		elif not toque.pressed and toque.index == _dedo_edicao:
			_dedo_edicao = SEM_DEDO
	elif evento is InputEventScreenDrag:
		var arrasto := evento as InputEventScreenDrag
		if arrasto.index == _dedo_edicao and _selecionado:
			_mover_para(_selecionado, arrasto.position - _pegada, _raio_de(_selecionado))
			get_viewport().set_input_as_handled()


## Liga ou desliga a edição em cada controle (editando = não apertam nada).
func _definir_edicao(ligada: bool) -> void:
	for controle: Control in _controles.values():
		controle.set(&"editando", ligada)


func _pegar(dedo: int, ponto: Vector2) -> void:
	var alvo := _controle_em(ponto)
	_selecionar(alvo)
	if alvo == null:
		return
	_dedo_edicao = dedo
	_pegada = ponto - _centro_de(alvo)
	get_viewport().set_input_as_handled()


## O controle visível sob o ponto (o de cima, se dois se cobrem).
func _controle_em(ponto: Vector2) -> Control:
	var ids := _controles.keys()
	ids.reverse()
	for id in ids:
		var controle: Control = _controles[id]
		if controle.is_visible_in_tree() and ponto.distance_to(_centro_de(controle)) <= _raio_de(controle):
			return controle
	return null


func _selecionar(controle: Control) -> void:
	if _selecionado:
		_selecionado.set(&"destacado", false)
	_selecionado = controle
	if _selecionado:
		_selecionado.set(&"destacado", true)


## Leva o controle para `centro` (px da tela), preso ao canto mais perto, e guarda.
func _mover_para(controle: Control, centro: Vector2, raio: float) -> void:
	var tela := _raiz.size
	centro = centro.clamp(Vector2(raio, raio), tela - Vector2(raio, raio))
	var canto := Vector2(0.0 if centro.x < tela.x / 2.0 else 1.0, 0.0 if centro.y < tela.y / 2.0 else 1.0)
	var a_partir_do_canto := centro - canto * tela
	_posicionar(controle, canto, a_partir_do_canto, raio)
	OpcoesToque.posicoes[_id_de(controle)] = [canto.x, canto.y, a_partir_do_canto.x, a_partir_do_canto.y, raio]


func _id_de(controle: Control) -> String:
	return _controles.find_key(controle)


func _centro_de(controle: Control) -> Vector2:
	return controle.global_position + controle.size / 2.0


func _raio_de(controle: Control) -> float:
	return minf(controle.size.x, controle.size.y) / 2.0


func _criar_painel() -> void:
	_painel = PanelContainer.new()
	_painel.name = "PainelEdicao"
	_painel.theme = TEMA
	_painel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_painel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_painel.position.y = 4.0
	var coluna := VBoxContainer.new()
	_painel.add_child(coluna)
	coluna.add_child(_rotulo(DICA_EDICAO))
	var linha := HBoxContainer.new()
	coluna.add_child(linha)
	linha.add_child(_botao_painel("−", mudar_tamanho.bind(-1)))
	linha.add_child(_botao_painel("+", mudar_tamanho.bind(1)))
	linha.add_child(_rotulo("Transparência"))
	_barra_opacidade = HSlider.new()
	_barra_opacidade.min_value = OpcoesToque.OPACIDADE_MINIMA
	_barra_opacidade.max_value = 1.0
	_barra_opacidade.step = 0.05
	_barra_opacidade.custom_minimum_size.x = 70.0
	_barra_opacidade.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_barra_opacidade.value_changed.connect(mudar_opacidade)
	linha.add_child(_barra_opacidade)
	linha.add_child(_botao_painel("Padrão", restaurar_padrao))
	linha.add_child(_botao_painel("Pronto", terminar_edicao))
	_painel.hide()
	_raiz.add_child(_painel)


func _rotulo(texto: String) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.add_theme_font_size_override(&"font_size", TAMANHO_FONTE_EDICAO)
	return rotulo


func _botao_painel(texto: String, ao_apertar: Callable) -> Button:
	var botao_novo := Button.new()
	botao_novo.name = "Botao" + texto
	botao_novo.text = texto
	botao_novo.add_theme_font_size_override(&"font_size", TAMANHO_FONTE_EDICAO)
	botao_novo.custom_minimum_size = TAMANHO_BOTAO_PAINEL
	botao_novo.pressed.connect(ao_apertar)
	return botao_novo


func _criar_botao(acao: StringName, texto: String, seta: Vector2, canto: Vector2, centro: Vector2, raio: float) -> BotaoToque:
	var novo := BotaoToque.new()
	novo.name = "Botao_" + String(acao)
	novo.acao = acao
	novo.texto = texto
	novo.seta = seta
	_registrar(String(acao), novo, canto, centro, raio)
	return novo


func _registrar(id: String, controle: Control, canto: Vector2, centro: Vector2, raio: float) -> void:
	_raiz.add_child(controle)
	_controles[id] = controle
	_padroes[id] = [canto, centro, raio]


## Prende o controle ao `canto` da tela (âncoras), com o centro a `centro` px dele.
func _posicionar(controle: Control, canto: Vector2, centro: Vector2, raio: float) -> void:
	controle.anchor_left = canto.x
	controle.anchor_right = canto.x
	controle.anchor_top = canto.y
	controle.anchor_bottom = canto.y
	controle.offset_left = centro.x - raio
	controle.offset_right = centro.x + raio
	controle.offset_top = centro.y - raio
	controle.offset_bottom = centro.y + raio
