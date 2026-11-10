class_name EstadoWight
extends Estado
## Base dos estados do Wight: guarda a referência a ele e o aviso antes do ataque.

var wight: Wight
## Quanto falta do aviso (s). 0 = sem aviso (ou já acabou).
var _aviso: float = 0.0


func configurar(dono: Node) -> void:
	wight = dono as Wight


## Começa o aviso (parado e brilhando) antes da sequência de ataques.
func iniciar_aviso() -> void:
	_aviso = wight.tempo_aviso()
	if _aviso > 0.0:
		wight.preparar_aviso()


## True enquanto ainda avisa: o estado espera. No quadro em que acaba, apaga o brilho.
func avisando(delta: float) -> bool:
	if _aviso <= 0.0:
		return false
	_aviso -= delta
	if _aviso > 0.0:
		return true
	wight.encerrar_aviso()
	return false
