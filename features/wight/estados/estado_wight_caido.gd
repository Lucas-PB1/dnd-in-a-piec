extends EstadoWight
## Caído (maestria Derrubar): deitado, sem andar nem atacar, até a condição acabar.


func entrar() -> void:
	wight.parar()
	wight.desligar_golpe()
	wight.tocar(&"parado")
	wight.deitar(true)


func sair() -> void:
	wight.deitar(false)


func processar_fisica(_delta: float) -> void:
	wight.parar()
	if not wight.esta_caido():
		trocar_para.emit(&"Perseguindo")
