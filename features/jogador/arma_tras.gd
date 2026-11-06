class_name ArmaTras
extends Sprite2D
## 2ª arma, na mão de trás. O dono chama mostrar() todo quadro (null = some).
## No golpe extra o dono passa null: quem gira é o AtaqueJogador, para não desenhar duas.

## A mão segura o cabo a esta distância (px) da ponta de trás da arma.
const PEGADA := 4.0
## Empurra a arma para trás do tronco, para não entrar no corpo na passada.
const AFASTAMENTO := 6.0
## Ponta para baixo e para trás (graus, herói olhando para a direita).
const ANGULO := 100.0


func _ready() -> void:
	centered = false
	hide()


## `mao` em pixels, relativa aos pés, já espelhada. `direcao`: 1 direita, -1 esquerda.
func mostrar(arma: Arma, mao: Vector2, direcao: int) -> void:
	var desenho: Texture2D = arma.textura if arma else null
	visible = desenho != null
	if desenho == null:
		return
	if texture != desenho:
		texture = desenho
		offset = Vector2(-PEGADA, -desenho.get_height() / 2.0)
	position = Vector2(mao.x - AFASTAMENTO * direcao, mao.y)
	rotation_degrees = ANGULO
	scale = Vector2(direcao, 1.0)
