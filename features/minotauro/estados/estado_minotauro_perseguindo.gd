extends EstadoMinotauro
## Decide a próxima ação: investir com a Chifrada (herói longe e a recarga pronta), golpear com o glaive (ao alcance, ou
## para quebrar o bloco que barra o caminho) ou andar até o herói.


func processar_fisica(_delta: float) -> void:
	if not minotauro.alvo_percebido():
		trocar_para.emit(&"Parado")
	elif minotauro.quer_investir():
		_esperar_vez(&"Investindo")
	elif minotauro.alvo_ao_alcance() or minotauro.bloqueado_por_bloco():
		_esperar_vez(&"Atacando")
	else:
		_correr_ou_saltar()


## Anda até o herói; diante de parede, degrau, vão ou queda que vale transpor, salta.
func _correr_ou_saltar() -> void:
	var plano := minotauro.planejar_salto()
	if plano.tipo != SaltoDnd.Tipo.NENHUM:
		minotauro.iniciar_salto(plano)
		trocar_para.emit(&"Pulando")
		return
	minotauro.andar_para_alvo()
	minotauro.tocar(&"andar" if not is_zero_approx(minotauro.velocity.x) else &"parado")  # na beira de um vão grande ele só espera


func _esperar_vez(proximo: StringName) -> void:
	minotauro.parar()
	minotauro.virar_para_alvo()
	minotauro.tocar(&"parado")
	if minotauro.pode_atacar():
		trocar_para.emit(proximo)
