class_name DesenhoArma
extends RefCounted
## Põe a imagem de uma Arma num Sprite2D com a origem na pegada (onde a mão segura) e
## converte a direção desejada da lâmina no giro do sprite, descontando o ângulo em que a
## arte foi desenhada (os ícones do pacote vêm na diagonal). Usado pela arma na mão, pela
## arma da mão de trás e pela arma arremessada.


## Mostra a `arma` no `sprite` (null ou sem imagem = esconde).
static func preparar(sprite: Sprite2D, arma: Arma) -> void:
	var textura: Texture2D = arma.textura if arma else null
	sprite.visible = textura != null
	if textura == null:
		return
	sprite.centered = false
	sprite.texture = textura
	sprite.offset = -arma.pegada
	sprite.modulate = arma.cor_do_brilho()


## Giro do sprite (graus) para a lâmina apontar em `angulo` (0 = para a frente).
static func rotacao(arma: Arma, angulo: float) -> float:
	return angulo - arma.angulo_arte


## Ângulo (graus) mais próximo de `angulo` em que a ponta não passa dos pés. Vale para a
## frente (0 a 90: inclina menos para baixo) e para trás (90 a 180: idem, espelhado).
## `altura_mao` = y da mão (negativo = acima dos pés); `folga` = px acima do chão.
static func angulo_sem_tocar_chao(angulo: float, altura_mao: float, arma: Arma, folga: float) -> float:
	if arma == null or arma.comprimento <= 0.0:
		return angulo
	var limite := rad_to_deg(asin(clampf((-altura_mao - folga) / arma.comprimento, -1.0, 1.0)))
	return maxf(angulo, 180.0 - limite) if angulo > 90.0 else minf(angulo, limite)
