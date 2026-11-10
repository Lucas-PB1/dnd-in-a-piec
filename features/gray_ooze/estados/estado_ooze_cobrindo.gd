extends EstadoOoze
## Cobertura: o herói atirou e há parede perto. Corre (Disparada) até o abrigo e espera.

const SILENCIO := 2.0
const ESPERA_MAXIMA := 5.0
const TEMPO_PARA_CHEGAR := 3.0

var _tempo: float = 0.0
var _no_abrigo: bool = false


func entrar() -> void:
	_tempo = 0.0
	_no_abrigo = false
	ooze.tocar(&"andar")


func processar_fisica(delta: float) -> void:
	_tempo += delta
	if ooze.alvo_ao_alcance():
		trocar_para.emit(&"Perseguindo")
		return
	if not _no_abrigo:
		_correr_ate_o_abrigo()
		return
	ooze.virar_para_alvo()
	if ooze.tempo_sem_disparo() >= SILENCIO or _tempo >= ESPERA_MAXIMA:
		trocar_para.emit(&"Perseguindo")


func _correr_ate_o_abrigo() -> void:
	if ooze.andar_ate(ooze.x_do_abrigo(), true):
		_no_abrigo = true
		_tempo = 0.0
		ooze.parar()
		ooze.tocar(&"parado")
	elif _tempo >= TEMPO_PARA_CHEGAR:
		trocar_para.emit(&"Perseguindo")
