extends EstadoGoblin
## Caído (maestria Derrubar): deitado, sem andar nem atacar, até a condição acabar.
## Ataques contra ele têm vantagem.


func entrar() -> void:
	goblin.parar()
	goblin.desligar_golpe()
	goblin.tocar(&"parado")
	goblin.deitar(true)


func sair() -> void:
	goblin.deitar(false)


func processar_fisica(_delta: float) -> void:
	goblin.parar()
	if not goblin.esta_caido():
		trocar_para.emit(&"Perseguindo")
