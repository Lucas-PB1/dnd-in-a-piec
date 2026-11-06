extends EstadoJogador
## Arremesso. A arma sai da mão no começo. No chão o herói freia; no ar continua caindo.
## Dura pouco: o projétil é quem voa.

## Tempo parado no gesto (s). O intervalo até o próximo ataque é o da iniciativa.
const DURACAO := 0.2

var _tempo: float = 0.0


func entrar() -> void:
	_tempo = 0.0
	jogador.lancar_arma()


func processar_fisica(delta: float) -> void:
	if jogador.is_on_floor():
		jogador.mover_horizontal(0.0, jogador.velocidade_andar(), delta, false)
	else:
		jogador.aplicar_gravidade(delta)
		jogador.cortar_pulo_se_soltou()
		jogador.mover_horizontal(jogador.direcao(), jogador.velocidade_andar(), delta, false)
	_tempo += delta
	if _tempo >= DURACAO:
		trocar_para.emit(_proximo_estado())


func _proximo_estado() -> StringName:
	if not jogador.is_on_floor():
		return &"NoAr"
	return &"Andando" if jogador.direcao() != 0.0 else &"Parado"
