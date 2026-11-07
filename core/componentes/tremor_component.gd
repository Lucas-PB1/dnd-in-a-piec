class_name TremorComponent
extends Node
## Treme o sprite (desloca o `offset` de um lado para o outro) por um tempo, e devolve ao
## lugar quando acaba. Serve para mostrar que um monstro levou dano. Só mexe no `offset`, então
## não atrapalha a escala, o giro nem a colisão.

## Sprite que treme.
@export var sprite: AnimatedSprite2D
## Quanto desloca para cada lado (px).
@export var intensidade: float = 2.0

var _restante: float = 0.0
var _base: Vector2 = Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func _process(delta: float) -> void:
	if _restante <= 0.0 or sprite == null:
		return
	_restante -= delta
	if _restante <= 0.0:
		sprite.offset = _base
		return
	sprite.offset = _base + Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * intensidade


## Treme por `duracao` segundos. Chamar de novo só renova o tempo.
func tremer(duracao: float) -> void:
	if sprite == null:
		return
	if _restante <= 0.0:
		_base = sprite.offset
	_restante = duracao


func esta_tremendo() -> bool:
	return _restante > 0.0


## Para na hora e devolve o sprite ao lugar.
func parar() -> void:
	if _restante > 0.0 and sprite != null:
		sprite.offset = _base
	_restante = 0.0
