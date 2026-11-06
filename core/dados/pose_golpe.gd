class_name PoseGolpe
extends Resource
## Uma pose-chave do golpe de uma arma. Entre duas poses o movimento é interpolado.
## Ângulos em graus com o herói olhando para a direita: 0 = lâmina para a frente,
## negativo = para cima/para trás, positivo = para baixo.

## Instante da pose, contado do início do golpe (s).
@export var tempo: float = 0.0
## Direção da lâmina.
@export var angulo: float = 0.0
## Deslocamento da mão em relação à mão da animação (px; x positivo = para a frente).
@export var mao: Vector2 = Vector2.ZERO
## Comprimento visível da arma (1 = inteira; o chicote enrolado usa menos).
@export var escala: float = 1.0
## O trecho que COMEÇA nesta pose (até a próxima) acerta.
@export var acerta: bool = false


static func criar(instante: float, graus: float, deslocamento: Vector2 = Vector2.ZERO,
		comprimento: float = 1.0, acertando: bool = false) -> PoseGolpe:
	var pose := PoseGolpe.new()
	pose.tempo = instante
	pose.angulo = graus
	pose.mao = deslocamento
	pose.escala = comprimento
	pose.acerta = acertando
	return pose


## A pose entre `a` e `b`, na fração `peso` (0 = a, 1 = b).
static func entre(a: PoseGolpe, b: PoseGolpe, peso: float) -> PoseGolpe:
	return criar(lerpf(a.tempo, b.tempo, peso), lerpf(a.angulo, b.angulo, peso), a.mao.lerp(b.mao, peso),
		lerpf(a.escala, b.escala, peso), a.acerta)
