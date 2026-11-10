extends EstadoQuimera
## Investida de cabeçada: depois do aviso corre na Disparada em linha reta com a cabeçada (derruba) ligada. Acaba ao acertar,
## bater na parede, chegar à beira de uma queda ou estourar o tempo.

## Tempo máximo da corrida (s).
const TEMPO_MAXIMO := 1.6
## Quanto tempo ela segue deslizando depois de acertar antes de voltar a perseguir (s).
const PAUSA_APOS_ACERTO := 0.25

var _tempo: float = 0.0
var _correndo: bool = false
var _pausa: float = 0.0


func entrar() -> void:
	_tempo = 0.0
	_pausa = 0.0
	_correndo = false
	quimera.limpar_acerto()
	iniciar_aviso()


func sair() -> void:
	quimera.encerrar_aviso()
	quimera.desligar_golpe()


func processar_fisica(delta: float) -> void:
	if not _correndo:
		quimera.parar()
		if avisando(delta):
			return
		_correndo = true
		quimera.iniciar_investida()
		return
	_tempo += delta
	if quimera.golpe_acertou() or quimera.investida_barrada() or _tempo >= TEMPO_MAXIMO:
		_encerrar(delta)
		return
	quimera.correr_na_investida()


## Freia (a cabeçada já não vale) e, passada a pausa, volta a perseguir.
func _encerrar(delta: float) -> void:
	quimera.desligar_golpe()
	quimera.parar()
	_pausa += delta
	if _pausa >= PAUSA_APOS_ACERTO and not quimera.em_movimento():
		trocar_para.emit(&"Perseguindo")
	elif _pausa >= PAUSA_APOS_ACERTO * 4.0:
		trocar_para.emit(&"Perseguindo")
