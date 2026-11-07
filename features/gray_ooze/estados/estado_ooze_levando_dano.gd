extends EstadoOoze
## Foi acertado: treme (e toca a animação de dano) e volta a perseguir quando ela acaba.

## Quanto tempo o sprite treme (s).
const DURACAO_TREMOR := 0.25


func entrar() -> void:
	ooze.parar()
	ooze.desligar_pseudopode()
	ooze.tocar(&"dano")
	ooze.tremer(DURACAO_TREMOR)


func sair() -> void:
	ooze.parar_tremor()


func processar_fisica(_delta: float) -> void:
	if ooze.animacao_terminou():
		trocar_para.emit(&"Perseguindo")
