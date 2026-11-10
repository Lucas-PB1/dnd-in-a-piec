extends EstadoWight
## Ataques Múltiplos (corpo a corpo): depois do aviso, dois ataques seguidos; cada um é a Espada Necrótica ou o Drenar Vida
## (que substitui um ataque). Só acerta na janela do golpe de cada animação.

var _tempo: float = 0.0
var _ligado: bool = false
var _comecou: bool = false
var _restantes: int = 0
var _drenar: bool = false


func entrar() -> void:
	_comecou = false
	_restantes = Wight.ATAQUES_POR_ACAO
	iniciar_aviso()


func sair() -> void:
	wight.encerrar_aviso()
	wight.desligar_golpe()


func processar_fisica(delta: float) -> void:
	if not _comecou:
		if avisando(delta):
			return
		_comecou = true
		_comecar_ataque()
		return
	_tempo += delta
	var na_janela := _tempo >= wight.inicio_acerto and _tempo < wight.fim_acerto
	if na_janela and not _ligado:
		wight.ligar_golpe(_drenar)
		_ligado = true
	elif not na_janela and _ligado:
		wight.desligar_golpe()
		_ligado = false
	if wight.animacao_terminou():
		_ao_terminar_ataque()


func _comecar_ataque() -> void:
	_tempo = 0.0
	_ligado = false
	_drenar = wight.sortear_drenar()
	wight.iniciar_ataque(&"drenar" if _drenar else &"espada")


func _ao_terminar_ataque() -> void:
	wight.desligar_golpe()
	_restantes -= 1
	if _restantes > 0 and wight.alvo_ao_alcance():
		_comecar_ataque()
	else:
		trocar_para.emit(&"Perseguindo")
