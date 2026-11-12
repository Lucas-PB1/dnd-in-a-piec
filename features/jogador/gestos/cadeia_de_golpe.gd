class_name CadeiaDeGolpe
extends RefCounted
## Quantos golpes saem numa ação de Atacar (Ataque Extra e Surto) e quando o 2º J
## pede o golpe da outra mão. Sem Input e sem nó: o herói guarda o contador e a aura.


## Golpes da ação, já dobrados se o Surto estava armado. O da outra mão não entra.
static func golpes_na_acao(ficha: Ficha, surto_armado: bool) -> int:
	var base := 1 if ficha == null else ficha.golpes_por_ataque()
	return base * 2 if surto_armado else base


## Corte Duplo numa das armas leves: o extra não gasta a ação bônus.
static func tem_corte_duplo(ficha: Ficha, principal: Arma, segunda: Arma) -> bool:
	if ficha == null:
		return false
	var na_principal := principal != null and ficha.maestria_de(principal) == Proficiencias.CORTE_DUPLO
	var na_segunda := segunda != null and ficha.maestria_de(segunda) == Proficiencias.CORTE_DUPLO
	return na_principal or na_segunda


## Mestre em Armas de Haste: o extra é a outra ponta, não uma segunda arma.
static func e_cabo(ficha: Ficha, principal: Arma) -> bool:
	return ficha != null and ficha.tem_talento(Ficha.TALENTO_MESTRE_ARMAS_DE_HASTE) and ficha.e_arma_de_haste(principal)


## Duas armas leves (ou Empunhadura Dupla) e ação bônus livre, ou Corte Duplo.
static func pede_duas_armas(principal: Arma, segunda: Arma, ficha: Ficha, bonus_livre: bool) -> bool:
	if ficha == null or principal == null or principal.disparavel() or segunda == null or segunda.disparavel():
		return false
	var leves := principal.leve and (segunda.leve or ficha.tem_talento(Ficha.TALENTO_EMPUNHADURA_DUPLA))
	return leves and (tem_corte_duplo(ficha, principal, segunda) or bonus_livre)
