extends EstadoOoze
## Parado, esperando perceber um alvo (Visão às Cegas).


func entrar() -> void:
	ooze.parar()
	ooze.tocar(&"parado")


func processar_fisica(_delta: float) -> void:
	if ooze.alvo_percebido():
		trocar_para.emit(&"Perseguindo")
