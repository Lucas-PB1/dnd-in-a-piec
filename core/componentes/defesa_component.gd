class_name DefesaComponent
extends Node
## Resolve os golpes que chegam na Hurtbox contra a CA (d20 + bônus >= CA) e, se causar
## dano (acerto, ou erro com Raspão), tira a vida do HealthComponent. Com condições, aplica
## vantagem (alvo Caído, Atormentado) e a maestria do golpe. Avisa o resultado ao dono.

## Emitido a cada golpe resolvido (acertou ou não).
signal golpe_resolvido(resultado: Combate.Resultado, origem: Vector2)

## Classe de Armadura.
@export var classe_armadura: int = 10
## Tipos de dano a que resiste (metade do dano), ex.: [&"acido", &"frio", &"fogo"].
@export var resistencias: Array[StringName] = []
## Área que recebe os golpes.
@export var hurtbox: HurtboxComponent
## Vida que perde o dano. Vazio = não perde vida (ex.: boneco de treino).
@export var vida: HealthComponent
## Condições do alvo (maestrias). Vazio = o alvo ignora as maestrias.
@export var condicoes: CondicoesComponent

## Enquanto true, golpes que chegam são ignorados (ex.: piscando depois de apanhar).
var invulneravel: bool = false
## Gerador dos dados (os testes podem fixar a semente).
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	hurtbox.golpe_recebido.connect(_ao_receber_golpe)


func _ao_receber_golpe(golpe: Golpe, origem: Vector2) -> void:
	if invulneravel or (vida and vida.esta_morto()):
		return
	if condicoes:
		condicoes.preparar_golpe_recebido(golpe)
	var resultado := Combate.resolver_ataque(golpe, classe_armadura, rng, resistencias)
	golpe.acertou_algum = golpe.acertou_algum or resultado.acertou
	if resultado.dano > 0 and vida:
		vida.receber_dano(resultado.dano)
	if condicoes and not (vida and vida.esta_morto()):
		condicoes.aplicar_maestria(resultado, signf(condicoes.global_position.x - origem.x))
	golpe_resolvido.emit(resultado, origem)
