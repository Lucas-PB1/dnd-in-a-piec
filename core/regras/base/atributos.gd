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

## O que cada atributo faz NESTE jogo (mostrado na criação e na ficha).
const DESCRICOES := {
	FORCA: "Acerto e dano das armas corpo a corpo (menos as de Acuidade) e das arremessadas. Também decide se aguenta armaduras e armas pesadas.",
	DESTREZA: "Classe de Armadura, iniciativa (ritmo dos golpes), acerto e dano de armas de Acuidade e de disparo, e a força do tiro.",
	CONSTITUICAO: "Pontos de vida: cada nível dá mais vida quanto maior for. Também ajuda nas salvaguardas contra veneno.",
	INTELIGENCIA: "Perícias de conhecimento (Arcanismo, História, Investigação, Natureza e Religião). Não muda o combate do Guerreiro.",
	SABEDORIA: "Perícias de percepção (Intuição, Percepção, Sobrevivência...) — Sobrevivência aumenta a chance de arma no saque — e a salvaguarda contra medo e encantos.",
	CARISMA: "Perícias sociais: Persuasão dá desconto na loja; Intimidação aumenta o ouro do saque.",
}

## Valor "médio" de um atributo (modificador zero).
const VALOR_MEDIO := 10


## "Força: acerto e dano..." — o nome e o que o atributo faz, para dicas na tela.
static func dica(atributo: StringName) -> String:
	return "%s: %s" % [NOMES[atributo], DESCRICOES[atributo]]


## Modificador de D&D: (valor - 10) / 2, arredondado para baixo. Ex.: 8 -> -1, 15 -> +2.
static func modificador(valor: int) -> int:
	return floori((valor - VALOR_MEDIO) / 2.0)


## Modificador com sinal, para mostrar na tela: "+2", "-1", "+0".
static func texto_modificador(valor: int) -> String:
	return texto_bonus(modificador(valor))


## Qualquer bônus com sinal: 4 -> "+4", -1 -> "-1", 0 -> "+0".
static func texto_bonus(bonus: int) -> String:
	return ("+%d" % bonus) if bonus >= 0 else str(bonus)
