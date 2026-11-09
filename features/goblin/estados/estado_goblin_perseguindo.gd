extends EstadoGoblin
## Ao alcance do golpe: espera a rodada e ataca. Longe, se ainda dá para arremessar ou
## atirar dentro do alcance longo: para e solta. Senão corre até o alvo. Perdeu o alvo, para.


func processar_fisica(_delta: float) -> void:
	if not goblin.alvo_percebido():
		trocar_para.emit(&"Parado")
		return
	if goblin.quer_cobertura():
		trocar_para.emit(&"Cobrindo")
	elif goblin.quer_flanquear():
		trocar_para.emit(&"Flanqueando")
	elif goblin.quer_afastar():
		trocar_para.emit(&"Afastando")
	elif goblin.alvo_ao_alcance():
		_esperar_vez(&"Atacando")
	elif goblin.pode_arremessar():
		_esperar_vez(&"Arremessando")
	elif goblin.pode_atirar() and goblin.pode_disparar():
		_esperar_vez(&"Arremessando")
	else:
		_correr_ou_saltar()


## Corre até o alvo; diante de parede, degrau, vão ou queda que vale transpor, salta.
func _correr_ou_saltar() -> void:
	var plano := goblin.planejar_salto()
	if plano.tipo != SaltoDnd.Tipo.NENHUM:
		goblin.iniciar_salto(plano)
		trocar_para.emit(&"Pulando")
		return
	goblin.andar_para_alvo()
	goblin.tocar(&"correr")


func _esperar_vez(proximo: StringName) -> void:
	goblin.parar()
	goblin.virar_para_alvo()
	goblin.tocar(&"parado")
	if goblin.pode_atacar():
		trocar_para.emit(proximo)
