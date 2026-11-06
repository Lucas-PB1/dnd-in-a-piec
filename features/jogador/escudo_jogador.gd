class_name EscudoJogador
extends Sprite2D
## Escudo na mão de trás do herói. Desenhado ATRÁS do corpo (o braço de trás fica do outro
## lado). O dono chama equipar() quando o equipamento muda e seguir_mao() todo quadro.


func _ready() -> void:
	hide()


## Mostra o escudo (null = sem escudo).
func equipar(escudo: Armadura) -> void:
	texture = escudo.textura if escudo else null
	visible = texture != null


## Coloca o escudo na `mao` de trás (pixels, relativo aos pés, já espelhado).
func seguir_mao(mao: Vector2, direcao: int) -> void:
	position = mao
	flip_h = direcao < 0
