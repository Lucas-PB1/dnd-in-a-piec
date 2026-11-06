class_name EscudoJogador
extends Sprite2D
## Escudo à frente do corpo, na altura do ombro, do lado para onde o herói olha. Fica por cima do sprite
## e por baixo da arma (ordem dos irmãos na cena). O dono chama equipar() quando o
## equipamento muda e seguir_mao() todo quadro.

## Distância à frente do centro do corpo (px): na borda da frente, sem cobrir a mão da arma.
const A_FRENTE := 13.0
## Altura do ombro acima dos pés (px). A mão puxa um pouco, para o escudo acompanhar o passo.
const ALTURA_PEITO := 33.0
## No golpe o escudo recua um pouco (guarda) e volta (px; velocidade em px/s).
const RECUO_NO_GOLPE := 5.0
const VELOCIDADE_RECUO := 60.0

var _recuo: float = 0.0
## Quanto a altura da mão entra na do escudo (0 = peito fixo, 1 = só a mão).
const PESO_DA_MAO := 0.35


func _ready() -> void:
	hide()


## Mostra o escudo (null = sem escudo).
func equipar(escudo: Armadura) -> void:
	texture = escudo.textura if escudo else null
	visible = texture != null


## `mao` de trás só empresta a altura (o passo). A posição horizontal é sempre à frente;
## com `golpeando`, recua um pouco.
func seguir_mao(mao: Vector2, direcao: int, golpeando: bool = false, delta: float = 0.0) -> void:
	_recuo = move_toward(_recuo, RECUO_NO_GOLPE if golpeando else 0.0, VELOCIDADE_RECUO * delta)
	var altura := lerpf(-ALTURA_PEITO, mao.y, PESO_DA_MAO)
	position = Vector2((A_FRENTE - _recuo) * direcao, altura)
	flip_h = direcao < 0
