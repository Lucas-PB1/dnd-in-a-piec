extends TesteBase
## Confere o mapeamento Xbox no InputMap e que Comandos não apaga o joypad.


func _initialize() -> void:
	_checar_mapeamento()
	_checar_eventos_disparam_acoes()
	_checar_comandos_preserva_joypad()
	_terminar("gamepad Xbox no InputMap")


func _checar_mapeamento() -> void:
	_checar(_tem_botao(&"pular", JOY_BUTTON_A), "A → pular")
	_checar(_tem_botao(&"atacar", JOY_BUTTON_X), "X → atacar")
	_checar(_tem_botao(&"arremessar", JOY_BUTTON_Y), "Y → arremessar")
	_checar(_tem_botao(&"interagir", JOY_BUTTON_B), "B → interagir")
	_checar(_tem_botao(&"folego", JOY_BUTTON_LEFT_SHOULDER), "LB → Fôlego")
	_checar(_tem_botao(&"surto_acao", JOY_BUTTON_RIGHT_SHOULDER), "RB → Surto")
	_checar(_tem_botao(&"pausa", JOY_BUTTON_START), "Start → pausa")
	_checar(_tem_botao(&"inventario", JOY_BUTTON_BACK), "Select → inventário")
	_checar(_tem_botao(&"mover_esquerda", JOY_BUTTON_DPAD_LEFT), "D-pad ← mover")
	_checar(_tem_botao(&"mover_direita", JOY_BUTTON_DPAD_RIGHT), "D-pad → mover")
	_checar(_tem_botao(&"mover_baixo", JOY_BUTTON_DPAD_DOWN), "D-pad ↓ abaixar")
	_checar(_tem_botao(&"mirar_cima", JOY_BUTTON_DPAD_UP), "D-pad ↑ mirar")
	_checar(_tem_eixo(&"mover_esquerda", JOY_AXIS_LEFT_X, -1.0), "stick esq. ←")
	_checar(_tem_eixo(&"mover_direita", JOY_AXIS_LEFT_X, 1.0), "stick esq. →")
	_checar(_tem_eixo(&"correr", JOY_AXIS_TRIGGER_RIGHT, 1.0), "RT → correr")
	_checar(_tem_eixo(&"defesa", JOY_AXIS_TRIGGER_LEFT, 1.0), "LT → defesa")
	_checar(_tem_eixo(&"mirar_cima", JOY_AXIS_RIGHT_Y, -1.0), "stick dir. ↑ mirar")


func _checar_eventos_disparam_acoes() -> void:
	var apertar := InputEventJoypadButton.new()
	apertar.device = 0
	apertar.button_index = JOY_BUTTON_A
	apertar.pressed = true
	_checar(InputMap.event_is_action(apertar, &"pular", true), "evento A casa com pular")
	var eixo := InputEventJoypadMotion.new()
	eixo.device = 0
	eixo.axis = JOY_AXIS_TRIGGER_RIGHT
	eixo.axis_value = 1.0
	_checar(InputMap.event_is_action(eixo, &"correr", true), "evento RT casa com correr")


func _checar_comandos_preserva_joypad() -> void:
	var antes := _contar_joypad(&"atacar")
	_checar(antes > 0, "atacar já tem evento de gamepad")
	Comandos.aplicar_tecla(&"atacar", KEY_U)
	_checar(_contar_joypad(&"atacar") == antes, "trocar tecla mantém joypad em atacar")
	_checar(Comandos.tecla_de(&"atacar") == OS.get_keycode_string(KEY_U), "tecla nova ficou")
	Comandos.aplicar_tecla(&"atacar", KEY_J)
	_checar(_contar_joypad(&"atacar") == antes, "restaurar tecla mantém joypad")
	_checar(Comandos.tecla_de(&"atacar") == OS.get_keycode_string(KEY_J), "J voltou em atacar")


func _tem_botao(acao: StringName, botao: JoyButton) -> bool:
	for evento in InputMap.action_get_events(acao):
		if evento is InputEventJoypadButton and (evento as InputEventJoypadButton).button_index == botao:
			return true
	return false


func _tem_eixo(acao: StringName, eixo: JoyAxis, valor: float) -> bool:
	for evento in InputMap.action_get_events(acao):
		if evento is InputEventJoypadMotion:
			var motion := evento as InputEventJoypadMotion
			if motion.axis == eixo and is_equal_approx(motion.axis_value, valor):
				return true
	return false


func _contar_joypad(acao: StringName) -> int:
	var total := 0
	for evento in InputMap.action_get_events(acao):
		if evento is InputEventJoypadButton or evento is InputEventJoypadMotion:
			total += 1
	return total
