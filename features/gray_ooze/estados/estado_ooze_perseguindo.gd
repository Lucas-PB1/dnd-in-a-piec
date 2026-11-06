extends EstadoOoze
## Vai na direção do alvo. Ao alcance, espera a rodada e ataca. Perdeu o alvo, para.


func processar_fisica(_delta: float) -> void:
	if not ooze.alvo_percebido():
		trocar_para.emit(&"Parado")
		return
	if not ooze.alvo_ao_alcance():
		ooze.andar_para_alvo()
		ooze.tocar(&"andar")
		return
	ooze.parar()
	ooze.virar_para_alvo()
	ooze.tocar(&"parado")
	if ooze.pode_atacar():
		trocar_para.emit(&"Atacando")
