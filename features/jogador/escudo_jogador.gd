class_name EscudoJogador
extends Sprite2D
## Escudo redondo seguro pela MÃO DE TRÁS, pela alça do meio: fica na frente do corpo, do
## lado das costas, centrado na mão e COBRINDO a mão (como quem segura a alça por trás: de
## fora se vê a face do escudo). Acompanha o balanço do braço.
## O dono chama equipar() quando o equipamento muda e seguir_mao() todo quadro.

## Do ponto da mão de trás até o centro do escudo (px, herói olhando para a direita).
## A mão fica atrás do miolo (a alça).
const DO_PUNHO := Vector2(0.0, 0.0)


func _ready() -> void:
	hide()


## Mostra o escudo (null = sem escudo).
func equipar(escudo: Armadura) -> void:
	texture = escudo.textura if escudo else null
	visible = texture != null


## `mao` de trás em pixels, relativa aos pés, já espelhada. `direcao`: 1 direita, -1 esquerda.
func seguir_mao(mao: Vector2, direcao: int) -> void:
	position = mao + Vector2(DO_PUNHO.x * direcao, DO_PUNHO.y)
	flip_h = direcao < 0
