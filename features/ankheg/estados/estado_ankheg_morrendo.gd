extends EstadoAnkheg
## Vida zerou: pisca e some em fumaça (morte por código, `DissolverComponent`).


func entrar() -> void:
	ankheg.parar()
	ankheg.dissolver()
