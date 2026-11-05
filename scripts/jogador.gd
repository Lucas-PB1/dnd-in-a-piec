class_name Jogador
extends CharacterBody2D
## Herói de ação lateral: corre, pula com altura variável, coyote time e buffer de pulo.

signal pulou
signal aterrissou
signal reapareceu

@export_group("Corrida")
## Velocidade máxima correndo (pixels por segundo).
@export var velocidade: float = 160.0
## Quão rápido chega na velocidade máxima no chão (px/s²).
@export var aceleracao: float = 1400.0
## Quão rápido para no chão ao soltar (px/s²).
@export var desaceleracao: float = 1800.0
## Controle no ar (px/s²). Menor = menos controle durante o pulo.
@export var aceleracao_no_ar: float = 1100.0

@export_group("Pulo")
## Altura máxima do pulo segurando o botão (pixels). 32 px = 1 ladrilho.
@export var altura_pulo: float = 104.0
## Tempo até chegar no topo do pulo (segundos). Menor = pulo mais "rápido".
@export var tempo_ate_topo: float = 0.38
## Gravidade extra na queda. Maior que 1 = cai mais rápido do que sobe (pulo mais firme).
@export var multiplicador_queda: float = 1.6
## Ao soltar o botão subindo, a velocidade vertical é multiplicada por isto (pulo curto).
@export_range(0.0, 1.0) var corte_pulo: float = 0.45
## Velocidade máxima de queda (px/s).
@export var velocidade_max_queda: float = 700.0
## Tempo depois de sair da beirada em que ainda dá para pular (s).
@export var tempo_coyote: float = 0.1
## Apertar pular um pouco antes de tocar o chão também vale (s).
@export var tempo_buffer: float = 0.12

@export_group("Fase")
## Se cair abaixo desta altura (Y), volta para o início.
@export var limite_queda: float = 600.0

## Para onde o herói está olhando: 1 = direita, -1 = esquerda.
var direcao_olhar: int = 1
var posicao_inicial: Vector2

var _contador_coyote: float = 0.0
var _contador_buffer: float = 0.0
var _estava_no_chao: bool = true

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	posicao_inicial = global_position


func _physics_process(delta: float) -> void:
	# A gravidade e a força do pulo saem da altura e do tempo desejados
	# (assim você ajusta "quão alto" e "quão rápido", e a física se ajusta sozinha).
	var gravidade := 2.0 * altura_pulo / (tempo_ate_topo * tempo_ate_topo)
	var forca_pulo := 2.0 * altura_pulo / tempo_ate_topo
	var no_chao := is_on_floor()

	# Coyote time: um tempinho de "graça" depois de sair da beirada.
	if no_chao:
		_contador_coyote = tempo_coyote
	else:
		_contador_coyote -= delta

	# Buffer: guarda o aperto do botão por um instante.
	if Input.is_action_just_pressed("pular"):
		_contador_buffer = tempo_buffer
	else:
		_contador_buffer -= delta

	# Gravidade (mais forte caindo do que subindo).
	if not no_chao:
		var g := gravidade if velocity.y < 0.0 else gravidade * multiplicador_queda
		velocity.y = minf(velocity.y + g * delta, velocidade_max_queda)

	# Pulo.
	if _contador_buffer > 0.0 and _contador_coyote > 0.0:
		velocity.y = -forca_pulo
		_contador_buffer = 0.0
		_contador_coyote = 0.0
		pulou.emit()

	# Pulo de altura variável: soltou o botão subindo -> corta a subida.
	if Input.is_action_just_released("pular") and velocity.y < 0.0:
		velocity.y *= corte_pulo

	# Corrida.
	var direcao := Input.get_axis("mover_esquerda", "mover_direita")
	var taxa: float
	if not no_chao:
		taxa = aceleracao_no_ar
	elif direcao != 0.0:
		taxa = aceleracao
	else:
		taxa = desaceleracao
	velocity.x = move_toward(velocity.x, direcao * velocidade, taxa * delta)
	if direcao != 0.0:
		direcao_olhar = 1 if direcao > 0.0 else -1
		sprite.flip_h = direcao_olhar < 0

	move_and_slide()

	if is_on_floor() and not _estava_no_chao:
		aterrissou.emit()
		sprite.play(&"aterrissar")
	_estava_no_chao = is_on_floor()

	_atualizar_animacao()

	if global_position.y > limite_queda:
		reaparecer()


func _atualizar_animacao() -> void:
	sprite.speed_scale = 1.0
	if not is_on_floor():
		if velocity.y < -80.0:
			sprite.play(&"pulo_subindo")
		elif velocity.y > 80.0:
			sprite.play(&"pulo_caindo")
		else:
			sprite.play(&"pulo_topo")
	elif absf(velocity.x) > 10.0:
		sprite.play(&"walk")
		# Os passos acompanham a velocidade (evita o pé "patinar").
		sprite.speed_scale = maxf(absf(velocity.x) / velocidade, 0.5)
	elif sprite.animation == &"aterrissar" and sprite.is_playing():
		pass  # deixa a aterrissagem terminar
	else:
		sprite.play(&"idle")


## Volta para o início da fase (ex.: caiu num buraco).
func reaparecer() -> void:
	global_position = posicao_inicial
	velocity = Vector2.ZERO
	reset_physics_interpolation()
	reapareceu.emit()
