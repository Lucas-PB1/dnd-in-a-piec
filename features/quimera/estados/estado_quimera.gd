class_name EstadoQuimera
extends Estado
## Base dos estados da Quimera: guarda a referência a ela e o aviso antes do ataque.

var quimera: Quimera
## Quanto falta do aviso (s). 0 = sem aviso (ou já acabou).
var _aviso: float = 0.0


func configurar(dono: Node) -> void:
	quimera = dono as Quimera


## Começa o aviso (ela se encolhe e brilha) antes do ataque.
func iniciar_aviso() -> void:
	_aviso = quimera.tempo_aviso()
	if _aviso > 0.0:
		quimera.preparar_aviso()


## True enquanto ainda avisa: o estado espera. No quadro em que acaba, apaga o brilho.
func avisando(delta: float) -> bool:
	if _aviso <= 0.0:
		return false
	_aviso -= delta
	if _aviso > 0.0:
		return true
	quimera.encerrar_aviso()
	return false
