extends EstadoWight
## Ataques Múltiplos (à distância): depois do aviso, duas flechas do Arco Necrótico, cada uma soltando no quadro da animação.

var _tempo: float = 0.0
var _soltou: bool = false
var _comecou: bool = false
var _restantes: int = 0


func entrar() -> void:
	_comecou = false
	_restantes = Wight.ATAQUES_POR_ACAO
	iniciar_aviso()


func sair() -> void:
	wight.encerrar_aviso()


func processar_fisica(delta: float) -> void:
	if not _comecou:
		if avisando(delta):
			return
		_comecou = true
		_comecar_tiro()
		return
	_tempo += delta
	if _tempo >= wight.momento_soltura and not _soltou:
		wight.atirar()
		_soltou = true
	if wight.animacao_terminou():
		_ao_terminar_tiro()


func _comecar_tiro() -> void:
	_tempo = 0.0
	_soltou = false
	wight.iniciar_ataque(&"arco")


func _ao_terminar_tiro() -> void:
	_restantes -= 1
	if _restantes > 0 and wight.alvo_percebido():
		_comecar_tiro()
	else:
		trocar_para.emit(&"Perseguindo")
