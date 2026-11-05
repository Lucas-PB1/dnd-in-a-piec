class_name CameraJogador
extends Camera2D
## Câmera filha do herói: segue com suavização e "olha à frente" na direção em que ele corre.

## Quantos pixels a câmera adianta na direção em que o herói olha.
@export var olhar_frente: float = 56.0
## Quão rápido a câmera troca de lado quando o herói vira. Maior = mais rápido.
@export var velocidade_olhar: float = 3.0

@onready var _jogador: Jogador = get_parent()


func _process(delta: float) -> void:
	var alvo := _jogador.direcao_olhar * olhar_frente
	offset.x = lerpf(offset.x, alvo, 1.0 - exp(-velocidade_olhar * delta))


## Impede a câmera de mostrar fora da fase. `area` em pixels.
func definir_limites(area: Rect2) -> void:
	limit_left = int(area.position.x)
	limit_top = int(area.position.y)
	limit_right = int(area.end.x)
	limit_bottom = int(area.end.y)
	reset_smoothing()
