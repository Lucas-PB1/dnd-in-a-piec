extends EstadoQuimera
## Salto da perseguição (degrau, vão ou queda): o impulso sai de `Quimera.iniciar_salto`; no ar só mantém a corrida e, ao pisar
## no chão de novo, volta a perseguir.

## Tempo mínimo no ar antes de aceitar o pouso (s): no 1º quadro ainda "está no chão".
const TEMPO_MINIMO := 0.08
## Se algo der errado (presa numa quina), volta a perseguir depois deste tempo (s).
const TEMPO_MAXIMO := 2.0

var _tempo: float = 0.0


func entrar() -> void:
	_tempo = 0.0
	quimera.tocar(&"pular")


func processar_fisica(delta: float) -> void:
	_tempo += delta
	quimera.correr_no_ar()
	if (quimera.is_on_floor() and _tempo >= TEMPO_MINIMO) or _tempo >= TEMPO_MAXIMO:
		trocar_para.emit(&"Perseguindo")
