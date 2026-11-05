extends EstadoJogador
## No ar (pulando ou caindo). Mantém o impulso da corrida e escolhe o estado ao aterrissar.

var _veio_correndo: bool = false
var _velocidade_maxima: float = 0.0


func entrar() -> void:
	_veio_correndo = absf(jogador.velocity.x) > jogador.stats.velocidade + VELOCIDADE_PARADO
	_velocidade_maxima = jogador.stats.velocidade_corrida if _veio_correndo else jogador.stats.velocidade


func processar_fisica(delta: float) -> void:
	var dir := jogador.direcao()
	jogador.aplicar_gravidade(delta)
	jogador.tentar_pular()  # coyote time: ainda dá para pular logo depois da beirada
	jogador.cortar_pulo_se_soltou()
	jogador.mover_horizontal(dir, _velocidade_maxima, delta)
	if jogador.is_on_floor() and jogador.velocity.y >= 0.0:
		trocar_para.emit(_estado_ao_aterrissar(dir))


func _estado_ao_aterrissar(dir: float) -> StringName:
	if dir == 0.0:
		return &"Parado"
	var mesma_direcao := signf(dir) == signf(jogador.velocity.x)
	return &"Correndo" if _veio_correndo and mesma_direcao else &"Andando"
