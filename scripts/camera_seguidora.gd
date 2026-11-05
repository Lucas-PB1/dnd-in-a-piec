class_name CameraSeguidora
extends Camera3D
## Câmera fixa a ~45° que segue um alvo com suavização.
## Ela não gira: só a posição acompanha o alvo. Isso evita "balanço" e tremedeira.

## Nó que a câmera segue (normalmente o Jogador).
@export var alvo: Node3D
## Posição da câmera em relação ao alvo. Y = altura, Z = distância para trás.
## Y igual a Z dá um ângulo de 45°.
@export var deslocamento: Vector3 = Vector3(0.0, 6.0, 6.0)
## Quanto maior, mais rápido a câmera alcança o alvo. 0 = não se mexe.
@export var suavizacao: float = 6.0


func _ready() -> void:
	# A câmera se move em _process (todo quadro desenhado), então ela mesma não deve
	# ser interpolada pela física; o que interpolamos é a posição do alvo.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if alvo:
		global_position = _posicao_desejada()
		look_at(alvo.global_position + Vector3.UP * 0.75)


func _process(delta: float) -> void:
	if not alvo:
		return
	# Suavização que não depende do FPS (mesma sensação a 60 ou 144 Hz).
	var peso := 1.0 - exp(-suavizacao * delta)
	global_position = global_position.lerp(_posicao_desejada(), peso)


func _posicao_desejada() -> Vector3:
	# get_global_transform_interpolated() dá a posição suave do alvo entre dois passos de física.
	return alvo.get_global_transform_interpolated().origin + deslocamento
