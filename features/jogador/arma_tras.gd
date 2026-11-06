class_name ArmaTras
extends Sprite2D
## 2ª arma, na mão de trás. O dono chama mostrar() todo quadro (null = some).
## No golpe extra o dono passa null: quem gira é o AtaqueJogador, para não desenhar duas.

## Empurra a arma para trás do tronco, para não entrar no corpo na passada.
const AFASTAMENTO := 6.0
## Ponta para baixo e para trás (graus, herói olhando para a direita).
const ANGULO := 100.0


func _ready() -> void:
	centered = false
	hide()


## `mao` em pixels, relativa aos pés, já espelhada. `direcao`: 1 direita, -1 esquerda.
func mostrar(arma: Arma, mao: Vector2, direcao: int) -> void:
	DesenhoArma.preparar(self, arma)
	if not visible:
		return
	position = Vector2(mao.x - AFASTAMENTO * direcao, mao.y)
	rotation_degrees = DesenhoArma.rotacao(arma, ANGULO)
	scale = Vector2(direcao, 1.0)
