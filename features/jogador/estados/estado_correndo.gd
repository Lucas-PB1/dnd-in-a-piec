extends EstadoJogador
## Correndo no chão (entrou com dois toques). Soltou ou inverteu a direção -> Andando.

var _direcao_corrida: float = 0.0


func entrar() -> void:
	var dir := jogador.direcao()
	_direcao_corrida = signf(dir) if dir != 0.0 else float(jogador.direcao_olhar)


func processar_fisica(delta: float) -> void:
	var dir := jogador.direcao()
	jogador.mover_horizontal(dir, jogador.stats.velocidade_corrida, delta)
	if _foi_para_o_ar():
		return
	if dir == 0.0 or signf(dir) != _direcao_corrida:
		trocar_para.emit(&"Andando")
