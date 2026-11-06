class_name DefesaComponent
extends Node
## Resolve os golpes que chegam na Hurtbox contra a CA (d20 + bônus >= CA) e, se acertar,
## tira a vida do HealthComponent. Avisa o resultado para o dono mostrar efeitos.

## Emitido a cada golpe resolvido (acertou ou não).
signal golpe_resolvido(resultado: Combate.Resultado, origem: Vector2)

## Classe de Armadura.
@export var classe_armadura: int = 10
## Área que recebe os golpes.
@export var hurtbox: HurtboxComponent
## Vida que perde o dano. Vazio = não perde vida (ex.: boneco de treino).
@export var vida: HealthComponent

## Enquanto true, golpes que chegam são ignorados (ex.: piscando depois de apanhar).
var invulneravel: bool = false
## Gerador dos dados (os testes podem fixar a semente).
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	hurtbox.golpe_recebido.connect(_ao_receber_golpe)


func _ao_receber_golpe(golpe: Golpe, origem: Vector2) -> void:
	if invulneravel or (vida and vida.esta_morto()):
		return
	var resultado := Combate.resolver_ataque(golpe, classe_armadura, rng)
	if resultado.acertou and vida:
		vida.receber_dano(resultado.dano)
	golpe_resolvido.emit(resultado, origem)
