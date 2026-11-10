extends EstadoGoblin
## Vida zerou: toca a animação `morrer`, se a arte tem, e some em fumaça (`DissolverComponent`); sem ela, some na hora.

var _dissolvendo: bool = false


func entrar() -> void:
	_dissolvendo = false
	goblin.parar()
	if goblin.tem_animacao(&"morrer"):
		goblin.tocar(&"morrer")
	else:
		_dissolver()


func processar_fisica(_delta: float) -> void:
	goblin.parar()
	if not _dissolvendo and goblin.animacao_terminou():
		_dissolver()


func _dissolver() -> void:
	_dissolvendo = true
	goblin.dissolver()
