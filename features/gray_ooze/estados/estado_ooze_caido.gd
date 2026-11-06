extends EstadoOoze
## Caído (maestria Derrubar): fica deitado, sem andar nem atacar, até a condição acabar
## (meia rodada: levantar gasta metade do deslocamento). Ataques contra ele têm vantagem.


func entrar() -> void:
	ooze.parar()
	ooze.desligar_pseudopode()
	ooze.tocar(&"parado")
	ooze.deitar(true)


func sair() -> void:
	ooze.deitar(false)


func processar_fisica(_delta: float) -> void:
	ooze.parar()
	if not ooze.esta_caido():
		trocar_para.emit(&"Perseguindo")
