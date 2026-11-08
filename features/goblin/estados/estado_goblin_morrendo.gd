extends EstadoGoblin
## Vida zerou: pisca e some em fumaça (morte por código, `DissolverComponent`).


func entrar() -> void:
	goblin.parar()
	goblin.dissolver()
