extends EstadoJogador
## Acabou de levar um golpe: é empurrado para longe de quem bateu e fica sem controle
## por um instante (stats.tempo_recuo). Depois volta para o chão ou para o ar.

var _tempo: float = 0.0


func entrar() -> void:
	_tempo = 0.0
	var lado := signf(jogador.global_position.x - jogador.origem_ultimo_golpe.x)
	if lado == 0.0:
		lado = -jogador.direcao_olhar  # golpe bem no meio: recua para trás
	jogador.velocity = Vector2(lado * jogador.stats.recuo_dano.x, jogador.stats.recuo_dano.y)


func processar_fisica(delta: float) -> void:
	_tempo += delta
	jogador.aplicar_gravidade(delta)
	jogador.mover_horizontal(0.0, jogador.velocidade_andar(), delta, false)
	if _tempo < jogador.tempo_de_recuo():
		return
	if not jogador.is_on_floor():
		trocar_para.emit(&"NoAr")
	else:
		trocar_para.emit(&"Andando" if jogador.direcao() != 0.0 else &"Parado")
