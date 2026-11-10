class_name Flecha
extends CharacterBody2D
## Flecha de quem atira com arco (Goblin Warrior, Wight). O voo repete o da adaga (outra cópia; a adaga e a flecha são
## os dois projéteis da ficha): sai na força do alcance longo, desvantagem além do normal e cai
## no longo. A ponta segue a velocidade, sem o giro da adaga. Fica solta no mundo
## (top_level) mesmo sendo filha de quem atira.

## O voo não fica mais curto que isto (s), para a conta da subida não estourar.
const TEMPO_MINIMO := 0.08

var _origem_x: float = 0.0
var _normal_px: float = 0.0
var _longo_px: float = 0.0
var _gravidade: float = 0.0
var _angulo_arte: float = 0.0
var _golpe: Golpe

@onready var _sprite: Sprite2D = $Sprite
@onready var _hitbox: HitboxComponent = $Hitbox


func _ready() -> void:
	top_level = true
	_hitbox.alvo_atingido.connect(func(_alvo: HurtboxComponent) -> void: queue_free())


## Começa o voo da `origem` até passar pelo `destino`. Chamar depois de entrar na árvore.
func lancar(golpe: Golpe, municao: Municao, origem: Vector2, destino: Vector2, normal_px: float, longo_px: float, gravidade: float) -> void:
	_golpe = golpe
	_normal_px = normal_px
	_longo_px = longo_px
	_gravidade = gravidade
	global_position = origem
	_origem_x = origem.x
	_preparar_sprite(municao)
	velocity = _velocidade_ate(destino)
	_hitbox.ligar(golpe)
	_apontar()


func _physics_process(delta: float) -> void:
	velocity.y += _gravidade * delta
	_apontar()
	_aplicar_alcance()
	move_and_slide()
	if is_on_floor() or is_on_wall():
		queue_free()


## True quando o ataque desta flecha sai com desvantagem (passou do alcance normal).
func em_desvantagem() -> bool:
	return _golpe != null and _golpe.desvantagem


## Arco que passa pelo destino com a velocidade horizontal da força do tiro.
func _velocidade_ate(destino: Vector2) -> Vector2:
	var rapidez := EscalaDnd.velocidade_para_alcance(_longo_px, _gravidade)
	var distancia := destino - global_position
	var tempo := maxf(absf(distancia.x) / rapidez, TEMPO_MINIMO)
	var subida := (distancia.y - 0.5 * _gravidade * tempo * tempo) / tempo
	return Vector2(signf(distancia.x) * rapidez, subida)


## Além do normal: desvantagem. No longo: perde o acerto e cai, sem atravessar.
func _aplicar_alcance() -> void:
	var distancia := absf(global_position.x - _origem_x)
	if distancia > _normal_px:
		_golpe.desvantagem = true
	if distancia >= _longo_px:
		_hitbox.desligar()
		velocity.x = 0.0


## A arte da flecha pode já nascer inclinada (`angulo_arte`); a ponta fica no rumo.
func _preparar_sprite(municao: Municao) -> void:
	_sprite.centered = true
	_sprite.offset = Vector2.ZERO
	if municao == null or municao.textura == null:
		return
	_sprite.texture = municao.textura
	_angulo_arte = municao.angulo_arte


func _apontar() -> void:
	if velocity.length_squared() <= 0.0:
		return
	_sprite.rotation_degrees = rad_to_deg(velocity.angle()) - _angulo_arte
