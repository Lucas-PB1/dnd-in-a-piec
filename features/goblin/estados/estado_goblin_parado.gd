extends EstadoGoblin
## Parado, esperando perceber um alvo (Visão no Escuro).


func entrar() -> void:
	goblin.parar()
	goblin.tocar(&"parado")


func processar_fisica(_delta: float) -> void:
	if goblin.alvo_percebido():
		trocar_para.emit(&"Perseguindo")
