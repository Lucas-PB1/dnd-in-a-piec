extends EstadoGoblin
## Flanqueio: um aliado já segura o herói de um lado; este monstro corre (Disparada) para o lado oposto, passando
## por ele (os monstros não colidem com o herói), e volta a perseguir: ao golpear dali, ataca com vantagem.

## Se não chegar ao outro lado neste tempo (s), desiste.
const TEMPO_MAXIMO := 3.0

var _tempo: float = 0.0


func entrar() -> void:
	_tempo = 0.0
	goblin.tocar(&"correr")


func processar_fisica(delta: float) -> void:
	_tempo += delta
	if goblin.andar_ate(goblin.x_do_flanco(), true) or _tempo >= TEMPO_MAXIMO:
		goblin.parar()
		trocar_para.emit(&"Perseguindo")
