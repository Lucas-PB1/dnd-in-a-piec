class_name BonecoTreino
extends Node2D
## Boneco de treino: tem CA mas não perde vida. Mostra o resultado de cada golpe (dano,
## "Errou!", "Crítico!") e, quando é acertado, pisca e balança para o lado do golpe.
## Não conhece quem bate: o DefesaComponent resolve e avisa.

## Emitido a cada golpe resolvido contra o boneco (acertou ou não).
signal atingido(resultado: Combate.Resultado)

## Quanto o boneco inclina ao ser atingido (graus).
@export var inclinacao_golpe: float = 14.0
## Duração do piscar e do balanço (s).
@export var duracao_reacao: float = 0.3
## Brilho do piscar (1 = normal; maior = mais branco).
@export var brilho_piscar: float = 3.0

## Total de golpes que chegaram (acertando ou não). Útil para testes e para um placar.
var golpes_recebidos: int = 0

@onready var _sprite: Sprite2D = $Sprite
@onready var _defesa: DefesaComponent = $Defesa
@onready var _texto: TextoFlutuanteComponent = $Texto


func _ready() -> void:
	_defesa.golpe_resolvido.connect(_ao_resolver_golpe)


func _ao_resolver_golpe(resultado: Combate.Resultado, origem: Vector2) -> void:
	golpes_recebidos += 1
	_texto.mostrar_resultado(resultado)
	if resultado.acertou:
		_piscar()
		_balancar(signf(global_position.x - origem.x))
	atingido.emit(resultado)


func _piscar() -> void:
	_sprite.modulate = Color(brilho_piscar, brilho_piscar, brilho_piscar)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, duracao_reacao)


## Inclina para o lado contrário de quem bateu e volta balançando.
func _balancar(lado: float) -> void:
	_sprite.rotation_degrees = inclinacao_golpe * lado
	var tween := create_tween()
	tween.tween_property(_sprite, "rotation_degrees", 0.0, duracao_reacao) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
