extends EstadoOoze
## Vida zerou: derrete (animação de morte) e some.


func entrar() -> void:
	ooze.parar()
	ooze.tocar(&"morrer")


func processar_fisica(_delta: float) -> void:
	if ooze.animacao_terminou():
		ooze.terminar_de_morrer()
