class_name Jogador
extends CharacterBody3D
## Jogador 2.5D: anda livre no chão (eixos X e Z) e mostra um sprite que olha para a câmera.

## Velocidade máxima andando (metros por segundo).
@export var velocidade: float = 4.0
## Quão rápido chega na velocidade máxima (m/s²). Maior = mais "seco".
@export var aceleracao: float = 30.0
## Quão rápido para ao soltar as teclas (m/s²). Maior = para mais rápido.
@export var desaceleracao: float = 40.0
## Abaixo desta velocidade o boneco é considerado parado (troca para idle).
@export var limite_parado: float = 0.2

@onready var sprite: AnimatedSprite3D = $Sprite

var _gravidade: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta: float) -> void:
	# Lê as teclas. get_vector já normaliza a diagonal (não anda mais rápido na diagonal).
	var entrada := Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
	# A câmera não gira, então "cima" na tela = -Z no mundo.
	var direcao := Vector3(entrada.x, 0.0, entrada.y)

	var alvo := direcao * velocidade
	var taxa := aceleracao if direcao != Vector3.ZERO else desaceleracao
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(alvo, taxa * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	# Gravidade simples, para o boneco ficar grudado no chão.
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravidade * delta

	move_and_slide()
	_atualizar_animacao(entrada, horizontal.length())


func _atualizar_animacao(entrada: Vector2, rapidez: float) -> void:
	if rapidez > limite_parado:
		sprite.play(&"walk")
	else:
		sprite.play(&"idle")
	# O sprite é desenhado virado para a direita; espelha quando vai para a esquerda.
	# Se só aperta cima/baixo, mantém o lado anterior.
	if entrada.x < -0.1:
		sprite.flip_h = true
	elif entrada.x > 0.1:
		sprite.flip_h = false
