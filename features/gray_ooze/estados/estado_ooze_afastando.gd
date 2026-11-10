extends EstadoOoze
## Estratégia: recua de costas (Disparada). Ooze sem ataque à distância só usa o motivo ferido.

const TEMPO_DISTANCIA := 1.0
const TEMPO_FERIDO := 3.0

var _tempo: float = 0.0


func entrar() -> void:
	_tempo = 0.0
	ooze.tocar(&"andar")


func processar_fisica(delta: float) -> void:
	_tempo += delta
	ooze.virar_para_alvo()
	ooze.recuar()
	var limite := TEMPO_FERIDO if ooze.motivo_afastar() == GrayOoze.MOTIVO_FERIDO else TEMPO_DISTANCIA
	if _tempo >= limite or ooze.afastado_o_bastante() or is_zero_approx(ooze.velocity.x):
		ooze.parar()
		trocar_para.emit(&"Perseguindo")
