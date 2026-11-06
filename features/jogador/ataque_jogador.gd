class_name AtaqueJogador
extends Node2D
## Componente do golpe corpo a corpo: gira a arma, mostra o arco de corte e liga a
## Hitbox só na janela de acerto da Arma. O dono chama golpear() (call down) e
## pergunta esta_golpeando().

## Curva do giro da arma (< 1 = rápido no começo e freia no fim, como um golpe de verdade).
const CURVA_GOLPE := 0.4

var _arma: Arma
var _tempo: float = 0.0
var _golpeando: bool = false
var _distancia_mao: float  # distância da mão ao centro do herói (px), espelhada ao virar

@onready var _espada: Sprite2D = $Espada
@onready var _corte: AnimatedSprite2D = $Corte
@onready var _hitbox: HitboxComponent = $Hitbox
@onready var _forma: CollisionShape2D = $Hitbox/Forma


func _ready() -> void:
	_distancia_mao = absf(position.x)
	_esconder()


## Começa um golpe com a `arma`, virado para `direcao` (1 = direita, -1 = esquerda).
func golpear(arma: Arma, direcao: int) -> void:
	_arma = arma
	_tempo = 0.0
	_golpeando = true
	position.x = _distancia_mao * direcao
	scale.x = direcao
	reset_physics_interpolation()
	_preparar_visual()
	_preparar_area()


func esta_golpeando() -> bool:
	return _golpeando


func _physics_process(delta: float) -> void:
	if not _golpeando:
		return
	_tempo += delta
	_girar_arma()
	_atualizar_acerto()
	if _tempo >= _arma.duracao:
		_terminar()


func _preparar_visual() -> void:
	_espada.texture = _arma.textura
	_espada.rotation_degrees = _arma.angulo_inicial
	_espada.show()
	_corte.modulate = _arma.cor_corte
	_corte.hide()


func _preparar_area() -> void:
	var retangulo := _forma.shape as RectangleShape2D
	retangulo.size = Vector2(_arma.alcance, _arma.altura)
	_forma.position = Vector2(_arma.alcance / 2.0, 0.0)


## A arma desce do ângulo inicial ao final até o fim da janela de acerto, depois fica parada.
func _girar_arma() -> void:
	var progresso := clampf(_tempo / _arma.fim_acerto, 0.0, 1.0)
	var suave := ease(progresso, CURVA_GOLPE)
	_espada.rotation_degrees = lerpf(_arma.angulo_inicial, _arma.angulo_final, suave)


func _atualizar_acerto() -> void:
	var na_janela := _tempo >= _arma.inicio_acerto and _tempo < _arma.fim_acerto
	if na_janela and not _hitbox.esta_ligada():
		_hitbox.ligar(_arma.dano)
		_corte.show()
		_corte.play(&"corte")
	elif not na_janela and _hitbox.esta_ligada():
		_hitbox.desligar()


func _terminar() -> void:
	_golpeando = false
	_hitbox.desligar()
	_esconder()


func _esconder() -> void:
	_espada.hide()
	_corte.hide()
