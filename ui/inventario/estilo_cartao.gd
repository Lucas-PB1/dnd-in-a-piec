class_name EstiloCartao
extends RefCounted
## Cores e molduras dos cartões da tela de inventário (slots de equipamento, atributos, etiquetas). Um lugar só,
## para os cartões terem o mesmo jeito. Regra de visual, sem estado.

const FUNDO := Color(0.17, 0.1, 0.05, 0.5)
const BORDA := Color(0.4, 0.28, 0.14, 1.0)
const TEXTO_FRACO := Color(0.78, 0.68, 0.55, 1.0)
const DOURADO := Color(1.0, 0.84, 0.4, 1.0)
## Uma cor por mão, igual nos slots, nos selos da lista e no resto: o jogador liga uma coisa à outra.
const COR_MAO_PRINCIPAL := Color(1.0, 0.82, 0.35, 1.0)
const COR_MAO_SECUNDARIA := Color(0.55, 0.78, 1.0, 1.0)
const COR_CORPO := Color(0.6, 0.9, 0.55, 1.0)
const COR_PV := Color(0.78, 0.2, 0.2, 1.0)
const COR_XP := Color(0.45, 0.35, 0.85, 1.0)
## Ácido / corrosão (Gray Ooze): selo e texto do item desgastado.
const COR_CORROSAO := Color(0.55, 0.9, 0.35, 1.0)
const SELO_CORROSAO := "~"
const RAIO := 3
const MARGEM := 4
const FAIXA_CORROSAO := 0.28


## Moldura de cartão: fundo escuro translúcido e borda da `cor_borda`.
static func cartao(cor_borda: Color = BORDA, espessura: int = 1) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = FUNDO
	estilo.border_color = cor_borda
	estilo.set_border_width_all(espessura)
	estilo.set_corner_radius_all(RAIO)
	estilo.set_content_margin_all(MARGEM)
	return estilo


## Barra cheia (a parte preenchida) com a `cor`.
static func preenchimento(cor: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(RAIO)
	return estilo


## A cor da mão ou do corpo onde o item está equipado.
static func cor_do_espaco(espaco: StringName) -> Color:
	match espaco:
		Item.ESPACO_MAO:
			return COR_MAO_PRINCIPAL
		Item.ESPACO_MAO_SECUNDARIA:
			return COR_MAO_SECUNDARIA
		Item.ESPACO_CORPO:
			return COR_CORPO
	return TEXTO_FRACO


## A letra do selo (P = mão principal, S = secundária, C = corpo).
static func selo_do_espaco(espaco: StringName) -> String:
	match espaco:
		Item.ESPACO_MAO:
			return "P"
		Item.ESPACO_MAO_SECUNDARIA:
			return "S"
		Item.ESPACO_CORPO:
			return "C"
	return ""
