class_name ProjetilArremesso
extends CharacterBody2D
## Arma arremessada por monstro (`ArremessoDeCriatura`). Sai na força do alcance longo da ficha
## num arco que passa pelo destino. Além do normal: desvantagem; no longo: perde o acerto e cai.
## Some ao acertar ou ao bater no chão/parede. Fica solta no mundo (top_level).

## Giro da arma no ar (rad/s).
const GIRO := 14.0
## O voo não fica mais curto que isto (s), para a conta da subida não estourar.
const TEMPO_MINIMO := 0.08

var _origem_x: float = 0.0
var _normal_px: float = 0.0
var _longo_px: float = 0.0
var _gravidade: float = 0.0
var _golpe: Golpe

@onready var _sprite: Sprite2D = $Sprite
@onready var _hitbox: HitboxComponent = $Hitbox


func _ready() -> void:
	top_level = true
	_hitbox.alvo_atingido.connect(func(_alvo: HurtboxComponent) -> void: queue_free())


## Começa o voo da `origem` até passar pelo `destino`. Chamar depois de entrar na árvore.
func lancar(
	golpe: Golpe,
	arma: Arma,
	origem: Vector2,
	destino: Vector2,
	normal_px: float,
	longo_px: float,
	gravidade: float,
) -> void:
	_golpe = golpe
	_normal_px = normal_px
	_longo_px = longo_px
	_gravidade = gravidade
	global_position = origem
	_origem_x = origem.x
	_preparar_sprite(arma)
	velocity = _velocidade_ate(destino)
	_hitbox.ligar(golpe)


func _physics_process(delta: float) -> void:
	velocity.y += _gravidade * delta
	_sprite.rotation += GIRO * delta * signf(velocity.x)
	_aplicar_alcance()
	move_and_slide()
	if is_on_floor() or is_on_wall():
		queue_free()


## True quando o ataque deste projétil sai com desvantagem (passou do alcance normal).
func em_desvantagem() -> bool:
	return _golpe != null and _golpe.desvantagem


func _velocidade_ate(destino: Vector2) -> Vector2:
	var rapidez := EscalaDnd.velocidade_para_alcance(_longo_px, _gravidade)
	var distancia := destino - global_position
	var tempo := maxf(absf(distancia.x) / rapidez, TEMPO_MINIMO)
	var subida := (distancia.y - 0.5 * _gravidade * tempo * tempo) / tempo
	return Vector2(signf(distancia.x) * rapidez, subida)


func _aplicar_alcance() -> void:
	var distancia := absf(global_position.x - _origem_x)
	if distancia > _normal_px:
		_golpe.desvantagem = true
	if distancia >= _longo_px:
		_hitbox.desligar()
		velocity.x = 0.0


func _preparar_sprite(arma: Arma) -> void:
	DesenhoArma.preparar(_sprite, arma)
	if arma and arma.textura:
		_sprite.offset = -arma.textura.get_size() / 2.0
