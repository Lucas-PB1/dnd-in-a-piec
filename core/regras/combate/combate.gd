class_name Combate
extends RefCounted
## Resolução de ataques e salvaguardas do D&D 5e. Regra pura.
## Ataque: d20 + bônus >= CA acerta. 20 natural = crítico (acerta sempre, dados de dano em
## dobro). 1 natural erra sempre. Resistência ao tipo do golpe = dano pela metade.
## Salvaguarda: d20 + bônus >= CD passa.

const FACES_D20 := 20
const ACERTO_CRITICO := 20
const FALHA_AUTOMATICA := 1
## Dano mínimo de um acerto antes da resistência (com modificador negativo poderia dar 0).
const DANO_MINIMO := 1


## Resultado de um ataque resolvido.
class Resultado:
	var golpe: Golpe
	var d20: int
	var total: int
	var acertou: bool
	var critico: bool
	## True se o alvo resistiu ao tipo de dano (dano pela metade).
	var resistido: bool
	var dano: int
	## Errou, mas a maestria Raspão causou dano mesmo assim.
	var raspao: bool
	## Golpe de salvaguarda: o alvo passou (levou metade).
	var salvou: bool


## Rola o ataque do `golpe` contra a `ca` do alvo (e o dano, se acertar), aplicando
## as `resistencias` do alvo (tipos de dano).
static func resolver_ataque(golpe: Golpe, ca: int, rng: RandomNumberGenerator,
		resistencias: Array[StringName] = []) -> Resultado:
	var r := Resultado.new()
	r.golpe = golpe
	r.d20 = rolar_d20(rng, golpe.desvantagem, golpe.vantagem)
	r.total = r.d20 + golpe.bonus_ataque
	# Natural 20 sempre acerta; crítico no limiar (20 ou 19 do Campeão) só se o ataque acertou.
	var natural_vinte := r.d20 == ACERTO_CRITICO
	r.acertou = natural_vinte or (r.d20 != FALHA_AUTOMATICA and r.total >= ca)
	r.critico = r.acertou and r.d20 >= golpe.limiar_critico
	if r.acertou:
		r.dano = dano_do_acerto(golpe, rng, r.critico)
		r.resistido = golpe.tipo_dano in resistencias
		if r.resistido:
			r.dano = TiposDano.aplicar_resistencia(r.dano)
	elif golpe.dano_raspao > 0:
		_aplicar_raspao(r, golpe, resistencias)
	return r


## Dano de um acerto. Com vantagem (e sem desvantagem anulando), soma o dado extra.
## No crítico os dois dados dobram; o bônus de cada um não.
static func dano_do_acerto(golpe: Golpe, rng: RandomNumberGenerator, critico: bool) -> int:
	var dano := _rolar_dano(golpe, rng, critico)
	if golpe.rola_duas_vezes():  # Atacante Selvagem: rola de novo e fica o maior
		dano = maxi(dano, _rolar_dano(golpe, rng, critico))
	for efeito in golpe.efeitos:  # Investida, Veneno Básico: dano a mais
		dano += efeito.dano_extra(golpe, rng, critico)
	for efeito in golpe.efeitos:
		efeito.ao_causar_dano(golpe)
	return maxi(dano, DANO_MINIMO)


static func _rolar_dano(golpe: Golpe, rng: RandomNumberGenerator, critico: bool) -> int:
	var gwf := golpe.trata_um_e_dois_como_tres()
	var dano := golpe.dano.rolar_perfurador(rng, critico) if golpe.rerrola_menor() \
		else golpe.dano.rolar(rng, critico, golpe.rerrola_um(), gwf)
	if teve_vantagem(golpe) and golpe.dano_extra != null:
		dano += golpe.dano_extra.rolar(rng, critico, golpe.rerrola_um(), gwf)
	return dano


## O ataque saiu com vantagem de verdade (as duas juntas se anulam, como no d20).
static func teve_vantagem(golpe: Golpe) -> bool:
	return golpe.vantagem and not golpe.desvantagem


## Raspão (maestria): errou, mas causa o modificador do ataque como dano (resistência vale).
static func _aplicar_raspao(r: Resultado, golpe: Golpe, resistencias: Array[StringName]) -> void:
	r.raspao = true
	r.dano = golpe.dano_raspao
	r.resistido = golpe.tipo_dano in resistencias
	if r.resistido:
		r.dano = TiposDano.aplicar_resistencia(r.dano)


## Golpe de salvaguarda (Borrifo Ácido): o alvo rola d20 + `bonus` contra a CD do golpe; falhou, dano inteiro; passou, metade.
## `acertou` fica true quando há dano (o alvo reage e mostra o número como num acerto).
static func resolver_salvaguarda(golpe: Golpe, bonus: int, rng: RandomNumberGenerator,
		resistencias: Array[StringName] = []) -> Resultado:
	var r := Resultado.new()
	r.golpe = golpe
	r.d20 = rolar_d20(rng)
	r.total = r.d20 + bonus
	r.salvou = r.total >= golpe.cd_salvaguarda
	r.dano = dano_do_acerto(golpe, rng, false)
	if r.salvou:
		r.dano = TiposDano.aplicar_resistencia(r.dano)
	r.resistido = golpe.tipo_dano in resistencias
	if r.resistido:
		r.dano = TiposDano.aplicar_resistencia(r.dano)
	r.acertou = r.dano > 0
	return r


## Rola uma salvaguarda: true se d20 + `bonus` alcançar a `cd`.
static func passou_salvaguarda(bonus: int, cd: int, rng: RandomNumberGenerator, desvantagem: bool = false) -> bool:
	return rolar_d20(rng, desvantagem) + bonus >= cd


## Dano de ambiente (lava, etc.): sempre aplica, sem ataque nem salvaguarda. Imunidade zera;
## vulnerabilidade dobra; resistência pela metade.
static func resolver_ambiente(golpe: Golpe, rng: RandomNumberGenerator,
		resistencias: Array[StringName] = [], imunidades: Array[StringName] = [],
		vulnerabilidades: Array[StringName] = []) -> Resultado:
	var r := Resultado.new()
	r.golpe = golpe
	r.acertou = true
	if golpe.tipo_dano in imunidades:
		r.dano = 0
		return r
	r.dano = maxi(golpe.dano.rolar(rng), DANO_MINIMO)
	if golpe.tipo_dano in vulnerabilidades:
		r.dano *= 2
	r.resistido = golpe.tipo_dano in resistencias
	if r.resistido:
		r.dano = TiposDano.aplicar_resistencia(r.dano)
	return r


## Um d20; com desvantagem, rola dois e fica com o menor; com vantagem, o maior.
## Vantagem e desvantagem juntas se anulam (rola um só).
static func rolar_d20(rng: RandomNumberGenerator, desvantagem: bool = false, vantagem: bool = false) -> int:
	var d20 := rng.randi_range(1, FACES_D20)
	if desvantagem and not vantagem:
		d20 = mini(d20, rng.randi_range(1, FACES_D20))
	elif vantagem and not desvantagem:
		d20 = maxi(d20, rng.randi_range(1, FACES_D20))
	return d20
