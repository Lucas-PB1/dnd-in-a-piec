extends EstadoGoblin
## Foi acertado: para, treme, pisca e volta a perseguir (a arte não tem animação de dano).

## Quanto tempo fica atordoado (s).
const DURACAO := 0.25

var _tempo: float = 0.0


func entrar() -> void:
	_tempo = 0.0
	goblin.parar()
	goblin.desligar_golpe()
	goblin.tocar(&"parado")
	goblin.piscar(true)
	goblin.tremer(DURACAO)


func sair() -> void:
	goblin.piscar(false)
	goblin.parar_tremor()


func processar_fisica(delta: float) -> void:
	_tempo += delta
	if _tempo >= DURACAO:
		trocar_para.emit(&"Perseguindo")
