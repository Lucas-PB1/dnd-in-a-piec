extends EstadoMinotauro
## Caído (maestria Derrubar): deitado, sem andar nem atacar, até a condição acabar.


func entrar() -> void:
	minotauro.parar()
	minotauro.desligar_glaive()
	minotauro.desligar_chifres()
	minotauro.tocar(&"parado")
	minotauro.deitar(true)


func sair() -> void:
	minotauro.deitar(false)


func processar_fisica(_delta: float) -> void:
	minotauro.parar()
	if not minotauro.esta_caido():
		trocar_para.emit(&"Perseguindo")
