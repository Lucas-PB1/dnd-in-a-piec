extends SceneTree
## Acrescenta (ou reaplica) o mapeamento Xbox no InputMap e grava o project.godot.
##   godot --headless --path . --script res://tools/aplicar_mapeamento_gamepad.gd
## Layout Xbox clássico: stick/D-pad mover · A pular · X atacar · Y arremessar · B interagir ·
## LB Fôlego · RB Surto (+ Rajada, como o R do teclado) · LT defesa · RT correr ·
## Start pausa · Select inventário · stick direito / D-pad cima = mirar.


func _initialize() -> void:
	_limpar_joypad_das_acoes()
	_mapear()
	_gravar_no_projeto()
	var erro := ProjectSettings.save()
	if erro != OK:
		push_error("Não gravou project.godot: %s" % erro)
		quit(1)
		return
	print("Gamepad Xbox aplicado e gravado em project.godot")
	quit(0)


func _limpar_joypad_das_acoes() -> void:
	for acao in InputMap.get_actions():
		if String(acao).begins_with("ui_"):
			continue
		for evento in InputMap.action_get_events(acao):
			if evento is InputEventJoypadButton or evento is InputEventJoypadMotion:
				InputMap.action_erase_event(acao, evento)


func _mapear() -> void:
	_botao(&"pular", JOY_BUTTON_A)
	_botao(&"atacar", JOY_BUTTON_X)
	_botao(&"arremessar", JOY_BUTTON_Y)
	_botao(&"interagir", JOY_BUTTON_B)
	_botao(&"folego", JOY_BUTTON_LEFT_SHOULDER)
	_botao(&"surto_acao", JOY_BUTTON_RIGHT_SHOULDER)
	_botao(&"rajada", JOY_BUTTON_RIGHT_SHOULDER)
	_botao(&"pausa", JOY_BUTTON_START)
	_botao(&"inventario", JOY_BUTTON_BACK)
	_botao(&"mover_esquerda", JOY_BUTTON_DPAD_LEFT)
	_botao(&"mover_direita", JOY_BUTTON_DPAD_RIGHT)
	_botao(&"mover_baixo", JOY_BUTTON_DPAD_DOWN)
	_botao(&"mirar_cima", JOY_BUTTON_DPAD_UP)
	_eixo(&"mover_esquerda", JOY_AXIS_LEFT_X, -1.0)
	_eixo(&"mover_direita", JOY_AXIS_LEFT_X, 1.0)
	_eixo(&"mover_baixo", JOY_AXIS_LEFT_Y, 1.0)
	_eixo(&"mirar_cima", JOY_AXIS_RIGHT_Y, -1.0)
	_eixo(&"correr", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_eixo(&"defesa", JOY_AXIS_TRIGGER_LEFT, 1.0)


func _botao(acao: StringName, botao: JoyButton) -> void:
	if not InputMap.has_action(acao):
		push_warning("Ação inexistente: %s" % acao)
		return
	var evento := InputEventJoypadButton.new()
	evento.device = -1
	evento.button_index = botao
	InputMap.action_add_event(acao, evento)


func _eixo(acao: StringName, eixo: JoyAxis, valor: float) -> void:
	if not InputMap.has_action(acao):
		push_warning("Ação inexistente: %s" % acao)
		return
	var evento := InputEventJoypadMotion.new()
	evento.device = -1
	evento.axis = eixo
	evento.axis_value = valor
	InputMap.action_add_event(acao, evento)


## O InputMap em memória não grava sozinho: copia cada ação de jogo para ProjectSettings.
func _gravar_no_projeto() -> void:
	for acao in InputMap.get_actions():
		var nome := String(acao)
		if nome.begins_with("ui_"):
			continue
		var eventos: Array = []
		for evento in InputMap.action_get_events(acao):
			eventos.append(evento)
		ProjectSettings.set_setting("input/%s" % nome, {
			"deadzone": InputMap.action_get_deadzone(acao),
			"events": eventos,
		})
