extends EstadoJogador
## Parado no chão: freia até zerar e espera o jogador se mexer.
## A direção já é aplicada no quadro do toque, então um toque rápido vira o herói.


func processar_fisica(delta: float) -> void:
	var dir := jogador.direcao()
	jogador.mover_horizontal(dir, jogador.stats.velocidade, delta)
	if _foi_atacar() or _foi_para_o_ar():
		return
	if jogador.pediu_corrida() != 0:
		trocar_para.emit(&"Correndo")
	elif dir != 0.0:
		trocar_para.emit(&"Andando")
