class_name EstadoAnkheg
extends Estado
## Base dos estados do Ankheg: guarda a referência a ele e o aviso antes do ataque.

var ankheg: Ankheg
## Quanto falta do aviso (s). 0 = sem aviso (ou já acabou).
var _aviso: float = 0.0


func configurar(dono: Node) -> void:
	ankheg = dono as Ankheg


func iniciar_aviso() -> void:
	_aviso = ankheg.tempo_aviso()
	if _aviso > 0.0:
		ankheg.preparar_aviso()


## True enquanto ainda avisa: o estado espera. No quadro em que acaba, apaga o brilho.
func avisando(delta: float) -> bool:
	if _aviso <= 0.0:
		return false
	_aviso -= delta
	if _aviso > 0.0:
		return true
	ankheg.encerrar_aviso()
	return false
