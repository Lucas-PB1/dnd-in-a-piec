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


## Giro do sprite (graus) para a lâmina apontar em `angulo` (0 = para a frente).
static func rotacao(arma: Arma, angulo: float) -> float:
	return angulo - arma.angulo_arte
