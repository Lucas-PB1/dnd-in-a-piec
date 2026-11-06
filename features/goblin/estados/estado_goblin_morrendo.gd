extends EstadoGoblin
## Vida zerou: toca a animação de morte e some.


func entrar() -> void:
	goblin.parar()
	goblin.tocar(&"morrer")


func processar_fisica(_delta: float) -> void:
	if goblin.animacao_terminou():
		goblin.terminar_de_morrer()
