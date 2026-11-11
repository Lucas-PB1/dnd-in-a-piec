class_name Saque
extends RefCounted
## O que um inimigo derrotado solta: ouro e, às vezes, uma arma.
## Intimidação melhora o ouro; Sobrevivência a chance de arma (bônus passivo da perícia).

## Cada ponto do bônus de Intimidação muda o ouro nesta fração (+10% por ponto, -10% se negativo).
const OURO_POR_PONTO := 0.1
## O ouro nunca cai abaixo desta fração do valor da criatura, mesmo com Intimidação baixa.
const OURO_MINIMO := 0.5
## O ouro sorteado varia nesta faixa em volta do valor da criatura (0,5 a 1,5 vezes).
const VARIACAO_DO_OURO := Vector2(0.5, 1.5)
## Chance de soltar arma com bônus 0 de Sobrevivência, e quanto cada ponto soma.
const CHANCE_BASE_DE_ARMA := 0.15
const CHANCE_POR_PONTO := 0.03
const CHANCE_MINIMA_DE_ARMA := 0.05
const CHANCE_MAXIMA_DE_ARMA := 0.5
## Entre as armas de saque, a chance de vir mágica: +1 comum, +2 rara, +3 raríssima (o resto é comum).
const CHANCE_MAIS_1 := 0.2
const CHANCE_MAIS_2 := 0.05
const CHANCE_MAIS_3 := 0.01


## Ouro que a criatura solta: valor dela, sorteado e ajustado pela Intimidação. 0 se ela não vale ouro.
static func ouro(valor_da_criatura: int, bonus_intimidacao: int, rng: RandomNumberGenerator) -> int:
	if valor_da_criatura <= 0:
		return 0
	var sorteio := rng.randf_range(VARIACAO_DO_OURO.x, VARIACAO_DO_OURO.y)
	var fator := maxf(1.0 + OURO_POR_PONTO * bonus_intimidacao, OURO_MINIMO)
	return maxi(roundi(valor_da_criatura * sorteio * fator), 1)


## Chance (0 a 1) de soltar uma arma, com o bônus de Sobrevivência do herói.
static func chance_de_arma(bonus_sobrevivencia: int) -> float:
	return clampf(
		CHANCE_BASE_DE_ARMA + CHANCE_POR_PONTO * bonus_sobrevivencia,
		CHANCE_MINIMA_DE_ARMA,
		CHANCE_MAXIMA_DE_ARMA,
	)


## Uma arma nova (cópia) se a sorte deixar, ou null.
static func arma(bonus_sobrevivencia: int, rng: RandomNumberGenerator) -> Item:
	if rng.randf() >= chance_de_arma(bonus_sobrevivencia):
		return null
	return _com_bonus_sorteado(ItemAleatorio.sortear(rng, true), rng)


## Quase toda arma de saque é comum; algumas vêm mágicas (+1 mais comum, +3 raríssima).
static func _com_bonus_sorteado(item: Item, rng: RandomNumberGenerator) -> Item:
	if not item is Arma:
		return item
	var sorte := rng.randf()
	var bonus := 0
	if sorte < CHANCE_MAIS_3:
		bonus = 3
	elif sorte < CHANCE_MAIS_3 + CHANCE_MAIS_2:
		bonus = 2
	elif sorte < CHANCE_MAIS_3 + CHANCE_MAIS_2 + CHANCE_MAIS_1:
		bonus = 1
	return (item as Arma).com_bonus_magico(bonus)
