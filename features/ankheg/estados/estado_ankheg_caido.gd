extends EstadoAnkheg
## Caído (maestria Derrubar): deitado, sem andar nem atacar, até a condição acabar.


func entrar() -> void:
	ankheg.parar()
	ankheg.desligar_golpe()
	ankheg.desligar_borrifo()
	ankheg.tocar(&"parado")
	ankheg.deitar(true)


func sair() -> void:
	ankheg.deitar(false)


func processar_fisica(_delta: float) -> void:
	ankheg.parar()
	if not ankheg.esta_caido():
		trocar_para.emit(&"Perseguindo")
