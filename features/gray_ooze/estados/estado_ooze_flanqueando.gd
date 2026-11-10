extends EstadoOoze
## Flanqueio: aliado segura o herói de um lado; este Ooze corre para o lado oposto.

const TEMPO_MAXIMO := 3.0

var _tempo: float = 0.0


func entrar() -> void:
	_tempo = 0.0
	ooze.tocar(&"andar")


func processar_fisica(delta: float) -> void:
	_tempo += delta
	if ooze.andar_ate(ooze.x_do_flanco(), true) or _tempo >= TEMPO_MAXIMO:
		ooze.parar()
		trocar_para.emit(&"Perseguindo")
