extends EstadoQuimera
## Parada, esperando perceber o herói. Ao perceber, desperta e ruge.


func entrar() -> void:
	quimera.parar()
	quimera.tocar(&"parado")


func processar_fisica(_delta: float) -> void:
	quimera.parar()
	if quimera.alvo_percebido():
		quimera.despertar()
		trocar_para.emit(&"Rugindo")
