extends EstadoAnkheg
## Sai do chão: a terra treme um instante no ponto (o herói ainda pode sair de cima) e então o Ankheg aparece mordendo
## de surpresa (vantagem, sem aviso).

## Quanto a terra avisa antes de o Ankheg sair (s).
const AVISO_DA_TERRA := 0.6

var _tempo: float = 0.0
var _x: float = 0.0


func entrar() -> void:
	_tempo = 0.0
	_x = ankheg.global_position.x
	ankheg.parar()


func processar_fisica(delta: float) -> void:
	_tempo += delta
	if _tempo < AVISO_DA_TERRA:
		return
	ankheg.emergir_em(_x)
	trocar_para.emit(&"Mordendo")
