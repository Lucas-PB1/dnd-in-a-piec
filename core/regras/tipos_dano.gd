class_name TiposDano
extends RefCounted
## Tipos de dano do D&D 5e (os que o jogo usa por enquanto) e o efeito da resistência.

const CONTUNDENTE := &"contundente"
const CORTANTE := &"cortante"
const PERFURANTE := &"perfurante"
## O dano das armas e dos monstros que a armadura pesada ensina a aguentar (Mestre em Armadura Pesada).
const FISICOS: Array[StringName] = [CONTUNDENTE, CORTANTE, PERFURANTE]
const ACIDO := &"acido"
const FRIO := &"frio"
const FOGO := &"fogo"
const VENENO := &"veneno"

const NOMES := {
	CONTUNDENTE: "contundente", CORTANTE: "cortante", PERFURANTE: "perfurante",
	ACIDO: "ácido", FRIO: "frio", FOGO: "fogo", VENENO: "veneno",
}


static func nome(tipo: StringName) -> String:
	return NOMES.get(tipo, String(tipo))


## Resistência: o dano cai pela metade, arredondado para baixo (pode chegar a 0).
static func aplicar_resistencia(dano: int) -> int:
	return floori(dano / 2.0)
