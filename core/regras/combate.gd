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


## Rola o ataque do `golpe` contra a `ca` do alvo (e o dano, se acertar), aplicando
## as `resistencias` do alvo (tipos de dano).
static func resolver_ataque(golpe: Golpe, ca: int, rng: RandomNumberGenerator,
		resistencias: Array[StringName] = []) -> Resultado:
	var r := Resultado.new()
	r.golpe = golpe
	r.d20 = rolar_d20(rng, golpe.desvantagem)
	r.total = r.d20 + golpe.bonus_ataque
	r.critico = r.d20 == ACERTO_CRITICO
	r.acertou = r.critico or (r.d20 != FALHA_AUTOMATICA and r.total >= ca)
	if r.acertou:
		r.dano = maxi(golpe.dano.rolar(rng, r.critico), DANO_MINIMO)
		r.resistido = golpe.tipo_dano in resistencias
		if r.resistido:
			r.dano = TiposDano.aplicar_resistencia(r.dano)
	return r


## Rola uma salvaguarda: true se d20 + `bonus` alcançar a `cd`.
static func passou_salvaguarda(bonus: int, cd: int, rng: RandomNumberGenerator, desvantagem: bool = false) -> bool:
	return rolar_d20(rng, desvantagem) + bonus >= cd


## Um d20; com desvantagem, rola dois e fica com o menor.
static func rolar_d20(rng: RandomNumberGenerator, desvantagem: bool = false) -> int:
	var d20 := rng.randi_range(1, FACES_D20)
	if desvantagem:
		d20 = mini(d20, rng.randi_range(1, FACES_D20))
	return d20
