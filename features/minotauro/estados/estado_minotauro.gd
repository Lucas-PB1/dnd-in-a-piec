class_name EstadoMinotauro
extends Estado
## Base dos estados do Minotauro: guarda a referência a ele e o aviso antes do ataque.

var minotauro: Minotauro
## Quanto falta do aviso (s). 0 = sem aviso (ou já acabou).
var _aviso: float = 0.0


func configurar(dono: Node) -> void:
	minotauro = dono as Minotauro


## Começa o aviso (parado e brilhando, na pose `animacao`) antes do golpe.
func iniciar_aviso(animacao: StringName) -> void:
	_aviso = minotauro.tempo_aviso()
	if _aviso > 0.0:
		minotauro.preparar_aviso(animacao)


## True enquanto ainda avisa: o estado espera. No quadro em que acaba, apaga o brilho.
func avisando(delta: float) -> bool:
	if _aviso <= 0.0:
		return false
	_aviso -= delta
	if _aviso > 0.0:
		return true
	minotauro.encerrar_aviso()
	return false
