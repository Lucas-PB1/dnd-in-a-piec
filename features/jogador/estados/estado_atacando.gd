extends EstadoJogador
## Golpe de espada. No chão o herói freia e fica firme (peso de Guerreiro); no ar ele
## continua caindo. Não vira de lado durante o golpe. Quando o golpe acaba, volta a se mexer.


func entrar() -> void:
	jogador.iniciar_golpe()


func processar_fisica(delta: float) -> void:
	if jogador.is_on_floor():
		jogador.mover_horizontal(0.0, jogador.velocidade_andar(), delta, false)
	else:
		jogador.aplicar_gravidade(delta)
		jogador.cortar_pulo_se_soltou()
		jogador.mover_horizontal(jogador.direcao(), jogador.velocidade_andar(), delta, false)
	if not jogador.esta_golpeando():
		trocar_para.emit(_proximo_estado())


func _proximo_estado() -> StringName:
	if not jogador.is_on_floor():
		return &"NoAr"
	return &"Andando" if jogador.direcao() != 0.0 else &"Parado"
