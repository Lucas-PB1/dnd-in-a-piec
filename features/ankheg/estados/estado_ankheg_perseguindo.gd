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
		ankheg.andar_para_alvo()
		ankheg.tocar(&"andar")


func _esperar_vez(proximo: StringName) -> void:
	ankheg.parar()
	ankheg.virar_para_alvo()
	ankheg.tocar(&"parado")
	if ankheg.pode_atacar():
		trocar_para.emit(proximo)
