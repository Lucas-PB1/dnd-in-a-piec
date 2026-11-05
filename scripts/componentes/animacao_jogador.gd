class_name AnimacaoJogador
extends AnimatedSprite2D
## Componente visual do herói: escolhe a animação a partir do estado do Jogador.
## Só lê o Jogador e escuta os sinais dele; nunca mexe na física.

## Velocidade vertical (px/s) a partir da qual troca de "topo do pulo" para subindo/caindo.
@export var limite_topo_pulo: float = 80.0
## Abaixo desta velocidade horizontal (px/s) o herói é considerado parado.
@export var limite_parado: float = 10.0
## Velocidade mínima da animação de passos, para não ficar em câmera lenta ao acelerar.
@export var escala_minima_passos: float = 0.5

@onready var _jogador: Jogador = get_parent()


func _ready() -> void:
	_jogador.aterrissou.connect(_ao_aterrissar)


# Roda depois do _physics_process do Jogador (pai antes dos filhos na árvore).
func _physics_process(_delta: float) -> void:
	flip_h = _jogador.direcao_olhar < 0
	speed_scale = 1.0
	if not _jogador.is_on_floor():
		_animar_no_ar()
	elif absf(_jogador.velocity.x) > limite_parado:
		_animar_passos()
	elif animation == &"aterrissar" and is_playing():
		pass  # deixa a aterrissagem terminar
	else:
		play(&"idle")


func _animar_no_ar() -> void:
	var vy := _jogador.velocity.y
	if vy < -limite_topo_pulo:
		play(&"pulo_subindo")
	elif vy > limite_topo_pulo:
		play(&"pulo_caindo")
	else:
		play(&"pulo_topo")


func _animar_passos() -> void:
	var correndo := _jogador.esta_correndo()
	play(&"correr" if correndo else &"walk")
	# Os passos acompanham a velocidade (evita o pé "patinar").
	var maxima := _jogador.velocidade_corrida if correndo else _jogador.velocidade
	speed_scale = maxf(absf(_jogador.velocity.x) / maxima, escala_minima_passos)


func _ao_aterrissar() -> void:
	play(&"aterrissar")
