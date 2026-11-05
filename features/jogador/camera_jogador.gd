class_name CameraJogador
extends Camera2D
## Câmera filha do herói: segue com suavização e "olha à frente" na direção indicada
## pelo dono via olhar_para() (call down). Não conhece o Jogador.

## Quantos pixels a câmera adianta na direção em que o herói olha.
@export var olhar_frente: float = 56.0
## Quão rápido a câmera troca de lado quando o herói vira. Maior = mais rápido.
@export var velocidade_olhar: float = 3.0

var _direcao_alvo: int = 1


## Diz para que lado olhar: 1 = direita, -1 = esquerda.
func olhar_para(direcao: int) -> void:
	_direcao_alvo = direcao


func _process(delta: float) -> void:
	var alvo := _direcao_alvo * olhar_frente
	offset.x = lerpf(offset.x, alvo, 1.0 - exp(-velocidade_olhar * delta))


## Impede a câmera de mostrar fora da fase. `area` em pixels.
func definir_limites(area: Rect2) -> void:
	limit_left = int(area.position.x)
	limit_top = int(area.position.y)
	limit_right = int(area.end.x)
	limit_bottom = int(area.end.y)
	reset_smoothing()
