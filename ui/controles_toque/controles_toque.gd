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
const ANALOGICO := ["analogico", Vector2(0, 1), Vector2(104, -104), 58.0]
## Setas: [ação, seta, canto, centro, raio]. ↑ mira para cima (não pula; o pulo tem botão).
const SETAS := [
	[&"mover_esquerda", Vector2.LEFT, Vector2(0, 1), Vector2(58, -94), 30.0],
	[&"mover_direita", Vector2.RIGHT, Vector2(0, 1), Vector2(152, -94), 30.0],
	[&"mirar_cima", Vector2.UP, Vector2(0, 1), Vector2(105, -154), 26.0],
	[&"mover_baixo", Vector2.DOWN, Vector2(0, 1), Vector2(105, -46), 24.0],
]
## Botões: [ação, texto, canto, centro, raio].
const BOTOES := [
	[&"atacar", "Atacar", Vector2(1, 1), Vector2(-64, -72), 40.0],
	[&"pular", "Pular", Vector2(1, 1), Vector2(-150, -58), 34.0],
	[&"arremessar", "Lançar", Vector2(1, 1), Vector2(-56, -158), 30.0],
	[&"interagir", "Abrir", Vector2(1, 1), Vector2(-136, -130), 30.0],
	[&"pausa", "Menu", Vector2(1, 0), Vector2(-54, 54), 30.0],
]
## Slots das habilidades especiais (barra de atalhos em arco, à esquerda e acima do Atacar, do Pular e do Lançar,
## que são ações básicas e ficam fixas): [id, canto, centro, raio]. Só aparece o slot que tem habilidade e que
## serve agora; o que vai em cada um é de OpcoesToque.slots.
const SLOTS := [
	["slot1", Vector2(1, 1), Vector2(-228, -52), 30.0],
	["slot2", Vector2(1, 1), Vector2(-216, -122), 30.0],
	["slot3", Vector2(1, 1), Vector2(-186, -190), 30.0],
	["slot4", Vector2(1, 1), Vector2(-120, -226), 30.0],
	["slot5", Vector2(1, 1), Vector2(-56, -236), 30.0],
	["slot6", Vector2(1, 1), Vector2(-290, -122), 30.0],
	["slot7", Vector2(1, 1), Vector2(-310, -190), 30.0],
	["slot8", Vector2(1, 1), Vector2(-250, -262), 30.0],
]
## Camada: acima do jogo e do HUD, abaixo dos menus (Interface = 10).
const CAMADA := 5
## Limites e passo do tamanho na edição (raio, px).
## Folga mínima entre qualquer botão e a borda da tela (px do jogo), para o dedo e a mão não esbarrarem na borda.
const MARGEM_BORDA := 20.0
const RAIO_MINIMO := 12.0
const RAIO_MAXIMO := 72.0
const PASSO_RAIO := 3.0
const SEM_DEDO := -1
## Texto do botão de interação quando a edição do layout o mostra sem nada perto.
const ROTULO_INTERACAO_PADRAO := "Abrir"
const TEMA := preload("res://ui/tema_menu.tres")
const TAMANHO_FONTE_EDICAO := 10
## Tamanho mínimo dos botões do painel de edição (px): dá para acertar com o dedo.
const TAMANHO_BOTAO_PAINEL := Vector2(30, 24)
const DICA_EDICAO := "Arraste para mudar o lugar. Toque num controle e use − / + para o tamanho."

var _raiz: Control
var _analogico: AnalogicoToque
var _setas: Array[BotaoToque] = []
var _botoes: Array[BotaoToque] = []
var _slots: Array[BotaoToque] = []
## id -> controle e id -> [canto, centro, raio] padrão.
var _controles: Dictionary[String, Control] = {}
var _padroes: Dictionary[String, Array] = {}

var _editando: bool = false
var _painel: PanelContainer
var _barra_opacidade: HSlider
## Ações cujo botão está escondido porque não servem agora (Surto antes do nível 2, E longe de tudo).
var _escondidos: Dictionary[StringName, bool] = {}
## Estado de cada habilidade (BotaoToque.EstadoBotao), guardado para valer também quando ela troca de slot.
var _estados: Dictionary[StringName, BotaoToque.EstadoBotao] = {}
## "Abrir" ou "Pegar" quando há algo perto (o botão de interação aparece só então); vazio = escondido.
var _rotulo_interacao: String = ""
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
		_setas.append(_criar_botao(String(d[0]), d[0], "", d[1], d[2], d[3], d[4]))
	for d in BOTOES:
		_botoes.append(_criar_botao(String(d[0]), d[0], d[1], Vector2.ZERO, d[2], d[3], d[4]))
	for d in SLOTS:
		_slots.append(_criar_botao(d[0], &"", "", Vector2.ZERO, d[1], d[2], d[3]))
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
	_aplicar_slots()
	_aplicar_interacao()
	_aplicar_escondidos()


## O botão de interação (Abrir, Pegar) aparece só enquanto houver algo perto; sem rótulo, some.
func definir_interacao(rotulo: String) -> void:
	_rotulo_interacao = rotulo
	_aplicar_interacao()


