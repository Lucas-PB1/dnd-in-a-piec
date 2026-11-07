class_name EstadoOoze
extends Estado
## Base dos estados do Gray Ooze: guarda a referência a ele e o aviso antes do golpe.

var ooze: GrayOoze
## Quanto falta do aviso (s). 0 = sem aviso (ou já acabou).
var _aviso: float = 0.0


func configurar(dono: Node) -> void:
	ooze = dono as GrayOoze


## Começa o aviso antes do Pseudópode (a duração vem da ficha).
func iniciar_aviso() -> void:
	_aviso = ooze.tempo_aviso()
	if _aviso > 0.0:
		ooze.preparar_aviso()


## True enquanto ainda avisa: o estado espera. No quadro em que acaba, apaga o brilho.
func avisando(delta: float) -> bool:
	if _aviso <= 0.0:
		return false
	_aviso -= delta
	if _aviso > 0.0:
		return true
	ooze.encerrar_aviso()
	return false
