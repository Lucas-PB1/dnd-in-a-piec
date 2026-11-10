extends EstadoQuimera
## Caída (maestria Derrubar): deitada, sem andar nem atacar, até a condição acabar.


func entrar() -> void:
	quimera.terminar_voo()  # derrubada no meio do voo: cai
	quimera.parar()
	quimera.desligar_golpe()
	quimera.desligar_sopro()
	quimera.deitar(true)


func processar_fisica(_delta: float) -> void:
	quimera.parar()
	if not quimera.esta_caido():
		trocar_para.emit(&"Perseguindo")