## Acende, deixa normal ou marca como desligado o botão de uma habilidade (BotaoToque.EstadoBotao).
func definir_estado(acao: StringName, estado: BotaoToque.EstadoBotao) -> void:
	_estados[acao] = estado
	var b := botao(acao)
	if b != null:
		b.estado = estado


## Mostra ou esconde o botão de uma ação conforme ela serve agora. Na edição do layout todos aparecem.
func mostrar_acao(acao: StringName, serve: bool) -> void:
	if serve:
		_escondidos.erase(acao)
	else:
		_escondidos[acao] = true
	_aplicar_escondidos()


## Põe cada controle no lugar e tamanho salvos (ou no padrão).
func aplicar_layout() -> void:
	for id in _controles:
		var padrao: Array = _padroes[id]
		var salvo: Array = OpcoesToque.posicoes.get(id, [])
		if salvo.size() == 5:  # o que o jogador pôs também respeita a folga da borda
			var canto := Vector2(salvo[0], salvo[1])
			_posicionar(_controles[id], canto, _com_folga_da_borda(canto, Vector2(salvo[2], salvo[3]), salvo[4]), salvo[4])
		else:
			_posicionar(_controles[id], padrao[0], _com_folga_da_borda(padrao[0], _empurrar_para_dentro(padrao[0], padrao[1]), padrao[2]), padrao[2])


func _aplicar_interacao() -> void:
	var interagir := botao(&"interagir")
	if interagir == null:
		return
	interagir.trocar_funcao(&"interagir", _rotulo_interacao if not _rotulo_interacao.is_empty() else ROTULO_INTERACAO_PADRAO)
	mostrar_acao(&"interagir", not _rotulo_interacao.is_empty())


## Põe em cada slot a habilidade que o jogador escolheu (OpcoesToque.slots). Slot vazio só aparece na edição.
func _aplicar_slots() -> void:
	for i in _slots.size():
		var acao: StringName = OpcoesToque.slots[i] if i < OpcoesToque.slots.size() else &""
		_slots[i].trocar_funcao(acao, OpcoesToque.nome_da_habilidade(acao))
		_slots[i].estado = _estados.get(acao, BotaoToque.EstadoBotao.NORMAL)


func _aplicar_escondidos() -> void:
	for b in _botoes + _slots:
		b.visible = _editando or (b.acao != &"" and not _escondidos.has(b.acao))


func esta_visivel() -> bool:
	return _raiz.visible


func esta_editando() -> bool:
	return _editando


## O botão da `acao` (para testes); null se não houver.
func botao(acao: StringName) -> BotaoToque:
	for b in _setas + _botoes + _slots:
		if b.acao == acao and acao != &"":
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
	var folga := Vector2.ONE * (raio + MARGEM_BORDA)
	centro = centro.clamp(folga, tela - folga)
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


func _criar_botao(id: String, acao: StringName, texto: String, seta: Vector2, canto: Vector2, centro: Vector2, raio: float) -> BotaoToque:
	var novo := BotaoToque.new()
	novo.name = "Botao_" + id
	novo.acao = acao
	novo.texto = texto
	novo.seta = seta
	_registrar(id, novo, canto, centro, raio)
	return novo


func _registrar(id: String, controle: Control, canto: Vector2, centro: Vector2, raio: float) -> void:
	_raiz.add_child(controle)
	_controles[id] = controle
	_padroes[id] = [canto, centro, raio]


## Leva o centro (relativo ao canto) para dentro da folga mínima da borda. Sem tamanho de tela ainda, não mexe.
func _com_folga_da_borda(canto: Vector2, centro: Vector2, raio: float) -> Vector2:
	var tela := _raiz.size
	if tela.x <= 0.0 or tela.y <= 0.0:
		return centro
	var folga := Vector2.ONE * (raio + MARGEM_BORDA)
	var absoluto := (canto * tela + centro).clamp(folga, tela - folga)
	return absoluto - canto * tela


## Celulares com recorte ou barras do sistema: afasta os controles padrão da área que o sistema ocupa.
func _empurrar_para_dentro(canto: Vector2, centro: Vector2) -> Vector2:
	var folga := _folga_do_sistema()
	var x := centro.x + (folga.x if canto.x == 0.0 else -folga.z)
	var y := centro.y + (folga.y if canto.y == 0.0 else -folga.w)
	return Vector2(x, y)


## Esquerda, cima, direita e baixo ocupados pelo sistema (recorte da câmera, barras), em px do jogo. Zero no PC.
func _folga_do_sistema() -> Vector4:
	var janela := Vector2(DisplayServer.window_get_size())
	if not OS.has_feature("mobile") or janela.x <= 0.0 or _raiz.size.x <= 0.0:
		return Vector4.ZERO
	var segura := Rect2(DisplayServer.get_display_safe_area())
	var tela := Vector2(DisplayServer.screen_get_size())
	var escala := _raiz.size.x / janela.x
	return Vector4(maxf(segura.position.x, 0.0), maxf(segura.position.y, 0.0),
		maxf(tela.x - segura.end.x, 0.0), maxf(tela.y - segura.end.y, 0.0)) * escala

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
