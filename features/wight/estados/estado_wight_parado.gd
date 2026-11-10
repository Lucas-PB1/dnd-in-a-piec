extends EstadoWight
## Parado, esperando perceber o herói. Ao perceber, desperta (a main faz surgirem os acompanhantes) e parte para cima.


func entrar() -> void:
	wight.parar()
	wight.tocar(&"parado")


func processar_fisica(_delta: float) -> void:
	wight.parar()
	if wight.alvo_percebido():
		wight.despertar()
		trocar_para.emit(&"Perseguindo")
