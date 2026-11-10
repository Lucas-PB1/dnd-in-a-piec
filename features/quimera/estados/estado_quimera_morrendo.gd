extends EstadoQuimera
## Vida zerou: toca a animação da queda e, quando ela deita, some em fumaça (`DissolverComponent`).

var _dissolvendo: bool = false


func entrar() -> void:
	_dissolvendo = false
	quimera.terminar_voo()
	quimera.parar()
	quimera.tocar(&"morte")


func processar_fisica(_delta: float) -> void:
	quimera.parar()
	if not _dissolvendo and quimera.animacao_terminou():
		_dissolvendo = true
		quimera.dissolver()
