extends EstadoWight
## Decide a próxima ação: golpear de perto (espada ou Drenar Vida), atirar com o arco (herói longe, com linha de tiro) ou
## andar até o herói.


func processar_fisica(_delta: float) -> void:
	if not wight.alvo_percebido():
		trocar_para.emit(&"Parado")
	elif wight.alvo_ao_alcance():
		_esperar_vez(&"Atacando")
	elif wight.quer_atirar():
		_esperar_vez(&"Atirando")
	else:
		_correr_ou_saltar()


## Anda até o herói; diante de parede, degrau, vão ou queda que vale transpor, salta.
func _correr_ou_saltar() -> void:
	var plano := wight.planejar_salto()
	if plano.tipo != SaltoDnd.Tipo.NENHUM:
		wight.iniciar_salto(plano)
		trocar_para.emit(&"Pulando")
		return
	wight.andar_para_alvo()
	wight.tocar(&"andar" if not is_zero_approx(wight.velocity.x) else &"parado")  # na beira de um vão grande ele só espera


func _esperar_vez(proximo: StringName) -> void:
	wight.parar()
	wight.virar_para_alvo()
	wight.tocar(&"parado")
	if wight.pode_atacar():
		trocar_para.emit(proximo)
