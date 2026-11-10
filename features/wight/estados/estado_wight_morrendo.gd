extends EstadoWight
## Vida zerou: pisca e some em fumaça (morte por código, `DissolverComponent`).


func entrar() -> void:
	wight.parar()
	wight.dissolver()
