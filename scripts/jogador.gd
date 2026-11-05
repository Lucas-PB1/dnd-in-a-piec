class_name Jogador
extends CharacterBody2D
## Física do herói de ação lateral: anda, corre (dois toques na direção) e pula.
## O visual fica no componente AnimacaoJogador (nó Sprite), que escuta os sinais daqui.

signal pulou
signal aterrissou
signal reapareceu

@export_group("Andar e correr")
## Velocidade máxima andando (pixels por segundo).
@export var velocidade: float = 160.0
## Velocidade máxima correndo (px/s). Corre com dois toques rápidos na direção.
@export var velocidade_corrida: float = 290.0
## Tempo máximo entre os dois toques para começar a correr (s).
@export var janela_toque_duplo: float = 0.25
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

var _correndo: bool = false
var _direcao_corrida: int = 0
var _contador_coyote: float = 0.0
var _contador_buffer: float = 0.0
var _estava_no_chao: bool = true
var _toque_duplo: ToqueDuplo


func _ready() -> void:
	posicao_inicial = global_position
	_toque_duplo = ToqueDuplo.new(janela_toque_duplo)


func _physics_process(delta: float) -> void:
	var direcao := Input.get_axis("mover_esquerda", "mover_direita")
	_atualizar_corrida(direcao, delta)
	_atualizar_contadores(delta)
	_aplicar_gravidade(delta)
	_tentar_pular()
	_mover_horizontal(direcao, delta)
	move_and_slide()
	_checar_aterrissagem()
	if global_position.y > limite_queda:
		reaparecer()


## True enquanto estiver correndo (dois toques na direção e segurando).
func esta_correndo() -> bool:
	return _correndo


## Volta para o início da fase (ex.: caiu num buraco).
func reaparecer() -> void:
	global_position = posicao_inicial
	velocity = Vector2.ZERO
	_correndo = false
	reset_physics_interpolation()
	reapareceu.emit()


# --- Passos da física ---------------------------------------------------------

func _atualizar_corrida(direcao: float, delta: float) -> void:
	_toque_duplo.janela = janela_toque_duplo
	var apertada := _direcao_apertada_agora()
	if _toque_duplo.registrar(apertada, delta):
		_correndo = true
		_direcao_corrida = apertada
	# Soltou ou inverteu a direção: volta a andar.
	if direcao == 0.0 or signf(direcao) != _direcao_corrida:
		_correndo = false


func _direcao_apertada_agora() -> int:
	if Input.is_action_just_pressed("mover_direita"):
		return 1
	if Input.is_action_just_pressed("mover_esquerda"):
		return -1
	return 0


func _atualizar_contadores(delta: float) -> void:
	# Coyote time: um tempinho de "graça" depois de sair da beirada.
	_contador_coyote = tempo_coyote if is_on_floor() else _contador_coyote - delta
	# Buffer: guarda o aperto do botão de pulo por um instante.
	_contador_buffer = tempo_buffer if Input.is_action_just_pressed("pular") else _contador_buffer - delta


func _aplicar_gravidade(delta: float) -> void:
	if is_on_floor():
		return
	var g := _gravidade() if velocity.y < 0.0 else _gravidade() * multiplicador_queda
	velocity.y = minf(velocity.y + g * delta, velocidade_max_queda)


func _tentar_pular() -> void:
	if _contador_buffer > 0.0 and _contador_coyote > 0.0:
		velocity.y = -_forca_pulo()
		_contador_buffer = 0.0
		_contador_coyote = 0.0
		pulou.emit()
	# Pulo de altura variável: soltou o botão subindo -> corta a subida.
	if Input.is_action_just_released("pular") and velocity.y < 0.0:
		velocity.y *= corte_pulo


func _mover_horizontal(direcao: float, delta: float) -> void:
	var maxima := velocidade_corrida if _correndo else velocidade
	velocity.x = move_toward(velocity.x, direcao * maxima, _taxa_aceleracao(direcao) * delta)
	if direcao != 0.0:
		direcao_olhar = 1 if direcao > 0.0 else -1


func _taxa_aceleracao(direcao: float) -> float:
	if not is_on_floor():
		return aceleracao_no_ar
	return aceleracao if direcao != 0.0 else desaceleracao


func _checar_aterrissagem() -> void:
	if is_on_floor() and not _estava_no_chao:
		aterrissou.emit()
	_estava_no_chao = is_on_floor()


# A gravidade e a força do pulo saem da altura e do tempo desejados:
# você ajusta "quão alto" e "quão rápido", e a física se ajusta sozinha.
func _gravidade() -> float:
	return 2.0 * altura_pulo / (tempo_ate_topo * tempo_ate_topo)


func _forca_pulo() -> float:
	return 2.0 * altura_pulo / tempo_ate_topo
