class_name EscudoJogador
extends Sprite2D
## Escudo na frente do corpo, do lado para onde o herói olha. Fica por cima do sprite
## e por baixo da arma (ordem dos irmãos na cena). O dono chama equipar() quando o
## equipamento muda e seguir_mao() todo quadro.

## Distância à frente do centro do corpo (px).
const A_FRENTE := 10.0
## Altura do peito acima dos pés (px). A mão puxa um pouco, para o escudo acompanhar o passo.
const ALTURA_PEITO := 32.0
## Quanto a altura da mão entra na do escudo (0 = peito fixo, 1 = só a mão).
const PESO_DA_MAO := 0.35


func _ready() -> void:
	hide()


## Mostra o escudo (null = sem escudo).
func equipar(escudo: Armadura) -> void:
	texture = escudo.textura if escudo else null
	visible = texture != null


## `mao` de trás só empresta a altura (o passo). A posição horizontal é sempre à frente.
func seguir_mao(mao: Vector2, direcao: int) -> void:
	var altura := lerpf(-ALTURA_PEITO, mao.y, PESO_DA_MAO)
	position = Vector2(A_FRENTE * direcao, altura)
	flip_h = direcao < 0
