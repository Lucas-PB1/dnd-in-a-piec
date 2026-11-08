extends EstadoJogador
## Golpe da arma. No chão, o herói mantém o deslocamento enquanto golpeia; armas curtas
## ainda dão um passo à frente para a ponta chegar ao alcance. No ar continua caindo.
## Não vira de lado durante o golpe. Quando o golpe acaba, volta a se mexer.


func entrar() -> void:
	jogador.iniciar_golpe()


func sair() -> void:
	jogador.cancelar_golpe_do_surto()  # se o ataque foi interrompido, o segundo golpe se perde


func processar_fisica(delta: float) -> void:
	if jogador.is_on_floor():
		jogador.tentar_pular()
		_mover_no_chao(delta)
	else:
		jogador.aplicar_gravidade(delta)
		jogador.cortar_pulo_se_soltou()
		jogador.mover_horizontal(jogador.direcao(), jogador.velocidade_andar(), delta, false)
	if not jogador.esta_golpeando():
		if jogador.quer_golpe_do_surto():
			jogador.iniciar_golpe_do_surto()  # Surto de Ação: o segundo golpe, logo atrás do primeiro
			return
		if jogador.quer_golpe_extra():
			jogador.iniciar_golpe_extra()
			return
		trocar_para.emit(_proximo_estado())


func _mover_no_chao(delta: float) -> void:
	var direcao := jogador.direcao()
	var manteve_disparada := jogador.correr_segurado() or jogador.pediu_corrida() != 0
	var veio_correndo := absf(jogador.velocity.x) > jogador.velocidade_andar() + VELOCIDADE_PARADO
	var maxima := jogador.velocidade_corrida() if manteve_disparada or veio_correndo else jogador.velocidade_andar()
	var passo := jogador.velocidade_do_passo()
	if passo != 0.0:
		jogador.velocity.x = passo + direcao * maxima
	else:
		jogador.mover_horizontal(direcao, maxima, delta, false)


func _proximo_estado() -> StringName:
	if not jogador.is_on_floor():
		return &"NoAr"
	return &"Andando" if jogador.direcao() != 0.0 else &"Parado"
