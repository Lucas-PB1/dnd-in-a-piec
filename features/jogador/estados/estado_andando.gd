extends EstadoJogador
## Andando no chão. Dois toques na direção -> Correndo; soltou e parou -> Parado.


func processar_fisica(delta: float) -> void:
	var dir := jogador.direcao()
	jogador.mover_horizontal(dir, jogador.velocidade_andar(), delta)
	if _foi_atacar() or _foi_para_o_ar():
		return
	if jogador.pediu_corrida() != 0:
		trocar_para.emit(&"Correndo")
	elif dir == 0.0 and absf(jogador.velocity.x) < VELOCIDADE_PARADO:
		trocar_para.emit(&"Parado")
