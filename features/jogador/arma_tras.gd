class_name ArmaTras
extends Sprite2D
## 2ª arma, na mão de trás. O dono chama mostrar() todo quadro (null = some).
## No golpe extra o dono passa null: quem gira é o AtaqueJogador, para não desenhar duas.

## Empurra a arma para trás do tronco, para não entrar no corpo na passada.
const AFASTAMENTO := 6.0
## Inclinada para baixo e para trás (graus, herói olhando para a direita). Arma comprida
## inclina menos, para a ponta não entrar no chão.
const ANGULO := 125.0
## A ponta fica pelo menos isto (px) acima do chão.
const FOLGA_DO_CHAO := 2.0


func _ready() -> void:
	centered = false
	hide()


## `mao` em pixels, relativa aos pés, já espelhada. `direcao`: 1 direita, -1 esquerda.
func mostrar(arma: Arma, mao: Vector2, direcao: int) -> void:
	DesenhoArma.preparar(self, arma)
	if not visible:
		return
	position = Vector2(mao.x - AFASTAMENTO * direcao, mao.y)
	var angulo := DesenhoArma.angulo_sem_tocar_chao(ANGULO, mao.y, arma, FOLGA_DO_CHAO)
	# Espelhado (scale.x = -1) o Godot gira depois de inverter: o giro também inverte.
	rotation_degrees = DesenhoArma.rotacao(arma, angulo) * direcao
	scale = Vector2(direcao, 1.0)
