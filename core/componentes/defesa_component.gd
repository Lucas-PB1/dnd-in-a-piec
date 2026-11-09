class_name DefesaComponent
extends Node
## Resolve os golpes que chegam na Hurtbox contra a CA (d20 + bônus >= CA) e, se causar
## dano (acerto, ou erro com Raspão), tira a vida do HealthComponent. Com condições, aplica
## vantagem (alvo Caído, Atormentado) e a maestria do golpe. Avisa o resultado ao dono.

## Emitido a cada golpe resolvido (acertou ou não).
signal golpe_resolvido(resultado: Combate.Resultado, origem: Vector2)
## O bônus de CA do Duelista Defensivo fez um golpe errar: a defesa virou um parry.
signal aparou(origem: Vector2)

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
## Mestre em Armadura Pesada: dano contundente, cortante e perfurante cai nisto (0 = não reduz).
@export var reducao_fisica: int = 0
## Duelista Defensivo: soma temporária à CA contra golpes corpo a corpo (0 = fora da janela de defesa).
var bonus_ca_corpo_a_corpo: int = 0

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
	var bonus_ca := bonus_ca_corpo_a_corpo if golpe.corpo_a_corpo else 0
	var resultado := Combate.resolver_ataque(golpe, classe_armadura + bonus_ca, rng, resistencias)
	if bonus_ca > 0 and not resultado.acertou and resultado.d20 != Combate.FALHA_AUTOMATICA and resultado.total >= classe_armadura:
		aparou.emit(origem)
	if resultado.dano > 0 and reducao_fisica > 0 and golpe.tipo_dano in TiposDano.FISICOS:
		resultado.dano = maxi(resultado.dano - reducao_fisica, 0)
	if condicoes and resultado.acertou:  # efeitos que dependem da salvaguarda do alvo (Envenenador)
		for efeito in golpe.efeitos:
			resultado.dano += efeito.dano_no_alvo(golpe, resultado, condicoes)
	golpe.acertou_algum = golpe.acertou_algum or resultado.acertou
	if resultado.dano > 0 and vida:
		vida.receber_dano(resultado.dano)
	if condicoes and not (vida and vida.esta_morto()):
		condicoes.aplicar_maestria(resultado, signf(condicoes.global_position.x - origem.x))
	golpe.resolvido.emit(resultado, resultado.dano > 0 and vida != null and vida.esta_morto())
	golpe_resolvido.emit(resultado, origem)
