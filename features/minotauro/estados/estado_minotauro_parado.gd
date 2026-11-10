extends EstadoMinotauro
## Parado, esperando perceber o herói.


func entrar() -> void:
	minotauro.parar()
	minotauro.tocar(&"parado")


func processar_fisica(_delta: float) -> void:
	minotauro.parar()
	if minotauro.alvo_percebido():
		trocar_para.emit(&"Perseguindo")
