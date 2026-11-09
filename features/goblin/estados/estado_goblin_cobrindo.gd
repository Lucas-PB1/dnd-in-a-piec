extends EstadoGoblin
## Cobertura: o herói atirou e há uma parede perto. Corre (Disparada) até o abrigo, espera de olho no herói e só
## sai quando ele para de atirar, chega perto ou a espera acaba. Quem tem arco ou adagas não atira daqui: a parede
## está na frente (`pode_atirar` exige linha livre), então sai do abrigo para achar um ângulo.

## Segundos sem tiro do herói para considerar seguro sair.
const SILENCIO := 2.0
## Espera máxima no abrigo (s).
const ESPERA_MAXIMA := 5.0
## Se não chegar ao abrigo neste tempo (s), desiste e volta a perseguir.
const TEMPO_PARA_CHEGAR := 3.0

var _tempo: float = 0.0
var _no_abrigo: bool = false


func entrar() -> void:
	_tempo = 0.0
	_no_abrigo = false
	goblin.tocar(&"correr")


func processar_fisica(delta: float) -> void:
	_tempo += delta
	if goblin.alvo_ao_alcance():
		trocar_para.emit(&"Perseguindo")
		return
	if not _no_abrigo:
		_correr_ate_o_abrigo()
		return
	goblin.virar_para_alvo()
	if goblin.tempo_sem_disparo() >= SILENCIO or _tempo >= ESPERA_MAXIMA:
		trocar_para.emit(&"Perseguindo")


func _correr_ate_o_abrigo() -> void:
	if goblin.andar_ate(goblin.x_do_abrigo(), true):
		_no_abrigo = true
		_tempo = 0.0
		goblin.parar()
		goblin.tocar(&"parado")
	elif _tempo >= TEMPO_PARA_CHEGAR:
		trocar_para.emit(&"Perseguindo")
