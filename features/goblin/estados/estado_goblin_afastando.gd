extends EstadoGoblin
## Estratégia: recua de costas, de olho no herói (na Disparada, que gasta a ação: não ataca enquanto corre).
## Para manter distância ele volta a atirar assim que ganha espaço; ferido, vai embora do herói na esperança de
## achar os aliados. Termina ao se afastar o bastante, no tempo limite, ou ao bater numa parede ou na beira.

## Tempo máximo recuando para manter distância (s): uma rodada (1,5 s) menos o que o tiro já pede.
const TEMPO_DISTANCIA := 1.0
## Tempo máximo recuando ferido (s).
const TEMPO_FERIDO := 3.0

var _tempo: float = 0.0


func entrar() -> void:
	_tempo = 0.0
	goblin.tocar(&"correr")


func processar_fisica(delta: float) -> void:
	_tempo += delta
	goblin.virar_para_alvo()
	goblin.recuar()
	var limite := TEMPO_FERIDO if goblin.motivo_afastar() == Goblin.MOTIVO_FERIDO else TEMPO_DISTANCIA
	if _tempo >= limite or goblin.afastado_o_bastante() or is_zero_approx(goblin.velocity.x):
		goblin.parar()
		trocar_para.emit(&"Perseguindo")
