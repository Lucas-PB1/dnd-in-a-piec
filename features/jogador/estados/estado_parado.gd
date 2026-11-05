extends EstadoJogador
## Parado no chão: freia até zerar e espera o jogador se mexer.


func processar_fisica(delta: float) -> void:
	jogador.mover_horizontal(0.0, jogador.stats.velocidade, delta)
	if _foi_para_o_ar():
		return
	if jogador.pediu_corrida() != 0:
		trocar_para.emit(&"Correndo")
	elif jogador.direcao() != 0.0:
		trocar_para.emit(&"Andando")
