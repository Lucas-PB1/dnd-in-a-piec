extends EstadoAnkheg
## Escavação: some no chão e avança por baixo, na direção do herói (a terra se mexendo é o aviso). Ao chegar, ou se o
## tempo acabar, passa a Emergindo.

## Tempo máximo debaixo da terra antes de emergir onde estiver (s).
const TEMPO_MAXIMO := 6.0

var _tempo: float = 0.0


func entrar() -> void:
	_tempo = 0.0
	ankheg.parar()
	ankheg.esconder()


func processar_fisica(delta: float) -> void:
	_tempo += delta
	if ankheg.alvo == null or ankheg.cavar_ate(ankheg.alvo.global_position.x) or _tempo >= TEMPO_MAXIMO:
		trocar_para.emit(&"Emergindo")
