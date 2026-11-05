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

@export_group("Pulinho do passo")
## Altura do pulinho a cada passo (metros). 0 desliga.
@export var altura_passo: float = 0.06
## Passos por segundo andando na velocidade máxima.
@export var passos_por_segundo: float = 4.0

@onready var sprite: AnimatedSprite3D = $Sprite
@onready var _altura_base_sprite: float = sprite.position.y

var _gravidade: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _fase_passo: float = 0.0


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
	_atualizar_pulinho(horizontal.length(), delta)


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


## Faz o sprite dar um pulinho a cada passo (enquanto não temos animação de andar).
## Roda na física: a interpolação deixa o movimento suave em qualquer FPS.
func _atualizar_pulinho(rapidez: float, delta: float) -> void:
	if rapidez > limite_parado:
		# A cadência acompanha a velocidade: andando devagar, passos mais lentos.
		_fase_passo += delta * passos_por_segundo * (rapidez / velocidade) * PI
		sprite.position.y = _altura_base_sprite + absf(sin(_fase_passo)) * altura_passo
	else:
		# Ao parar, desce suavemente para o chão.
		_fase_passo = 0.0
		sprite.position.y = move_toward(sprite.position.y, _altura_base_sprite, delta * 1.0)
