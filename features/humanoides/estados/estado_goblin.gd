class_name EstadoGoblin
extends Estado
## Base dos estados do Goblin: guarda a referência a ele e o aviso antes do golpe.

var goblin: Goblin
## Quanto falta do aviso (s). 0 = sem aviso (ou já acabou).
var _aviso: float = 0.0


func configurar(dono: Node) -> void:
	goblin = dono as Goblin


## Começa o aviso antes do golpe ou do tiro (a duração vem da ficha; 0 na emboscada).
func iniciar_aviso() -> void:
	_aviso = goblin.tempo_aviso()
	if _aviso > 0.0:
		goblin.preparar_aviso()


## True enquanto ainda avisa: o estado espera. No quadro em que acaba, apaga o brilho.
func avisando(delta: float) -> bool:
	if _aviso <= 0.0:
		return false
	_aviso -= delta
	if _aviso > 0.0:
		return true
	goblin.encerrar_aviso()
	return false
