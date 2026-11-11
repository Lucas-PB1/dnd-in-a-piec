class_name DefesaComponent
extends Node
## Resolve os golpes que chegam na Hurtbox contra a CA (d20 + bônus >= CA) e, se causar
## dano (acerto, ou erro com Raspão), tira a vida do HealthComponent. Com condições, aplica
## vantagem (alvo Caído, Atormentado) e a maestria do golpe. Avisa o resultado ao dono.

## Emitido a cada golpe resolvido (acertou ou não).
signal golpe_resolvido(resultado: Combate.Resultado, origem: Vector2)
## O bônus de CA do Duelista Defensivo fez um golpe errar: a defesa virou um parry.
signal aparou(origem: Vector2)
## Um golpe com Agarrar acertou quem não tem Condições (o herói): quem agarrou e a CD do escape.
signal agarrado(autor_id: int, cd: int)
## Um golpe com Derrubada acertou quem não tem Condições (o herói): de quem veio.
signal derrubado(autor_id: int)
## A Fortitude dos Mortos-Vivos segurou a criatura em 1 PV.
signal fortitude_usada

const CD_BASE_FORTITUDE := 5

## Classe de Armadura.
@export var classe_armadura: int = 10
## Tipos de dano a que resiste (metade do dano), ex.: [&"acido", &"frio", &"fogo"].
@export var resistencias: Array[StringName] = []
## Tipos de dano a que é imune (o dano vira 0), ex.: [&"veneno"] no Wight.
@export var imunidades: Array[StringName] = []
## Tipos de dano a que é vulnerável (o dano dobra), ex.: [&"contundente"] no Skeleton.
@export var vulnerabilidades: Array[StringName] = []
## Fortitude dos Mortos-Vivos: ver `CriaturaRPG.fortitude_morto_vivo`.
@export var fortitude_morto_vivo: bool = false
## Área que recebe os golpes.
@export var hurtbox: HurtboxComponent
## Vida que perde o dano. Vazio = não perde vida (ex.: boneco de treino).
@export var vida: HealthComponent
## Condições do alvo (maestrias). Vazio = o alvo ignora as maestrias.
@export var condicoes: CondicoesComponent
## Mestre em Armadura Pesada: dano contundente, cortante e perfurante cai nisto (0 = não reduz).
@export var reducao_fisica: int = 0
## Bônus de salvaguarda por atributo de quem não tem Condições (o herói). Com Condições, valem os dela.
var bonus_salvaguardas: Dictionary[StringName, int] = {}
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
	_aplicar_rajada_se_valer(golpe)
	var bonus_ca := bonus_ca_corpo_a_corpo if golpe.corpo_a_corpo else 0
	var resultado := _resolver(golpe, bonus_ca)
	if golpe.cd_salvaguarda == 0 and bonus_ca > 0 and not resultado.acertou and resultado.d20 != Combate.FALHA_AUTOMATICA and resultado.total >= classe_armadura:
		aparou.emit(origem)
	if golpe.tipo_dano in imunidades:
		resultado.dano = 0
	elif golpe.tipo_dano in vulnerabilidades and not resultado.resistido:
		resultado.dano *= 2
	if resultado.dano > 0 and reducao_fisica > 0 and golpe.tipo_dano in TiposDano.FISICOS:
		resultado.dano = maxi(resultado.dano - reducao_fisica, 0)
	if condicoes and resultado.acertou:  # efeitos que dependem da salvaguarda do alvo (Envenenador)
		for efeito in golpe.efeitos:
			resultado.dano += efeito.dano_no_alvo(golpe, resultado, condicoes)
	golpe.acertou_algum = golpe.acertou_algum or resultado.acertou
	if condicoes == null and resultado.acertou:
		_avisar_agarrao(golpe)
		_avisar_derrubada(golpe)
	_aplicar_fortitude(golpe, resultado)
	if resultado.dano > 0 and vida:
		vida.receber_dano(resultado.dano)
	if vida and resultado.acertou and not resultado.salvou and golpe.tem(Proficiencias.EFEITO_DRENAR_VIDA):
		vida.reduzir_maximo(resultado.dano)
	if condicoes and not (vida and vida.esta_morto()):
		condicoes.aplicar_maestria(resultado, signf(condicoes.global_position.x - origem.x))
	golpe.resolvido.emit(resultado, resultado.dano > 0 and vida != null and vida.esta_morto())
	golpe_resolvido.emit(resultado, origem)


