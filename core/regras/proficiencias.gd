class_name Proficiencias
extends RefCounted
## Categorias de proficiência do D&D 5e (armas e treinamento de armaduras).
## Arma sem proficiência: não soma o bônus de proficiência no ataque.
## Armadura sem treinamento: desvantagem em testes de FOR e DES (entra com as armaduras).

const ARMA_SIMPLES := &"simples"
const ARMA_MARCIAL := &"marcial"

const ARMADURA_LEVE := &"leve"
const ARMADURA_MEDIA := &"media"
const ARMADURA_PESADA := &"pesada"
const ESCUDO := &"escudo"

## Maestrias de arma (D&D 2024). O efeito de cada uma entra na fatia 11c.
const TRESPASSAR := &"trespassar"   # Cleave
const RASPAO := &"raspao"           # Graze
const CORTE_DUPLO := &"corte_duplo" # Nick
const EMPURRAR := &"empurrar"       # Push
const ENFRAQUECER := &"enfraquecer" # Sap
const LENTIDAO := &"lentidao"       # Slow
const DERRUBAR := &"derrubar"       # Topple
const ATORMENTAR := &"atormentar"   # Vex
const NOMES_MAESTRIAS := {
	TRESPASSAR: "Trespassar", RASPAO: "Raspão", CORTE_DUPLO: "Corte Duplo", EMPURRAR: "Empurrar",
	ENFRAQUECER: "Enfraquecer", LENTIDAO: "Lentidão", DERRUBAR: "Derrubar", ATORMENTAR: "Atormentar",
}

const NOMES_ARMAS := {ARMA_SIMPLES: "simples", ARMA_MARCIAL: "marciais"}
const NOMES_ARMADURAS := {ARMADURA_LEVE: "leves", ARMADURA_MEDIA: "médias", ARMADURA_PESADA: "pesadas", ESCUDO: "escudos"}
const NOMES_CATEGORIA_ARMA := {ARMA_SIMPLES: "simples", ARMA_MARCIAL: "marcial"}


## "armas simples e marciais"
static func texto_armas(categorias: Array[StringName]) -> String:
	return "armas %s" % _juntar(categorias, NOMES_ARMAS) if not categorias.is_empty() else "nenhuma arma"


## "armaduras leves, médias, pesadas e escudos"
static func texto_armaduras(categorias: Array[StringName]) -> String:
	return "armaduras %s" % _juntar(categorias, NOMES_ARMADURAS) if not categorias.is_empty() else "nenhuma armadura"


## Junta como em português: "a", "a e b", "a, b e c".
static func _juntar(categorias: Array[StringName], nomes: Dictionary) -> String:
	var partes: PackedStringArray = []
	for categoria in categorias:
		partes.append(nomes.get(categoria, String(categoria)))
	if partes.size() <= 1:
		return "".join(partes)
	return "%s e %s" % [", ".join(partes.slice(0, partes.size() - 1)), partes[partes.size() - 1]]
