extends EstadoOoze
## Vida zerou: pisca e some em fumaça (morte por código, `DissolverComponent`).


func entrar() -> void:
	ooze.parar()
	ooze.dissolver()
