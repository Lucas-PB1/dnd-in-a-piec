class_name Equipamento
extends RefCounted
## Regras que juntam a ficha com o que está equipado no inventário (arma, armadura, escudo).
## Usado pelo herói (combate e movimento) e pela tela de inventário (ficha), para os dois
## calcularem igual. Regra pura.


## Arma na mão, ou o ataque `desarmado` se a mão estiver vazia.
static func arma(inventario: Inventario, desarmado: Arma) -> Arma:
	var na_mao := inventario.equipado(Item.ESPACO_MAO) as Arma
	return na_mao if na_mao else desarmado


static func armadura(inventario: Inventario) -> Armadura:
	return inventario.equipado(Item.ESPACO_CORPO) as Armadura


static func escudo(inventario: Inventario) -> Armadura:
	return inventario.equipado(Item.ESPACO_MAO_SECUNDARIA) as Armadura


## CA com a armadura e o escudo vestidos, já com o desgaste da armadura.
static func classe_armadura(ficha: Ficha, inventario: Inventario) -> int:
	var vestida := armadura(inventario)
	return ficha.classe_armadura(vestida, escudo(inventario), inventario.penalidade(vestida))


## Deslocamento (pés), com a perda por falta de Força para a armadura.
static func deslocamento_pes(ficha: Ficha, inventario: Inventario) -> float:
	return ficha.deslocamento_pes(armadura(inventario))


## Bônus de ataque com a arma, já sem o desgaste dela.
static func bonus_ataque(ficha: Ficha, inventario: Inventario, com_arma: Arma) -> int:
	return ficha.bonus_ataque(com_arma) - inventario.penalidade(com_arma)


## O golpe da arma: desgaste da arma e desvantagem por armadura sem treinamento.
static func golpe(ficha: Ficha, inventario: Inventario, com_arma: Arma) -> Golpe:
	return ficha.golpe_com(com_arma, inventario.penalidade(com_arma), armadura(inventario))
