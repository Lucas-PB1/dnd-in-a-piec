extends EstadoOoze
## Vai na direção do alvo. Prioriza cobertura, flanqueio e afastamento; ao alcance, ataca.


func processar_fisica(_delta: float) -> void:
	if not ooze.alvo_percebido():
		trocar_para.emit(&"Parado")
		return
	if ooze.quer_cobertura():
		trocar_para.emit(&"Cobrindo")
	elif ooze.quer_flanquear():
		trocar_para.emit(&"Flanqueando")
	elif ooze.quer_afastar():
		trocar_para.emit(&"Afastando")
	elif not ooze.alvo_ao_alcance():
		_andar_ou_saltar()
	else:
		ooze.parar()
		ooze.virar_para_alvo()
		ooze.tocar(&"parado")
		if ooze.pode_atacar():
			trocar_para.emit(&"Atacando")


## Anda até o alvo; diante de parede, degrau, vão ou queda que vale transpor, salta.
func _andar_ou_saltar() -> void:
	var plano := ooze.planejar_salto()
	if plano.tipo != SaltoDnd.Tipo.NENHUM:
		ooze.iniciar_salto(plano)
		trocar_para.emit(&"Pulando")
		return
	ooze.andar_para_alvo()
	ooze.tocar(&"andar" if not is_zero_approx(ooze.velocity.x) else &"parado")
