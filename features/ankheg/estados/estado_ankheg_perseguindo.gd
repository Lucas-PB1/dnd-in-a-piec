extends EstadoAnkheg
## Decide a próxima ação: cavar para surpreender (longe), morder (ao alcance), borrifar ácido (na linha) ou andar até o herói.


func processar_fisica(_delta: float) -> void:
	if not ankheg.alvo_percebido():
		trocar_para.emit(&"Parado")
	elif ankheg.quer_cavar():
		trocar_para.emit(&"Cavando")
	elif ankheg.alvo_ao_alcance():
		_esperar_vez(&"Mordendo")
	elif ankheg.quer_borrifar():
		_esperar_vez(&"Borrifando")
	else:
		_andar_ou_saltar()


## Anda até o herói; diante de parede, degrau, vão ou queda que vale transpor, salta (como os goblins).
func _andar_ou_saltar() -> void:
	var plano := ankheg.planejar_salto()
	if plano.tipo != SaltoDnd.Tipo.NENHUM:
		ankheg.iniciar_salto(plano)
		trocar_para.emit(&"Pulando")
		return
	if ankheg.quer_cavar_para_transpor():
		trocar_para.emit(&"Cavando")
		return
	ankheg.andar_para_alvo()
	ankheg.tocar(&"andar")


func _esperar_vez(proximo: StringName) -> void:
	ankheg.parar()
	ankheg.virar_para_alvo()
	ankheg.tocar(&"parado")
	if ankheg.pode_atacar():
		trocar_para.emit(proximo)
