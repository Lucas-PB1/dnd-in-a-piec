extends EstadoAnkheg
## Parado, esperando perceber o herói (Sentido Sísmico e Visão no Escuro).


func entrar() -> void:
	ankheg.parar()
	ankheg.tocar(&"parado")


func processar_fisica(_delta: float) -> void:
	ankheg.parar()
	if ankheg.alvo_percebido():
		trocar_para.emit(&"Perseguindo")
