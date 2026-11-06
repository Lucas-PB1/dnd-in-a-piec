class_name BonecoTreino
extends Node2D
## Boneco de treino: leva golpes sem morrer. Pisca, balança para o lado do golpe e mostra o dano.
## Não conhece quem bate: só reage ao sinal da sua HurtboxComponent.

## Emitido a cada golpe recebido.
signal atingido(dano: int)

## Quanto o boneco inclina ao ser atingido (graus).
@export var inclinacao_golpe: float = 14.0
## Duração do piscar e do balanço (s).
@export var duracao_reacao: float = 0.3
## Brilho do piscar (1 = normal; maior = mais branco).
@export var brilho_piscar: float = 3.0
## Quanto o número de dano sobe antes de sumir (px).
@export var subida_numero: float = 20.0

## Total de golpes recebidos (útil para testes e para um placar de treino).
var golpes_recebidos: int = 0

@onready var _sprite: Sprite2D = $Sprite
@onready var _hurtbox: HurtboxComponent = $Hurtbox
@onready var _ponto_numero: Marker2D = $PontoNumero


func _ready() -> void:
	_hurtbox.golpe_recebido.connect(_ao_receber_golpe)


func _ao_receber_golpe(dano: int, origem: Vector2) -> void:
	golpes_recebidos += 1
	_piscar()
	_balancar(signf(global_position.x - origem.x))
	_mostrar_dano(dano)
	atingido.emit(dano)


func _piscar() -> void:
	_sprite.modulate = Color(brilho_piscar, brilho_piscar, brilho_piscar)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, duracao_reacao)


## Inclina para o lado contrário de quem bateu e volta balançando.
func _balancar(lado: float) -> void:
	_sprite.rotation_degrees = inclinacao_golpe * lado
	var tween := create_tween()
	tween.tween_property(_sprite, "rotation_degrees", 0.0, duracao_reacao) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _mostrar_dano(dano: int) -> void:
	var numero := Label.new()
	numero.text = str(dano)
	numero.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	numero.add_theme_color_override("font_outline_color", Color.BLACK)
	numero.add_theme_constant_override("outline_size", 4)
	numero.position = _ponto_numero.position
	add_child(numero)
	var tween := create_tween().set_parallel()
	tween.tween_property(numero, "position:y", numero.position.y - subida_numero, duracao_reacao * 2.0)
	tween.tween_property(numero, "modulate:a", 0.0, duracao_reacao * 2.0)
	tween.chain().tween_callback(numero.queue_free)
