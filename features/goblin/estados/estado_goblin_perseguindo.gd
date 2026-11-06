extends EstadoGoblin
## Ao alcance do golpe: espera a rodada e ataca. Longe, se ainda dá para arremessar ou
## atirar dentro do alcance longo: para e solta. Senão corre até o alvo. Perdeu o alvo, para.


func processar_fisica(_delta: float) -> void:
	if not goblin.alvo_percebido():
		trocar_para.emit(&"Parado")
		return
	if goblin.alvo_ao_alcance():
		_esperar_vez(&"Atacando")
	elif goblin.pode_arremessar():
		_esperar_vez(&"Arremessando")
	elif goblin.pode_atirar() and goblin.pode_disparar():
		_esperar_vez(&"Arremessando")
	else:
		goblin.andar_para_alvo()
		goblin.tocar(&"correr")


func _esperar_vez(proximo: StringName) -> void:
	goblin.parar()
	goblin.virar_para_alvo()
	goblin.tocar(&"parado")
	if goblin.pode_atacar():
		trocar_para.emit(proximo)
