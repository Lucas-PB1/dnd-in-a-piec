extends EstadoMinotauro
## Vida zerou: pisca e some em fumaça (morte por código, `DissolverComponent`).


func entrar() -> void:
	minotauro.parar()
	minotauro.dissolver()
