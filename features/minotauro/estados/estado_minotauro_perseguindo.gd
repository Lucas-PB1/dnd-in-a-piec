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
		minotauro.andar_para_alvo()
		minotauro.tocar(&"andar")


func _esperar_vez(proximo: StringName) -> void:
	minotauro.parar()
	minotauro.virar_para_alvo()
	minotauro.tocar(&"parado")
	if minotauro.pode_atacar():
		trocar_para.emit(proximo)
