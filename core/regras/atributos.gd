class_name Atributos
extends RefCounted
## Os seis atributos de D&D e o cálculo do modificador. Regra pura.

const FORCA := &"forca"
const DESTREZA := &"destreza"
const CONSTITUICAO := &"constituicao"
const INTELIGENCIA := &"inteligencia"
const SABEDORIA := &"sabedoria"
const CARISMA := &"carisma"

## Ordem em que aparecem na ficha.
const TODOS: Array[StringName] = [FORCA, DESTREZA, CONSTITUICAO, INTELIGENCIA, SABEDORIA, CARISMA]

const NOMES := {
	FORCA: "Força", DESTREZA: "Destreza", CONSTITUICAO: "Constituição",
	INTELIGENCIA: "Inteligência", SABEDORIA: "Sabedoria", CARISMA: "Carisma",
}
const SIGLAS := {
	FORCA: "FOR", DESTREZA: "DES", CONSTITUICAO: "CON",
	INTELIGENCIA: "INT", SABEDORIA: "SAB", CARISMA: "CAR",
}

## Valor "médio" de um atributo (modificador zero).
const VALOR_MEDIO := 10


## Modificador de D&D: (valor - 10) / 2, arredondado para baixo. Ex.: 8 -> -1, 15 -> +2.
static func modificador(valor: int) -> int:
	return floori((valor - VALOR_MEDIO) / 2.0)


## Modificador com sinal, para mostrar na tela: "+2", "-1", "+0".
static func texto_modificador(valor: int) -> String:
	var mod := modificador(valor)
	return ("+%d" % mod) if mod >= 0 else str(mod)