## Dano de ambiente (lava, etc.): sem rolagem de ataque; imunidade/vulnerabilidade/resistência valem.
func receber_ambiente(golpe: Golpe, origem: Vector2) -> void:
	if invulneravel or (vida and vida.esta_morto()):
		return
	var resultado := Combate.resolver_ambiente(golpe, rng, resistencias, imunidades, vulnerabilidades)
	if resultado.dano > 0 and vida:
		vida.receber_dano(resultado.dano)
	golpe.resolvido.emit(resultado, resultado.dano > 0 and vida != null and vida.esta_morto())
	golpe_resolvido.emit(resultado, origem)


## Rajada: se o golpe tinha vantagem de verdade e o toggle pediu a troca, abre mão dela.
func _aplicar_rajada_se_valer(golpe: Golpe) -> void:
	if not golpe.pode_rajada or golpe.rajada == null:
		return
	if not Combate.teve_vantagem(golpe):
		return
	golpe.vantagem = false
	golpe.usou_rajada = true


## Ataque contra a CA, ou salvaguarda contra a CD do golpe (Borrifo Ácido).
func _resolver(golpe: Golpe, bonus_ca: int) -> Combate.Resultado:
	if golpe.cd_salvaguarda > 0:
		return Combate.resolver_salvaguarda(golpe, _bonus_de_salvaguarda(golpe.atributo_salvaguarda), rng, resistencias)
	return Combate.resolver_ataque(golpe, classe_armadura + bonus_ca, rng, resistencias)


func _bonus_de_salvaguarda(atributo: StringName) -> int:
	if condicoes:
		return condicoes.bonus_salvaguardas.get(atributo, 0)
	return bonus_salvaguardas.get(atributo, 0)


## Quem não tem Condições não guarda o Caído: avisa o dono, que cuida disso.
func _avisar_derrubada(golpe: Golpe) -> void:
	if golpe.efeito(Proficiencias.EFEITO_DERRUBADA) != null:
		derrubado.emit(golpe.autor_id)
		golpe.efeito_usado.emit(Proficiencias.EFEITO_DERRUBADA)

## Quem não tem Condições não guarda o agarrão: avisa o dono, que cuida disso.
func _avisar_agarrao(golpe: Golpe) -> void:
	var efeito := golpe.efeito(Proficiencias.EFEITO_AGARRAR) as EfeitosDeTalento.Agarrar
	if efeito != null:
		agarrado.emit(golpe.autor_id, efeito.cd)
		golpe.efeito_usado.emit(efeito.id)


## Fortitude dos Mortos-Vivos: o golpe mataria, então salvaguarda de Constituição (CD 5 + dano); se passar, sobra 1 PV.
## Não vale contra dano radiante nem acerto crítico.
func _aplicar_fortitude(golpe: Golpe, resultado: Combate.Resultado) -> void:
	if not fortitude_morto_vivo or vida == null or resultado.dano < vida.vida_atual:
		return
	if resultado.critico or golpe.tipo_dano == TiposDano.RADIANTE:
		return
	var cd := CD_BASE_FORTITUDE + resultado.dano
	if Combate.passou_salvaguarda(_bonus_de_salvaguarda(Atributos.CONSTITUICAO), cd, rng):
		resultado.dano = vida.vida_atual - 1
		fortitude_usada.emit()
